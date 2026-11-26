import 'package:flutter_test/flutter_test.dart';

import 'package:kianex_pts50n1_app/core/crypto/crc32_stm32.dart';

/// Shared CRC test vectors of the Source of Truth, table 4-8.
void main() {
  test('TV-01: ASCII "123456789" -> 0x0376E6E7', () {
    expect(crc32Stm32('123456789'.codeUnits), 0x0376E6E7);
  });

  test('TV-02: bytes 0x00..0x0F -> 0xA97AFF4D', () {
    expect(crc32Stm32(List<int>.generate(16, (i) => i)), 0xA97AFF4D);
  });

  test('TV-03: one block 0x00..0x03 -> 0x6B6DC92A', () {
    expect(crc32Stm32([0, 1, 2, 3]), 0x6B6DC92A);
  });

  test('self test passes', () {
    expect(crcSelfTest(), isTrue);
  });

  test('hex formatting', () {
    expect(crc32Hex(0x0376E6E7), '0x0376E6E7');
  });
}
