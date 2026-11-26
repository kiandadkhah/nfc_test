/// Byte-level link to the ST25DV16KC tag — NFC Forum Type 5 (ISO/IEC
/// 15693), 512 × 4-byte blocks, 2048 bytes of user memory.
///
/// Command layer — ST25DV datasheet (DS13921) ISO 15693 command set:
///   · Read Single Block 0x20, Write Single Block 0x21,
///     Read Multiple Blocks 0x23, Get System Info 0x2B;
///   · tags with more than 256 blocks (ST25DV16K/64K) are addressed with
///     the PROTOCOL EXTENSION flag (bit 3, 0x08) — the block number
///     becomes 16-bit while the command codes stay the same. The earlier
///     builds mistakenly used a fictitious "extended command set"
///     (0x30/0x31/0x33/0x3B): those codes are the mailbox commands of the
///     datasheet, so every read was rejected with ISO error 0x03
///     («option not supported») — the root cause of the v4.0.x field
///     failures, fixed here;
///   · tags with up to 256 blocks (ST25DV04K, ST25TV…) use the standard
///     1-byte block numbers (same command codes, PE flag = 0).
/// Because of this, the app works with any ISO 15693 Type 5 tag that has
/// enough memory for the shared-memory layout, not only ST25DV16KC.
///
/// Request flag bytes (ISO 15693-3): bit1 sub-carrier 0x01, bit2 data rate
/// 0x02, bit3 inventory 0x04, bit4 protocol extension 0x08, bit5 select
/// 0x10, bit6 address 0x20, bit7 option 0x40, bit8 RFU 0x80. The link
/// always talks to a single tag in the field, so requests are
/// non-addressed (no UID byte).
library;

import 'dart:typed_data';

import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';

/// Abstract transport so the protocol engine can be unit-tested against a
/// fake tag image.
abstract class TagLink {
  /// True when the underlying hardware/session is alive.
  bool get isOpen;

  /// Tag identification reported by the discovery layer (diagnostics only).
  String get tagUid;

  /// Memory geometry detected at open time (0 = unknown).
  int get totalBlocks;
  int get blockSize;

  /// IC_REF reported by Get System Info (0 = unknown). Log value only —
  /// the model decision uses the memory size, not a hard-coded IC list.
  int get icRef;

  Future<Uint8List> readBlock(int block);
  Future<List<Uint8List>> readBlockRange(int first, int last);
  Future<void> writeBlock(int block, Uint8List b0to3);
  Future<void> close();
}

class TagLinkException implements Exception {
  const TagLinkException(this.message, {this.errorCode});
  final String message;
  final int? errorCode;

  @override
  String toString() =>
      'TagLinkException($message${errorCode == null ? '' : ', code=0x${errorCode!.toRadixString(16)}'})';
}

/// Human-readable meaning of the ISO 15693-3 error codes (datasheet
/// table «Error codes») — used in the log so field reports are
/// self-explanatory.
String iso15693ErrorText(int code) => switch (code) {
      0x01 => 'command not supported',
      0x02 => 'command not recognised',
      0x03 => 'option not supported',
      0x0F => 'unknown error (tag busy or RF condition)',
      0x10 => 'block not available',
      0x11 => 'block already locked',
      0x12 => 'block locked, unreadable',
      0x13 => 'block not successfully written/locked',
      0x14 => 'block not successfully written',
      _ => 'error 0x${code.toRadixString(16)}',
    };

// ISO 15693-3 request flag bits (ST25DV datasheet tables 94/95):
const int _flagDataRateHigh = 0x02;
const int _flagProtocolExtension = 0x08;

// Command codes — the SAME codes serve standard and extended addressing;
// the protocol-extension flag selects the 16-bit block number.
// CAUTION: 0x2A is Lock DSFID — a wrong multi-read code would address a
// destructive/irrelevant command instead of reading (field-log lesson).
const int _cmdReadSingleBlock = 0x20;
const int _cmdWriteSingleBlock = 0x21;
const int _cmdReadMultipleBlocks = 0x23;
const int _cmdGetSystemInfo = 0x2B;

