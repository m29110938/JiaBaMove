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
      webOptions: WebOptions(
        dbName: 'jiaba_secure_storage',
        publicKey: 'jiaba_client_key',
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

  static const String _dailyWorkoutItemsKey = 'jiaba_daily_workout_items_json';

  /// 讀取儲存的今日菜單資料 JSON (含日期與各項目)
  Future<String?> getDailyWorkoutItemsJson() async {
    return await _storage.read(key: _dailyWorkoutItemsKey);
  }

  /// 安全存入今日菜單資料 JSON
  Future<void> saveDailyWorkoutItemsJson(String json) async {
    await _storage.write(key: _dailyWorkoutItemsKey, value: json);
  }

  static const String _customExercisesByBodyPartKey = 'jiaba_custom_exercises_by_body_part_json';

  /// 讀取儲存的依部位自訂動作清單 JSON
  Future<String?> getCustomExercisesByBodyPartJson() async {
    return await _storage.read(key: _customExercisesByBodyPartKey);
  }

  /// 安全存入依部位自訂動作清單 JSON
  Future<void> saveCustomExercisesByBodyPartJson(String json) async {
    await _storage.write(key: _customExercisesByBodyPartKey, value: json);
  }

  static const String _restTimerAutoTriggerKey = 'jiaba_rest_timer_auto_trigger';

  /// 讀取組間休息計時器勾選動作自動啟動偏好設定 (預設 true)
  Future<bool> getRestTimerAutoTrigger() async {
    final val = await _storage.read(key: _restTimerAutoTriggerKey);
    if (val == null) return true;
    return val == 'true';
  }

  /// 安全存入組間休息計時器自動啟動偏好設定
  Future<void> saveRestTimerAutoTrigger(bool autoTrigger) async {
    await _storage.write(key: _restTimerAutoTriggerKey, value: autoTrigger.toString());
  }

  static const String _mealLogsKey = 'jiaba_meal_logs_json';

  /// 讀取飲食紀錄 JSON (陣列)
  Future<String?> getMealLogsJson() async {
    return await _storage.read(key: _mealLogsKey);
  }

  /// 安全存入飲食紀錄 JSON (陣列)
  Future<void> saveMealLogsJson(String json) async {
    await _storage.write(key: _mealLogsKey, value: json);
  }

  static const String _favoriteFoodsKey = 'jiaba_favorite_foods_json';

  /// 讀取常吃食物清單 JSON
  Future<String?> getFavoriteFoodsJson() async {
    return await _storage.read(key: _favoriteFoodsKey);
  }

  /// 儲存常吃食物清單 JSON
  Future<void> saveFavoriteFoodsJson(String json) async {
    await _storage.write(key: _favoriteFoodsKey, value: json);
  }

  /// 清除本 App 存於 Keychain 的所有資料 (API Key、個人資料、課表、飲食紀錄)
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// 檢查是否存在有效的 API Key
  Future<bool> hasGeminiApiKey() async {
    final key = await getGeminiApiKey();
    return key != null && key.trim().isNotEmpty;
  }
}
