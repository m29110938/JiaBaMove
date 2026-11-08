import 'dart:typed_data';

/// 移除 JPEG 中可能含有個資的中繼資料區段，影像內容不變。
///
/// 移除：APP1 (EXIF：GPS 位置、拍攝時間、裝置型號；XMP)、APP13 (IPTC)、COM (註解)。
/// 保留：其餘區段 (含 APP0 JFIF、APP2 ICC 色彩描述檔) 與影像資料。
///
/// 非 JPEG 或結構無法解析時，原樣回傳。
Uint8List stripJpegMetadata(Uint8List bytes) {
  if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
    return bytes;
  }

  final out = BytesBuilder(copy: false)..add(const [0xFF, 0xD8]);
  var i = 2;

  while (i + 1 < bytes.length) {
    if (bytes[i] != 0xFF) return bytes; // 結構異常
    final marker = bytes[i + 1];

    // 填充位元組
    if (marker == 0xFF) {
      i++;
      continue;
    }

    // SOS：之後為壓縮影像資料，直接全部保留
    if (marker == 0xDA) {
      out.add(Uint8List.sublistView(bytes, i));
      return out.takeBytes();
    }

    // EOI
    if (marker == 0xD9) {
      out.add(const [0xFF, 0xD9]);
      return out.takeBytes();
    }

    // 無長度欄位的標記 (RSTn、TEM)
    if ((marker >= 0xD0 && marker <= 0xD7) || marker == 0x01) {
      out.add(Uint8List.sublistView(bytes, i, i + 2));
      i += 2;
      continue;
    }

    if (i + 3 >= bytes.length) return bytes;
    final length = (bytes[i + 2] << 8) | bytes[i + 3];
    final end = i + 2 + length;
    if (length < 2 || end > bytes.length) return bytes;

    final isMetadata = marker == 0xE1 || marker == 0xED || marker == 0xFE;
    if (!isMetadata) {
      out.add(Uint8List.sublistView(bytes, i, end));
    }
    i = end;
  }

  return bytes;
}