/// ISO 15693 response flag: bit 0 = error.
const int _respErrorFlag = 0x01;

/// Tag geometry + identity parsed from (Extended) Get System Info.
class TagSystemInfo {
  const TagSystemInfo({
    required this.totalBlocks,
    required this.blockSize,
    required this.icRef,
    required this.dsfid,
    required this.afid,
    required this.twoByteAddressing,
    this.raw = const [],
  });

  final int totalBlocks;
  final int blockSize;
  final int icRef;
  final int dsfid;
  final int afid;

  /// True when the tag uses 2-byte block addressing (MOI / geometry rule).
  final bool twoByteAddressing;
  final List<int> raw;

  bool get known => totalBlocks > 0 && blockSize > 0;

  /// Human-readable family name used by diagnostics; memory size decides,
  /// not a hard-coded IC_REF table.
  String get modelName {
    if (!known) return '';
    final bytes = totalBlocks * blockSize;
    if (bytes == 512) return 'ST25DV04K/ST25TV512';
    if (bytes == 2048) return 'ST25DV16K(C)';
    if (bytes == 8192) return 'ST25DV64K(C)';
    return 'Type-5 · $bytes B';
  }
}

/// CRC-16 used by ISO 15693 (poly 0x8408 reflected, init 0xFFFF, final
/// XOR 0xFFFF) — only used to auto-detect whether the platform stack
/// already stripped the CRC from a response.
int iso15693Crc16(List<int> bytes) {
  var crc = 0xFFFF;
  for (final b in bytes) {
    crc ^= b;
    for (var i = 0; i < 8; i++) {
      crc = (crc >> 1) ^ ((crc & 1) * 0x8408);
    }
  }
  return crc ^ 0xFFFF;
}

class Iso15693TagLink implements TagLink {
  Iso15693TagLink._(this.tag, this._info, {void Function(String event)? onEvent})
      : _onEvent = onEvent;

  /// The polled tag metadata (id / dsfId available for diagnostics).
  final NFCTag tag;
  TagSystemInfo _info;
  final void Function(String event)? _onEvent;

  /// Set when the tag rejected the protocol-extension flag — the link
  /// falls back to the standard 1-byte addressing (small Type 5 models).
  bool _forceStandard = false;

  bool _open = false;

  @override
  bool get isOpen => _open;
  @override
  String get tagUid => tag.id;
  @override
  int get totalBlocks => _info.totalBlocks;
  @override
  int get blockSize => _info.blockSize;
  @override
  int get icRef => _info.icRef;

  void _event(String msg) => _onEvent?.call(msg);

  /// Extended addressing (16-bit block number) for tags larger than 256
  /// blocks (ST25DV16K/64K) — unless the tag rejected the PE flag.
  bool get _useExtended =>
      !_forceStandard && (_info.known ? _info.totalBlocks > 256 : true);

