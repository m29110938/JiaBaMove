import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// iOS Keychain 安全存儲封裝服務
/// 嚴格遵守資安原則，金鑰禁止明文儲存於 SharedPreferences
class SecureStorageService {
  SecureStorageService() {
    _storage = const FlutterSecureStorage(
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock,
        synchronizable: false, // 禁止未授權跨 iCloud 明文同步
      ),
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
  }

  late final FlutterSecureStorage _storage;

  static const String _geminiApiKeyKey = 'jiaba_gemini_api_key';

  /// 讀取 Gemini API Key
  Future<String?> getGeminiApiKey() async {
    return await _storage.read(key: _geminiApiKeyKey);
  }

  /// 安全存入 Gemini API Key
  Future<void> saveGeminiApiKey(String apiKey) async {
    await _storage.write(key: _geminiApiKeyKey, value: apiKey.trim());
  }

  /// 清除已存之 API Key
  Future<void> deleteGeminiApiKey() async {
    await _storage.delete(key: _geminiApiKeyKey);
  }

  static const String _selectedModelKey = 'jiaba_selected_ai_model';

  /// 讀取選定的 AI 模型名稱
  Future<String?> getSelectedModel() async {
    return await _storage.read(key: _selectedModelKey);
  }

  /// 安全存入選定的 AI 模型名稱
  Future<void> saveSelectedModel(String model) async {
    await _storage.write(key: _selectedModelKey, value: model.trim());
  }

  static const String _userDisplayNameKey = 'jiaba_user_display_name';

  /// 讀取自訂會員名稱
  Future<String?> getUserDisplayName() async {
    return await _storage.read(key: _userDisplayNameKey);
  }

  /// 安全存入自訂會員名稱
  Future<void> saveUserDisplayName(String name) async {
    await _storage.write(key: _userDisplayNameKey, value: name.trim());
  }

  static const String _userProfileKey = 'jiaba_user_profile_json';

  /// 讀取儲存的個人身材代謝檔案 JSON
  Future<String?> getUserProfileJson() async {
    return await _storage.read(key: _userProfileKey);
  }

  /// 安全存入個人身材代謝檔案 JSON
  Future<void> saveUserProfileJson(String json) async {
    await _storage.write(key: _userProfileKey, value: json);
  }

  static const String _customWorkoutPlansKey = 'jiaba_custom_workout_plans_json';

  /// 讀取儲存的自訂課表 JSON
  Future<String?> getCustomWorkoutPlansJson() async {
    return await _storage.read(key: _customWorkoutPlansKey);
  }

  /// 安全存入自訂課表 JSON
  Future<void> saveCustomWorkoutPlansJson(String json) async {
    await _storage.write(key: _customWorkoutPlansKey, value: json);
  }

  /// 檢查是否存在有效的 API Key
  Future<bool> hasGeminiApiKey() async {
    final key = await getGeminiApiKey();
    return key != null && key.trim().isNotEmpty;
  }
}
