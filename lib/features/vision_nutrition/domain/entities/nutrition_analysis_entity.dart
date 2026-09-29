/// 視覺營養分析領域實體 (Domain Entity)
class NutritionAnalysisEntity {
  const NutritionAnalysisEntity({
    required this.foodName,
    required this.servingSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.confidence,
    required this.coachAdvice,
    this.isFood = true,
  });

  /// 餐點名稱 (例如：香煎雞胸肉佐地瓜)
  final String foodName;

  /// 預估份量 (例如：1份 (約 300g))
  final String servingSize;

  /// 總熱量 (大卡 kcal)
  final double calories;

  /// 蛋白質 (克 g)
  final double protein;

  /// 碳水化合物 (克 g)
  final double carbs;

  /// 脂肪 (克 g)
  final double fat;

  /// 辨識信心度 ('high' | 'medium' | 'low')
  final String confidence;

  /// 台灣健身教練親切叮嚀
  final String coachAdvice;

  /// 是否成功辨識出食物
  final bool isFood;
}
