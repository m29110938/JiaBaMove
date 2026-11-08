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

  /// 由 AI 分析結果建立紀錄
  factory MealLogEntity.fromAnalysis(
    NutritionAnalysisEntity analysis, {
    required DateTime loggedAt,
  }) {
    return MealLogEntity(
      id: 'meal_${loggedAt.microsecondsSinceEpoch}',
      dateString: formatDate(loggedAt),
      loggedAt: loggedAt,
      mealType: MealType.fromTime(loggedAt),
      foodName: analysis.foodName,
      servingSize: analysis.servingSize,
      calories: analysis.calories,
      protein: analysis.protein,
      carbs: analysis.carbs,
      fat: analysis.fat,
    );
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
