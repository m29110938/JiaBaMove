import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/rest_alert_scheduler.dart';

/// 組間休息計時器狀態
enum RestTimerStatus {
  idle,
  running,
  paused,
  finished,
}

class RestTimerState {
  const RestTimerState({
    this.totalSeconds = 60,
    this.remainingSeconds = 60,
    this.status = RestTimerStatus.idle,
    this.isMinimized = false,
    this.autoTriggerOnCheck = true,
    this.currentExerciseName,
  });

  final int totalSeconds;
  final int remainingSeconds;
  final RestTimerStatus status;
  final bool isMinimized;
  final bool autoTriggerOnCheck;
  final String? currentExerciseName;

  bool get isRunning => status == RestTimerStatus.running;
  bool get isPaused => status == RestTimerStatus.paused;
  bool get isFinished => status == RestTimerStatus.finished;
  bool get isActive => status == RestTimerStatus.running || status == RestTimerStatus.paused;
  bool get isVisible => status != RestTimerStatus.idle;

  double get progress {
    if (totalSeconds <= 0) return 0.0;
    return (remainingSeconds / totalSeconds).clamp(0.0, 1.0);
  }

  String get formattedTime {
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  RestTimerState copyWith({
    int? totalSeconds,
    int? remainingSeconds,
    RestTimerStatus? status,
    bool? isMinimized,
    bool? autoTriggerOnCheck,
    String? currentExerciseName,
    bool clearExerciseName = false,
  }) {
    return RestTimerState(
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      status: status ?? this.status,
      isMinimized: isMinimized ?? this.isMinimized,
      autoTriggerOnCheck: autoTriggerOnCheck ?? this.autoTriggerOnCheck,
      currentExerciseName: clearExerciseName
          ? null
          : (currentExerciseName ?? this.currentExerciseName),
    );
  }
}

/// 休息結束提醒排程器 (iOS 本地通知)
final restAlertSchedulerProvider = Provider<RestAlertScheduler>((ref) {
  return LocalNotificationRestAlertScheduler();
});

final restTimerControllerProvider =
    StateNotifierProvider<RestTimerNotifier, RestTimerState>((ref) {
  return RestTimerNotifier(alertScheduler: ref.watch(restAlertSchedulerProvider));
});

/// 組間休息計時器
///
/// 以「結束時間點」計算剩餘秒數，而非每秒遞減：
/// iPhone 鎖屏或切到背景時 App 會被暫停，回到前景後仍能顯示正確的剩餘時間；
/// 同時排程本地通知，讓休息結束時即使鎖屏也會提醒。
class RestTimerNotifier extends StateNotifier<RestTimerState> {
  RestTimerNotifier({
    SecureStorageService? storageService,
    RestAlertScheduler? alertScheduler,
    DateTime Function()? clock,
  })  : _storage = storageService ?? SecureStorageService(),
        _alerts = alertScheduler ?? const NoopRestAlertScheduler(),
        _clock = clock ?? DateTime.now,
        super(const RestTimerState()) {
    loadPreferences();
  }

  final SecureStorageService _storage;
  final RestAlertScheduler _alerts;
  final DateTime Function() _clock;

  /// UI 更新用的輪詢計時器 (不負責計算時間)
  Timer? _ticker;

  /// 倒數中時的結束時間點；暫停 / 結束時為 null
  DateTime? _endAt;

  Future<void> loadPreferences() async {
    try {
      final auto = await _storage.getRestTimerAutoTrigger();
      if (!mounted) return;
      state = state.copyWith(autoTriggerOnCheck: auto);
    } catch (_) {}
  }

  /// 啟動指定秒數的休息計時
  void startTimer(int seconds, {String? exerciseName}) {
    final clamped = seconds.clamp(5, 600);
    state = state.copyWith(
      totalSeconds: clamped,
      remainingSeconds: clamped,
      status: RestTimerStatus.running,
      currentExerciseName: exerciseName,
      isMinimized: false,
    );
    _runFor(clamped);
  }

