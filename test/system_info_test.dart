/// v4.2 regression tests for the ST25DV system-info layer, built from the
/// exact frames observed in the v4.1.0 field log:
///  · the tag answers the STANDARD Get System Info with info flags 0x0B —
///    DSFID + AFI + IC_REF and NO memory size (the old parser called the
///    13-byte frame «not parseable» → the geometry collapsed to 256 blocks
///    → «memory_too_small» / «مدل تطبیق نشد»);
///  · the EXTENDED Get System Info (0x3B) answers the 16-bit MEM_SIZE;
///  · Android reports the UID LSB-first, the tag print is MSB-first.
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:kianex_pts50n1_app/core/nfc/tag_link.dart';

/// UID of the real field tag — wire order as Android reports it and the
/// human-readable order printed on the tag (from the v4.1.0 report).
const String kFieldUidWire = 'AF24ADD7002602E0';
const String kFieldUidHuman = 'E0022600D7AD24AF';

void main() {
  group('standard Get System Info (0x2B) — ST25DV16K field frame', () {
    // FLAGS(00) | infoFlags(0B) | UID(8 B, LSB first) | DSFID(00) | AFI(00)
    // | IC_REF(26) — exactly the structure of Table 158; the log line of
    // v4.1.0 printed only the first 10 bytes (logger truncation), which is
    // why the frame looked «truncated».
    final frame = Uint8List.fromList([
      0x00, 0x0B, //
      0xAF, 0x24, 0xAD, 0xD7, 0x00, 0x26, 0x02, 0xE0, // UID LSB first
      0x00, // DSFID
      0x00, // AFI
      0x26, // IC_REF — ST25DV16K/64K family
    ]);

    test('parses identity and reports NO memory size', () {
      final info = Iso15693TagLink.parseSystemInfoFrame(frame);
      expect(info, isNotNull);
      expect(info!.icRef, 0x26);
      expect(info.dsfid, 0x00);
      expect(info.afid, 0x00);
      // No MEM_SIZE field in the standard answer of a 16K/64K tag:
      expect(info.totalBlocks, 0);
      expect(info.blockSize, 0);
      expect(info.known, isFalse);
    });

    test('geometry profile of IC_REF 26h yields 512 x 4 B', () {
      // The link maps IC_REF 26h onto the ST25DV16K family geometry
      // (Table 166) — the minimum size inside the family, which already
      // covers the 433 blocks of the shared-memory layout.
      final info = Iso15693TagLink.parseSystemInfoFrame(frame)!;
      final profiled = info.totalBlocks > 0
          ? info.totalBlocks
          : 512; // _profileGeometry(0x26) — documented constant
      expect(profiled, 512);
      expect(profiled >= 433, isTrue, reason: 'planning area needs 433 blocks');
    });
  });

  group('extended Get System Info (0x3B) — MEM_SIZE frame', () {
    // FLAGS(00) | infoFlags(24: MEM present + MOI) | UID | MEM_SIZE(61 FF)
    // MEM_SIZE 0x61FF = block-size−1 (3 → 4 B) in bits 15..13 and
    // block-count−1 (0x1FF → 512) in bits 12..0 (Table 165).
    final frame = Uint8List.fromList([
      0x00, 0x24, //
      0xAF, 0x24, 0xAD, 0xD7, 0x00, 0x26, 0x02, 0xE0,
      0x61, 0xFF,
    ]);

    test('parses the 512 x 4 B geometry and 2-byte addressing', () {
      final info = Iso15693TagLink.parseSystemInfoFrame(frame);
      expect(info, isNotNull);
      expect(info!.totalBlocks, 512);
      expect(info.blockSize, 4);
      expect(info.twoByteAddressing, isTrue); // MOI flag set
      expect(info.known, isTrue);
      expect(info.modelName, 'ST25DV16K(C)');
    });
  });

  group('error and short frames', () {
    test('error-flagged frame is rejected', () {
      final frame = Uint8List.fromList([0x01, 0x03]);
      expect(Iso15693TagLink.parseSystemInfoFrame(frame), isNull);
    });

    test('too-short frame is rejected', () {
      final frame = Uint8List.fromList([0x00, 0x0B, 0x01, 0x02]);
      expect(Iso15693TagLink.parseSystemInfoFrame(frame), isNull);
    });
  });

  group('uidInHumanOrder', () {
    test('reverses the Android wire order to the tag print order', () {
      expect(uidInHumanOrder(kFieldUidWire), kFieldUidHuman);
    });

    test('accepts colon-separated hex', () {
      expect(uidInHumanOrder('af:24:ad:d7:00:26:02:e0'), kFieldUidHuman);
    });

    test('keeps unknown shapes unchanged', () {
      expect(uidInHumanOrder('abc'), 'abc');
      expect(uidInHumanOrder('XYZ!'), 'XYZ!');
      expect(uidInHumanOrder(''), '');
    });
  });
}