  /// Polls for an ISO 15693 tag and opens the session. Reads the tag
  /// system info (Get System Info, extended first) so the addressing mode
  /// and memory geometry match the actual tag model, then verifies the
  /// addressing mode with a block-0 probe.
  /// [timeout] bounds the whole poll; returns null when the user never
  /// presented a compatible tag. Throws [TagLinkException]('nfc_disabled')
  /// when the phone NFC adapter is off or absent.
  static Future<Iso15693TagLink?> open({
    Duration timeout = const Duration(seconds: 45),
    String iosAlertMessage = 'برای شناسایی رله، گوشی را نزدیک تگ NFC نگه دارید',
    void Function(String event)? onEvent,
  }) async {
    try {
      final availability = await FlutterNfcKit.nfcAvailability;
      if (availability != NFCAvailability.available) {
        onEvent?.call('open: NFC adapter not available ($availability)');
        throw const TagLinkException('nfc_disabled');
      }
    } on TagLinkException {
      rethrow;
    } catch (_) {
      // availability check itself unsupported — continue with the poll
    }
    NFCTag? polled;
    try {
      polled = await FlutterNfcKit.poll(
        timeout: timeout,
        androidCheckNDEF: false, // raw block access only — skip NDEF parse
        iosAlertMessage: iosAlertMessage,
      );
    } catch (_) {
      // poll timed out or was cancelled by the platform
      return null;
    }
    if (polled.type != NFCTagType.iso15693) {
      try {
        await FlutterNfcKit.finish(
          iosErrorMessage: 'برچسب سازگار نیست (NFC Type 5 / ISO 15693 لازم است)',
        );
      } catch (_) {
        // session already closed by the platform
      }
      onEvent?.call('poll: tag type ${polled.type} is not ISO 15693');
      throw const TagLinkException('not_iso15693');
    }
    final info = await _readSystemInfo(polled, onEvent);
    final link = Iso15693TagLink._(polled, info, onEvent: onEvent);
    link._open = true;

    // Addressing self-check (field hardening): a tag that rejects the
    // protocol-extension flag answers ISO error 0x01/0x02/0x03, and some
    // phone/tag pairs answer a PE-flagged frame with plain silence (the
    // v4.0.1 log — «Communication error», no error code). Both cases fall
    // back to the standard 1-byte addressing; any other failure (busy /
    // RF condition, already retried once by the link) propagates.
    if (link._useExtended) {
      try {
        await link.readBlock(0);
      } on TagLinkException catch (e) {
        final reject = e.errorCode == null ||
            e.errorCode == 0x01 ||
            e.errorCode == 0x02 ||
            e.errorCode == 0x03;
        if (!reject) {
          rethrow; // busy / RF condition — the caller retry policy handles it
        }
        onEvent?.call(
            'open: extended addressing rejected '
            '(${e.errorCode == null ? 'no response (silent PE frame)' : iso15693ErrorText(e.errorCode!)}) '
            '— switching to standard addressing');
        link._forceStandard = true;
        if (link._info.totalBlocks > 256) {
          // Without 16-bit addressing only the first 256 blocks are
          // reachable; the shared-memory layout needs 432 — the memory
          // check in the protocol will report it honestly.
          link._info = TagSystemInfo(
            totalBlocks: link._info.totalBlocks.clamp(0, 256),
            blockSize: link._info.blockSize,
            icRef: link._info.icRef,
            dsfid: link._info.dsfid,
            afid: link._info.afid,
            twoByteAddressing: false,
          );
        }
        await link.readBlock(0); // must succeed now, else the session fails
      }
    }

    onEvent?.call(
        'open: uid=${polled.id} model=${link._info.modelName} blocks=${link._info.totalBlocks} '
        'blockSize=${link._info.blockSize} icRef=0x${link._info.icRef.toRadixString(16)} '
        'extended=${link._useExtended}');
    return link;
  }

  /// Best-effort system info read. Any failure falls back to the PST50R1
  /// target geometry (512 × 4 B) so the protocol can still proceed; every
  /// anomaly is reported through [onEvent].
  ///
  /// Order: the STANDARD Get System Info is tried FIRST — the ST25 family
  /// already reports the memory size as 3 bytes (16-bit block count +
  /// block size) in the standard response, and the v4.0.1 field log showed
  /// the PE-flagged variant getting no answer at all on some phone/tag
  /// combinations (silence ⇒ PlatformException). The PE variant stays as
  /// the fallback for tags that implement ISO 15693-3:2009 amendment only.
  static Future<TagSystemInfo> _readSystemInfo(
      NFCTag tag, void Function(String event)? onEvent) async {
    const fallback = TagSystemInfo(
      totalBlocks: 512,
      blockSize: 4,
      icRef: 0,
      dsfid: 0,
      afid: 0,
      twoByteAddressing: true,
    );
    // Standard Get System Info — the command carries NO request parameters
    // (the earlier 0x3B+0x1F frame was a malformed non-existent command and
    // made the tag go silent).
    try {
      final resp = await FlutterNfcKit.transceive<Uint8List>(
        Uint8List.fromList([_flagDataRateHigh, _cmdGetSystemInfo]),
      );
      final parsed = _parseSystemInfo(resp);
      if (parsed != null) return parsed;
      onEvent?.call('std get system info: response not parseable '
          '(${_hex(resp)}) — trying protocol-extension variant');
    } catch (e) {
      onEvent?.call('std get system info failed: $e');
    }
    // Small pause so the RF layer settles before the second attempt.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    // PE-flagged variant (ISO 15693-3:2009 amendment — 16-bit MEM_SIZE).
    try {
      final resp = await FlutterNfcKit.transceive<Uint8List>(
        Uint8List.fromList([_flagDataRateHigh | _flagProtocolExtension, _cmdGetSystemInfo]),
      );
      final parsed = _parseSystemInfo(resp);
      if (parsed != null) return parsed;
      onEvent?.call('ext get system info: response not parseable (${_hex(resp)})');
    } catch (e) {
      onEvent?.call('ext get system info failed: $e');
    }
    onEvent?.call('system info unknown — using target geometry 512x4');
    return fallback;
  }

