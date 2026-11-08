import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/daily_workout_item_entity.dart';
import '../../domain/entities/workout_plan_entity.dart';

class WorkoutState {
  const WorkoutState({
    required this.selectedCategory,
    required this.selectedBodyPart,
    required this.isCustomOnly,
    required this.completedWorkoutIds,
    this.totalCaloriesBurned = 0,
    required this.plans,
    required this.dailyWorkoutItems,
    required this.yesterdayWorkoutItems,
    required this.currentDateString,
    this.customExercisesByBodyPart = const {},
  });

  final WorkoutCategory? selectedCategory; // 第一層：null 代表全部推薦
  final TargetBodyPart? selectedBodyPart;  // 第二層：null 代表全部部位
  final bool isCustomOnly;                // 是否切換至「我的自訂」標籤頁
  final Set<String> completedWorkoutIds;   // 今日已打卡完成的課表 ID
  final int totalCaloriesBurned;          // 預設為 0 (已全面移除運動熱量計算)
  final List<WorkoutPlanEntity> plans;     // 系統精選課表 + 使用者自訂課表
  final List<DailyWorkoutItemEntity> dailyWorkoutItems;      // 今日自訂菜單動作清單
  final List<DailyWorkoutItemEntity> yesterdayWorkoutItems;  // 昨日菜單清單 (供隔日沿用)
  final String currentDateString;         // 當前日期 yyyy-MM-dd
  final Map<TargetBodyPart, List<String>> customExercisesByBodyPart; // 依部位自訂動作清單

  WorkoutState copyWith({
    WorkoutCategory? selectedCategory,
    bool clearCategory = false,
    TargetBodyPart? selectedBodyPart,
    bool clearBodyPart = false,
    bool? isCustomOnly,
    Set<String>? completedWorkoutIds,
    int? totalCaloriesBurned,
    List<WorkoutPlanEntity>? plans,
    List<DailyWorkoutItemEntity>? dailyWorkoutItems,
    List<DailyWorkoutItemEntity>? yesterdayWorkoutItems,
    String? currentDateString,
    Map<TargetBodyPart, List<String>>? customExercisesByBodyPart,
  }) {
    return WorkoutState(
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedBodyPart: clearBodyPart ? null : (selectedBodyPart ?? this.selectedBodyPart),
      isCustomOnly: isCustomOnly ?? this.isCustomOnly,
      completedWorkoutIds: completedWorkoutIds ?? this.completedWorkoutIds,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      plans: plans ?? this.plans,
      dailyWorkoutItems: dailyWorkoutItems ?? this.dailyWorkoutItems,
      yesterdayWorkoutItems: yesterdayWorkoutItems ?? this.yesterdayWorkoutItems,
      currentDateString: currentDateString ?? this.currentDateString,
      customExercisesByBodyPart: customExercisesByBodyPart ?? this.customExercisesByBodyPart,
    );
  }

  /// 依據當前選取的型態分類與部位分類過濾後的課表
  List<WorkoutPlanEntity> get filteredPlans {
    var result = plans;

    // 第一層型態過濾
    if (isCustomOnly) {
      result = result.where((p) => p.isCustom).toList();
    } else if (selectedCategory != null) {
      result = result.where((p) => p.category == selectedCategory).toList();
    }

    // 第二層部位過濾
    if (selectedBodyPart != null) {
      result = result.where((p) {
        if (p.targetBodyPart != null) {
          return p.targetBodyPart == selectedBodyPart;
        }
        final bodyPartLabel = selectedBodyPart!.label;
        return p.muscleGroups.any((m) => m.contains(bodyPartLabel));
      }).toList();
    }

    return result;
  }

  /// 所有自訂課表
  List<WorkoutPlanEntity> get customPlans =>
      plans.where((p) => p.isCustom).toList();

  /// 檢查某推薦課表是否今日已打卡
  bool isCompleted(String planId) => completedWorkoutIds.contains(planId);
}

final workoutControllerProvider =
    StateNotifierProvider<WorkoutNotifier, WorkoutState>((ref) {
  return WorkoutNotifier();
});

