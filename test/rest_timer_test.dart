import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/core/storage/secure_storage_service.dart';
import 'package:jiaba_move/features/fitness_recommendations/data/rest_alert_scheduler.dart';
import 'package:jiaba_move/features/fitness_recommendations/domain/entities/daily_workout_item_entity.dart';
import 'package:jiaba_move/features/fitness_recommendations/domain/entities/workout_plan_entity.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/controllers/rest_timer_controller.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/controllers/workout_controller.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/views/fitness_recommendations_view.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/widgets/rest_timer_floating_widget.dart';

class MockSecureStorageService extends SecureStorageService {
  bool _auto = true;

  @override
  Future<bool> getRestTimerAutoTrigger() async => _auto;

  @override
  Future<void> saveRestTimerAutoTrigger(bool autoTrigger) async {
    _auto = autoTrigger;
  }

  @override
  Future<String?> getDailyWorkoutItemsJson() async => null;

  @override
  Future<void> saveDailyWorkoutItemsJson(String json) async {}

  @override
  Future<String?> getCustomExercisesByBodyPartJson() async => null;

  @override
  Future<void> saveCustomExercisesByBodyPartJson(String json) async {}
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async => null);
  });

  group('RestTimer Unit Tests', () {
    test('RestTimerState formattedTime & progress calculation', () {
      const state = RestTimerState(
        totalSeconds: 60,
        remainingSeconds: 45,
        status: RestTimerStatus.running,
      );

      expect(state.formattedTime, '00:45');
      expect(state.progress, 0.75);
      expect(state.isRunning, isTrue);
      expect(state.isActive, isTrue);
      expect(state.isVisible, isTrue);
      expect(state.isPaused, isFalse);
      expect(state.isFinished, isFalse);

      const state2 = RestTimerState(
        totalSeconds: 90,
        remainingSeconds: 70,
        status: RestTimerStatus.paused,
      );
      expect(state2.formattedTime, '01:10');
      expect(state2.isPaused, isTrue);
      expect(state2.isActive, isTrue);
    });

    test('RestTimerNotifier lifecycle: start, pause, resume, adjust, skip, and reset', () async {
      final mockStorage = MockSecureStorageService();
      final notifier = RestTimerNotifier(storageService: mockStorage);
      await notifier.loadPreferences();

      expect(notifier.state.status, RestTimerStatus.idle);
      expect(notifier.state.isVisible, isFalse);

      // 啟動 60 秒
      notifier.startTimer(60, exerciseName: '槓鈴深蹲');
      expect(notifier.state.status, RestTimerStatus.running);
      expect(notifier.state.totalSeconds, 60);
      expect(notifier.state.remainingSeconds, 60);
      expect(notifier.state.currentExerciseName, '槓鈴深蹲');

      // 暫停
      notifier.pauseTimer();
      expect(notifier.state.status, RestTimerStatus.paused);
      expect(notifier.state.isPaused, isTrue);

      // 恢復
      notifier.resumeTimer();
      expect(notifier.state.status, RestTimerStatus.running);

      // 增加 15 秒
      notifier.adjustSeconds(15);
      expect(notifier.state.remainingSeconds, 75);
      expect(notifier.state.totalSeconds, 75);

      // 減少 15 秒
      notifier.adjustSeconds(-15);
      expect(notifier.state.remainingSeconds, 60);

      // 跳過
      notifier.skipOrFinish();
      expect(notifier.state.status, RestTimerStatus.finished);
      expect(notifier.state.remainingSeconds, 0);

      // 關閉完成訊息
      notifier.dismissFinished();
      expect(notifier.state.status, RestTimerStatus.idle);

      // 最小化切換
      expect(notifier.state.isMinimized, isFalse);
      notifier.toggleMinimized();
      expect(notifier.state.isMinimized, isTrue);
      notifier.setMinimized(false);
      expect(notifier.state.isMinimized, isFalse);

      // 自動觸發偏好切換
      final initialAuto = notifier.state.autoTriggerOnCheck;
      await notifier.toggleAutoTrigger();
      expect(notifier.state.autoTriggerOnCheck, !initialAuto);

      notifier.reset();
      notifier.dispose();
    });
  });

  group('RestTimerFloatingWidget Widget Tests', () {
    testWidgets('Renders nothing when timer is idle', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RestTimerFloatingWidget(),
            ),
          ),
        ),
      );

      expect(find.byType(RestTimerFloatingWidget), findsOneWidget);
      expect(find.byKey(const Key('rest_timer_expanded_card')), findsNothing);
      expect(find.byKey(const Key('rest_timer_minimized_bubble')), findsNothing);
    });

    testWidgets('Renders expanded card and interactive controls when timer is running', (tester) async {
      final container = ProviderContainer();
      addTearDown(() {
        container.read(restTimerControllerProvider.notifier).reset();
        container.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: RestTimerFloatingWidget(),
            ),
          ),
        ),
      );

      // 啟動計時器
      container.read(restTimerControllerProvider.notifier).startTimer(90, exerciseName: '臥推');
      await tester.pump();

      // 驗證展開卡片存在
      expect(find.byKey(const Key('rest_timer_expanded_card')), findsOneWidget);
      expect(find.text('01:30'), findsOneWidget);
      expect(find.text('組間休息：臥推'), findsOneWidget);
      expect(find.text('倒數進行中...'), findsOneWidget);

      // 驗證常用秒數快捷鍵存在
      expect(find.byKey(const Key('rest_timer_chip_30s')), findsOneWidget);
      expect(find.byKey(const Key('rest_timer_chip_60s')), findsOneWidget);
      expect(find.byKey(const Key('rest_timer_chip_90s')), findsOneWidget);
      expect(find.byKey(const Key('rest_timer_chip_120s')), findsOneWidget);

      // 點擊 +15s
      await tester.tap(find.byKey(const Key('rest_timer_plus_15_btn')));
      await tester.pump();
      expect(find.text('01:45'), findsOneWidget);

      // 點擊暫停
      await tester.tap(find.byKey(const Key('rest_timer_play_pause_btn')));
      await tester.pump();
      expect(find.text('已暫停'), findsOneWidget);

      // 點擊最小化按鈕
      await tester.tap(find.byKey(const Key('rest_timer_minimize_btn')));
      await tester.pump();

      // 驗證轉為最小化氣泡
      expect(find.byKey(const Key('rest_timer_minimized_bubble')), findsOneWidget);
      expect(find.byKey(const Key('rest_timer_expanded_card')), findsNothing);

      // 點擊氣泡展開
      await tester.tap(find.byKey(const Key('rest_timer_minimized_bubble')));
      await tester.pump();
      expect(find.byKey(const Key('rest_timer_expanded_card')), findsOneWidget);

      // 點擊跳過
      await tester.tap(find.byKey(const Key('rest_timer_skip_btn')));
      await tester.pump();
      expect(find.text('🔔 休息結束！準備下一組！'), findsOneWidget);
      expect(find.byKey(const Key('rest_timer_finished_ok_btn')), findsOneWidget);

      // 點擊完成按鈕關閉
      await tester.tap(find.byKey(const Key('rest_timer_finished_ok_btn')));
      await tester.pump();
      expect(find.byKey(const Key('rest_timer_expanded_card')), findsNothing);
    });
  });

  group('FitnessRecommendationsView RestTimer Integration Tests', () {
    testWidgets('Tapping timer icon in AppBar starts rest timer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(() {
        container.read(restTimerControllerProvider.notifier).reset();
        container.dispose();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FitnessRecommendationsView(),
          ),
        ),
      );
      await tester.pump();

      // 點擊 AppBar 上的碼錶按鈕
      final timerBtn = find.byKey(const Key('appbar_rest_timer_btn'));
      expect(timerBtn, findsOneWidget);
      await tester.tap(timerBtn);
      await tester.pump();
      await tester.pump();

      // 驗證展開計時卡片出現
      expect(find.byKey(const Key('rest_timer_expanded_card')), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);

      // 重設計時器以清理待定 timer
      container.read(restTimerControllerProvider.notifier).reset();
      await tester.pump();
    });

    testWidgets('Checking an uncompleted daily workout item auto-triggers rest timer', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(() {
        container.read(restTimerControllerProvider.notifier).reset();
        container.dispose();
      });

      // 預先加入一項未完成動作
      const item = DailyWorkoutItemEntity(
        id: 'test_item_1',
        dateString: '2026-10-10',
        exerciseName: '羅馬尼亞硬舉',
        targetBodyPart: TargetBodyPart.legs,
        weightKg: 60,
        reps: 10,
        sets: 3,
      );

      await container.read(workoutControllerProvider.notifier).addDailyWorkoutItem(item);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: FitnessRecommendationsView(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('羅馬尼亞硬舉'), findsOneWidget);
      expect(find.byKey(const Key('rest_timer_expanded_card')), findsNothing);

      // 點擊勾選圓圈
      final checkCircle = find.byWidgetPredicate(
        (widget) => widget is GestureDetector && widget.child is Container,
      );
      expect(checkCircle, findsWidgets);
      await tester.tap(checkCircle.first);
      await tester.pump();
      await tester.pump();

      // 驗證自動啟動休息計時器，且顯示動作名稱「羅馬尼亞硬舉」
      expect(find.byKey(const Key('rest_timer_expanded_card')), findsOneWidget);
      expect(find.text('組間休息：羅馬尼亞硬舉'), findsOneWidget);

      // 重設計時器以清理待定 timer
      container.read(restTimerControllerProvider.notifier).reset();
      await tester.pump();
    });
  });

  group('RestTimer 背景 / 鎖屏行為', () {
    late DateTime now;
    late FakeRestAlertScheduler alerts;
    late RestTimerNotifier notifier;

    setUp(() {
      now = DateTime(2026, 11, 8, 18, 0, 0);
      alerts = FakeRestAlertScheduler();
      notifier = RestTimerNotifier(
        storageService: MockSecureStorageService(),
        alertScheduler: alerts,
        clock: () => now,
      );
    });

    tearDown(() => notifier.dispose());

    test('依結束時間點計算剩餘秒數 (模擬鎖屏 40 秒後回來)', () {
      notifier.startTimer(90, exerciseName: '臥推');
      now = now.add(const Duration(seconds: 40));
      notifier.syncWithClock();
      expect(notifier.state.remainingSeconds, 50);
      expect(notifier.state.isRunning, isTrue);
    });

    test('鎖屏期間時間已到，回來時直接顯示完成', () {
      notifier.startTimer(60);
      now = now.add(const Duration(minutes: 3));
      notifier.syncWithClock();
      expect(notifier.state.isFinished, isTrue);
      expect(notifier.state.remainingSeconds, 0);
    });

    test('啟動時排程提醒，暫停 / 跳過 / 重設時取消提醒', () {
      notifier.startTimer(60, exerciseName: '深蹲');
      expect(alerts.scheduled, const Duration(seconds: 60));
      expect(alerts.exerciseName, '深蹲');

      now = now.add(const Duration(seconds: 20));
      notifier.pauseTimer();
      expect(notifier.state.remainingSeconds, 40);
      expect(alerts.scheduled, isNull);

      // 暫停期間時間不流逝
      now = now.add(const Duration(minutes: 5));
      notifier.resumeTimer();
      expect(notifier.state.remainingSeconds, 40);
      expect(alerts.scheduled, const Duration(seconds: 40));

      notifier.skipOrFinish();
      expect(alerts.scheduled, isNull);

      notifier.startTimer(30);
      notifier.reset();
      expect(alerts.scheduled, isNull);
    });

    test('倒數中調整秒數會以目前剩餘時間為基準並重新排程', () {
      notifier.startTimer(60);
      now = now.add(const Duration(seconds: 10));
      notifier.adjustSeconds(15);
      expect(notifier.state.remainingSeconds, 65);
      expect(alerts.scheduled, const Duration(seconds: 65));

      now = now.add(const Duration(seconds: 5));
      notifier.syncWithClock();
      expect(notifier.state.remainingSeconds, 60);
    });
  });
}

class FakeRestAlertScheduler implements RestAlertScheduler {
  Duration? scheduled;
  String? exerciseName;

  @override
  Future<void> schedule(Duration after, {String? exerciseName}) async {
    scheduled = after;
    this.exerciseName = exerciseName;
  }

  @override
  Future<void> cancel() async {
    scheduled = null;
  }
}
