/// API Key 連線驗證結果狀態
enum ApiKeyValidationStatus {
  valid,
  invalidKey,        // 400, 401, 403
  serviceNotEnabled, // 404 (專案未開通模型或地區不支援)
  quotaExceeded,     // 429 (用量上限)
  networkError,      // 連線逾時、無網路、DNS 失敗
  unknown,
}

/// API Key 存取與驗證合約介面
abstract class ApiKeyRepository {
  /// 取得當前存儲之 API Key
  Future<String?> getApiKey();

  /// 儲存 API Key 至 Keychain
  Future<void> saveApiKey(String apiKey);

  /// 清除 API Key
  Future<void> deleteApiKey();

  /// 測試並驗證 Gemini API Key 是否合法有效
  /// 透過發送輕量請求至 GET /v1beta/models 驗證，回傳精確之狀態枚舉
  Future<ApiKeyValidationStatus> validateApiKey(String apiKey);

  /// 透過 API Key 向 Google 伺服器動態查詢目前真正可用之模型清單
  Future<List<String>> fetchAvailableGeminiModels(String apiKey);

  /// 取得當前選定之 AI 模型名稱
  Future<String?> getSelectedModel();

  /// 儲存選定之 AI 模型名稱
  Future<void> saveSelectedModel(String model);
}
