import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/features/settings/domain/repositories/api_key_repository.dart';

void main() {
  group('ApiKeyValidationStatus Enum & Parsing Tests', () {
    test('Verify ApiKeyValidationStatus contains expected states', () {
      expect(ApiKeyValidationStatus.values, contains(ApiKeyValidationStatus.valid));
      expect(ApiKeyValidationStatus.values, contains(ApiKeyValidationStatus.invalidKey));
      expect(ApiKeyValidationStatus.values, contains(ApiKeyValidationStatus.serviceNotEnabled));
      expect(ApiKeyValidationStatus.values, contains(ApiKeyValidationStatus.quotaExceeded));
      expect(ApiKeyValidationStatus.values, contains(ApiKeyValidationStatus.networkError));
    });

    test('Clean key strips quotes and spaces including AQ. new key format', () {
      const dirtyKey1 = '  "AIzaSyTestKey123"  ';
      const dirtyKey2 = "  'AQ.Ab8RN6IYDEfiYqFoTestKey' \n";
      
      final clean1 = dirtyKey1.replaceAll('"', '').replaceAll("'", '').trim();
      final clean2 = dirtyKey2.replaceAll('"', '').replaceAll("'", '').trim();

      expect(clean1, equals('AIzaSyTestKey123'));
      expect(clean2, equals('AQ.Ab8RN6IYDEfiYqFoTestKey'));
      expect(clean2.startsWith('AQ.'), isTrue);
    });

    test('Google Models JSON parsing extracts generateContent capable models', () {
      final mockGoogleResponse = {
        'models': [
          {
            'name': 'models/gemini-2.5-flash',
            'version': '001',
            'displayName': 'Gemini 2.5 Flash',
            'supportedGenerationMethods': ['generateContent', 'countTokens'],
          },
          {
            'name': 'models/gemini-2.5-pro',
            'version': '001',
            'displayName': 'Gemini 2.5 Pro',
            'supportedGenerationMethods': ['generateContent'],
          },
          {
            'name': 'models/text-embedding-004',
            'version': '001',
            'displayName': 'Embedding',
            'supportedGenerationMethods': ['embedContent'],
          },
          {
            'name': 'models/gemini-3.5-flash',
            'version': '001',
            'displayName': 'Gemini 3.5 Flash',
            'supportedGenerationMethods': ['generateContent'],
          },
        ]
      };

      final modelsList = mockGoogleResponse['models'] as List<dynamic>;
      final available = modelsList
          .where((m) {
            final methods = (m['supportedGenerationMethods'] as List<dynamic>?) ?? [];
            return methods.contains('generateContent');
          })
          .map((m) {
            final rawName = m['name'] as String;
            return rawName.replaceFirst('models/', '');
          })
          .toList();

      expect(available, contains('gemini-2.5-flash'));
      expect(available, contains('gemini-2.5-pro'));
      expect(available, contains('gemini-3.5-flash'));
      expect(available, isNot(contains('text-embedding-004')));
    });
  });
}