  /// Parses a Get System Info response body. Frame layout per ISO 15693-3 /
  /// ST25DV datasheet: FLAGS | info flags | UID (8 B, LSB first) | AFI? |
  /// DSFID? | MEM_SIZE? | IC_REF?; the tag reports «value − 1» in both
  /// MEM_SIZE fields.
  ///
  /// The MEM_SIZE field layout differs between families, so BOTH known
  /// layouts are tried under the same plausibility check:
  ///   A) 16-bit block count (LSB first) + 1-byte block size — the ST25
  ///      family layout (ST25DV/ST25TV datasheets);
  ///   B) 1-byte block size + 1-byte block count — the classic ISO layout
  ///      of small Type 5 tags.
  /// Returns null when no layout yields a plausible geometry — the caller
  /// then tries the next request variant.
  static TagSystemInfo? _parseSystemInfo(Uint8List resp) {
    final body = _stripCrcIfPresent(resp);
    if (body.length < 11) return null; // flags + infoFlags + UID minimum
    if ((body[0] & _respErrorFlag) != 0) return null;
    final infoFlags = body[1];
    var i = 10; // after FLAGS + infoFlags + UID
    var dsfid = 0;
    var afid = 0;
    var blocks = 0;
    var blockSize = 0;
    var icRef = 0;
    // Response body order: AFI, DSFID, memory size, IC_REF. Both AFI and
    // DSFID are single bytes, so their order cannot shift the offsets.
    if ((infoFlags & 0x02) != 0) {
      if (body.length < i + 1) return null;
      afid = body[i];
      i += 1;
    }
    if ((infoFlags & 0x01) != 0) {
      if (body.length < i + 1) return null;
      dsfid = body[i];
      i += 1;
    }
    if ((infoFlags & 0x04) != 0) {
      if (body.length < i + 2) return null;
      var parsed = false;
      if (body.length >= i + 3) {
        // Layout A — 16-bit block count first (ST25 family, 3-byte MEM_SIZE).
        final aBlocks = ((body[i + 1] << 8) | body[i]) + 1;
        final aSize = body[i + 2] + 1;
        if (aSize >= 1 && aSize <= 32 && aBlocks >= 1 && aBlocks <= 4096) {
          blocks = aBlocks;
          blockSize = aSize;
          i += 3;
          parsed = true;
        }
      }
      if (!parsed) {
        // Layout B — block size first, 8-bit block count (classic ISO).
        blockSize = body[i] + 1;
        blocks = body[i + 1] + 1;
        i += 2;
      }
    }
    if ((infoFlags & 0x08) != 0) {
      if (body.length < i + 1) return null;
      icRef = body[i];
      i += 1;
    }
    if (blockSize <= 0 || blockSize > 32 || blocks <= 0 || blocks > 4096) {
      return null;
    }
    // MOI flag (bit 4) mirrors the geometry rule: > 256 blocks ⇒ 2-byte
    // block addressing. The addressing decision itself always uses the
    // geometry, not the flag byte.
    return TagSystemInfo(
      totalBlocks: blocks,
      blockSize: blockSize,
      icRef: icRef,
      dsfid: dsfid,
      afid: afid,
      twoByteAddressing: blocks > 256,
      raw: body,
    );
  }

