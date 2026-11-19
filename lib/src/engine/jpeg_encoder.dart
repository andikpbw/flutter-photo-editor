import 'dart:math' as math;
import 'dart:typed_data';

/// Pure-Dart baseline DCT (SOF0, 4:4:4 YCbCr) JPEG encoder with zero external
/// dependencies, ensuring consistent cross-platform and Web/WASM export.
abstract final class JpegEncoder {
  static const List<int> _zigzag = <int>[
    0,
    1,
    5,
    6,
    14,
    15,
    27,
    28,
    2,
    4,
    7,
    13,
    16,
    26,
    29,
    42,
    3,
    8,
    12,
    17,
    25,
    30,
    41,
    43,
    9,
    11,
    18,
    24,
    31,
    40,
    44,
    53,
    10,
    19,
    23,
    32,
    39,
    45,
    52,
    54,
    20,
    22,
    33,
    38,
    46,
    51,
    55,
    60,
    21,
    34,
    37,
    47,
    50,
    56,
    59,
    61,
    35,
    36,
    48,
    49,
    57,
    58,
    62,
    63,
  ];

  // Standard ITU-T T.81 Annex K luminance quantization table.
  static const List<int> _baseYQuant = <int>[
    16,
    11,
    10,
    16,
    24,
    40,
    51,
    61,
    12,
    12,
    14,
    19,
    26,
    58,
    60,
    55,
    14,
    13,
    16,
    24,
    40,
    57,
    69,
    56,
    14,
    17,
    22,
    29,
    51,
    87,
    80,
    62,
    18,
    22,
    37,
    56,
    68,
    109,
    103,
    77,
    24,
    35,
    55,
    64,
    81,
    104,
    113,
    92,
    49,
    64,
    78,
    87,
    103,
    121,
    120,
    101,
    72,
    92,
    95,
    98,
    112,
    100,
    103,
    99,
  ];

  // Standard ITU-T T.81 Annex K chrominance quantization table.
  static const List<int> _baseCbCrQuant = <int>[
    17,
    18,
    24,
    47,
    99,
    99,
    99,
    99,
    18,
    21,
    26,
    66,
    99,
    99,
    99,
    99,
    24,
    26,
    56,
    99,
    99,
    99,
    99,
    99,
    47,
    66,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
    99,
  ];

  // Standard Annex K Huffman tables.
  static const List<int> _stdDcLumBits = <int>[
    0,
    1,
    5,
    1,
    1,
    1,
    1,
    1,
    1,
    0,
    0,
    0,
    0,
    0,
    0,
    0,
  ];
  static const List<int> _stdDcLumVals = <int>[
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
  ];

  static const List<int> _stdDcChrBits = <int>[
    0,
    3,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    1,
    0,
    0,
    0,
    0,
    0,
  ];
  static const List<int> _stdDcChrVals = <int>[
    0,
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
  ];

  static const List<int> _stdAcLumBits = <int>[
    0,
    2,
    1,
    3,
    3,
    2,
    4,
    3,
    5,
    5,
    4,
    4,
    0,
    0,
    1,
    125,
  ];
  static const List<int> _stdAcLumVals = <int>[
    0x01,
    0x02,
    0x03,
    0x00,
    0x04,
    0x11,
    0x05,
    0x12,
    0x21,
    0x31,
    0x41,
    0x06,
    0x13,
    0x51,
    0x61,
    0x07,
    0x22,
    0x71,
    0x14,
    0x32,
    0x81,
    0x91,
    0xa1,
    0x08,
    0x23,
    0x42,
    0xb1,
    0xc1,
    0x15,
    0x52,
    0xd1,
    0xf0,
    0x24,
    0x33,
    0x62,
    0x72,
    0x82,
    0x09,
    0x0a,
    0x16,
    0x17,
    0x18,
    0x19,
    0x1a,
    0x25,
    0x26,
    0x27,
    0x28,
    0x29,
    0x2a,
    0x34,
    0x35,
    0x36,
    0x37,
    0x38,
    0x39,
    0x3a,
    0x43,
    0x44,
    0x45,
    0x46,
    0x47,
    0x48,
    0x49,
    0x4a,
    0x53,
    0x54,
    0x55,
    0x56,
    0x57,
    0x58,
    0x59,
    0x5a,
    0x63,
    0x64,
    0x65,
    0x66,
    0x67,
    0x68,
    0x69,
    0x6a,
    0x73,
    0x74,
    0x75,
    0x76,
    0x77,
    0x78,
    0x79,
    0x7a,
    0x83,
    0x84,
    0x85,
    0x86,
    0x87,
    0x88,
    0x89,
    0x8a,
    0x92,
    0x93,
    0x94,
    0x95,
    0x96,
    0x97,
    0x98,
    0x99,
    0x9a,
    0xa2,
    0xa3,
    0xa4,
    0xa5,
    0xa6,
    0xa7,
    0xa8,
    0xa9,
    0xaa,
    0xb2,
    0xb3,
    0xb4,
    0xb5,
    0xb6,
    0xb7,
    0xb8,
    0xb9,
    0xba,
    0xc2,
    0xc3,
    0xc4,
    0xc5,
    0xc6,
    0xc7,
    0xc8,
    0xc9,
    0xca,
    0xd2,
    0xd3,
    0xd4,
    0xd5,
    0xd6,
    0xd7,
    0xd8,
    0xd9,
    0xda,
    0xe1,
    0xe2,
    0xe3,
    0xe4,
    0xe5,
    0xe6,
    0xe7,
    0xe8,
    0xe9,
    0xea,
    0xf1,
    0xf2,
    0xf3,
    0xf4,
    0xf5,
    0xf6,
    0xf7,
    0xf8,
    0xf9,
    0xfa,
  ];

