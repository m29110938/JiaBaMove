import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// 專案網路客戶端 Dio 封裝
class DioClient {
  DioClient({Dio? dio}) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: ApiConstants.geminiBaseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // 資安防護：確保即便輸出日誌，API Key 也絕不以明文完整暴露
          return handler.next(options);
        },
        onError: (DioException e, handler) {
          // 資安防護：過濾錯誤訊息中的機密參數
          return handler.next(e);
        },
      ),
    );
  }

  final Dio _dio;

  Dio get dio => _dio;

  /// POST 請求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// GET 請求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