  /// Returns [resp] without the trailing CRC16 when the platform stack did
  /// not strip it (detected via the ISO 15693 CRC over the prefix).
  static Uint8List _stripCrcIfPresent(Uint8List resp) {
    if (resp.length >= 3) {
      final crc = iso15693Crc16(resp.sublist(0, resp.length - 2));
      final last = (resp[resp.length - 2] << 8) | resp[resp.length - 1];
      final lastLe = (resp[resp.length - 1] << 8) | resp[resp.length - 2];
      if (crc == last || crc == lastLe) {
        return Uint8List.sublistView(resp, 0, resp.length - 2);
      }
    }
    return resp;
  }

  // ------------------------------------------------------------------
  // Frame helpers
  // ------------------------------------------------------------------

  /// T5T addressing: extended mode → 2-byte block number (LSB first);
  /// standard mode → 1-byte block number.
  List<int> _addr(int block) => _useExtended
      ? [block & 0xFF, (block >> 8) & 0xFF]
      : [block & 0xFF];

  int get _baseFlags => _useExtended ? _flagProtocolExtension : 0x00;

  /// Sends one frame and returns the response body (CRC auto-stripped).
  /// Platform IO errors are normalized into [TagLinkException] so the
  /// retry policy and the protocol engine see a uniform error type.
  Future<Uint8List> _transceive(List<int> frame, String what) async {
    Uint8List resp;
    try {
      resp = await FlutterNfcKit.transceive<Uint8List>(
        Uint8List.fromList(frame),
      );
    } catch (e) {
      // RF field lost / I/O error — mapped to a link exception with no
      // error code (treated as transient by the retry policy).
      _event('tx $what failed: $e');
      throw TagLinkException('io_${what}_error:$e');
    }
    _event('tx $what: ${_hex(frame)} -> ${_hex(resp)}');
    return resp;
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).take(10).join(' ');

  Future<Uint8List> _respBody(List<int> frame, String what) async {
    final resp = await _transceive(frame, what);
    final body = _stripCrcIfPresent(resp);
    if (body.isEmpty) {
      throw TagLinkException('empty_${what}_response');
    }
    if ((body[0] & _respErrorFlag) != 0) {
      final code = body.length > 1 ? body[1] : null;
      if (code != null) {
        _event('$what: tag rejected — ${iso15693ErrorText(code)}');
      }
      throw TagLinkException('error_${what}_response', errorCode: code);
    }
    return body;
  }

  // ------------------------------------------------------------------
  // Block operations
  // ------------------------------------------------------------------

  @override
  Future<Uint8List> readBlock(int block) async {
    final body = await _retry(() => _respBody(
          [_baseFlags | _flagDataRateHigh, _cmdReadSingleBlock, ..._addr(block)],
          'read[$block]',
        ));
    if (body.length < 5) {
      throw const TagLinkException('short_read_response');
    }
    return Uint8List.fromList(body.sublist(1, 5)); // Byte_0..Byte_3
  }

  /// Reads [first]..[last] (inclusive) with Read Multiple Blocks (0x2A)
  /// in chunks. The block count stays a single byte in both addressing
  /// modes (values 00–FF mean 1–256 blocks). When a chunk crosses a tag
  /// memory-area boundary the tag answers with an error (code 10h) — the
  /// chunk is then split recursively down to single-block reads, so any
  /// factory area configuration works.
  @override
  Future<List<Uint8List>> readBlockRange(int first, int last) async {
    final out = <Uint8List>[];
    const chunk = 32;
    var b = first;
    while (b <= last) {
      var end = (b + chunk - 1) > last ? last : (b + chunk - 1);
      var ok = false;
      while (!ok) {
        try {
          final count = end - b + 1;
          final frame = [
            _baseFlags | _flagDataRateHigh,
            _cmdReadMultipleBlocks,
            ..._addr(b),
            (count - 1) & 0xFF,
          ];
          final body = await _respBody(frame, 'readMulti[$b..$end]');
          if (body.length < 1 + count * 4) {
            throw const TagLinkException('short_readmulti_response');
          }
          for (var i = 0; i < count; i++) {
            out.add(Uint8List.fromList(body.sublist(1 + i * 4, 5 + i * 4)));
          }
          ok = true;
        } on TagLinkException catch (e) {
          if (end > b) {
            // Split the chunk and retry — an area boundary or a busy I²C
            // window may sit inside the range.
            _event('readBlockRange: chunk [$b..$end] failed (${e.message}); splitting');
            end = b + ((end - b + 1) ~/ 2) - 1;
          } else {
            rethrow; // single block already failing — real error
          }
        }
      }
      b = end + 1;
    }
    return out;
  }