  static const List<int> _stdAcChrBits = <int>[
    0,
    2,
    1,
    2,
    4,
    4,
    3,
    4,
    7,
    5,
    4,
    4,
    0,
    1,
    2,
    119,
  ];
  static const List<int> _stdAcChrVals = <int>[
    0x00,
    0x01,
    0x02,
    0x03,
    0x11,
    0x04,
    0x05,
    0x21,
    0x31,
    0x06,
    0x12,
    0x41,
    0x51,
    0x07,
    0x61,
    0x71,
    0x13,
    0x22,
    0x32,
    0x81,
    0x08,
    0x14,
    0x42,
    0x91,
    0xa1,
    0xb1,
    0xc1,
    0x09,
    0x23,
    0x33,
    0x52,
    0xf0,
    0x15,
    0x62,
    0x72,
    0xd1,
    0x0a,
    0x16,
    0x24,
    0x34,
    0xe1,
    0x25,
    0xf1,
    0x17,
    0x18,
    0x19,
    0x1a,
    0x26,
    0x27,
    0x28,
    0x29,
    0x2a,
    0x35,
    0x36,
    0x37,
    0x38,
    0x39,
    0x3a,
    0x43,
    0x44,
    0x45,
    0x46,
    0x47,
    0x48,
    0x49,
    0x4a,
    0x53,
    0x54,
    0x55,
    0x56,
    0x57,
    0x58,
    0x59,
    0x5a,
    0x63,
    0x64,
    0x65,
    0x66,
    0x67,
    0x68,
    0x69,
    0x6a,
    0x73,
    0x74,
    0x75,
    0x76,
    0x77,
    0x78,
    0x79,
    0x7a,
    0x82,
    0x83,
    0x84,
    0x85,
    0x86,
    0x87,
    0x88,
    0x89,
    0x8a,
    0x92,
    0x93,
    0x94,
    0x95,
    0x96,
    0x97,
    0x98,
    0x99,
    0x9a,
    0xa2,
    0xa3,
    0xa4,
    0xa5,
    0xa6,
    0xa7,
    0xa8,
    0xa9,
    0xaa,
    0xb2,
    0xb3,
    0xb4,
    0xb5,
    0xb6,
    0xb7,
    0xb8,
    0xb9,
    0xba,
    0xc2,
    0xc3,
    0xc4,
    0xc5,
    0xc6,
    0xc7,
    0xc8,
    0xc9,
    0xca,
    0xd2,
    0xd3,
    0xd4,
    0xd5,
    0xd6,
    0xd7,
    0xd8,
    0xd9,
    0xda,
    0xe2,
    0xe3,
    0xe4,
    0xe5,
    0xe6,
    0xe7,
    0xe8,
    0xe9,
    0xea,
    0xf2,
    0xf3,
    0xf4,
    0xf5,
    0xf6,
    0xf7,
    0xf8,
    0xf9,
    0xfa,
  ];

