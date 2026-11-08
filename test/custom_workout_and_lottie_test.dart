import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/core/theme/app_theme.dart';
import 'package:jiaba_move/features/fitness_recommendations/domain/entities/workout_plan_entity.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/controllers/workout_controller.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/views/create_custom_plan_view.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/views/fitness_recommendations_view.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/widgets/exercise_animation_viewer.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/widgets/body_part_guidance_card.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  group('Custom Workout Plans & Two-Tier Body Part Recommendations Tests', () {
    test('WorkoutExercise & WorkoutPlanEntity JSON serialization preserves targetBodyPart', () {
      const exercise = WorkoutExercise(
        name: '開源啞鈴深蹲',
        targetMuscle: '股四頭肌',
        sets: 4,
        reps: '12 次',
        restSeconds: 60,
        tips: '保持挺胸核心收緊',
        equipment: '一對啞鈴',
        animationAsset: 'assets/exercises/barbell_squat.gif',
      );

      final exJson = exercise.toJson();
      final deserializedEx = WorkoutExercise.fromJson(exJson);
      expect(deserializedEx.name, equals('開源啞鈴深蹲'));
      expect(deserializedEx.animationAsset, equals('assets/exercises/barbell_squat.gif'));
      expect(deserializedEx.effectiveAnimationAsset, equals('assets/exercises/barbell_squat.gif'));

      const plan = WorkoutPlanEntity(
        id: 'test_custom_1',
        title: '我的自訂爆汗計畫',
        subtitle: '週日高效訓練',
        category: WorkoutCategory.homeWorkout,
        targetBodyPart: TargetBodyPart.legs,
        targetGoals: [],
        durationMinutes: 25,
        estimatedCalories: 210,
        difficulty: WorkoutDifficulty.intermediate,
        muscleGroups: ['下肢', '核心'],
        exercises: [exercise],
        accentColorHex: 0xFF0D9488,
        isCustom: true,
      );

      final planJson = plan.toJson();
      expect(planJson['isCustom'], isTrue);
      expect(planJson['title'], equals('我的自訂爆汗計畫'));
      expect(planJson['targetBodyPart'], equals('legs'));

      final deserializedPlan = WorkoutPlanEntity.fromJson(planJson);
      expect(deserializedPlan.isCustom, isTrue);
      expect(deserializedPlan.targetBodyPart, equals(TargetBodyPart.legs));
      expect(deserializedPlan.exercises.length, equals(1));
      expect(deserializedPlan.exercises.first.name, equals('開源啞鈴深蹲'));
    });

    test('WorkoutNotifier handles custom plan CRUD, category filter, and body part filter', () async {
      final notifier = WorkoutNotifier();
      final initialCount = WorkoutPlanEntity.defaultPlans.length;
      expect(notifier.state.plans.length, equals(initialCount));
      expect(notifier.state.customPlans, isEmpty);

      // Verify Body Part Guidance Map contains all 6 body parts
      expect(WorkoutPlanEntity.bodyPartGuidanceMap.length, equals(6));
      expect(WorkoutPlanEntity.bodyPartGuidanceMap.containsKey(TargetBodyPart.chest), isTrue);
      expect(WorkoutPlanEntity.bodyPartGuidanceMap[TargetBodyPart.chest]!.title, contains('挺拔胸膛'));

      const customPlan = WorkoutPlanEntity(
        id: 'plan_my_custom_001',
        title: '個人專用腹肌撕裂者',
        subtitle: '睡前15分鐘腹肌喚醒',
        category: WorkoutCategory.homeWorkout,
        targetBodyPart: TargetBodyPart.core,
        targetGoals: [],
        durationMinutes: 15,
        estimatedCalories: 120,
        difficulty: WorkoutDifficulty.beginner,
        muscleGroups: ['腹直肌'],
        exercises: [
          WorkoutExercise(
            name: '棒式支撐',
            targetMuscle: '核心',
            sets: 3,
            reps: '45 秒',
            restSeconds: 30,
            tips: '不要塌腰',
            equipment: '瑜珈墊',
            animationAsset: 'assets/exercises/plank.gif',
          ),
        ],
        accentColorHex: 0xFF0D9488,
        isCustom: true,
      );

      // Add custom plan
      await notifier.addCustomPlan(customPlan);
      expect(notifier.state.plans.length, equals(initialCount + 1));
      expect(notifier.state.customPlans.length, equals(1));
      expect(notifier.state.customPlans.first.title, equals('個人專用腹肌撕裂者'));

      // Filter by body part: Chest
      notifier.setBodyPart(TargetBodyPart.chest);
      expect(notifier.state.selectedBodyPart, equals(TargetBodyPart.chest));
      expect(notifier.state.filteredPlans.every((p) => p.targetBodyPart == TargetBodyPart.chest), isTrue);

      // Filter by body part: Core
      notifier.setBodyPart(TargetBodyPart.core);
      expect(notifier.state.filteredPlans.any((p) => p.id == 'plan_my_custom_001'), isTrue);

      // Reset body part filter
      notifier.setBodyPart(null);
      expect(notifier.state.selectedBodyPart, isNull);

      // Filter by custom only
      notifier.setCustomFilter(true);
      expect(notifier.state.isCustomOnly, isTrue);
      expect(notifier.state.filteredPlans.length, equals(1));
      expect(notifier.state.filteredPlans.first.id, equals('plan_my_custom_001'));

      // Update custom plan
      final updatedPlan = customPlan.copyWith(title: '升級版腹肌撕裂者', durationMinutes: 20);
      await notifier.updateCustomPlan(updatedPlan);
      expect(notifier.state.customPlans.first.title, equals('升級版腹肌撕裂者'));
      expect(notifier.state.customPlans.first.durationMinutes, equals(20));

      // Reset to all
      notifier.setCategory(null);
      expect(notifier.state.isCustomOnly, isFalse);
      expect(notifier.state.filteredPlans.length, equals(initialCount + 1));

      // Delete custom plan
      await notifier.deleteCustomPlan('plan_my_custom_001');
      expect(notifier.state.plans.length, equals(initialCount));
      expect(notifier.state.customPlans, isEmpty);
    });

    testWidgets('ExerciseAnimationViewer renders Lottie viewer and opens dialog on tap',
        (tester) async {
      const exercise = WorkoutExercise(
        name: '測試深蹲',
        targetMuscle: '股四頭肌',
        sets: 3,
        reps: '12 次',
        restSeconds: 45,
        tips: '保持膝蓋與腳尖方向一致',
        equipment: '徒手',
        animationAsset: 'assets/animations/squat.json',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ExerciseAnimationViewer(
              exercise: exercise,
              height: 120,
              enableEnlargeModal: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Enlarge badge should be visible
      expect(find.text('放大演示'), findsOneWidget);

      // Tap to open enlarged dialog
      await tester.tap(find.text('放大演示'));
      await tester.pumpAndSettle();

      // Verify enlarged modal content and dataset attribution
      expect(find.text('測試深蹲'), findsOneWidget);
      expect(find.text('保持膝蓋與腳尖方向一致'), findsOneWidget);
      expect(find.text('動作示範：© Gym visual (exercises-dataset)'), findsOneWidget);
      expect(find.text('了解動作要領'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('了解動作要領'));
      await tester.pumpAndSettle();

      expect(find.text('了解動作要領'), findsNothing);
    });

    testWidgets('ExerciseAnimationViewer renders exercises-dataset GIF asset properly',
        (tester) async {
      const exercise = WorkoutExercise(
        name: '槓鈴臥推',
        targetMuscle: '胸肌',
        sets: 4,
        reps: '10 次',
        restSeconds: 60,
        tips: '挺胸後收',
        equipment: '槓鈴',
        animationAsset: 'assets/exercises/bench_press.gif',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(
            body: ExerciseAnimationViewer(
              exercise: exercise,
              height: 120,
              enableEnlargeModal: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('放大演示'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('CreateCustomPlanView renders form with body part selector and allows saving',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const CreateCustomPlanView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify form elements exist
      expect(find.text('建立自訂課表'), findsOneWidget);
      expect(find.text('課表名稱 *'), findsOneWidget);
      expect(find.text('主要訓練部位'), findsOneWidget);

      // Tap '背部' body part pill
      expect(find.text('背部'), findsWidgets);
      await tester.tap(find.text('背部').first);
      await tester.pump();

      // Enter plan title
      await tester.enterText(find.byType(TextFormField).first, '週二背肌精準鍛鍊');
      await tester.pump();

      // Scroll to action button
      await tester.scrollUntilVisible(
        find.text('從動作庫挑選'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('從動作庫挑選'), findsOneWidget);
      expect(find.text('+ 自訂新動作'), findsOneWidget);

      // Open Exercise Library bottom sheet
      await tester.tap(find.text('從動作庫挑選'));
      await tester.pumpAndSettle();

      expect(find.text('精選動作資料庫'), findsOneWidget);
      expect(find.text('加入'), findsWidgets);

      // Tap first "加入"
      await tester.tap(find.text('加入').first);
      await tester.pumpAndSettle();

      // Tap "完成" on bottom sheet
      await tester.tap(find.text('完成'));
      await tester.pumpAndSettle();

      // Scroll to exercise list section
      await tester.scrollUntilVisible(
        find.textContaining('訓練動作清單'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('訓練動作清單 (1)'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('立即建立課表'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('立即建立課表'), findsOneWidget);
    });

    testWidgets('FitnessRecommendationsView displays two-tier tabs and BodyPartGuidanceCard on selection',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FitnessRecommendationsView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tier 1 tabs exist
      expect(find.text('全部推薦'), findsOneWidget);
      expect(find.text('器材機器'), findsWidgets);
      expect(find.text('自由重量'), findsWidgets);
      expect(find.text('居家徒手'), findsWidgets);
      expect(find.text('我的自訂'), findsWidgets);

      // Tier 2 body part tabs exist
      expect(find.text('全部部位'), findsOneWidget);
      expect(find.text('胸部'), findsWidgets);
      expect(find.text('臀腿'), findsWidgets);
      expect(find.text('肩臂'), findsWidgets);
      expect(find.text('核心'), findsWidgets);

      // Initially no BodyPartGuidanceCard because '全部部位' is selected
      expect(find.byType(BodyPartGuidanceCard), findsNothing);

      // Tap '胸部' body part pill
      await tester.ensureVisible(find.text('胸部').first);
      await tester.tap(find.text('胸部').first);
      await tester.pumpAndSettle();

      // BodyPartGuidanceCard should now appear
      expect(find.byType(BodyPartGuidanceCard), findsOneWidget);
      expect(find.text('胸部專屬教練指引'), findsOneWidget);
      expect(find.text('挺拔胸膛與厚度雕塑'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('發力感受要領'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('避坑指南'),
        ),
        findsOneWidget,
      );

      // Tap '全部部位' to reset
      await tester.tap(find.text('全部部位').first);
      await tester.pumpAndSettle();

      // Guidance card disappears
      expect(find.byType(BodyPartGuidanceCard), findsNothing);
    });
  });
}