  @override
  Future<void> writeBlock(int block, Uint8List b0to3) async {
    final data = List<int>.generate(4, (i) => i < b0to3.length ? b0to3[i] : 0);
    // Plain Write Single Block — no option flag (the option/write-verify
    // variant is not supported by every Type 5 model and was one of the
    // rejected combinations seen in the field logs).
    final frame = [
      _baseFlags | _flagDataRateHigh,
      _cmdWriteSingleBlock,
      ..._addr(block),
      ...data,
    ];
    await _retry(() async {
      final body = await _respBody(frame, 'write[$block]');
      if (body.isEmpty) throw const TagLinkException('empty_write_response');
      return body;
    });
  }

  /// One retry after a short pause — covers the RF/I²C arbitration windows
  /// described in SOT §4.1 (tag busy while the MCU owns the I²C bus).
  /// Command-level rejections (0x01/0x02/0x03) are NOT retried — the frame
  /// itself is wrong and a pause cannot fix it.
  Future<T> _retry<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on TagLinkException catch (e) {
      final code = e.errorCode;
      final transient = code == null || code == 0x0F;
      if (!transient) rethrow;
      _event('retry after busy (code=${code == null ? '-' : '0x${code.toRadixString(16)}'})');
      await Future<void>.delayed(const Duration(milliseconds: 400));
      return op();
    }
  }

  @override
  Future<void> close() async {
    if (!_open) return;
    _open = false;
    try {
      await FlutterNfcKit.finish();
    } catch (_) {
      // session already closed by the platform
    }
  }
}

/// Deterministic in-memory tag — unit tests and the golden CRC path.
class FakeTagLink implements TagLink {
  FakeTagLink({
    int totalBlocks = 512,
    int blockSize = 4,
    int icRef = 0x26,
    String uid = '04:11:22:33:44:55:66',
  })  : _image = List<Uint8List>.generate(
            totalBlocks, (_) => Uint8List(blockSize)),
        _totalBlocks = totalBlocks,
        _blockSize = blockSize,
        icRefValue = icRef,
        uidValue = uid;

  final List<Uint8List> _image;
  final int _totalBlocks;
  final int _blockSize;
  final int icRefValue;
  final String uidValue;
  bool open = true;

  int get writeCount => _writes;
  int _writes = 0;

  Uint8List blockData(int block) => _image[block];

  void seedBlock(int block, List<int> b0to3) {
    for (var i = 0; i < _blockSize; i++) {
      _image[block][i] = i < b0to3.length ? b0to3[i] : 0;
    }
  }

  @override
  bool get isOpen => open;
  @override
  String get tagUid => uidValue;
  @override
  int get totalBlocks => _totalBlocks;
  @override
  int get blockSize => _blockSize;
  @override
  int get icRef => icRefValue;

  @override
  Future<Uint8List> readBlock(int block) async => Uint8List.fromList(_image[block]);

  @override
  Future<List<Uint8List>> readBlockRange(int first, int last) async =>
      [for (var b = first; b <= last; b++) Uint8List.fromList(_image[b])];

  @override
  Future<void> writeBlock(int block, Uint8List b0to3) async {
    seedBlock(block, b0to3);
    _writes += 1;
  }

  @override
  Future<void> close() async {
    open = false;
  }
}
