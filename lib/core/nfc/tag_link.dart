/// Byte-level link to the ST25DV16KC tag — NFC Forum Type 5 (ISO/IEC
/// 15693), 512 × 4-byte blocks, 2048 bytes of user memory.
///
/// The command layer follows the ST25DV04KC/16KC/64KC datasheet (RF
/// commands chapter) and is adaptive to other Type 5 tag models:
///   · tags with more than 256 blocks (ST25DV16K/64K) are addressed with
///     the EXTENDED command set — Protocol_Extension flag + 2-byte block
///     number: 0x30 Extended Read Single Block, 0x31 Extended Write Single
///     Block, 0x33 Extended Read Multiple Blocks, 0x3B Extended Get
///     System Info;
///   · tags with up to 256 blocks (ST25DV04K, ST25TV…) use the standard
///     command set with 1-byte block numbers (0x20/0x21/0x23/0x2B).
/// Because of this, the app works with any ISO 15693 Type 5 tag that has
/// enough memory for the shared-memory layout, not only ST25DV16KC.
///
/// Request flag bytes (ISO 15693-3): bit1 sub-carrier, bit2 data rate,
/// bit3 inventory, bit4 select / protocol-extension, bit5 address,
/// bit6 option, bit7-8 RFU. The link always talks to a single tag in the
/// field, so requests are non-addressed (no UID byte).
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

// ISO 15693-3 request flag bits (ST25DV datasheet tables 94/95):
// bit1 sub-carrier 0x01, bit2 data rate 0x02, bit3 inventory 0x04,
// bit4 protocol extension 0x08, bit5 select 0x10, bit6 address 0x20,
// bit7 option 0x40, bit8 RFU 0x80. The link talks to a single tag in
// non-addressed mode, so only these three flags are ever set:
const int _flagDataRateHigh = 0x02;
const int _flagProtocolExtension = 0x08;
const int _flagOption = 0x40;