  /// 暫停計時
  void pauseTimer() {
    if (!state.isRunning) return;
    final remaining = _computeRemaining();
    _stopRunning();
    if (remaining <= 0) {
      _finish();
      return;
    }
    state = state.copyWith(
      remainingSeconds: remaining,
      status: RestTimerStatus.paused,
    );
  }

  /// 繼續計時
  void resumeTimer() {
    if (state.isPaused && state.remainingSeconds > 0) {
      state = state.copyWith(status: RestTimerStatus.running);
      _runFor(state.remainingSeconds);
    }
  }

  /// 調整剩餘秒數 (如 +15s 或 -15s)
  void adjustSeconds(int delta) {
    if (!state.isActive && !state.isFinished) {
      // 若尚未開始，直接調整預設秒數並開始
      final target = (state.totalSeconds + delta).clamp(15, 600);
      startTimer(target, exerciseName: state.currentExerciseName);
      return;
    }

    final current = state.isRunning ? _computeRemaining() : state.remainingSeconds;
    final newRemaining = (current + delta).clamp(1, 600);
    final newTotal =
        newRemaining > state.totalSeconds ? newRemaining : state.totalSeconds;
    final shouldRun = state.isRunning || state.isFinished;

    state = state.copyWith(
      remainingSeconds: newRemaining,
      totalSeconds: newTotal,
      status: shouldRun ? RestTimerStatus.running : state.status,
    );

    if (shouldRun) {
      _runFor(newRemaining);
    }
  }

  /// 跳過或立即完成休息
  void skipOrFinish() {
    _stopRunning();
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    state = state.copyWith(
      remainingSeconds: 0,
      status: RestTimerStatus.finished,
    );
  }

  /// 重設/關閉計時面板
  void reset() {
    _stopRunning();
    state = state.copyWith(
      remainingSeconds: state.totalSeconds,
      status: RestTimerStatus.idle,
      clearExerciseName: true,
      isMinimized: false,
    );
  }

  /// 關閉已完成狀態
  void dismissFinished() {
    state = state.copyWith(status: RestTimerStatus.idle, clearExerciseName: true);
  }

  /// 切換最小化氣泡狀態
  void toggleMinimized() {
    state = state.copyWith(isMinimized: !state.isMinimized);
  }

  /// 設定是否最小化
  void setMinimized(bool value) {
    state = state.copyWith(isMinimized: value);
  }

  /// 切換勾選動作時自動啟動
  Future<void> toggleAutoTrigger() async {
    final updated = !state.autoTriggerOnCheck;
    state = state.copyWith(autoTriggerOnCheck: updated);
    try {
      await _storage.saveRestTimerAutoTrigger(updated);
    } catch (_) {}
  }

  /// 依目前時間重新計算剩餘秒數 (App 回到前景時也會由輪詢自動呼叫)
  void syncWithClock() {
    if (!state.isRunning || _endAt == null) return;
    final remaining = _computeRemaining();
    if (remaining <= 0) {
      _stopRunning(cancelAlert: false);
      _finish();
    } else if (remaining != state.remainingSeconds) {
      state = state.copyWith(remainingSeconds: remaining);
    }
  }

  void _runFor(int seconds) {
    _endAt = _clock().add(Duration(seconds: seconds));
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => syncWithClock(),
    );
    _alerts.schedule(
      Duration(seconds: seconds),
      exerciseName: state.currentExerciseName,
    );
  }

  void _stopRunning({bool cancelAlert = true}) {
    _ticker?.cancel();
    _ticker = null;
    _endAt = null;
    if (cancelAlert) {
      _alerts.cancel();
    }
  }

  int _computeRemaining() {
    final endAt = _endAt;
    if (endAt == null) return state.remainingSeconds;
    final ms = endAt.difference(_clock()).inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / 1000).ceil();
  }

  void _finish() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
    state = state.copyWith(
      remainingSeconds: 0,
      status: RestTimerStatus.finished,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _alerts.cancel();
    super.dispose();
  }
}