  // Precomputed AAN scale factors and cosine matrix for fast 8x8 FDCT.
  static final Float64List _cosTable = _buildCosTable();

  static Float64List _buildCosTable() {
    final table = Float64List(64);
    const factor = math.pi / 16.0;
    for (var u = 0; u < 8; u++) {
      final cu = u == 0 ? 1.0 / math.sqrt2 : 1.0;
      for (var x = 0; x < 8; x++) {
        table[u * 8 + x] = 0.5 * cu * math.cos((2 * x + 1) * u * factor);
      }
    }
    return table;
  }

  static final _HuffmanTable _dcLum = _HuffmanTable.build(
    _stdDcLumBits,
    _stdDcLumVals,
  );
  static final _HuffmanTable _dcChr = _HuffmanTable.build(
    _stdDcChrBits,
    _stdDcChrVals,
  );
  static final _HuffmanTable _acLum = _HuffmanTable.build(
    _stdAcLumBits,
    _stdAcLumVals,
  );
  static final _HuffmanTable _acChr = _HuffmanTable.build(
    _stdAcChrBits,
    _stdAcChrVals,
  );

  /// Encodes an uncompressed 32-bit RGBA pixel buffer [rgba] of dimensions
  /// `[width] x [height]` into a standard Baseline JPEG byte buffer.
  ///
  /// [quality] ranges from `1` (maximum compression) to `100` (highest quality).
  static Uint8List encodeRgba(
    Uint8List rgba,
    int width,
    int height, {
    int quality = 90,
  }) {
    if (width <= 0 || height <= 0) {
      throw ArgumentError('Image width and height must be positive.');
    }
    if (rgba.length < width * height * 4) {
      throw ArgumentError(
        'RGBA buffer length (${rgba.length}) is smaller than '
        'width * height * 4 (${width * height * 4}).',
      );
    }

    final q = quality.clamp(1, 100);
    final sf = q < 50 ? (5000 / q).floor() : 200 - q * 2;
    final yTable = Uint8List(64);
    final uvTable = Uint8List(64);
    for (var i = 0; i < 64; i++) {
      yTable[_zigzag[i]] = ((_baseYQuant[i] * sf + 50) ~/ 100).clamp(1, 255);
      uvTable[_zigzag[i]] = ((_baseCbCrQuant[i] * sf + 50) ~/ 100).clamp(
        1,
        255,
      );
    }

    // Quantization denominators in natural raster 8x8 order for fast division.
    final yDiv = Float64List(64);
    final uvDiv = Float64List(64);
    for (var i = 0; i < 64; i++) {
      yDiv[i] = yTable[_zigzag[i]].toDouble();
      uvDiv[i] = uvTable[_zigzag[i]].toDouble();
    }

    final writer = _JpegByteWriter();

    // SOI (Start of Image)
    writer.writeMarker(0xFFD8);

    // APP0 (JFIF header)
    writer.writeMarker(0xFFE0);
    writer.writeUint16(16);
    writer.writeBytes(const <int>[0x4A, 0x46, 0x49, 0x46, 0x00]); // JFIF\0
    writer.writeByte(1); // major
    writer.writeByte(1); // minor
    writer.writeByte(0); // density units
    writer.writeUint16(1); // Xdensity
    writer.writeUint16(1); // Ydensity
    writer.writeByte(0); // thumb width
    writer.writeByte(0); // thumb height

    // DQT (Quantization Tables)
    _writeDqt(writer, 0, yTable);
    _writeDqt(writer, 1, uvTable);

    // SOF0 (Baseline DCT, 8-bit precision, 3 components 4:4:4)
    writer.writeMarker(0xFFC0);
    writer.writeUint16(17);
    writer.writeByte(8);
    writer.writeUint16(height);
    writer.writeUint16(width);
    writer.writeByte(3);
    // Component 1: Y
    writer.writeByte(1);
    writer.writeByte(0x11);
    writer.writeByte(0);
    // Component 2: Cb
    writer.writeByte(2);
    writer.writeByte(0x11);
    writer.writeByte(1);
    // Component 3: Cr
    writer.writeByte(3);
    writer.writeByte(0x11);
    writer.writeByte(1);

    // DHT (Huffman Tables)
    _writeDht(writer, 0x00, _stdDcLumBits, _stdDcLumVals);
    _writeDht(writer, 0x10, _stdAcLumBits, _stdAcLumVals);
    _writeDht(writer, 0x01, _stdDcChrBits, _stdDcChrVals);
    _writeDht(writer, 0x11, _stdAcChrBits, _stdAcChrVals);

    // SOS (Start of Scan)
    writer.writeMarker(0xFFDA);
    writer.writeUint16(12);
    writer.writeByte(3);
    writer.writeByte(1);
    writer.writeByte(0x00);
    writer.writeByte(2);
    writer.writeByte(0x11);
    writer.writeByte(3);
    writer.writeByte(0x11);
    writer.writeByte(0);
    writer.writeByte(63);
    writer.writeByte(0);

    // Entropy-coded MCU blocks (8x8 blocks in 4:4:4 sampling).
    final yBlock = Float64List(64);
    final cbBlock = Float64List(64);
    final crBlock = Float64List(64);
    final tempBlock = Float64List(64);
    final dctBlock = Float64List(64);
    final zzQuant = Int32List(64);

    var dcY = 0;
    var dcCb = 0;
    var dcCr = 0;

    for (var by = 0; by < height; by += 8) {
      for (var bx = 0; bx < width; bx += 8) {
        for (var dy = 0; dy < 8; dy++) {
          final py = (by + dy) < height ? (by + dy) : height - 1;
          final rowOffset = py * width * 4;
          final blockRow = dy * 8;
          for (var dx = 0; dx < 8; dx++) {
            final px = (bx + dx) < width ? (bx + dx) : width - 1;
            final p = rowOffset + px * 4;
            final r = rgba[p];
            final g = rgba[p + 1];
            final b = rgba[p + 2];

            // Level-shifted YCbCr in [-128, 127].
            yBlock[blockRow + dx] = 0.299 * r + 0.587 * g + 0.114 * b - 128.0;
            cbBlock[blockRow + dx] = -0.168736 * r - 0.331264 * g + 0.5 * b;
            crBlock[blockRow + dx] = 0.5 * r - 0.418688 * g - 0.081312 * b;
          }
        }

        dcY = _encodeBlock(
          writer,
          yBlock,
          tempBlock,
          dctBlock,
          zzQuant,
          yDiv,
          dcY,
          _dcLum,
          _acLum,
        );
        dcCb = _encodeBlock(
          writer,
          cbBlock,
          tempBlock,
          dctBlock,
          zzQuant,
          uvDiv,
          dcCb,
          _dcChr,
          _acChr,
        );
        dcCr = _encodeBlock(
          writer,
          crBlock,
          tempBlock,
          dctBlock,
          zzQuant,
          uvDiv,
          dcCr,
          _dcChr,
          _acChr,
        );
      }
    }

    writer.flushBits();

    // EOI (End of Image)
    writer.writeMarker(0xFFD9);
    return writer.toBytes();
  }

