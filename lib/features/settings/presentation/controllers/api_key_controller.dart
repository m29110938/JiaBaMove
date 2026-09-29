import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/repositories/api_key_repository_impl.dart';
import '../../domain/repositories/api_key_repository.dart';

// --- Dependency Injection Providers ---

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

final apiKeyRepositoryProvider = Provider<ApiKeyRepository>((ref) {
  return ApiKeyRepositoryImpl(
    secureStorageService: ref.watch(secureStorageServiceProvider),
    dioClient: ref.watch(dioClientProvider),
  );
});

// --- State Definition ---

enum ApiKeyStatus {
  initial,
  testing,
  validSaved,
  invalid,
  error,
}

class ApiKeyUiState {
  const ApiKeyUiState({
    this.keyText = '',
    this.isObscured = true,
    this.status = ApiKeyStatus.initial,
    this.errorMessage,
    this.successMessage,
    this.hasExistingKey = false,
    this.availableModels = const [],
    this.selectedModel = 'gemini-2.5-flash',
    this.isFetchingModels = false,
  });

  final String keyText;
  final bool isObscured;
  final ApiKeyStatus status;
  final String? errorMessage;
  final String? successMessage;
  final bool hasExistingKey;
  final List<String> availableModels;
  final String selectedModel;
  final bool isFetchingModels;

  bool get isTesting => status == ApiKeyStatus.testing;

  ApiKeyUiState copyWith({
    String? keyText,
    bool? isObscured,
    ApiKeyStatus? status,
    String? errorMessage,
    String? successMessage,
    bool? hasExistingKey,
    List<String>? availableModels,
    String? selectedModel,
    bool? isFetchingModels,
  }) {
    return ApiKeyUiState(
      keyText: keyText ?? this.keyText,
      isObscured: isObscured ?? this.isObscured,
      status: status ?? this.status,
      errorMessage: errorMessage,
      successMessage: successMessage,
      hasExistingKey: hasExistingKey ?? this.hasExistingKey,
      availableModels: availableModels ?? this.availableModels,
      selectedModel: selectedModel ?? this.selectedModel,
      isFetchingModels: isFetchingModels ?? this.isFetchingModels,
    );
  }
}

// --- Controller Notifier ---

final apiKeyControllerProvider =
    StateNotifierProvider<ApiKeyNotifier, ApiKeyUiState>((ref) {
  return ApiKeyNotifier(ref.watch(apiKeyRepositoryProvider));
});

class ApiKeyNotifier extends StateNotifier<ApiKeyUiState> {
  ApiKeyNotifier(this._repository) : super(const ApiKeyUiState()) {
    loadSavedKey();
  }

  final ApiKeyRepository _repository;

  /// 從 Keychain 讀取已存的金鑰與選定模型
  Future<void> loadSavedKey() async {
    final savedKey = await _repository.getApiKey();
    final savedModel = await _repository.getSelectedModel();

    if (savedKey != null && savedKey.isNotEmpty) {
      state = state.copyWith(
        keyText: savedKey,
        hasExistingKey: true,
        status: ApiKeyStatus.validSaved,
        selectedModel: savedModel ?? 'gemini-2.5-flash',
      );
      // 自動背景同步最新模型清單
      fetchModels(savedKey);
    } else if (savedModel != null && savedModel.isNotEmpty) {
      state = state.copyWith(selectedModel: savedModel);
    }
  }

  /// 切換明文 / 遮罩顯示
  void toggleObscure() {
    state = state.copyWith(isObscured: !state.isObscured);
  }

  /// 切換選定的 AI 模型並持久化存儲
  Future<void> setSelectedModel(String model) async {
    await _repository.saveSelectedModel(model);
    state = state.copyWith(selectedModel: model);
  }

  /// 向 Google 官方請求最新開通之模型清單
  Future<void> fetchModels([String? key]) async {
    final targetKey = key ?? state.keyText;
    if (targetKey.isEmpty) return;

    state = state.copyWith(isFetchingModels: true);
    final models = await _repository.fetchAvailableGeminiModels(targetKey);
    if (models.isNotEmpty) {
      // 若當前選定的模型不在新清單中，且清單有 gemini-2.5-flash，優先切換至首位或 2.5-flash
      String currentSelected = state.selectedModel;
      if (!models.contains(currentSelected) && currentSelected.startsWith('gemini-')) {
        currentSelected = models.contains('gemini-2.5-flash')
            ? 'gemini-2.5-flash'
            : models.first;
        await _repository.saveSelectedModel(currentSelected);
      }
      state = state.copyWith(
        availableModels: models,
        selectedModel: currentSelected,
        isFetchingModels: false,
      );
    } else {
      state = state.copyWith(isFetchingModels: false);
    }
  }

  /// 測試連線並安全寫入 Keychain
  Future<bool> testAndSaveKey(String inputKey) async {
    final trimmedKey = inputKey.trim();

    if (trimmedKey.isEmpty) {
      state = state.copyWith(
        status: ApiKeyStatus.invalid,
        errorMessage: AppStrings.apiKeyEmptyError,
        successMessage: null,
      );
      return false;
    }

    state = state.copyWith(
      status: ApiKeyStatus.testing,
      errorMessage: null,
      successMessage: null,
    );

    final validationStatus = await _repository.validateApiKey(trimmedKey);

    switch (validationStatus) {
      case ApiKeyValidationStatus.valid:
        // 驗證成功，存入 iOS Keychain
        final cleanKey =
            trimmedKey.replaceAll('"', '').replaceAll("'", '').trim();
        await _repository.saveApiKey(cleanKey);
        state = state.copyWith(
          keyText: cleanKey,
          status: ApiKeyStatus.validSaved,
          hasExistingKey: true,
          successMessage: AppStrings.apiKeySavedSuccess,
          errorMessage: null,
        );
        // 同步自動抓取 Google 官方最新可用模型清單
        await fetchModels(cleanKey);
        return true;

      case ApiKeyValidationStatus.invalidKey:
        state = state.copyWith(
          status: ApiKeyStatus.invalid,
          errorMessage: AppStrings.apiKeyInvalidError,
          successMessage: null,
        );
        return false;

      case ApiKeyValidationStatus.serviceNotEnabled:
        state = state.copyWith(
          status: ApiKeyStatus.invalid,
          errorMessage: AppStrings.serviceNotEnabledError,
          successMessage: null,
        );
        return false;

      case ApiKeyValidationStatus.quotaExceeded:
        state = state.copyWith(
          status: ApiKeyStatus.error,
          errorMessage: AppStrings.quotaExceededError,
          successMessage: null,
        );
        return false;

      case ApiKeyValidationStatus.networkError:
        state = state.copyWith(
          status: ApiKeyStatus.error,
          errorMessage: AppStrings.networkError,
          successMessage: null,
        );
        return false;

      case ApiKeyValidationStatus.unknown:
        state = state.copyWith(
          status: ApiKeyStatus.error,
          errorMessage: AppStrings.unknownError,
          successMessage: null,
        );
        return false;
    }
  }

  /// 清除金鑰
  Future<void> clearKey() async {
    await _repository.deleteApiKey();
    state = const ApiKeyUiState(
      keyText: '',
      hasExistingKey: false,
      status: ApiKeyStatus.initial,
    );
  }
}
