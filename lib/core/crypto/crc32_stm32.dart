/// CRC-32 with STM32G0 hardware defaults = CRC-32/MPEG-2
/// (polynomial 0x04C11DB7, init 0xFFFFFFFF, no reflection, no final XOR). [§4.11]
library;

/// Computes the CRC over [bytes], byte-by-byte from the lowest block
/// to the highest and Byte_0..Byte_3 within each block.
int crc32Stm32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final b in bytes) {
    crc ^= (b & 0xFF) << 24;
    for (var bit = 0; bit < 8; bit++) {
      if (crc & 0x80000000 != 0) {
        crc = ((crc << 1) ^ 0x04C11DB7) & 0xFFFFFFFF;
      } else {
        crc = (crc << 1) & 0xFFFFFFFF;
      }
    }
  }
  return crc;
}

String crc32Hex(int crc) =>
    '0x${crc.toRadixString(16).toUpperCase().padLeft(8, '0')}';

/// True when all three shared test vectors (SOT table 4-8) match.
/// TV-01 "123456789" -> 0x0376E6E7, TV-02 0x00..0x0F -> 0xA97AFF4D,
/// TV-03 0x00..0x03  -> 0x6B6DC92A.
bool crcSelfTest() {
  final tv01 = '123456789'.codeUnits;
  final tv02 = List<int>.generate(16, (i) => i);
  const tv03 = [0, 1, 2, 3];
  return crc32Stm32(tv01) == 0x0376E6E7 &&
      crc32Stm32(tv02) == 0xA97AFF4D &&
      crc32Stm32(tv03) == 0x6B6DC92A;
}