  static void _writeDqt(_JpegByteWriter writer, int tableId, Uint8List table) {
    writer.writeMarker(0xFFDB);
    writer.writeUint16(67);
    writer.writeByte(tableId & 0x0F);
    writer.writeBytes(table);
  }

  static void _writeDht(
    _JpegByteWriter writer,
    int tableInfo,
    List<int> bits,
    List<int> vals,
  ) {
    writer.writeMarker(0xFFC4);
    writer.writeUint16(2 + 1 + 16 + vals.length);
    writer.writeByte(tableInfo);
    writer.writeBytes(bits);
    writer.writeBytes(vals);
  }

  static int _encodeBlock(
    _JpegByteWriter writer,
    Float64List input,
    Float64List temp,
    Float64List dct,
    Int32List zzQuant,
    Float64List quantDiv,
    int prevDc,
    _HuffmanTable dcTable,
    _HuffmanTable acTable,
  ) {
    // Separable 2D FDCT: 1D across rows -> temp, then 1D across columns -> dct.
    for (var y = 0; y < 8; y++) {
      final row = y * 8;
      for (var u = 0; u < 8; u++) {
        final cRow = u * 8;
        var sum = 0.0;
        for (var x = 0; x < 8; x++) {
          sum += input[row + x] * _cosTable[cRow + x];
        }
        temp[row + u] = sum;
      }
    }
    for (var u = 0; u < 8; u++) {
      for (var v = 0; v < 8; v++) {
        final cRow = v * 8;
        var sum = 0.0;
        for (var y = 0; y < 8; y++) {
          sum += temp[y * 8 + u] * _cosTable[cRow + y];
        }
        dct[v * 8 + u] = sum;
      }
    }

    // Quantize & reorder to zigzag order.
    for (var i = 0; i < 64; i++) {
      zzQuant[_zigzag[i]] = (dct[i] / quantDiv[i]).round();
    }

    // Encode DC difference (Baseline 8-bit JPEG DC diff category is 0..11).
    final dc = zzQuant[0];
    final diff = (dc - prevDc).clamp(-2047, 2047);
    if (diff == 0) {
      writer.writeBits(dcTable.codes[0], dcTable.sizes[0]);
    } else {
      final cat = _bitCategory(diff);
      writer.writeBits(dcTable.codes[cat], dcTable.sizes[cat]);
      writer.writeBits(_encodeSignedValue(diff, cat), cat);
    }

    // Encode AC coefficients with run-length encoding (AC category is 1..10).
    var lastNonZero = 63;
    while (lastNonZero > 0 && zzQuant[lastNonZero] == 0) {
      lastNonZero--;
    }

    if (lastNonZero == 0) {
      // EOB (0x00)
      writer.writeBits(acTable.codes[0x00], acTable.sizes[0x00]);
      return dc;
    }

    var idx = 1;
    while (idx <= lastNonZero) {
      var zeroRun = 0;
      while (zzQuant[idx] == 0 && idx <= lastNonZero) {
        zeroRun++;
        idx++;
      }
      while (zeroRun >= 16) {
        // ZRL (0xF0)
        writer.writeBits(acTable.codes[0xF0], acTable.sizes[0xF0]);
        zeroRun -= 16;
      }
      final val = zzQuant[idx].clamp(-1023, 1023);
      final cat = _bitCategory(val);
      final symbol = (zeroRun << 4) | cat;
      writer.writeBits(acTable.codes[symbol], acTable.sizes[symbol]);
      writer.writeBits(_encodeSignedValue(val, cat), cat);
      idx++;
    }

    if (lastNonZero != 63) {
      writer.writeBits(acTable.codes[0x00], acTable.sizes[0x00]);
    }

    return dc;
  }