// Command codes — standard and extended (T5T extended addressing).
const int _cmdReadSingleBlock = 0x20;
const int _cmdWriteSingleBlock = 0x21;
const int _cmdReadMultipleBlocks = 0x23;
const int _cmdGetSystemInfo = 0x2B;
const int _cmdExtReadSingleBlock = 0x30;
const int _cmdExtWriteSingleBlock = 0x31;
const int _cmdExtReadMultipleBlocks = 0x33;
const int _cmdExtGetSystemInfo = 0x3B;

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

  /// True when the tag reports 2-byte block addressing (MOI flag).
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
  final TagSystemInfo _info;
  final void Function(String event)? _onEvent;

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

  /// Extended addressing for tags larger than 256 blocks (ST25DV16K/64K).
  bool get _useExtended => _info.known ? _info.totalBlocks > 256 : true;

  /// Polls for an ISO 15693 tag and opens the session. Reads the tag
  /// system info (Extended Get System Info with standard fallback) so the
  /// addressing mode and memory geometry match the actual tag model.
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
    onEvent?.call(
        'open: uid=${polled.id} model=${info.modelName} blocks=${info.totalBlocks} '
        'blockSize=${info.blockSize} icRef=0x${info.icRef.toRadixString(16)} '
        'extended=${info.totalBlocks > 256}');
    return link;
  }

  /// Best-effort system info read. Any failure falls back to the PST50R1
  /// target geometry (512 × 4 B) so the protocol can still proceed; every
  /// anomaly is reported through [onEvent].
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
    try {
      // Extended Get System Info: flags = PE (0x08), param list =
      // DSFID|AFI|MEM_SIZE|IC_REF|MOI (0x1F).
      final resp = await FlutterNfcKit.transceive<Uint8List>(
        Uint8List.fromList([_flagProtocolExtension, _cmdExtGetSystemInfo, 0x1F]),
      );
      final parsed = _parseSystemInfo(resp, extended: true);
      if (parsed != null) return parsed;
    } catch (e) {
      onEvent?.call('ext get system info failed: $e');
    }
    try {
      // Standard Get System Info: flags = high data rate (0x02), no params.
      final resp = await FlutterNfcKit.transceive<Uint8List>(
        Uint8List.fromList([_flagDataRateHigh, _cmdGetSystemInfo]),
      );
      final parsed = _parseSystemInfo(resp, extended: false);
      if (parsed != null) return parsed;
    } catch (e) {
      onEvent?.call('std get system info failed: $e');
    }
    onEvent?.call('system info unknown — using target geometry 512x4');
    return fallback;
  }

  /// Parses an (Extended) Get System Info response body. Returns null when
  /// the frame is not plausible — the caller then tries the next variant.
  static TagSystemInfo? _parseSystemInfo(Uint8List resp, {required bool extended}) {
    final body = _stripCrcIfPresent(resp);
    if (body.isEmpty) return null;
    if ((body[0] & _respErrorFlag) != 0) return null;
    if (body.length < 2) return null;
    final infoFlags = body[1];
    // UID always present (8 bytes, transmitted LSB first).
    var i = 2 + 8;
    if (body.length < i) return null;
    var dsfid = 0;
    var afid = 0;
    var blocks = 0;
    var blockSize = 0;
    var icRef = 0;
    var twoByte = false;
    // Fields follow the information-flag bit order: DSFID, AFI, memory
    // size, IC_REF. Extended memory size = 3 bytes (block-size byte +
    // 16-bit block count); standard = 2 bytes (block size byte | block
    // count byte) and is only reported by small tags.
    if ((infoFlags & 0x01) != 0) {
      if (body.length < i + 1) return null;
      dsfid = body[i];
      i += 1;
    }
    if ((infoFlags & 0x02) != 0) {
      if (body.length < i + 1) return null;
      afid = body[i];
      i += 1;
    }
    if ((infoFlags & 0x04) != 0) {
      if (extended) {
        if (body.length < i + 3) return null;
        blockSize = body[i] + 1;
        blocks = (body[i + 1] << 8) | body[i + 2];
        blocks += 1;
        i += 3;
      } else {
        if (body.length < i + 2) return null;
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
    // MOI flag (0x10): 1 = the tag uses 2-byte block addressing.
    twoByte = (infoFlags & 0x10) != 0;
    if (blockSize <= 0 || blockSize > 8 || blocks <= 0) return null;
    return TagSystemInfo(
      totalBlocks: blocks,
      blockSize: blockSize,
      icRef: icRef,
      dsfid: dsfid,
      afid: afid,
      twoByteAddressing: twoByte,
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

  int get _readCmd => _useExtended ? _cmdExtReadSingleBlock : _cmdReadSingleBlock;
  int get _writeCmd => _useExtended ? _cmdExtWriteSingleBlock : _cmdWriteSingleBlock;
  int get _readMultiCmd =>
      _useExtended ? _cmdExtReadMultipleBlocks : _cmdReadMultipleBlocks;

  int get _baseFlags =>
      _useExtended ? _flagProtocolExtension : 0x00;

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
      throw TagLinkException(
        'error_${what}_response',
        errorCode: body.length > 1 ? body[1] : null,
      );
    }
    return body;
  }

  // ------------------------------------------------------------------
  // Block operations
  // ------------------------------------------------------------------

  @override
  Future<Uint8List> readBlock(int block) async {
    final body = await _retry(() => _respBody(
          [_baseFlags | _flagDataRateHigh, _readCmd, ..._addr(block)],
          'read[$block]',
        ));
    if (body.length < 5) {
      throw const TagLinkException('short_read_response');
    }
    return Uint8List.fromList(body.sublist(1, 5)); // Byte_0..Byte_3
  }

  /// Reads [first]..[last] (inclusive) with Extended Read Multiple Blocks
  /// in chunks. When a chunk crosses a tag memory-area boundary the tag
  /// answers with an error (code 10h) — the chunk is then split recursively
  /// down to single-block reads, so any factory area configuration works.
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
          final frame = _useExtended
              ? [
                  _baseFlags,
                  _readMultiCmd,
                  b & 0xFF,
                  (b >> 8) & 0xFF,
                  (count - 1) & 0xFF,
                  ((count - 1) >> 8) & 0xFF,
                ]
              : [_baseFlags, _readMultiCmd, b & 0xFF, (count - 1) & 0xFF];
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
    // Option flag (0x40) is mandatory for write commands per ISO 15693-3.
    final frame = [
      _baseFlags | _flagDataRateHigh | _flagOption,
      _writeCmd,
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
