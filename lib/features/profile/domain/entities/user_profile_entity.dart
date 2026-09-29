/// 生理性別 (僅用於醫學營養公式推算基礎代謝率，LGBTQ+ 友善)
enum BiologicalSex {
  male,
  female,
  undisclosed;

  String get label {
    switch (this) {
      case BiologicalSex.male:
        return '生理男性';
      case BiologicalSex.female:
        return '生理女性';
      case BiologicalSex.undisclosed:
        return '不透露';
    }
  }
}

/// 日常活動量等級
enum ActivityLevel {
  sedentary, // 久坐族 (1.2)
  light,     // 輕度活動 (1.375)
  moderate,  // 中度規律運動 (1.55)
  active;    // 高強度運動 (1.725)

  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return '久坐辦公族';
      case ActivityLevel.light:
        return '輕度運動族';
      case ActivityLevel.moderate:
        return '規律運動巨巨';
      case ActivityLevel.active:
        return '高強度運動達人';
    }
  }

  String get description {
    switch (this) {
      case ActivityLevel.sedentary:
        return '幾乎不運動，日常靜態辦公居多 (x1.2)';
      case ActivityLevel.light:
        return '每週散步或輕量運動 1~3 天 (x1.375)';
      case ActivityLevel.moderate:
        return '每週規律重訓或有氧 3~5 天 (x1.55)';
      case ActivityLevel.active:
        return '每週高強度扎實鍛鍊 6~7 天 (x1.725)';
    }
  }

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
    }
  }
}

/// 健身與體態目標
enum FitnessGoal {
  fatLoss,
  maintain,
  muscleGain;

  String get label {
    switch (this) {
      case FitnessGoal.fatLoss:
        return '減脂瘦身';
      case FitnessGoal.maintain:
        return '維持體態';
      case FitnessGoal.muscleGain:
        return '增肌變壯';
    }
  }

  String get description {
    switch (this) {
      case FitnessGoal.fatLoss:
        return '熱量赤字 (-350 kcal)，高蛋白質飽足防掉肌';
      case FitnessGoal.maintain:
        return '熱量平衡，享受美食維持健美線條';
      case FitnessGoal.muscleGain:
        return '熱量微盈餘 (+350 kcal)，充足碳水催化肌肉合成';
    }
  }

  String get emoji {
    switch (this) {
      case FitnessGoal.fatLoss:
        return '🔥';
      case FitnessGoal.maintain:
        return '⚖️';
      case FitnessGoal.muscleGain:
        return '💪';
    }
  }
}

/// 每日營養目標預算
class NutritionBudget {
  const NutritionBudget({
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
  });

  final int targetCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
}

/// 個人身材與代謝檔案領域實體 (Domain Entity)
class UserProfileEntity {
  const UserProfileEntity({
    required this.birthDate,
    required this.biologicalSex,
    required this.heightCm,
    required this.weightKg,
    required this.activityLevel,
    required this.goal,
    required this.bmr,
    required this.tdee,
    required this.targetCalories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.bmi,
  });

  final DateTime birthDate;
  final BiologicalSex biologicalSex;
  final double heightCm;
  final double weightKg;
  final ActivityLevel activityLevel;
  final FitnessGoal goal;

  final int bmr;
  final int tdee;
  final int targetCalories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final double bmi;

  int get age {
    final now = DateTime.now();
    int calculatedAge = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      calculatedAge--;
    }
    return calculatedAge.clamp(10, 100);
  }

  Map<String, dynamic> toJson() {
    return {
      'birthDate': birthDate.toIso8601String(),
      'biologicalSex': biologicalSex.name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'activityLevel': activityLevel.name,
      'goal': goal.name,
      'bmr': bmr,
      'tdee': tdee,
      'targetCalories': targetCalories,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'bmi': bmi,
    };
  }

  factory UserProfileEntity.fromJson(Map<String, dynamic> json) {
    return UserProfileEntity(
      birthDate: DateTime.parse(json['birthDate'] as String),
      biologicalSex: BiologicalSex.values.byName(json['biologicalSex'] as String),
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      activityLevel: ActivityLevel.values.byName(json['activityLevel'] as String),
      goal: FitnessGoal.values.byName(json['goal'] as String),
      bmr: json['bmr'] as int,
      tdee: json['tdee'] as int,
      targetCalories: json['targetCalories'] as int,
      proteinGrams: json['proteinGrams'] as int,
      carbsGrams: json['carbsGrams'] as int,
      fatGrams: json['fatGrams'] as int,
      bmi: (json['bmi'] as num).toDouble(),
    );
  }
}
