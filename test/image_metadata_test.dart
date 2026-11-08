import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:jiaba_move/core/utils/image_metadata.dart';

List<int> _segment(int marker, List<int> payload) {
  final len = payload.length + 2;
  return [0xFF, marker, (len >> 8) & 0xFF, len & 0xFF, ...payload];
}

void main() {
  group('stripJpegMetadata', () {
    // 模擬含 GPS 的 EXIF 區段 (假資料)
    final exif = _segment(0xE1, [...'Exif'.codeUnits, 0, 0, ...'GPS-25.03,121.56'.codeUnits]);
    final xmp = _segment(0xE1, 'http://ns.adobe.com/xap/1.0/'.codeUnits);
    final iptc = _segment(0xED, 'Photoshop 3.0'.codeUnits);
    final comment = _segment(0xFE, 'secret comment'.codeUnits);
    final jfif = _segment(0xE0, [...'JFIF'.codeUnits, 0, 1, 1, 0, 0, 1, 0, 1, 0, 0]);
    final icc = _segment(0xE2, 'ICC_PROFILE'.codeUnits);
    final dqt = _segment(0xDB, List.filled(65, 1));
    final sos = [
      ..._segment(0xDA, [1, 1, 0, 0, 63, 0]),
      0x12, 0x34, 0xFF, 0x00, 0x56, // 壓縮資料 (含 byte stuffing)
      0xFF, 0xD9,
    ];

    Uint8List build(List<List<int>> parts) =>
        Uint8List.fromList([0xFF, 0xD8, for (final p in parts) ...p]);

    test('移除 EXIF / XMP / IPTC / 註解，保留其他區段與影像資料', () {
      final input = build([jfif, exif, xmp, icc, iptc, comment, dqt, sos]);
      final output = stripJpegMetadata(input);
      final expected = build([jfif, icc, dqt, sos]);

      expect(output, equals(expected));
      expect(String.fromCharCodes(output).contains('GPS'), isFalse);
      expect(String.fromCharCodes(output).contains('Exif'), isFalse);
    });

    test('沒有中繼資料的 JPEG 維持不變', () {
      final input = build([jfif, dqt, sos]);
      expect(stripJpegMetadata(input), equals(input));
    });

    test('非 JPEG 原樣回傳', () {
      final png = Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 1, 2, 3]);
      expect(stripJpegMetadata(png), same(png));
    });

    test('區段長度損毀時原樣回傳，不會丟出例外', () {
      final broken = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE1, 0xFF, 0xFF, 1]);
      expect(stripJpegMetadata(broken), same(broken));
    });
  });
}
