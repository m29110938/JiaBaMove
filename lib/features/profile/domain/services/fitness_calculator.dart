import '../entities/user_profile_entity.dart';

/// 科學健身與代謝率計算引擎 (Mifflin-St Jeor 方程式)
class FitnessCalculator {
  FitnessCalculator._();

  /// 計算基礎代謝率 (BMR)
  /// 男：10 * 體重(kg) + 6.25 * 身高(cm) - 5 * 年齡 + 5
  /// 女：10 * 體重(kg) + 6.25 * 身高(cm) - 5 * 年齡 - 161
  /// 不透露 (LGBTQ+ 友善中性)：10 * 體重(kg) + 6.25 * 身高(cm) - 5 * 年齡 - 78
  static int calculateBmr({
    required BiologicalSex sex,
    required double weightKg,
    required double heightCm,
    required int age,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    final double constant;

    switch (sex) {
      case BiologicalSex.male:
        constant = 5;
        break;
      case BiologicalSex.female:
        constant = -161;
        break;
      case BiologicalSex.undisclosed:
        // 醫學營養中性平衡常數 ( (5 + -161) / 2 = -78 )
        constant = -78;
        break;
    }

    return (base + constant).round();
  }

  /// 計算每日總消耗熱量 (TDEE)
  static int calculateTdee({
    required int bmr,
    required ActivityLevel activityLevel,
  }) {
    return (bmr * activityLevel.multiplier).round();
  }

  /// 計算身體質量指數 (BMI)
  static double calculateBmi({
    required double weightKg,
    required double heightCm,
  }) {
    final heightM = heightCm / 100.0;
    if (heightM <= 0) return 0.0;
    final bmi = weightKg / (heightM * heightM);
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// 依據健身目標計算每日熱量預算與三大營養素分配
  static NutritionBudget calculateNutritionBudget({
    required int tdee,
    required double weightKg,
    required FitnessGoal goal,
  }) {
    final int targetCalories;
    final double proteinFactor;

    switch (goal) {
      case FitnessGoal.fatLoss:
        targetCalories = (tdee - 350).clamp(1200, 5000);
        proteinFactor = 2.0; // 減脂期高蛋白防掉肌
        break;
      case FitnessGoal.maintain:
        targetCalories = tdee.clamp(1200, 5000);
        proteinFactor = 1.6;
        break;
      case FitnessGoal.muscleGain:
        targetCalories = (tdee + 350).clamp(1200, 5000);
        proteinFactor = 1.8; // 增肌期充沛原料
        break;
    }

    // 蛋白質：每公斤體重分配克數 (1g = 4 kcal)
    final proteinGrams = (weightKg * proteinFactor).round();
    final proteinCalories = proteinGrams * 4;

    // 脂肪：佔總熱量 25% (1g = 9 kcal)
    final fatCalories = (targetCalories * 0.25).round();
    final fatGrams = (fatCalories / 9).round();

    // 碳水化合物：剩餘熱量全部提供日常訓練動能 (1g = 4 kcal)
    final remainingCalories = targetCalories - proteinCalories - fatCalories;
    final carbsGrams = (remainingCalories / 4).round().clamp(50, 800);

    return NutritionBudget(
      targetCalories: targetCalories,
      proteinGrams: proteinGrams,
      carbsGrams: carbsGrams,
      fatGrams: fatGrams,
    );
  }
}