  static int _bitCategory(int value) {
    var absVal = value < 0 ? -value : value;
    var cat = 0;
    while (absVal > 0) {
      absVal >>= 1;
      cat++;
    }
    return cat;
  }

  static int _encodeSignedValue(int value, int category) {
    if (value >= 0) {
      return value;
    }
    return value + ((1 << category) - 1);
  }
}

class _HuffmanTable {
  _HuffmanTable(this.codes, this.sizes);

  factory _HuffmanTable.build(List<int> bits, List<int> vals) {
    final codes = Int32List(256);
    final sizes = Uint8List(256);
    var code = 0;
    var valIdx = 0;
    for (var length = 1; length <= 16; length++) {
      final count = bits[length - 1];
      for (var i = 0; i < count; i++) {
        final sym = vals[valIdx++];
        codes[sym] = code;
        sizes[sym] = length;
        code++;
      }
      code <<= 1;
    }
    return _HuffmanTable(codes, sizes);
  }

  final Int32List codes;
  final Uint8List sizes;
}

class _JpegByteWriter {
  final BytesBuilder _buffer = BytesBuilder(copy: false);
  int _bitBuffer = 0;
  int _bitCount = 0;

  void writeByte(int b) => _buffer.addByte(b & 0xFF);

  void writeBytes(List<int> bytes) => _buffer.add(bytes);

  void writeUint16(int value) {
    _buffer.addByte((value >> 8) & 0xFF);
    _buffer.addByte(value & 0xFF);
  }

  void writeMarker(int marker) => writeUint16(marker);

  void writeBits(int code, int size) {
    _bitBuffer = (_bitBuffer << size) | (code & ((1 << size) - 1));
    _bitCount += size;
    while (_bitCount >= 8) {
      _bitCount -= 8;
      final byte = (_bitBuffer >> _bitCount) & 0xFF;
      _buffer.addByte(byte);
      if (byte == 0xFF) {
        // JPEG byte stuffing prevents accidental marker sequences in entropy data.
        _buffer.addByte(0x00);
      }
    }
  }

  void flushBits() {
    if (_bitCount > 0) {
      final pad = 8 - _bitCount;
      writeBits((1 << pad) - 1, pad);
    }
  }

  Uint8List toBytes() => _buffer.toBytes();
}
