import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/image_metadata.dart';
import '../models/nutrition_analysis_model.dart';

/// Gemini 1.5 Flash 視覺營養分析客戶端
class GeminiVisionService {
  GeminiVisionService({
    required DioClient dioClient,
    required SecureStorageService secureStorageService,
  })  : _dioClient = dioClient,
        _storage = secureStorageService;

  final DioClient _dioClient;
  final SecureStorageService _storage;

  /// 系統提示詞：台灣在地運動營養師角色
  static const String _nutritionistSystemPrompt = '''
你是一位專業且風格親切、帶有微幽默感的台灣運動健身營養師。
請分析這張餐點照片，評估其熱量與三大營養素。
若照片中不是食物或無法辨識，請將 is_food 設為 false。

你必須只回傳符合下列格式的純 JSON 物件，嚴禁包含任何額外的 Markdown 標記 (不要加 ```json 等字元)：
{
  "is_food": true,
  "food_name": "餐點名稱 (請用地道台灣名稱，如：滷肉飯加蛋、香煎雞胸肉地瓜餐)",
  "serving_size": "預估份量 (如：1碗 約250g)",
  "calories": 520,
  "macros": {
    "protein": 28.5,
    "carbs": 65.0,
    "fat": 15.2
  },
  "confidence": "high",
  "coach_advice": "一句親切、具台灣健身教練幽默風格的飲食與鍛鍊點評"
}
''';

  /// 圖片壓縮處理：長邊上限 1024px，品質 75% (記憶體純處理，相容 Web 與 iOS)
  ///
  /// 隱私：一律重新編碼 (不保留 EXIF)，並再移除一次 JPEG 中繼資料，
  /// 確保 GPS 位置、拍攝時間、裝置型號不會隨照片送出。
  Future<List<int>> compressImageBytes(List<int> bytes) async {
    final inputBytes = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);
    var output = inputBytes;

    try {
      final compressed = await FlutterImageCompress.compressWithList(
        inputBytes,
        minWidth: ApiConstants.imageMaxSide,
        minHeight: ApiConstants.imageMaxSide,
        quality: ApiConstants.imageQuality,
        format: CompressFormat.jpeg,
        keepExif: false,
      );

      if (compressed.isNotEmpty) {
        output = compressed;
      }
    } catch (_) {
      // 若壓縮外掛在特定環境未註冊，回退使用原始 byte (下方仍會移除中繼資料)
    }

    return stripJpegMetadata(output);
  }

  /// 相容別名方法：壓縮圖片
  Future<List<int>> compressImage(List<int> bytes) async {
    return compressImageBytes(bytes);
  }

  /// 接收圖片位元組 (Bytes)，壓縮後發送至 Gemini 1.5 Flash 進行結構化營養辨識
  Future<NutritionAnalysisModel> analyzeFoodImage(List<int> imageBytes) async {
    return analyzeFoodImageBytes(imageBytes);
  }

  /// 接收圖片位元組 (Bytes)，發送至 Gemini 進行結構化營養辨識
  Future<NutritionAnalysisModel> analyzeFoodImageBytes(List<int> imageBytes) async {
    // 1. 從 Keychain / SecureStorage 取得 API Key 並清洗引號與空白
    final rawApiKey = await _storage.getGeminiApiKey();
    if (rawApiKey == null) {
      throw StateError('尚未設定 Gemini API Key，請先至設定頁配置！');
    }
    final cleanApiKey =
        rawApiKey.replaceAll('"', '').replaceAll("'", '').trim();
    if (cleanApiKey.isEmpty) {
      throw StateError('尚未設定 Gemini API Key，請先至設定頁配置！');
    }

    // 2. 進行圖片標準壓縮處理
    final compressedBytes = await compressImageBytes(imageBytes);

    // 3. 轉為 Base64 字串
    final base64Image = base64Encode(compressedBytes);

    // 4. 構建 Gemini 1.5 Flash 請求酬載 (強制 JSON 結構化輸出)
    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': _nutritionistSystemPrompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'response_mime_type': 'application/json',
        'temperature': 0.2, // 保持營養數值預估穩定性
      },
    };

    // 讀取當前選定之 AI 模型 (預設為 2026 活躍的 gemini-2.5-flash)
    final selectedModel =
        await _storage.getSelectedModel() ?? ApiConstants.geminiModel;
    final targetPath = ApiConstants.generateContentPathFor(selectedModel);

    try {
      final response = await _dioClient.post(
        targetPath,
        options: Options(
          headers: {
            'x-goog-api-key': cleanApiKey, // Google 2026 規範：AQ. 與 AIza 一律透過 Header 認證
            'Content-Type': 'application/json',
          },
        ),
        data: payload,
      );

      if (response.statusCode == 200 && response.data != null) {
        return _parseGeminiResponse(response.data);
      } else {
        throw Exception('Gemini API 呼叫異常，HTTP 代碼: ${response.statusCode}');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400 || statusCode == 403) {
        throw StateError('Gemini API Key 無效或未開通權限，請重新確認！');
      }
      throw Exception('網路連線逾時或失敗，請稍後再試。');
    }
  }

  /// 解析 Gemini 回傳的 JSON 結構
  NutritionAnalysisModel _parseGeminiResponse(dynamic responseData) {
    try {
      final candidates = responseData['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const FormatException('Gemini 未回傳有效分析候選結果');
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        throw const FormatException('分析內容為空');
      }

      final rawText = parts.first['text'] as String? ?? '{}';

      // 清理可能殘留的 markdown tag (以防萬一)
      final cleanJsonText = rawText
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final jsonMap = jsonDecode(cleanJsonText) as Map<String, dynamic>;
      return NutritionAnalysisModel.fromJson(jsonMap);
    } catch (e) {
      throw FormatException('無法正確解析營養分析結果: $e');
    }
  }
}
