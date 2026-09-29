/// Gemini API 與網路相關常數定義
class ApiConstants {
  ApiConstants._();

  /// Google Generative Language API 基礎 URL
  static const String geminiBaseUrl = 'https://generativelanguage.googleapis.com';

  /// 預設採用的視覺分析模型版本 (2026 現行活躍主流)
  static const String geminiModel = 'gemini-2.5-flash';

  /// 官方模型清單查詢端點路徑
  static const String modelsPath = '/v1beta/models';

  /// 預設內容生成端點路徑
  static const String generateContentPath = '/v1beta/models/$geminiModel:generateContent';

  /// 針對特定模型動態取得內容生成端點路徑
  static String generateContentPathFor(String model) => '/v1beta/models/$model:generateContent';

  /// 圖片壓縮規格
  static const int imageMaxSide = 1024;
  static const int imageQuality = 75;

  /// 逾時時間設定
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
