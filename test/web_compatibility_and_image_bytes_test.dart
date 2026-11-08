import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/core/storage/secure_storage_service.dart';
import 'package:jiaba_move/features/vision_nutrition/data/datasources/gemini_vision_service.dart';
import 'package:jiaba_move/features/vision_nutrition/data/models/nutrition_analysis_model.dart';
import 'package:jiaba_move/core/network/dio_client.dart';

void main() {
  group('Web Compatibility & Cross-Platform Bytes Processing Tests', () {
    test('SecureStorageService initializes properly with WebOptions', () {
      final storage = SecureStorageService();
      expect(storage, isNotNull);
    });

    test('GeminiVisionService compressImageBytes handles small bytes directly', () async {
      final dioClient = DioClient();
      final storage = SecureStorageService();
      final service = GeminiVisionService(
        dioClient: dioClient,
        secureStorageService: storage,
      );

      // 產生 100 bytes 的模擬測試資料 (脫敏假資料)
      final dummyBytes = Uint8List.fromList(List.generate(100, (i) => i % 256));
      final resultBytes = await service.compressImageBytes(dummyBytes);

      expect(resultBytes.length, equals(100));
      expect(resultBytes, equals(dummyBytes));
    });

    test('NutritionAnalysisModel correctly deserializes nutrition JSON', () {
      const mockJsonString = '''
      {
        "is_food": true,
        "food_name": "經典雞胸肉健康便當",
        "serving_size": "1盒 (約 350g)",
        "calories": 480.0,
        "macros": {
          "protein": 36.0,
          "carbs": 52.0,
          "fat": 12.0
        },
        "confidence": "high",
        "coach_advice": "蛋白質超充足！今天重訓後補充剛剛好，繼續保持！"
      }
      ''';

      final map = jsonDecode(mockJsonString) as Map<String, dynamic>;
      final model = NutritionAnalysisModel.fromJson(map);

      expect(model.isFood, isTrue);
      expect(model.foodName, '經典雞胸肉健康便當');
      expect(model.calories, 480.0);
      expect(model.protein, 36.0);
      expect(model.carbs, 52.0);
      expect(model.fat, 12.0);
      expect(model.confidence, 'high');
      expect(model.coachAdvice, contains('蛋白質超充足'));
    });
  });
}
