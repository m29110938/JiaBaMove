import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../domain/repositories/api_key_repository.dart';

/// API Key Repository 實作層
class ApiKeyRepositoryImpl implements ApiKeyRepository {
  ApiKeyRepositoryImpl({
    required SecureStorageService secureStorageService,
    required DioClient dioClient,
  })  : _storage = secureStorageService,
        _dioClient = dioClient;

  final SecureStorageService _storage;
  final DioClient _dioClient;

  @override
  Future<String?> getApiKey() async {
    return await _storage.getGeminiApiKey();
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    await _storage.saveGeminiApiKey(apiKey);
  }

  @override
  Future<void> deleteApiKey() async {
    await _storage.deleteGeminiApiKey();
  }

  @override
  Future<ApiKeyValidationStatus> validateApiKey(String apiKey) async {
    // 資安與資料清洗：清除前後空格、換行以及可能複製到的單雙引號
    final cleanKey = apiKey.replaceAll('"', '').replaceAll("'", '').trim();
    if (cleanKey.isEmpty) return ApiKeyValidationStatus.invalidKey;

    try {
      // 官方標準驗證：向 GET /v1beta/models 請求清單，輕量、零 Token 消耗，永不因特定模型世代退役報 404
      final response = await _dioClient.get(
        ApiConstants.modelsPath,
        options: Options(
          headers: {
            'x-goog-api-key': cleanKey, // Google 2026 規範：AQ. 與 AIza 一律透過 Header 認證
          },
        ),
      );

      if (response.statusCode == 200) {
        return ApiKeyValidationStatus.valid;
      }
      return ApiKeyValidationStatus.unknown;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      final errorData = e.response?.data;
      String errorMessage = '';
      if (errorData is Map) {
        final err = errorData['error'];
        if (err is Map) {
          errorMessage = err['message']?.toString() ?? '';
        }
      }

      if (statusCode == 400 || statusCode == 401) {
        return ApiKeyValidationStatus.invalidKey;
      }
      if (statusCode == 403) {
        // 檢查是否為專案未開通 Generative Language API
        if (errorMessage.contains('has not been used') ||
            errorMessage.contains('disabled') ||
            errorMessage.contains('enable')) {
          return ApiKeyValidationStatus.serviceNotEnabled;
        }
        return ApiKeyValidationStatus.invalidKey;
      }
      if (statusCode == 404) {
        return ApiKeyValidationStatus.serviceNotEnabled;
      }
      if (statusCode == 429) {
        return ApiKeyValidationStatus.quotaExceeded;
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return ApiKeyValidationStatus.networkError;
      }
      if (e.response == null) {
        return ApiKeyValidationStatus.networkError;
      }
      return ApiKeyValidationStatus.unknown;
    } catch (_) {
      return ApiKeyValidationStatus.unknown;
    }
  }

  @override
  Future<List<String>> fetchAvailableGeminiModels(String apiKey) async {
    final cleanKey = apiKey.replaceAll('"', '').replaceAll("'", '').trim();
    if (cleanKey.isEmpty) return [];

    try {
      final response = await _dioClient.get(
        ApiConstants.modelsPath,
        options: Options(
          headers: {
            'x-goog-api-key': cleanKey,
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final rawList = data['models'] as List<dynamic>? ?? [];

        final capableModels = <String>[];
        for (final item in rawList) {
          if (item is Map) {
            final methods = (item['supportedGenerationMethods'] as List<dynamic>?) ?? [];
            final name = item['name']?.toString() ?? '';
            // 僅篩選支援 generateContent 之模型 (排除 embedding, text-bison 等舊時代或特殊模型)
            if (methods.contains('generateContent') && name.isNotEmpty) {
              final cleanName = name.replaceFirst('models/', '');
              // 聚焦於 Gemini 系列模型
              if (cleanName.startsWith('gemini-')) {
                capableModels.add(cleanName);
              }
            }
          }
        }

        // 排序：推薦的 2.5 flash、3.5 flash、2.5 pro 優先排在最前面
        capableModels.sort((a, b) {
          int score(String model) {
            if (model.contains('2.5-flash')) return 1;
            if (model.contains('3.5-flash')) return 2;
            if (model.contains('2.5-pro')) return 3;
            if (model.contains('flash')) return 4;
            if (model.contains('pro')) return 5;
            return 6;
          }
          return score(a).compareTo(score(b));
        });

        return capableModels;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<String?> getSelectedModel() async {
    return await _storage.getSelectedModel();
  }

  @override
  Future<void> saveSelectedModel(String model) async {
    await _storage.saveSelectedModel(model);
  }
}