class WorkoutNotifier extends StateNotifier<WorkoutState> {
  WorkoutNotifier({SecureStorageService? storageService})
      : _storage = storageService ?? SecureStorageService(),
        super(
          WorkoutState(
            selectedCategory: null,
            selectedBodyPart: null,
            isCustomOnly: false,
            completedWorkoutIds: const {},
            totalCaloriesBurned: 0,
            plans: WorkoutPlanEntity.defaultPlans,
            dailyWorkoutItems: const [],
            yesterdayWorkoutItems: const [],
            currentDateString: getTodayString(),
          ),
        ) {
    loadCustomPlans();
    loadDailyWorkoutItems();
    loadCustomExercises();
  }

  final SecureStorageService _storage;

  /// 取得今日標準日期字串 yyyy-MM-dd
  static String getTodayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }


  /// 從持久化儲存載入自訂課表
  Future<void> loadCustomPlans() async {
    try {
      final jsonStr = await _storage.getCustomWorkoutPlansJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonStr) as List<dynamic>;
        final customPlans = list
            .map((item) => WorkoutPlanEntity.fromJson(item as Map<String, dynamic>))
            .toList();
        state = state.copyWith(
          plans: [...WorkoutPlanEntity.defaultPlans, ...customPlans],
        );
      }
    } catch (e) {
      debugPrint('Failed to load custom plans: $e');
    }
  }

  /// 從持久化儲存載入依部位自訂動作
  Future<void> loadCustomExercises() async {
    try {
      final jsonStr = await _storage.getCustomExercisesByBodyPartJson();
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> rawMap = jsonDecode(jsonStr) as Map<String, dynamic>;
        final Map<TargetBodyPart, List<String>> map = {};
        for (final entry in rawMap.entries) {
          final part = TargetBodyPart.values.firstWhere(
            (p) => p.name == entry.key,
            orElse: () => TargetBodyPart.chest,
          );
          final list = (entry.value as List<dynamic>).map((e) => e.toString()).toList();
          map[part] = list;
        }
        state = state.copyWith(customExercisesByBodyPart: map);
      }
    } catch (e) {
      debugPrint('Failed to load custom exercises: $e');
    }
  }

  /// 持久化儲存依部位自訂動作
  Future<void> _persistCustomExercises() async {
    try {
      final Map<String, List<String>> rawMap = {};
      for (final entry in state.customExercisesByBodyPart.entries) {
        rawMap[entry.key.name] = entry.value;
      }
      await _storage.saveCustomExercisesByBodyPartJson(jsonEncode(rawMap));
    } catch (e) {
      debugPrint('Failed to persist custom exercises: $e');
    }
  }

  /// 新增使用者自訂動作至指定部位
  Future<void> addCustomExercise(TargetBodyPart bodyPart, String exerciseName) async {
    final trimmed = exerciseName.trim();
    if (trimmed.isEmpty) return;

    final currentMap = Map<TargetBodyPart, List<String>>.from(state.customExercisesByBodyPart);
    final currentList = List<String>.from(currentMap[bodyPart] ?? []);
    if (!currentList.contains(trimmed)) {
      currentList.add(trimmed);
      currentMap[bodyPart] = currentList;
      state = state.copyWith(customExercisesByBodyPart: currentMap);
      await _persistCustomExercises();
    }
  }

  /// 刪除指定部位的自訂動作
  Future<void> deleteCustomExercise(TargetBodyPart bodyPart, String exerciseName) async {
    final trimmed = exerciseName.trim();
    final currentMap = Map<TargetBodyPart, List<String>>.from(state.customExercisesByBodyPart);
    final currentList = List<String>.from(currentMap[bodyPart] ?? []);
    if (currentList.contains(trimmed)) {
      currentList.remove(trimmed);
      currentMap[bodyPart] = currentList;
      state = state.copyWith(customExercisesByBodyPart: currentMap);
      await _persistCustomExercises();
    }
  }

  /// 從持久化儲存載入今日菜單 (具備隔日清空原則)
  Future<void> loadDailyWorkoutItems() async {
    try {
      final jsonStr = await _storage.getDailyWorkoutItemsJson();
      final todayStr = getTodayString();

      if (jsonStr != null && jsonStr.isNotEmpty) {
        final Map<String, dynamic> data =
            jsonDecode(jsonStr) as Map<String, dynamic>;
        final storedDate = data['dateString'] as String? ?? '';
        final rawItems = data['items'] as List<dynamic>? ?? [];
        final items = rawItems
            .map((e) =>
                DailyWorkoutItemEntity.fromJson(e as Map<String, dynamic>))
            .toList();

        final rawYesterday = data['yesterdayItems'] as List<dynamic>? ?? [];
        final storedYesterday = rawYesterday
            .map((e) =>
                DailyWorkoutItemEntity.fromJson(e as Map<String, dynamic>))
            .toList();

        if (storedDate == todayStr) {
          // 當天打開：載入今日菜單
          state = state.copyWith(
            dailyWorkoutItems: items,
            yesterdayWorkoutItems: storedYesterday,
            currentDateString: todayStr,
            totalCaloriesBurned: 0,
          );
        } else {
          // 隔日打開：依規範清空今日菜單 (每日訓練部位與課表不同)，將前日菜單保留供沿用
          final yesterdayList = items.isNotEmpty ? items : storedYesterday;
          state = state.copyWith(
            dailyWorkoutItems: const [],
            yesterdayWorkoutItems: yesterdayList,
            currentDateString: todayStr,
            totalCaloriesBurned: 0,
          );
          await _persistDailyWorkoutItems();
        }
      } else {
        state = state.copyWith(currentDateString: todayStr);
      }
    } catch (e) {
      debugPrint('Failed to load daily workout items: $e');
    }
  }

  /// 持久化儲存今日菜單
  Future<void> _persistDailyWorkoutItems() async {
    try {
      final data = {
        'dateString': state.currentDateString,
        'items': state.dailyWorkoutItems.map((e) => e.toJson()).toList(),
        'yesterdayItems':
            state.yesterdayWorkoutItems.map((e) => e.toJson()).toList(),
      };
      await _storage.saveDailyWorkoutItemsJson(jsonEncode(data));
    } catch (e) {
      debugPrint('Failed to persist daily workout items: $e');
    }
  }

  /// 檢查某課表的動作是否已在今日菜單中 (防呆判斷)
  bool isPlanAlreadyAddedToDaily(WorkoutPlanEntity plan) {
    if (plan.exercises.isEmpty) return false;
    final currentNames = state.dailyWorkoutItems.map((e) => e.exerciseName).toSet();
    final matchedCount = plan.exercises.where((e) => currentNames.contains(e.name)).length;
    return matchedCount > 0 && matchedCount >= (plan.exercises.length / 2).ceil();
  }

  /// 一鍵將推薦課表整套動作追加加入至今日菜單
  Future<void> addPlanExercisesToDailyWorkout(WorkoutPlanEntity plan) async {
    final now = DateTime.now();
    final newItems = <DailyWorkoutItemEntity>[];
    for (var i = 0; i < plan.exercises.length; i++) {
      final ex = plan.exercises[i];
      final match = RegExp(r'\d+').firstMatch(ex.reps);
      final repsNumber = match != null ? (int.tryParse(match.group(0)!) ?? 10) : 10;

      newItems.add(
        DailyWorkoutItemEntity(
          id: 'daily_${now.microsecondsSinceEpoch}_$i',
          dateString: state.currentDateString,
          exerciseName: ex.name,
          targetBodyPart: plan.targetBodyPart ?? TargetBodyPart.fullBody,
          weightKg: 0.0,
          reps: repsNumber,
          sets: ex.sets,
          estimatedCalories: 0,
          isCompleted: false,
          animationAsset: ex.animationAsset,
          isCustom: false,
          createdAt: now.add(Duration(milliseconds: i)),
        ),
      );
    }

    final updated = [...state.dailyWorkoutItems, ...newItems];
    state = state.copyWith(
      dailyWorkoutItems: updated,
      totalCaloriesBurned: 0,
    );
    await _persistDailyWorkoutItems();
  }

  /// 新增今日自訂菜單動作
  Future<void> addDailyWorkoutItem(DailyWorkoutItemEntity item) async {
    final updated = [...state.dailyWorkoutItems, item];
    state = state.copyWith(
      dailyWorkoutItems: updated,
      totalCaloriesBurned: 0,
    );
    await _persistDailyWorkoutItems();
  }

  /// 切換今日動作打卡完成狀態
  Future<void> toggleDailyWorkoutItemCompleted(String id) async {
    final updated = state.dailyWorkoutItems.map((item) {
      if (item.id == id) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();
    state = state.copyWith(
      dailyWorkoutItems: updated,
      totalCaloriesBurned: 0,
    );
    await _persistDailyWorkoutItems();
  }

  /// 刪除今日動作
  Future<void> deleteDailyWorkoutItem(String id) async {
    final updated =
        state.dailyWorkoutItems.where((item) => item.id != id).toList();
    state = state.copyWith(
      dailyWorkoutItems: updated,
      totalCaloriesBurned: 0,
    );
    await _persistDailyWorkoutItems();
  }

  /// 編輯更新今日動作
  Future<void> updateDailyWorkoutItem(DailyWorkoutItemEntity updatedItem) async {
    final updated = state.dailyWorkoutItems.map((item) {
      return item.id == updatedItem.id ? updatedItem : item;
    }).toList();
    state = state.copyWith(
      dailyWorkoutItems: updated,
      totalCaloriesBurned: 0,
    );
    await _persistDailyWorkoutItems();
  }

  /// 拖曳重新排序今日動作清單
  Future<void> reorderDailyWorkoutItems(int oldIndex, int newIndex) async {
    final items = List<DailyWorkoutItemEntity>.from(state.dailyWorkoutItems);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = state.copyWith(dailyWorkoutItems: items);
    await _persistDailyWorkoutItems();
  }

  /// 沿用昨日菜單
  Future<void> copyYesterdayWorkoutItems() async {
    if (state.yesterdayWorkoutItems.isEmpty) return;
    final todayStr = getTodayString();
    final copied = state.yesterdayWorkoutItems.map((item) {
      return item.copyWith(
        id: 'item_${DateTime.now().microsecondsSinceEpoch}_${item.exerciseName.hashCode}',
        dateString: todayStr,
        isCompleted: false,
        createdAt: DateTime.now(),
      );
    }).toList();
    final updated = [...state.dailyWorkoutItems, ...copied];
    state = state.copyWith(
      dailyWorkoutItems: updated,
      totalCaloriesBurned: 0,
    );
    await _persistDailyWorkoutItems();
  }

  /// 持久化儲存自訂課表
  Future<void> _persistCustomPlans() async {
    try {
      final customList = state.customPlans.map((p) => p.toJson()).toList();
      await _storage.saveCustomWorkoutPlansJson(jsonEncode(customList));
    } catch (e) {
      debugPrint('Failed to persist custom plans: $e');
    }
  }

  /// 切換運動型態過濾 (第一層)
  void setCategory(WorkoutCategory? category) {
    if (category == null) {
      state = state.copyWith(clearCategory: true, isCustomOnly: false);
    } else {
      state = state.copyWith(selectedCategory: category, isCustomOnly: false);
    }
  }

  /// 切換訓練部位過濾 (第二層)
  void setBodyPart(TargetBodyPart? bodyPart) {
    if (bodyPart == null) {
      state = state.copyWith(clearBodyPart: true);
    } else {
      state = state.copyWith(selectedBodyPart: bodyPart);
    }
  }

  /// 切換至「我的自訂」標籤頁
  void setCustomFilter(bool onlyCustom) {
    state = state.copyWith(isCustomOnly: onlyCustom, clearCategory: true);
  }

  /// 新增自訂課表
  Future<void> addCustomPlan(WorkoutPlanEntity plan) async {
    final customPlan = plan.copyWith(isCustom: true);
    state = state.copyWith(
      plans: [...state.plans, customPlan],
    );
    await _persistCustomPlans();
  }

  /// 更新自訂課表
  Future<void> updateCustomPlan(WorkoutPlanEntity updatedPlan) async {
    final updatedList = state.plans.map((p) {
      return p.id == updatedPlan.id ? updatedPlan : p;
    }).toList();
    state = state.copyWith(plans: updatedList);
    await _persistCustomPlans();
  }

  /// 刪除自訂課表
  Future<void> deleteCustomPlan(String planId) async {
    final updatedList = state.plans.where((p) => p.id != planId).toList();
    state = state.copyWith(plans: updatedList);
    await _persistCustomPlans();
  }

  /// 完成課表打卡
  bool completeWorkout(WorkoutPlanEntity plan) {
    final alreadyCompleted = state.completedWorkoutIds.contains(plan.id);
    if (alreadyCompleted) {
      return false; // 今日已打卡過
    }

    final newCompleted = Set<String>.from(state.completedWorkoutIds)..add(plan.id);

    state = state.copyWith(
      completedWorkoutIds: newCompleted,
      totalCaloriesBurned: 0,
    );
    return true;
  }
}
