import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/core/theme/app_theme.dart';
import 'package:jiaba_move/features/fitness_recommendations/domain/entities/workout_plan_entity.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/controllers/workout_controller.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/views/fitness_recommendations_view.dart';
import 'package:jiaba_move/features/fitness_recommendations/presentation/views/workout_plan_detail_view.dart';
import 'package:jiaba_move/features/main/presentation/views/main_navigation_screen.dart';

import 'package:flutter/services.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return null;
    });
  });

  group('Workout Recommendations Unit & Widget Tests (CI/CD-First)', () {
    test('WorkoutNotifier initial state has all plans and 0 calories burned', () {
      final notifier = WorkoutNotifier();
      final state = notifier.state;

      expect(state.plans.length, equals(14));
      expect(state.selectedCategory, isNull);
      expect(state.completedWorkoutIds, isEmpty);
      expect(state.totalCaloriesBurned, equals(0));
      expect(state.filteredPlans.length, equals(14));
    });

    test('WorkoutNotifier category filtering filters plans correctly', () {
      final notifier = WorkoutNotifier();

      // 機器器材
      notifier.setCategory(WorkoutCategory.machines);
      expect(notifier.state.filteredPlans.length, equals(4));
      for (final plan in notifier.state.filteredPlans) {
        expect(plan.category, equals(WorkoutCategory.machines));
      }

      // 自由重量
      notifier.setCategory(WorkoutCategory.freeWeights);
      expect(notifier.state.filteredPlans.length, equals(6));
      for (final plan in notifier.state.filteredPlans) {
        expect(plan.category, equals(WorkoutCategory.freeWeights));
      }

      // 居家徒手
      notifier.setCategory(WorkoutCategory.homeWorkout);
      expect(notifier.state.filteredPlans.length, equals(4));
      for (final plan in notifier.state.filteredPlans) {
        expect(plan.category, equals(WorkoutCategory.homeWorkout));
      }

      // 全部
      notifier.setCategory(null);
      expect(notifier.state.filteredPlans.length, equals(14));
    });

    test('WorkoutNotifier completeWorkout records completion and prevents duplicate check-in', () {
      final notifier = WorkoutNotifier();
      final planA = WorkoutPlanEntity.defaultPlans[0];
      final planB = WorkoutPlanEntity.defaultPlans[1];

      // Complete Plan A
      final resA1 = notifier.completeWorkout(planA);
      expect(resA1, isTrue);
      expect(notifier.state.completedWorkoutIds, contains(planA.id));
      expect(notifier.state.totalCaloriesBurned, equals(0));
      expect(notifier.state.isCompleted(planA.id), isTrue);

      // Duplicate Complete Plan A
      final resA2 = notifier.completeWorkout(planA);
      expect(resA2, isFalse);
      expect(notifier.state.totalCaloriesBurned, equals(0));

      // Complete Plan B
      final resB = notifier.completeWorkout(planB);
      expect(resB, isTrue);
      expect(notifier.state.completedWorkoutIds, contains(planB.id));
      expect(notifier.state.totalCaloriesBurned, equals(0));
    });

    testWidgets('MainNavigationScreen contains 4 tabs including "健身菜單"', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: MainNavigationScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 4 bottom tabs
      expect(find.text('今日紀錄'), findsOneWidget);
      expect(find.text('健身菜單'), findsOneWidget);
      expect(find.text('拍照分析'), findsOneWidget);
      expect(find.text('會員中心'), findsOneWidget);

      // Tap on 健身菜單
      await tester.tap(find.text('健身菜單'));
      await tester.pumpAndSettle();

      // Verify FitnessRecommendationsView is displayed
      expect(find.text('全部推薦'), findsOneWidget);
      expect(find.text('器材機器'), findsWidgets);
      expect(find.text('自由重量'), findsWidgets);
      expect(find.text('居家徒手'), findsWidgets);
    });

    testWidgets('FitnessRecommendationsView filters plans when category pill is tapped', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const FitnessRecommendationsView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially shows "14 個訓練方案"
      expect(find.text('14 個訓練方案'), findsOneWidget);

      // Tap "居家徒手" category selector (the first match in the horizontal pills)
      await tester.ensureVisible(find.text('居家徒手').first);
      await tester.tap(find.text('居家徒手').first);
      await tester.pumpAndSettle();

      // Now shows "4 個訓練方案"
      expect(find.text('4 個訓練方案'), findsOneWidget);
      expect(find.text('客廳多角度俯臥撐胸肌挑戰'), findsOneWidget);
      expect(find.text('客廳徒手高效爆汗間歇'), findsOneWidget);
    });

    testWidgets('WorkoutPlanDetailView displays plan details and adds all exercises to daily menu on button tap',
        (tester) async {
      final plan = WorkoutPlanEntity.defaultPlans[0];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: WorkoutPlanDetailView(plan: plan),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify plan title and exercises
      expect(find.text('器械胸肌專項推力爆發'), findsOneWidget);
      expect(find.text('坐姿機械胸推'), findsOneWidget);
      expect(find.text('蝴蝶機夾胸'), findsOneWidget);

      // Tap "加入今日菜單 (4 項動作)"
      final button = find.text('加入今日菜單 (${plan.exercises.length} 項動作)');
      expect(button, findsOneWidget);
      await tester.tap(button);
      await tester.pumpAndSettle();

      // Verify SnackBar appears confirming addition
      expect(find.text('已成功將「${plan.title}」的 ${plan.exercises.length} 項動作加入今日菜單！'), findsOneWidget);
    });
  });
}
