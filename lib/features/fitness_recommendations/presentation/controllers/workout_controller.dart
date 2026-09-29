import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/entities/workout_plan_entity.dart';

class WorkoutState {
  const WorkoutState({
    required this.selectedCategory,
    required this.selectedBodyPart,
    required this.isCustomOnly,
    required this.completedWorkoutIds,
    required this.totalCaloriesBurned,
    required this.plans,
  });

  final WorkoutCategory? selectedCategory; // 第一層：null 代表全部推薦
  final TargetBodyPart? selectedBodyPart;  // 第二層：null 代表全部部位
  final bool isCustomOnly;                // 是否切換至「我的自訂」標籤頁
  final Set<String> completedWorkoutIds;   // 今日已打卡完成的課表 ID
  final int totalCaloriesBurned;          // 今日運動總消耗熱量 (kcal)
  final List<WorkoutPlanEntity> plans;     // 系統精選課表 + 使用者自訂課表

  WorkoutState copyWith({
    WorkoutCategory? selectedCategory,
    bool clearCategory = false,
    TargetBodyPart? selectedBodyPart,
    bool clearBodyPart = false,
    bool? isCustomOnly,
    Set<String>? completedWorkoutIds,
    int? totalCaloriesBurned,
    List<WorkoutPlanEntity>? plans,
  }) {
    return WorkoutState(
      selectedCategory: clearCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedBodyPart: clearBodyPart ? null : (selectedBodyPart ?? this.selectedBodyPart),
      isCustomOnly: isCustomOnly ?? this.isCustomOnly,
      completedWorkoutIds: completedWorkoutIds ?? this.completedWorkoutIds,
      totalCaloriesBurned: totalCaloriesBurned ?? this.totalCaloriesBurned,
      plans: plans ?? this.plans,
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
        // 若自訂課表未設定 targetBodyPart，可嘗試比對肌肉標籤
        final bodyPartLabel = selectedBodyPart!.label;
        return p.muscleGroups.any((m) => m.contains(bodyPartLabel));
      }).toList();
    }

    return result;
  }

  /// 所有自訂課表
  List<WorkoutPlanEntity> get customPlans =>
      plans.where((p) => p.isCustom).toList();

  /// 檢查某課表是否今日已打卡
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
          const WorkoutState(
            selectedCategory: null, // 預設全部型態
            selectedBodyPart: null, // 預設全部部位
            isCustomOnly: false,
            completedWorkoutIds: {},
            totalCaloriesBurned: 0,
            plans: WorkoutPlanEntity.defaultPlans,
          ),
        ) {
    loadCustomPlans();
  }

  final SecureStorageService _storage;

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
    final newCalories = state.totalCaloriesBurned + plan.estimatedCalories;

    state = state.copyWith(
      completedWorkoutIds: newCompleted,
      totalCaloriesBurned: newCalories,
    );
    return true;
  }
}
