import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/core/storage/secure_storage_service.dart';
import 'package:jiaba_move/core/theme/app_theme.dart';
import 'package:jiaba_move/features/fitness_recommendations/domain/entities/daily_workout_item_entity.dart';
import 'package:jiaba_move/features/fitness_recommendations/domain/entities/workout_plan_entity.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/controllers/workout_controller.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/views/fitness_recommendations_view.dart';

class MockSecureStorageService extends SecureStorageService {
  String? _dailyJson;
  String? _customJson;

  @override
  Future<String?> getDailyWorkoutItemsJson() async => _dailyJson;

  @override
  Future<void> saveDailyWorkoutItemsJson(String json) async {
    _dailyJson = json;
  }

  @override
  Future<String?> getCustomExercisesByBodyPartJson() async => _customJson;

  @override
  Future<void> saveCustomExercisesByBodyPartJson(String json) async {
    _customJson = json;
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async => null);
  });

  group('Daily Workout Menu & Calorie Estimation Tests (CI/CD-First)', () {
    test('calculateWorkoutCalories calculates scientifically higher burn for leg/compound vs arms', () {
      // 槓鈴深蹲 80kg x 10次 x 4組 (臀腿大肌群)
      final squatCalories = DailyWorkoutItemEntity.calculateWorkoutCalories(
        bodyPart: TargetBodyPart.legs,
        weightKg: 80.0,
        reps: 10,
        sets: 4,
        userWeightKg: 70.0,
      );

      // 二頭彎舉 15kg x 10次 x 4組 (手臂小肌群)
      final curlCalories = DailyWorkoutItemEntity.calculateWorkoutCalories(
        bodyPart: TargetBodyPart.shouldersAndArms,
        weightKg: 15.0,
        reps: 10,
        sets: 4,
        userWeightKg: 70.0,
      );

      expect(squatCalories, greaterThan(curlCalories));
      expect(squatCalories, greaterThan(60));
      expect(curlCalories, greaterThan(15));
    });

    test('calculateWorkoutCalories handles zero weight bodyweight workouts correctly', () {
      final pushupCalories = DailyWorkoutItemEntity.calculateWorkoutCalories(
        bodyPart: TargetBodyPart.chest,
        weightKg: 0.0,
        reps: 15,
        sets: 3,
        userWeightKg: 70.0,
      );

      expect(pushupCalories, greaterThanOrEqualTo(15));
    });

    test('DailyWorkoutItemEntity serializes and deserializes to JSON accurately', () {
      const item = DailyWorkoutItemEntity(
        id: 'test_item_1',
        dateString: '2026-10-10',
        exerciseName: '槓鈴臥推',
        targetBodyPart: TargetBodyPart.chest,
        weightKg: 60.0,
        reps: 10,
        sets: 4,
        estimatedCalories: 75,
        isCompleted: true,
      );

      final jsonMap = item.toJson();
      final restored = DailyWorkoutItemEntity.fromJson(jsonMap);

      expect(restored.id, equals('test_item_1'));
      expect(restored.exerciseName, equals('槓鈴臥推'));
      expect(restored.targetBodyPart, equals(TargetBodyPart.chest));
      expect(restored.weightKg, equals(60.0));
      expect(restored.reps, equals(10));
      expect(restored.sets, equals(4));
      expect(restored.estimatedCalories, equals(75));
      expect(restored.isCompleted, isTrue);
      expect(restored.animationAsset, isNull);
      expect(restored.isCustom, isFalse);

      final gifItem = item.copyWith(
        animationAsset: 'assets/exercises/bench_press.gif',
        isCustom: false,
      );
      final restoredGif = DailyWorkoutItemEntity.fromJson(gifItem.toJson());
      expect(restoredGif.animationAsset, equals('assets/exercises/bench_press.gif'));
      expect(restoredGif.isCustom, isFalse);

      final customItem = item.copyWith(
        exerciseName: '我的專屬動作',
        animationAsset: null,
        isCustom: true,
      );
      final restoredCustom = DailyWorkoutItemEntity.fromJson(customItem.toJson());
      expect(restoredCustom.animationAsset, isNull);
      expect(restoredCustom.isCustom, isTrue);
    });

    test('WorkoutNotifier manages daily workout items and toggle completion', () async {
      final mockStorage = MockSecureStorageService();
      final notifier = WorkoutNotifier(storageService: mockStorage);

      expect(notifier.state.dailyWorkoutItems, isEmpty);
      expect(notifier.state.totalCaloriesBurned, equals(0));

      final item1 = DailyWorkoutItemEntity(
        id: 'item_1',
        dateString: notifier.state.currentDateString,
        exerciseName: '啞鈴側平舉',
        targetBodyPart: TargetBodyPart.shouldersAndArms,
        weightKg: 10.0,
        reps: 12,
        sets: 4,
        isCompleted: false,
      );

      await notifier.addDailyWorkoutItem(item1);
      expect(notifier.state.dailyWorkoutItems.length, equals(1));
      expect(notifier.state.totalCaloriesBurned, equals(0));

      // 勾選完成打卡
      await notifier.toggleDailyWorkoutItemCompleted('item_1');
      expect(notifier.state.dailyWorkoutItems.first.isCompleted, isTrue);
      // 運動熱量依使用者指示全數移除，保持為 0
      expect(notifier.state.totalCaloriesBurned, equals(0));

      // 再次切換為未完成
      await notifier.toggleDailyWorkoutItemCompleted('item_1');
      expect(notifier.state.dailyWorkoutItems.first.isCompleted, isFalse);
      expect(notifier.state.totalCaloriesBurned, equals(0));

      // 刪除該項目
      await notifier.deleteDailyWorkoutItem('item_1');
      expect(notifier.state.dailyWorkoutItems, isEmpty);
    });

    test('WorkoutNotifier manages custom exercises by body part and persists to storage', () async {
      final mockStorage = MockSecureStorageService();
      final notifier = WorkoutNotifier(storageService: mockStorage);

      expect(notifier.state.customExercisesByBodyPart, isEmpty);

      // 新增胸部自訂動作
      await notifier.addCustomExercise(TargetBodyPart.chest, '啞鈴飛鳥');
      expect(notifier.state.customExercisesByBodyPart[TargetBodyPart.chest], equals(['啞鈴飛鳥']));

      // 再新增一個背部自訂動作
      await notifier.addCustomExercise(TargetBodyPart.back, '單臂滑輪引體');
      expect(notifier.state.customExercisesByBodyPart[TargetBodyPart.back], equals(['單臂滑輪引體']));

      // 驗證持久化儲存有資料
      expect(await mockStorage.getCustomExercisesByBodyPartJson(), isNotNull);

      // 刪除胸部自訂動作
      await notifier.deleteCustomExercise(TargetBodyPart.chest, '啞鈴飛鳥');
      expect(notifier.state.customExercisesByBodyPart[TargetBodyPart.chest], isEmpty);
      expect(notifier.state.customExercisesByBodyPart[TargetBodyPart.back], equals(['單臂滑輪引體']));
    });

    test('WorkoutNotifier resets daily menu across different dates but retains yesterday items', () async {
      final mockStorage = MockSecureStorageService();
      // 模擬昨日儲存的資料
      final yesterdayData = {
        'dateString': '2026-10-09',
        'items': [
          {
            'id': 'y_1',
            'dateString': '2026-10-09',
            'exerciseName': '槓鈴硬舉',
            'targetBodyPart': 'back',
            'weightKg': 100.0,
            'reps': 5,
            'sets': 5,
            'estimatedCalories': 0,
            'isCompleted': true,
          }
        ],
      };
      await mockStorage.saveDailyWorkoutItemsJson(jsonEncode(yesterdayData));

      final notifier = WorkoutNotifier(storageService: mockStorage);
      await notifier.loadDailyWorkoutItems();

      // 今日菜單依規範自動清空（每日訓練不同）
      expect(notifier.state.dailyWorkoutItems, isEmpty);
      // 昨日菜單保留在 yesterdayWorkoutItems 供沿用
      expect(notifier.state.yesterdayWorkoutItems.length, equals(1));
      expect(notifier.state.yesterdayWorkoutItems.first.exerciseName, equals('槓鈴硬舉'));

      // 點擊「沿用昨日菜單」
      await notifier.copyYesterdayWorkoutItems();
      expect(notifier.state.dailyWorkoutItems.length, equals(1));
      expect(notifier.state.dailyWorkoutItems.first.exerciseName, equals('槓鈴硬舉'));
      // 沿用過來後打卡狀態應重置為 false
      expect(notifier.state.dailyWorkoutItems.first.isCompleted, isFalse);
    });

    test('WorkoutNotifier updates daily workout item correctly', () async {
      final mockStorage = MockSecureStorageService();
      final notifier = WorkoutNotifier(storageService: mockStorage);

      const item1 = DailyWorkoutItemEntity(
        id: 'item_1',
        dateString: '2026-10-10',
        exerciseName: '平板臥推',
        targetBodyPart: TargetBodyPart.chest,
        weightKg: 50.0,
        reps: 10,
        sets: 4,
        isCompleted: true,
      );

      await notifier.addDailyWorkoutItem(item1);

      // 編輯更新動作：重量增至 70kg
      final updatedItem = item1.copyWith(
        weightKg: 70.0,
      );
      await notifier.updateDailyWorkoutItem(updatedItem);

      expect(notifier.state.dailyWorkoutItems.first.weightKg, equals(70.0));
      expect(notifier.state.totalCaloriesBurned, equals(0));
    });

    test('WorkoutNotifier batch adds plan exercises to daily workout and detects duplication', () async {
      final mockStorage = MockSecureStorageService();
      final notifier = WorkoutNotifier(storageService: mockStorage);

      final plan = WorkoutPlanEntity.defaultPlans[0];
      expect(notifier.state.dailyWorkoutItems, isEmpty);
      expect(notifier.isPlanAlreadyAddedToDaily(plan), isFalse);

      // 批次加入整套課表
      await notifier.addPlanExercisesToDailyWorkout(plan);
      expect(notifier.state.dailyWorkoutItems.length, equals(plan.exercises.length));
      expect(notifier.state.dailyWorkoutItems.first.exerciseName, equals(plan.exercises.first.name));
      expect(notifier.isPlanAlreadyAddedToDaily(plan), isTrue);

      // 驗證持久化儲存有資料
      expect(await mockStorage.getDailyWorkoutItemsJson(), isNotNull);
    });

    test('WorkoutNotifier reorders daily workout items correctly', () async {
      final mockStorage = MockSecureStorageService();
      final notifier = WorkoutNotifier(storageService: mockStorage);

      const item1 = DailyWorkoutItemEntity(
        id: 'item_1',
        dateString: '2026-10-10',
        exerciseName: '動作一',
        targetBodyPart: TargetBodyPart.chest,
        weightKg: 50.0,
        reps: 10,
        sets: 4,
        estimatedCalories: 60,
      );
      const item2 = DailyWorkoutItemEntity(
        id: 'item_2',
        dateString: '2026-10-10',
        exerciseName: '動作二',
        targetBodyPart: TargetBodyPart.back,
        weightKg: 60.0,
        reps: 10,
        sets: 4,
        estimatedCalories: 70,
      );
      const item3 = DailyWorkoutItemEntity(
        id: 'item_3',
        dateString: '2026-10-10',
        exerciseName: '動作三',
        targetBodyPart: TargetBodyPart.legs,
        weightKg: 80.0,
        reps: 10,
        sets: 4,
        estimatedCalories: 90,
      );

      await notifier.addDailyWorkoutItem(item1);
      await notifier.addDailyWorkoutItem(item2);
      await notifier.addDailyWorkoutItem(item3);

      expect(notifier.state.dailyWorkoutItems.map((e) => e.exerciseName).toList(),
          equals(['動作一', '動作二', '動作三']));

      // 將動作一 (index 0) 拖曳移到 動作三 後方 (index 3 -> 插入位置)
      await notifier.reorderDailyWorkoutItems(0, 3);
      expect(notifier.state.dailyWorkoutItems.map((e) => e.exerciseName).toList(),
          equals(['動作二', '動作三', '動作一']));
    });

    testWidgets('FitnessRecommendationsView renders "健身菜單", date banner, and add action', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FitnessRecommendationsView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 驗證標題更名為「健身菜單」
      expect(find.text('健身菜單'), findsOneWidget);

      // 驗證頂部看板激勵標籤
      expect(find.text('持之以恆'), findsOneWidget);

      // 驗證今日菜單區塊與新增按鈕
      expect(find.text('今日菜單'), findsOneWidget);
      expect(find.text('＋ 新增今日訓練動作'), findsOneWidget);

      // 驗證空狀態文案
      expect(find.text('今天還沒有安排訓練動作喔！'), findsOneWidget);
      expect(find.text('點選下方「＋ 新增今日訓練動作」，安排今天的專屬重訓菜單！'), findsOneWidget);
    });

    testWidgets('FitnessRecommendationsView full interactive flow: custom exercises, add, adjust, check-in, edit, and delete', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockStorage = MockSecureStorageService();
      final notifier = WorkoutNotifier(storageService: mockStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutControllerProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: FitnessRecommendationsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. 點擊「＋ 新增今日訓練動作」開啟底部抽屜
      final addBtn = find.text('＋ 新增今日訓練動作');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('新增今日訓練動作'), findsOneWidget);
      expect(find.text('1. 選擇部位'), findsOneWidget);
      expect(find.text('2. 選擇或自填動作'), findsOneWidget);
      expect(find.text('3. 設定重量與組數 (可直接點擊數字手打，或按 +- 微調)'), findsOneWidget);

      // 2. 測試點擊「新增自訂動作」按鈕
      final addCustomActionChip = find.text('新增自訂動作');
      expect(addCustomActionChip, findsOneWidget);
      await tester.tap(addCustomActionChip);
      await tester.pumpAndSettle();

      // 彈窗出現
      expect(find.text('新增【胸部】自訂動作'), findsOneWidget);
      final customInput = find.widgetWithText(TextField, '例如：阿嬤牌深蹲、單臂啞鈴側舉');
      await tester.enterText(customInput, '特製伏地挺身');
      await tester.pumpAndSettle();
      final confirmAddBtn = find.text('新增並選取');
      await tester.tap(confirmAddBtn);
      await tester.pumpAndSettle();

      // 自訂動作出現在步驟二並被選中
      expect(find.text('特製伏地挺身'), findsOneWidget);
      expect(find.text('✏️ 自訂專屬動作（無示範動畫）'), findsOneWidget);

      // 3. 測試 +- 快速微調：按重量的 + 按鈕
      // 重量預設為 40 kg，按 + 後應為 42.5 kg
      final plusButtons = find.byWidgetPredicate((widget) =>
          widget is Icon && widget.icon == CupertinoIcons.plus && widget.size == 12.0);
      expect(plusButtons, findsNWidgets(3)); // 重量、次數、組數 各一個
      await tester.tap(plusButtons.first); // 點擊重量的 +
      await tester.pumpAndSettle();
      expect(find.text('42.5'), findsOneWidget);

      // 4. 點擊「加入今日菜單」
      final submitBtn = find.text('加入今日菜單');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // 抽屜關閉，今日菜單列表中出現動作卡片
      expect(find.text('新增今日訓練動作'), findsNothing);
      expect(find.text('特製伏地挺身'), findsOneWidget);
      expect(find.text('42.5 kg'), findsOneWidget);
      expect(find.text('10 下'), findsOneWidget);
      expect(find.text('4 組'), findsOneWidget);

      // 5. 點擊勾選圓圈進行打卡
      final checkCircle = find.byWidgetPredicate((widget) =>
          widget is Container &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle);
      await tester.ensureVisible(checkCircle.first);
      await tester.tap(checkCircle.first);
      await tester.pumpAndSettle();

      expect(find.byIcon(CupertinoIcons.checkmark), findsOneWidget);

      // 6. 點擊筆型圖示進入「編輯訓練動作」
      final editBtn = find.byIcon(CupertinoIcons.pencil);
      await tester.ensureVisible(editBtn.first);
      await tester.tap(editBtn.first);
      await tester.pumpAndSettle();

      expect(find.text('編輯訓練動作'), findsOneWidget);
      expect(find.text('儲存修改'), findsOneWidget);

      // 修改次數為 12 下
      final repsField = find.widgetWithText(TextFormField, '下');
      await tester.enterText(repsField, '12');
      await tester.pumpAndSettle();

      // 儲存修改
      final saveBtn = find.text('儲存修改');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('編輯訓練動作'), findsNothing);
      expect(find.text('12 下'), findsOneWidget);

      // 7. 刪除動作
      final deleteBtn = find.byIcon(CupertinoIcons.trash);
      await tester.ensureVisible(deleteBtn);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // 驗證恢復為空狀態
      expect(find.text('特製伏地挺身'), findsNothing);
      expect(find.text('今天還沒有安排訓練動作喔！'), findsOneWidget);

      // 8. 再次開啟抽屜，驗證剛才新增的「特製伏地挺身」有被持久化保存，且可透過 ✕ 刪除
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('特製伏地挺身'), findsOneWidget);
      // 點擊自訂動作旁的 ✕ 刪除按鈕
      final removeCustomChipBtn = find.byIcon(CupertinoIcons.clear_circled_solid);
      expect(removeCustomChipBtn, findsOneWidget);
      await tester.tap(removeCustomChipBtn);
      await tester.pumpAndSettle();

      // 確認對話框
      expect(find.text('確定要刪除自訂動作「特製伏地挺身」嗎？'), findsOneWidget);
      final confirmDeleteBtn = find.text('確定刪除');
      await tester.tap(confirmDeleteBtn);
      await tester.pumpAndSettle();

      // 刪除後列表不再有「特製伏地挺身」
      expect(find.text('特製伏地挺身'), findsNothing);
    });

    testWidgets('ReorderableListView onReorderItem passes adjusted newIndex', (tester) async {
      int? receivedOldIndex;
      int? receivedNewIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReorderableListView(
              onReorderItem: (oldIndex, newIndex) {
                receivedOldIndex = oldIndex;
                receivedNewIndex = newIndex;
              },
              children: const [
                Text('Item 0', key: ValueKey('0')),
                Text('Item 1', key: ValueKey('1')),
                Text('Item 2', key: ValueKey('2')),
              ],
            ),
          ),
        ),
      );

      // Drag item 0 down past item 1
      final firstItem = find.text('Item 0');
      final secondItem = find.text('Item 1');
      final gesture = await tester.startGesture(tester.getCenter(firstItem));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(tester.getCenter(secondItem) + const Offset(0, 50));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(receivedOldIndex, equals(0));
      expect(receivedNewIndex, equals(2));
    });

    testWidgets('Daily workout menu handles preset with GIF and custom without GIF accurately', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockStorage = MockSecureStorageService();
      final notifier = WorkoutNotifier(storageService: mockStorage);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            workoutControllerProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(
              body: FitnessRecommendationsView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. 新增內建動作（應自動帶有示範動畫）
      final addBtn = find.text('＋ 新增今日訓練動作');
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // 抽屜內應展示「🎬 內建示範動畫」預覽
      expect(find.text('🎬 內建示範動畫'), findsOneWidget);

      final submitBtn = find.text('加入今日菜單');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // 卡片應渲染「示範動畫」標籤
      expect(find.text('槓鈴平胸臥推'), findsOneWidget);
      expect(find.text('示範動畫'), findsOneWidget);

      // 點擊「示範動畫」標籤彈出大圖播放彈窗
      await tester.ensureVisible(find.text('示範動畫'));
      await tester.tap(find.text('示範動畫'));
      await tester.pumpAndSettle();

      // 彈窗內顯示動作名稱與關閉按鈕
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsOneWidget);
      // 點擊關閉
      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
      await tester.pumpAndSettle();
      expect(find.byIcon(CupertinoIcons.xmark_circle_fill), findsNothing);

      // 2. 新增自訂動作（如果是自己自訂的就不用 gif）
      await tester.ensureVisible(addBtn);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // 點擊「新增自訂動作」Chip 彈出對話框
      await tester.tap(find.text('新增自訂動作'));
      await tester.pumpAndSettle();

      final customInput2 = find.widgetWithText(TextField, '例如：阿嬤牌深蹲、單臂啞鈴側舉');
      await tester.enterText(customInput2, '我的超級自訂深蹲');
      await tester.pumpAndSettle();
      await tester.tap(find.text('新增並選取'));
      await tester.pumpAndSettle();

      // 抽屜內應顯示「✏️ 自訂專屬動作（無示範動畫）」
      expect(find.text('✏️ 自訂專屬動作（無示範動畫）'), findsOneWidget);
      expect(find.text('🎬 內建示範動畫'), findsNothing);

      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // 卡片上出現自訂動作名稱
      expect(find.text('我的超級自訂深蹲'), findsOneWidget);

      // 驗證「示範動畫」標籤仍然只有 1 個（只屬於第一個內建動作，自訂動作沒有示範動畫標籤！）
      expect(find.text('示範動畫'), findsOneWidget);
    });
  });
}


