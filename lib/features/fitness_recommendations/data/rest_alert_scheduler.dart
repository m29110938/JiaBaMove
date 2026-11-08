import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// 組間休息結束提醒排程 (App 在背景或鎖屏時仍能提醒)
abstract class RestAlertScheduler {
  /// 在 [after] 之後發出「休息結束」提醒；會取代先前排程的提醒
  Future<void> schedule(Duration after, {String? exerciseName});

  /// 取消尚未發出的提醒 (並移除已顯示的同一則提醒)
  Future<void> cancel();
}

/// 不做任何事的排程器 (測試或不支援的平台使用)
class NoopRestAlertScheduler implements RestAlertScheduler {
  const NoopRestAlertScheduler();

  @override
  Future<void> schedule(Duration after, {String? exerciseName}) async {}

  @override
  Future<void> cancel() async {}
}

/// 以 iOS 本地通知實作的提醒排程器
///
/// - 只在 iOS 上啟用，其他平台自動略過。
/// - 第一次排程時才向使用者請求通知權限 (而非 App 啟動時)。
/// - App 在前景時不跳橫幅 (畫面上已有計時面板與提示)，只播放提示音。
class LocalNotificationRestAlertScheduler implements RestAlertScheduler {
  LocalNotificationRestAlertScheduler({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const int _notificationId = 7001;

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;
  bool _permissionRequested = false;

  bool get _isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> _ensureReady() async {
    if (!_isSupported) return false;
    if (!_initialized) {
      await _plugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestSoundPermission: false,
            requestBadgePermission: false,
          ),
        ),
      );
      _initialized = true;
    }
    if (!_permissionRequested) {
      _permissionRequested = true;
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, sound: true);
    }
    return true;
  }

  @override
  Future<void> schedule(Duration after, {String? exerciseName}) async {
    try {
      if (!await _ensureReady()) return;
      await _plugin.cancel(id: _notificationId);
      final fireAt = tz.TZDateTime.now(tz.UTC).add(after);
      await _plugin.zonedSchedule(
        id: _notificationId,
        scheduledDate: fireAt,
        title: '🔔 休息結束！',
        body: exerciseName != null
            ? '「$exerciseName」準備下一組！'
            : '準備下一組！',
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(
            presentAlert: false,
            presentBanner: false,
            presentList: false,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule rest alert: $e');
    }
  }

  @override
  Future<void> cancel() async {
    if (!_isSupported || !_initialized) return;
    try {
      await _plugin.cancel(id: _notificationId);
    } catch (e) {
      debugPrint('Failed to cancel rest alert: $e');
    }
  }
}
