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
import 'package:jiaba_move/features/vision_nutrition/presentation/widgets/meal_entry_sheet.dart';

class MemoryStorage extends SecureStorageService {
  MemoryStorage({this.mealJson, this.favJson});
  String? mealJson;
  String? favJson;

  @override
  Future<String?> getMealLogsJson() async => mealJson;

  @override
  Future<void> saveMealLogsJson(String json) async => mealJson = json;

  @override
  Future<String?> getFavoriteFoodsJson() async => favJson;

  @override
  Future<void> saveFavoriteFoodsJson(String json) async => favJson = json;
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

MealDraft _withCalories(MealDraft d, double kcal) => MealDraft(
      foodName: d.foodName,
      servingSize: d.servingSize,
      calories: kcal,
      protein: d.protein,
      carbs: d.carbs,
      fat: d.fat,
      mealType: d.mealType,
    );

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async => null);
  });

  group('MealDraft 與手動輸入', () {
    test('AI 回傳極端或負數值會被限制在合理範圍', () {
      final entry = MealLogEntity.fromAnalysis(
        _analysis('怪怪的結果', 99999, p: -5, c: 3000, f: double.nan),
        loggedAt: DateTime(2026, 11, 8, 12),
      );
      expect(entry.calories, MealDraft.maxCalories);
      expect(entry.protein, 0);
      expect(entry.carbs, MealDraft.maxMacroGrams);
      expect(entry.fat, 0);
    });

    test('手動新增可指定餐別，名稱前後空白會去掉', () async {
      final notifier = MealLogNotifier(
          storageService: MemoryStorage(),
          clock: () => DateTime(2026, 11, 8, 15));
      await notifier.ready;
      final entry = await notifier.addDraft(const MealDraft(
          foodName: ' 茶葉蛋 ',
          calories: 75,
          protein: 7,
          mealType: MealType.breakfast));
      expect(entry.mealType, MealType.breakfast);
      expect(entry.foodName, '茶葉蛋');
      expect(notifier.state.todayCalories, 75);
    });

    test('修改紀錄保留原本時間與 id，並寫入存儲', () async {
      final storage = MemoryStorage();
      final notifier = MealLogNotifier(
          storageService: storage, clock: () => DateTime(2026, 11, 8, 12));
      await notifier.ready;
      final entry = await notifier.addFromAnalysis(_analysis('便當', 900));
      await notifier.update(
          entry.id, _withCalories(MealDraft.fromLog(entry), 650));

      final updated = notifier.state.todayLogs.single;
      expect(updated.id, entry.id);
      expect(updated.loggedAt, entry.loggedAt);
      expect(updated.calories, 650);
      expect((jsonDecode(storage.mealJson!) as List).single['calories'], 650);
    });

    test('跨日後 refreshToday 讓今日加總歸零，但保留歷史', () async {
      var now = DateTime(2026, 11, 8, 23, 50);
      final notifier =
          MealLogNotifier(storageService: MemoryStorage(), clock: () => now);
      await notifier.ready;
      await notifier.addDraft(const MealDraft(foodName: '宵夜', calories: 400));
      expect(notifier.state.todayCalories, 400);

      now = DateTime(2026, 11, 9, 0, 5);
      notifier.refreshToday();
      expect(notifier.state.todayCalories, 0);
      expect(notifier.state.logs.length, 1);
    });
  });

  group('常吃清單', () {
    test('新增、去重、移除並寫入存儲', () async {
      final storage = MemoryStorage();
      final notifier = MealLogNotifier(storageService: storage);
      await notifier.ready;

      await notifier.addFavorite(const MealDraft(
          foodName: '無糖豆漿', servingSize: '大杯', calories: 120));
      await notifier.addFavorite(const MealDraft(foodName: '茶葉蛋', calories: 75));
      await notifier.addFavorite(const MealDraft(
          foodName: '無糖豆漿', servingSize: '大杯', calories: 130));

      expect(notifier.state.favorites.map((f) => f.foodName),
          ['無糖豆漿', '茶葉蛋']);
      expect(notifier.state.favorites.first.calories, 130);
      expect((jsonDecode(storage.favJson!) as List).length, 2);

      await notifier
          .removeFavorite(const MealDraft(foodName: '茶葉蛋', calories: 0));
      expect(notifier.state.favorites.length, 1);

      final reloaded = MealLogNotifier(storageService: storage);
      await reloaded.ready;
      expect(reloaded.state.favorites.single.foodName, '無糖豆漿');
    });

    test('空白名稱不會加入', () async {
      final notifier = MealLogNotifier(storageService: MemoryStorage());
      await notifier.ready;
      await notifier.addFavorite(const MealDraft(foodName: '  ', calories: 10));
      expect(notifier.state.favorites, isEmpty);
    });

    test('常吃清單資料損毀時以空清單起步', () async {
      final notifier =
          MealLogNotifier(storageService: MemoryStorage(favJson: '{bad'));
      await notifier.ready;
      expect(notifier.state.isLoaded, isTrue);
      expect(notifier.state.favorites, isEmpty);
    });
  });

  group('MealEntrySheet 表單', () {
    Future<void> openSheet(
      WidgetTester tester,
      MealLogNotifier notifier, {
      MealDraft? initial,
      void Function(MealEntryResult?)? onResult,
    }) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [mealLogControllerProvider.overrideWith((ref) => notifier)],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  final r = await showMealEntrySheet(context, initial: initial);
                  onResult?.call(r);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('meal_entry_submit')));
      await tester.tap(find.byKey(const Key('meal_entry_submit')));
      await tester.pumpAndSettle();
    }

    testWidgets('必填欄位未填時顯示錯誤，不會關閉', (tester) async {
      final notifier = MealLogNotifier(storageService: MemoryStorage());
      await openSheet(tester, notifier);
      await submit(tester);
      expect(find.text('請輸入餐點名稱'), findsOneWidget);
      expect(find.text('必填'), findsOneWidget);
    });

    testWidgets('超過上限的熱量顯示錯誤', (tester) async {
      final notifier = MealLogNotifier(storageService: MemoryStorage());
      await openSheet(tester, notifier);
      await tester.enterText(find.byKey(const Key('meal_name_field')), '大餐');
      await tester.enterText(
          find.byKey(const Key('meal_calories_field')), '9000');
      await submit(tester);
      expect(find.text('最多 5000'), findsOneWidget);
    });

    testWidgets('份量 ×½ 會縮放熱量與營養素，送出後回傳結果', (tester) async {
      final notifier = MealLogNotifier(storageService: MemoryStorage());
      MealEntryResult? result;
      await openSheet(
        tester,
        notifier,
        initial: const MealDraft(
            foodName: '便當', calories: 800, protein: 30, carbs: 100, fat: 25),
        onResult: (r) => result = r,
      );
      await tester.tap(find.byKey(const Key('scale_0.5')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('save_favorite_checkbox')));
      await tester.pump();
      await submit(tester);

      expect(result, isNotNull);
      expect(result!.draft.calories, 400);
      expect(result!.draft.protein, 15);
      expect(result!.draft.fat, 12.5);
      expect(result!.saveAsFavorite, isTrue);
    });

    testWidgets('點常吃清單會帶入表單', (tester) async {
      final storage = MemoryStorage(
        favJson: jsonEncode([
          const MealDraft(foodName: '無糖豆漿', servingSize: '大杯', calories: 120)
              .toJson()
        ]),
      );
      final notifier = MealLogNotifier(storageService: storage);
      await notifier.ready;
      await openSheet(tester, notifier);
      await tester.tap(find.textContaining('無糖豆漿'));
      await tester.pump();
      expect(find.widgetWithText(TextFormField, '無糖豆漿'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '120'), findsOneWidget);
    });
  });

  group('HomeView 新功能', () {
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

    testWidgets('超過目標時顯示超過量', (tester) async {
      final entry = MealLogEntity.fromAnalysis(_analysis('吃到飽', 3000),
          loggedAt: DateTime.now());
      final notifier = MealLogNotifier(
        storageService: MemoryStorage(mealJson: jsonEncode([entry.toJson()])),
      );
      await pumpHome(tester, notifier);
      expect(find.text('超過 800 kcal'), findsOneWidget);
    });

    testWidgets('從首頁手動新增一餐', (tester) async {
      final notifier = MealLogNotifier(storageService: MemoryStorage());
      await pumpHome(tester, notifier);
      await tester.tap(find.byKey(const Key('manual_add_meal_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('meal_name_field')), '地瓜');
      await tester.enterText(
          find.byKey(const Key('meal_calories_field')), '180');
      await tester.ensureVisible(find.byKey(const Key('meal_entry_submit')));
      await tester.tap(find.byKey(const Key('meal_entry_submit')));
      await tester.pumpAndSettle();
      expect(find.text('已攝取 180 kcal'), findsOneWidget);
      expect(find.textContaining('地瓜'), findsOneWidget);
    });

    testWidgets('點餐點可修改熱量', (tester) async {
      final entry = MealLogEntity.fromAnalysis(_analysis('牛肉麵', 700),
          loggedAt: DateTime.now());
      final notifier = MealLogNotifier(
        storageService: MemoryStorage(mealJson: jsonEncode([entry.toJson()])),
      );
      await pumpHome(tester, notifier);
      await tester.tap(find.textContaining('牛肉麵'));
      await tester.pumpAndSettle();
      expect(find.text('修改餐點'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('meal_calories_field')), '550');
      await tester.ensureVisible(find.byKey(const Key('meal_entry_submit')));
      await tester.tap(find.byKey(const Key('meal_entry_submit')));
      await tester.pumpAndSettle();
      expect(find.text('已攝取 550 kcal'), findsOneWidget);
    });
  });
}
