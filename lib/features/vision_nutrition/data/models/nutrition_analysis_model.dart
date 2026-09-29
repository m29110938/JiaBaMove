import '../../domain/entities/nutrition_analysis_entity.dart';

/// 視覺營養分析資料模型 (Data Model / DTO)
class NutritionAnalysisModel extends NutritionAnalysisEntity {
  const NutritionAnalysisModel({
    required super.foodName,
    required super.servingSize,
    required super.calories,
    required super.protein,
    required super.carbs,
    required super.fat,
    required super.confidence,
    required super.coachAdvice,
    super.isFood,
  });

  /// 從 Gemini 結構化 JSON 解析
  factory NutritionAnalysisModel.fromJson(Map<String, dynamic> json) {
    final isFood = json['is_food'] as bool? ?? true;

    if (!isFood) {
      return const NutritionAnalysisModel(
        foodName: '未偵測到食物',
        servingSize: '0g',
        calories: 0.0,
        protein: 0.0,
        carbs: 0.0,
        fat: 0.0,
        confidence: 'low',
        coachAdvice: '照片中好像找不到食物耶！請拍清楚美味的一餐再來分析喔！',
        isFood: false,
      );
    }

    final macros = json['macros'] as Map<String, dynamic>? ?? {};

    return NutritionAnalysisModel(
      foodName: json['food_name'] as String? ?? '美味餐點',
      servingSize: json['serving_size'] as String? ?? '1份',
      calories: _parseDouble(json['calories']),
      protein: _parseDouble(macros['protein']),
      carbs: _parseDouble(macros['carbs']),
      fat: _parseDouble(macros['fat']),
      confidence: json['confidence'] as String? ?? 'medium',
      coachAdvice: json['coach_advice'] as String? ??
          '吃得好也練得好，呷飽來動肌肉長飽飽！',
      isFood: true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_food': isFood,
      'food_name': foodName,
      'serving_size': servingSize,
      'calories': calories,
      'macros': {
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
      },
      'confidence': confidence,
      'coach_advice': coachAdvice,
    };
  }

  /// 安全解析數值 (支援 int, double, String 等來源型別)
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }
}
