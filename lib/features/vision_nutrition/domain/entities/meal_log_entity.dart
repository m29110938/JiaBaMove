import 'nutrition_analysis_entity.dart';

/// 餐別 (依記錄時間自動推斷)
enum MealType {
  breakfast('早餐'),
  lunch('午餐'),
  afternoonSnack('下午點心'),
  dinner('晚餐'),
  lateNight('宵夜');

  const MealType(this.label);
  final String label;

  /// 依時間推斷餐別
  static MealType fromTime(DateTime time) {
    final minutes = time.hour * 60 + time.minute;
    if (minutes >= 4 * 60 && minutes < 10 * 60 + 30) return MealType.breakfast;
    if (minutes >= 10 * 60 + 30 && minutes < 14 * 60) return MealType.lunch;
    if (minutes >= 14 * 60 && minutes < 17 * 60) return MealType.afternoonSnack;
    if (minutes >= 17 * 60 && minutes < 21 * 60) return MealType.dinner;
    return MealType.lateNight;
  }

  static MealType fromName(String? name) {
    return MealType.values.firstWhere(
      (t) => t.name == name,
      orElse: () => MealType.lunch,
    );
  }
}

/// 單筆飲食紀錄 (拍照分析後存入)
class MealLogEntity {
  const MealLogEntity({
    required this.id,
    required this.dateString,
    required this.loggedAt,
    required this.mealType,
    required this.foodName,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  /// 由 AI 分析結果建立紀錄 (數值會限制在合理範圍)
  factory MealLogEntity.fromAnalysis(
    NutritionAnalysisEntity analysis, {
    required DateTime loggedAt,
  }) {
    return MealDraft.fromAnalysis(analysis).toLog(loggedAt: loggedAt);
  }

  factory MealLogEntity.fromJson(Map<String, dynamic> json) {
    final loggedAt =
        DateTime.tryParse(json['loggedAt'] as String? ?? '') ?? DateTime.now();
    return MealLogEntity(
      id: json['id'] as String? ?? 'meal_${loggedAt.microsecondsSinceEpoch}',
      dateString: json['dateString'] as String? ?? formatDate(loggedAt),
      loggedAt: loggedAt,
      mealType: MealType.fromName(json['mealType'] as String?),
      foodName: json['foodName'] as String? ?? '',
      servingSize: json['servingSize'] as String? ?? '',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String dateString; // yyyy-MM-dd
  final DateTime loggedAt;
  final MealType mealType;
  final String foodName;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateString': dateString,
        'loggedAt': loggedAt.toIso8601String(),
        'mealType': mealType.name,
        'foodName': foodName,
        'servingSize': servingSize,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  /// 標準日期字串 yyyy-MM-dd
  static String formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

/// 餐點內容草稿 (手動輸入、修改 AI 結果、常吃清單共用)
class MealDraft {
  const MealDraft({
    required this.foodName,
    this.servingSize = '',
    required this.calories,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.mealType,
  });

  /// 合理範圍上限 (避免手誤或 AI 回傳極端值)
  static const double maxCalories = 5000;
  static const double maxMacroGrams = 1000;

  final String foodName;
  final String servingSize;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  /// 指定餐別；null 代表依記錄時間自動推斷
  final MealType? mealType;

  factory MealDraft.fromAnalysis(NutritionAnalysisEntity a) => MealDraft(
        foodName: a.foodName,
        servingSize: a.servingSize,
        calories: a.calories,
        protein: a.protein,
        carbs: a.carbs,
        fat: a.fat,
      );

  factory MealDraft.fromLog(MealLogEntity m) => MealDraft(
        foodName: m.foodName,
        servingSize: m.servingSize,
        calories: m.calories,
        protein: m.protein,
        carbs: m.carbs,
        fat: m.fat,
        mealType: m.mealType,
      );

  factory MealDraft.fromJson(Map<String, dynamic> json) => MealDraft(
        foodName: json['foodName'] as String? ?? '',
        servingSize: json['servingSize'] as String? ?? '',
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        protein: (json['protein'] as num?)?.toDouble() ?? 0,
        carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
        fat: (json['fat'] as num?)?.toDouble() ?? 0,
      );

  /// 常吃清單只存營養內容，不存餐別
  Map<String, dynamic> toJson() => {
        'foodName': foodName,
        'servingSize': servingSize,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      };

  /// 將數值限制在合理範圍內
  MealDraft sanitized() => MealDraft(
        foodName: foodName.trim(),
        servingSize: servingSize.trim(),
        calories: _clamp(calories, maxCalories),
        protein: _clamp(protein, maxMacroGrams),
        carbs: _clamp(carbs, maxMacroGrams),
        fat: _clamp(fat, maxMacroGrams),
        mealType: mealType,
      );

  static double _clamp(double v, double max) =>
      v.isNaN ? 0 : v.clamp(0, max).toDouble();

  /// 依名稱判斷是否為同一道常吃食物
  bool sameFoodAs(MealDraft other) =>
      foodName.trim() == other.foodName.trim() &&
      servingSize.trim() == other.servingSize.trim();
}

extension MealLogFromDraft on MealDraft {
  /// 以草稿建立新紀錄
  MealLogEntity toLog({required DateTime loggedAt, String? id}) {
    final d = sanitized();
    return MealLogEntity(
      id: id ?? 'meal_${loggedAt.microsecondsSinceEpoch}',
      dateString: MealLogEntity.formatDate(loggedAt),
      loggedAt: loggedAt,
      mealType: d.mealType ?? MealType.fromTime(loggedAt),
      foodName: d.foodName,
      servingSize: d.servingSize,
      calories: d.calories,
      protein: d.protein,
      carbs: d.carbs,
      fat: d.fat,
    );
  }
}
