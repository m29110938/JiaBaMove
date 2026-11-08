import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/core/storage/secure_storage_service.dart';
import 'package:jiaba_move/features/home/presentation/views/home_view.dart';
import 'package:jiaba_move/features/vision_nutrition/data/models/nutrition_analysis_model.dart';
import 'package:jiaba_move/features/vision_nutrition/domain/entities/meal_log_entity.dart';
import 'package:jiaba_move/features/vision_nutrition/presentation/controllers/meal_log_controller.dart';

class InMemoryStorage extends SecureStorageService {
  InMemoryStorage([this.mealJson]);
  String? mealJson;

  @override
  Future<String?> getMealLogsJson() async => mealJson;

  @override
  Future<void> saveMealLogsJson(String json) async => mealJson = json;
}

NutritionAnalysisModel _analysis(String name, double kcal,
    {double p = 10, double c = 20, double f = 5}) {
  return NutritionAnalysisModel(
    foodName: name,
    servingSize: '1份',
    calories: kcal,
    protein: p,
    carbs: c,
    fat: f,
    confidence: 'high',
    coachAdvice: '讚',
  );
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => null);
  });

  group('MealType.fromTime', () {
    test('依時段推斷餐別', () {
      expect(MealType.fromTime(DateTime(2026, 1, 1, 7, 30)), MealType.breakfast);
      expect(MealType.fromTime(DateTime(2026, 1, 1, 12)), MealType.lunch);
      expect(MealType.fromTime(DateTime(2026, 1, 1, 15)), MealType.afternoonSnack);
      expect(MealType.fromTime(DateTime(2026, 1, 1, 19)), MealType.dinner);
      expect(MealType.fromTime(DateTime(2026, 1, 1, 23)), MealType.lateNight);
      expect(MealType.fromTime(DateTime(2026, 1, 1, 2)), MealType.lateNight);
    });
  });

  group('MealLogNotifier', () {
    test('新增紀錄後今日加總正確並寫入存儲', () async {
      final storage = InMemoryStorage();
      final now = DateTime(2026, 11, 8, 12, 30);
      final notifier = MealLogNotifier(storageService: storage, clock: () => now);
      await notifier.ready;

      await notifier.addFromAnalysis(_analysis('滷肉飯', 520, p: 18, c: 70, f: 18));
      await notifier.addFromAnalysis(_analysis('燙青菜', 80, p: 3, c: 8, f: 4));

      expect(notifier.state.todayLogs.length, 2);
      expect(notifier.state.todayCalories, 600);
      expect(notifier.state.todayProtein, 21);
      expect(notifier.state.todayLogs.first.mealType, MealType.lunch);

      final saved = jsonDecode(storage.mealJson!) as List;
      expect(saved.length, 2);
    });

    test('重新啟動後能從存儲還原，且只計入今日', () async {
      final storage = InMemoryStorage();
      var now = DateTime(2026, 11, 7, 19);
      final first = MealLogNotifier(storageService: storage, clock: () => now);
      await first.ready;
      await first.addFromAnalysis(_analysis('昨天晚餐', 700));

      now = DateTime(2026, 11, 8, 8);
      final second = MealLogNotifier(storageService: storage, clock: () => now);
      await second.ready;
      expect(second.state.logs.length, 1);
      expect(second.state.todayLogs, isEmpty);
      expect(second.state.todayCalories, 0);
    });

    test('刪除紀錄', () async {
      final storage = InMemoryStorage();
      final notifier = MealLogNotifier(
          storageService: storage, clock: () => DateTime(2026, 11, 8, 12));
      await notifier.ready;
      final entry = await notifier.addFromAnalysis(_analysis('便當', 750));
      await notifier.remove(entry.id);
      expect(notifier.state.todayLogs, isEmpty);
      expect(jsonDecode(storage.mealJson!), isEmpty);
    });

    test('超過保留天數的舊紀錄會被清掉', () async {
      final old = MealLogEntity.fromAnalysis(_analysis('很久以前', 500),
          loggedAt: DateTime(2026, 1, 1, 12));
      final storage = InMemoryStorage(jsonEncode([old.toJson()]));
      final notifier = MealLogNotifier(
          storageService: storage, clock: () => DateTime(2026, 11, 8, 12));
      await notifier.ready;
      expect(notifier.state.logs, isEmpty);
    });

    test('存儲資料損毀時以空清單起步', () async {
      final storage = InMemoryStorage('not json');
      final notifier = MealLogNotifier(storageService: storage);
      await notifier.ready;
      expect(notifier.state.isLoaded, isTrue);
      expect(notifier.state.logs, isEmpty);
    });
  });

  group('HomeView 顯示真實紀錄', () {
    Future<void> pumpHome(WidgetTester tester, MealLogNotifier notifier) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealLogControllerProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(home: HomeView()),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('沒有紀錄時顯示空狀態與 0 kcal', (tester) async {
      final notifier = MealLogNotifier(storageService: InMemoryStorage());
      await pumpHome(tester, notifier);

      expect(find.text('已攝取 0 kcal'), findsOneWidget);
      expect(find.text('0 餐已紀錄'), findsOneWidget);
      expect(find.text('今天還沒有紀錄任何一餐'), findsOneWidget);
    });

    testWidgets('有紀錄時顯示加總與餐點', (tester) async {
      final now = DateTime.now();
      final entry = MealLogEntity.fromAnalysis(_analysis('雞胸便當', 650),
          loggedAt: now);
      final notifier = MealLogNotifier(
        storageService: InMemoryStorage(jsonEncode([entry.toJson()])),
      );
      await pumpHome(tester, notifier);

      expect(find.text('已攝取 650 kcal'), findsOneWidget);
      expect(find.text('1 餐已紀錄'), findsOneWidget);
      expect(find.textContaining('雞胸便當'), findsOneWidget);
    });
  });
}
