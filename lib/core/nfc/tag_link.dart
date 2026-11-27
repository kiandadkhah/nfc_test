/// Byte-level link to the ST25DV16KC tag — NFC Forum Type 5 (ISO/IEC
/// 15693), 512 × 4-byte blocks, 2048 bytes of user memory.
///
/// Command layer — ST25DV datasheet (DS10925 Rev 9, Table 101 «Command
/// codes») — the authoritative addressing model, confirmed against the
/// v4.1.0 field log (tag answered ISO 0x02/0x03 to every PE-flagged
/// frame) and the datasheet request-flag table («Protocol_extension:
/// reserved for future use» — the flag stays 0 on ST25DV at all times):
///   · STANDARD commands (1-byte block number, only blocks 0..255 of a
///     ST25DV16K/64K are reachable — §7.6.6): Read Single Block 0x20,
///     Write Single Block 0x21, Read Multiple Blocks 0x23 (8-bit count),
///     Get System Info 0x2B. The 16K/64K answer carries NO memory size
///     (info flags 0x0B = DSFID + AFI + IC_REF, Table 158) — the size
///     must come from the Extended Get System Info;
///   · EXTENDED commands (2-byte block number, LSB first, all blocks —
///     §7.6.7/§7.6.12): Extended Read Single Block 0x30, Extended Write
///     Single Block 0x31, Extended Read Multiple Blocks 0x33 (16-bit
///     count), Extended Get System Info 0x3B (Table 165: 16-bit
///     MEM_SIZE, MOI bit = 2-byte addressing);
///   · small Type 5 tags (ST25DV04K…) only implement the standard set,
///     so the link probes the extended commands once at open time and
///     falls back to the standard set + honest 256-block geometry.
/// Because of this, the app works with any ISO 15693 Type 5 tag that has
/// enough memory for the shared-memory layout, not only ST25DV16KC.
///
/// Request flag bytes (ISO 15693-3): bit1 sub-carrier 0x01, bit2 data rate
/// 0x02, bit3 inventory 0x04, bit4 protocol extension 0x08 (reserved on
/// ST25DV — NEVER set), bit5 select 0x10, bit6 address 0x20, bit7 option
/// 0x40, bit8 RFU 0x80. The link always talks to a single tag in the
/// field, so requests are non-addressed (no UID byte).
library;

import 'package:flutter/services.dart';

import 'native_transport.dart';

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

  /// v4.4 — reads one ST25DV dynamic register over the RF custom command
  /// «Read Dynamic Register» (B2h). Returns null when the tag does not
  /// answer the custom command (unsupported model / busy RF condition) —
  /// the caller then falls back to the logger heuristic.
  Future<int?> readDynamicRegister(int address);

  /// v4.4 — reads the EH_CTRL_Dyn power-supply status (VCC_ON / FIELD_ON /
  /// EH_ON / EH_EN). The base implementation reports «unavailable»; the
  /// ISO 15693 link implements the real register probe and the fake
  /// test link serves its seeded register map.
  Future<TagPowerStatus?> readPowerStatus() async => null;

  Future<void> close();
}

/// v4.4 — power-supply status decoded from the ST25DV dynamic register
/// EH_CTRL_Dyn (system config address 0001h on ST25DV-I2C; the KC
/// generation may place it at 0002h — both are probed). The register
/// carries the LIVE hardware status bits the field report asked for
/// («یک ثبات در ای‌سی وضعیت تغذیه را اعلام می کند»):
///   b0 EH_EN     — energy harvesting enable (RW)
///   b1 EH_ON     — EH output currently active (RO)
///   b2 FIELD_ON  — an RF field is present right now (RO)
///   b3 VCC_ON    — the tag VCC pin is powered = the relay is alive (RO)
class TagPowerStatus {
  const TagPowerStatus(this.registerAddress, this.raw);

  final int registerAddress;
  final int raw;

  bool get ehEn => raw & 0x01 != 0;
  bool get ehOn => raw & 0x02 != 0;
  bool get fieldOn => raw & 0x04 != 0;
  bool get vccOn => raw & 0x08 != 0;

  @override
  String toString() =>
      'EH_CTRL_Dyn@0x${registerAddress.toRadixString(16)}=0x${raw.toRadixString(16).padLeft(2, '0')}'
      ' (EH_EN=${ehEn ? 1 : 0} EH_ON=${ehOn ? 1 : 0} FIELD_ON=${fieldOn ? 1 : 0} VCC_ON=${vccOn ? 1 : 0})';
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
// the protocol-extension flag (0x08) is RESERVED on ST25DV and never set
// — extended access goes through the dedicated 0x30-family commands.
const int _flagDataRateHigh = 0x02;

// Command codes — DS10925 Rev 9 Table 101. Standard and extended access
// use DIFFERENT command codes (not a flag bit):
//   0x20/0x21/0x23  standard read/write/multi — 1-byte block number;
//   0x30/0x31/0x33  extended read/write/multi — 2-byte block number.
// CAUTION: 0x2A is Lock DSFID — a wrong multi-read code would address a
// destructive/irrelevant command instead of reading (field-log lesson).
const int _cmdReadSingleBlock = 0x20;
const int _cmdWriteSingleBlock = 0x21;
const int _cmdReadMultipleBlocks = 0x23;
const int _cmdGetSystemInfo = 0x2B;
const int _cmdExtReadSingleBlock = 0x30;
const int _cmdExtWriteSingleBlock = 0x31;
const int _cmdExtReadMultipleBlocks = 0x33;
const int _cmdExtGetSystemInfo = 0x3B;

/// Extended Get System Info parameter-request byte: b3 (0x04) asks for
/// the VICC memory size field (Table 162).
const int _extSysInfoRequestMemorySize = 0x04;

/// ISO 15693 response flag: bit 0 = error.
const int _respErrorFlag = 0x01;

/// Get System Info info-flag bits (Table 158): optional response fields
/// follow the fixed wire order DSFID, AFI, MEM_SIZE (2 B), IC_REF.
const int _infoFlagDsfid = 0x01;
const int _infoFlagAfi = 0x02;
const int _infoFlagMemSize = 0x04;
const int _infoFlagIcRef = 0x08;

/// Extended Get System Info response info-flag: MOI (memory organisation
/// information) — 1 = the tag uses 2-byte block addressing (Table 164).
const int _extInfoFlagMoi = 0x20;

/// IC_REF of the ST25DV family per Table 166 — 24h = ST25DV04K,
/// 26h = ST25DV16K AND ST25DV64K (the family does not distinguish them;
/// 512 × 4 B is the conservative size of the smaller 16K model).
const int _icRefSt25dv04k = 0x24;
const int _icRefSt25dv16k64k = 0x26;

/// Reverses an NFC UID from wire order (LSB first, as Android reports it)
/// to the human-readable order printed on the tag (MSB first), e.g.
/// "AF24ADD7002602E0" → "E0022600D7AD24AF". Accepts plain hex and
/// colon-separated hex; unknown shapes are returned unchanged.
String uidInHumanOrder(String raw) {
  final hex = raw.replaceAll(':', '').toUpperCase();
  if (hex.length < 4 || hex.length.isOdd ||
      !RegExp(r'^[0-9A-F]+$').hasMatch(hex)) {
    return raw;
  }
  final bytes = <String>[];
  for (var i = 0; i < hex.length; i += 2) {
    bytes.add(hex.substring(i, i + 2));
  }
  return bytes.reversed.join();
}

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
  Iso15693TagLink._(this._rawUidHex, {void Function(String event)? onEvent})
      : _onEvent = onEvent;

  /// Raw tag id as reported by the discovery layer (LSB-first hex) — the
  /// UI and the logs use the human-readable order via [tagUid].
  final String _rawUidHex;
  TagSystemInfo _info = const TagSystemInfo(
    totalBlocks: 0,
    blockSize: 0,
    icRef: 0,
    dsfid: 0,
    afid: 0,
    twoByteAddressing: false,
  );
  final void Function(String event)? _onEvent;

  /// Set when the tag rejected the protocol-extension flag — the link
  /// falls back to the standard 1-byte addressing (small Type 5 models).
  bool _forceStandard = false;

  bool _open = false;

  @override
  bool get isOpen => _open;

  /// Android reports the ISO 15693 UID LSB-first; the UI and the logs use
  /// the human-readable order printed on the tag (MSB first).
  @override
  String get tagUid => uidInHumanOrder(_rawUidHex);
  @override
  int get totalBlocks => _info.totalBlocks;
  @override
  int get blockSize => _info.blockSize;
  @override
  int get icRef => _info.icRef;

  void _event(String msg) => _onEvent?.call(msg);

  /// Extended command family (0x30/0x31/0x33 — 2-byte block numbers) for
  /// tags larger than 256 blocks (ST25DV16K/64K) — unless the probe at
  /// open time showed the tag does not implement them.
  bool get _useExtended =>
      !_forceStandard && (_info.known ? _info.totalBlocks > 256 : true);

  /// Polls for an ISO 15693 tag over the native reader-mode transport and
  /// opens the session. The reader mode itself is owned by the native layer
  /// (enabled from onResume — exclusive access, no NDEF dispatch), so the
  /// poll only connects the tag and reads its system info (standard Get
  /// System Info first, extended 0x3B second, IC_REF profile as the final
  /// fallback) so the addressing mode and memory geometry match the actual
  /// tag model, then verifies the addressing mode with a block-0 probe.
  /// [timeout] bounds the whole poll; returns null when the user never
  /// presented a compatible tag. Throws [TagLinkException]('nfc_disabled')
  /// when the phone NFC adapter is off or absent.
  static Future<Iso15693TagLink?> open({
    Duration timeout = const Duration(seconds: 45),
    void Function(String event)? onEvent,
  }) async {
    final transport = NativeNfcTransport.instance;
    transport.onEvent = onEvent;
    final availability = await transport.availability();
    if (availability != 'available') {
      onEvent?.call('open: NFC adapter not available ($availability)');
      throw const TagLinkException('nfc_disabled');
    }
    // Reader mode stays registered with the native layer for the whole
    // app lifetime; this idempotent call only guarantees it is active.
    await transport.enable();
    final String? rawUid;
    try {
      rawUid = await transport.poll(timeout);
    } on TagLinkException catch (e) {
      if (e.message == 'not_iso15693') {
        onEvent?.call('poll: tag is not ISO 15693 (NFC Type 5 required)');
      }
      rethrow;
    } catch (_) {
      // poll timed out or was cancelled by the platform
      return null;
    }
    if (rawUid == null || rawUid.isEmpty) {
      onEvent?.call('poll: no tag presented within the timeout');
      return null;
    }
    final link = Iso15693TagLink._(rawUid, onEvent: onEvent);
    link._open = true;
    link._info = await link._readSystemInfo();

    // Addressing self-check (field hardening): a tag that does not
    // implement the ST extended command family answers ISO error
    // 0x01/0x02/0x03 to the 0x30 probe, and some phone/tag pairs answer
    // such a frame with plain silence. Both cases fall back to the
    // standard 1-byte addressing; any other failure (busy / RF condition,
    // already retried once by the link) propagates.
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
            'open: extended commands (0x30-family) rejected '
            '(${e.errorCode == null ? 'no response (silent frame)' : iso15693ErrorText(e.errorCode!)}) '
            '— switching to standard addressing');
        link._forceStandard = true;
        if (link._info.totalBlocks > 256) {
          // Without the extended command family only the first 256 blocks
          // are reachable; the shared-memory layout needs 433 — the memory
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
        'open: uid=${link.tagUid} model=${link._info.modelName} blocks=${link._info.totalBlocks} '
        'blockSize=${link._info.blockSize} icRef=0x${link._info.icRef.toRadixString(16)} '
        'extended=${link._useExtended}');
    return link;
  }

  /// Best-effort system info read. Every anomaly is reported through
  /// [onEvent]; when neither variant yields a memory size, the geometry
  /// comes from the IC_REF profile (Table 166) or, as the last resort,
  /// from the PST50R1 target geometry (512 × 4 B) so the protocol can
  /// still proceed.
  ///
  /// Order (DS10925 Rev 9):
  ///  1. STANDARD Get System Info 0x2B — for ST25DV16K/64K it answers UID
  ///     + DSFID + AFI + IC_REF with info flags 0x0B and NO memory size
  ///     (Table 158). The v4.1.0 field log proves the point: the tag
  ///     answered correctly, but the old parser rejected the 13-byte
  ///     frame because it expected a MEM_SIZE field.
  ///  2. EXTENDED Get System Info 0x3B with the memory-size parameter —
  ///     answers the 16-bit MEM_SIZE (Table 165) + the MOI addressing
  ///     bit. Answering 0x3B at all also proves the tag implements the
  ///     extended command family (0x30/0x31/0x33).
  ///  3. IC_REF profile: 26h ⇒ ST25DV16K/64K family ⇒ 512 × 4 B;
  ///     24h ⇒ ST25DV04K ⇒ 128 × 4 B; unknown ⇒ target geometry.
  Future<TagSystemInfo> _readSystemInfo() async {
    final onEvent = _onEvent;
    TagSystemInfo? identity;
    // 1) STANDARD Get System Info — no request parameters.
    try {
      final resp = await NativeNfcTransport.instance.transceive(
        [_flagDataRateHigh, _cmdGetSystemInfo],
      );
      identity = parseSystemInfoFrame(resp);
      if (identity != null && identity.known) {
        onEvent?.call('system info: ${identity.totalBlocks}x${identity.blockSize}B '
            'icRef=0x${identity.icRef.toRadixString(16)} moi=${identity.twoByteAddressing}');
        return identity;
      }
      onEvent?.call('std get system info: no memory size in answer '
          '(${_hex(resp)}) — normal for ST25DV16K/64K (info flags 0x0B)');
    } catch (e) {
      onEvent?.call('std get system info failed: $e');
    }
    // Small pause so the RF layer settles before the extended variant.
    await Future<void>.delayed(const Duration(milliseconds: 150));
    // 2) EXTENDED Get System Info (0x3B) — parameter 0x04 = ask for the
    //    VICC memory size (Table 162).
    TagSystemInfo? ext;
    try {
      final resp = await NativeNfcTransport.instance.transceive(
        [_flagDataRateHigh, _cmdExtGetSystemInfo, _extSysInfoRequestMemorySize],
      );
      ext = parseSystemInfoFrame(resp);
      if (ext != null && ext.known) {
        onEvent?.call('ext get system info: ${ext.totalBlocks}x${ext.blockSize}B '
            'icRef=0x${ext.icRef.toRadixString(16)} moi=${ext.twoByteAddressing}');
        return ext;
      }
      onEvent?.call('ext get system info: geometry not reported (${_hex(resp)})');
    } catch (e) {
      onEvent?.call('ext get system info failed: $e');
    }
    // 3) Geometry from the IC_REF profile — for the production ST25DV16KC
    //    (IC_REF 26h) this is the exact 512 × 4 B target geometry.
    final ic = identity?.icRef ?? ext?.icRef ?? 0;
    final (blocks, size) = _profileGeometry(ic);
    onEvent?.call('system info: geometry from IC_REF profile '
        'icRef=0x${ic.toRadixString(16)} → ${blocks}x${size}B');
    return TagSystemInfo(
      totalBlocks: blocks,
      blockSize: size,
      icRef: ic,
      dsfid: identity?.dsfid ?? ext?.dsfid ?? 0,
      afid: identity?.afid ?? ext?.afid ?? 0,
      twoByteAddressing: blocks > 256,
    );
  }

  /// Geometry profile per IC_REF — DS10925 Table 166. Unknown IC_REFs fall
  /// back to the PST50R1 target geometry (512 × 4 B); the 16K-vs-64K
  /// distinction inside the 26h family is irrelevant because both models
  /// cover the 433 blocks of the shared-memory layout.
  static (int, int) _profileGeometry(int icRef) => switch (icRef) {
        _icRefSt25dv04k => (128, 4),
        _icRefSt25dv16k64k => (512, 4),
        _ => (512, 4),
      };

  /// Public for the field-frame unit tests: parses a Get System Info
  /// response body — the standard 0x2B and the
  /// extended 0x3B answers share the same optional-field wire order:
  /// FLAGS | infoFlags | UID (8 B, LSB first) | DSFID? | AFI? | MEM_SIZE?
  /// (2 B) | IC_REF? (Table 158/163/165). The MEM_SIZE 16-bit value packs
  /// block-size−1 into bits 15..13 and block-count−1 into bits 12..0
  /// (ISO 15693-3:2009 layout); the MOI info-flag of the extended answer
  /// directly reports 2-byte addressing. Returns identity-only data
  /// (totalBlocks = blockSize = 0) when no plausible geometry is present.
  ///
  /// ST25DV16K/64K answer the STANDARD command with info flags 0x0B —
  /// DSFID + AFI + IC_REF and NO MEM_SIZE. This is the exact behaviour
  /// seen in the v4.1.0 field log: the old parser called the 13-byte
  /// frame «not parseable» because it expected a MEM_SIZE field.
  static TagSystemInfo? parseSystemInfoFrame(Uint8List resp) {
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
    if ((infoFlags & _infoFlagDsfid) != 0) {
      if (body.length < i + 1) return null;
      dsfid = body[i];
      i += 1;
    }
    if ((infoFlags & _infoFlagAfi) != 0) {
      if (body.length < i + 1) return null;
      afid = body[i];
      i += 1;
    }
    if ((infoFlags & _infoFlagMemSize) != 0) {
      if (body.length < i + 2) return null;
      final v = (body[i] << 8) | body[i + 1];
      i += 2;
      // ISO 15693-3:2009 layout — bits 15..13 = block size − 1,
      // bits 12..0 = block count − 1. When it yields an implausible
      // geometry, the legacy 8-bit order ([count−1][size−1]) gets one
      // chance (some non-ST Type 5 tags); otherwise the caller falls
      // back to the IC_REF profile.
      final aSize = ((v >> 13) & 0x07) + 1;
      final aBlocks = (v & 0x1FFF) + 1;
      if (aSize >= 1 && aSize <= 32 && aBlocks >= 1 && aBlocks <= 4096) {
        blockSize = aSize;
        blocks = aBlocks;
      } else {
        final bBlocks = body[i - 2] + 1;
        final bSize = body[i - 1] + 1;
        if (bSize >= 1 && bSize <= 32 && bBlocks >= 1 && bBlocks <= 4096) {
          blockSize = bSize;
          blocks = bBlocks;
        }
      }
    }
    if ((infoFlags & _infoFlagIcRef) != 0) {
      if (body.length < i + 1) return null;
      icRef = body[i];
      i += 1;
    }
    final moi = (infoFlags & _extInfoFlagMoi) != 0;
    if (blockSize <= 0 || blockSize > 32 || blocks <= 0 || blocks > 4096) {
      // No memory size reported (or none plausible) — identity only.
      return TagSystemInfo(
        totalBlocks: 0,
        blockSize: 0,
        icRef: icRef,
        dsfid: dsfid,
        afid: afid,
        twoByteAddressing: moi,
        raw: body,
      );
    }
    return TagSystemInfo(
      totalBlocks: blocks,
      blockSize: blockSize,
      icRef: icRef,
      dsfid: dsfid,
      afid: afid,
      twoByteAddressing: moi || blocks > 256,
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

  /// Block number: extended commands carry it as 2 bytes (LSB first,
  /// Table 109); standard commands as 1 byte.
  List<int> _addr(int block) => _useExtended
      ? [block & 0xFF, (block >> 8) & 0xFF]
      : [block & 0xFF];

  /// Request flags — high data rate only. The protocol-extension flag is
  /// RESERVED on ST25DV (Table 95: «reserved for future use») and never
  /// set; the v4.1.0 field log shows the tag rejecting every PE-flagged
  /// frame with ISO error 0x02/0x03.
  int get _baseFlags => _flagDataRateHigh;

  /// Sends one frame and returns the response body (CRC auto-stripped).
  /// Platform IO errors are normalized into [TagLinkException] so the
  /// retry policy and the protocol engine see a uniform error type.
  Future<Uint8List> _transceive(List<int> frame, String what) async {
    Uint8List resp;
    try {
      resp = await NativeNfcTransport.instance.transceive(frame);
    } on PlatformException catch (e) {
      // RF field lost / I/O error — mapped to a link exception with no
      // error code (treated as transient by the retry policy).
      _event('tx $what failed: ${e.code} ${e.message ?? ''}');
      throw TagLinkException('io_${what}_error:${e.code}');
    } catch (e) {
      _event('tx $what failed: $e');
      throw TagLinkException('io_${what}_error:$e');
    }
    _event('tx $what: ${_hex(frame)} -> ${_hex(resp)}');
    return resp;
  }

  static String _hex(List<int> b) =>
      b.map((x) => x.toRadixString(16).padLeft(2, '0')).take(24).join(' ');

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
          [
            _baseFlags,
            _useExtended ? _cmdExtReadSingleBlock : _cmdReadSingleBlock,
            ..._addr(block),
          ],
          'read[$block]',
        ));
    if (body.length < 5) {
      throw const TagLinkException('short_read_response');
    }
    return Uint8List.fromList(body.sublist(1, 5)); // Byte_0..Byte_3
  }

  /// Reads [first]..[last] (inclusive) with (Extended) Read Multiple
  /// Blocks in chunks. The block count is a single byte in standard mode
  /// (values 00–FF mean 1–256 blocks) and 16 bits LSB first in extended
  /// mode (Table 129). When a chunk crosses a tag memory-area boundary
  /// the tag answers with an error (code 10h) — the chunk is then split
  /// recursively down to single-block reads, so any factory area
  /// configuration works.
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
          final countField = count - 1;
          final frame = [
            _baseFlags,
            _useExtended ? _cmdExtReadMultipleBlocks : _cmdReadMultipleBlocks,
            ..._addr(b),
            if (_useExtended)
              ...[countField & 0xFF, (countField >> 8) & 0xFF]
            else
              countField & 0xFF,
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
    // Plain (Extended) Write Single Block — no option flag (the
    // option/write-verify variant is not supported by every Type 5 model
    // and was one of the rejected combinations seen in the field logs).
    final frame = [
      _baseFlags,
      _useExtended ? _cmdExtWriteSingleBlock : _cmdWriteSingleBlock,
      ..._addr(block),
      ...data,
    ];
    await _retry(() async {
      final body = await _respBody(frame, 'write[$block]');
      if (body.isEmpty) throw const TagLinkException('empty_write_response');
      return body;
    });
  }

  // ------------------------------------------------------------------
  // v4.4 — ST25DV dynamic registers (power-supply status)
  // ------------------------------------------------------------------

  /// Request flags for the ST25DV custom commands: high data rate +
  /// ADDRESSED (bit 5 = 0x20) — the custom command family (B1h..BFh) is
  /// only served in addressed or selected mode, never unaddressed.
  static const int _customCommandFlags = _flagDataRateHigh | 0x20;

  /// IC manufacturing code of STMicroelectronics in ISO 15693 — the first
  /// byte after the request flags in every ST25DV custom command frame.
  static const int _stIcMfgCode = 0x02;

  /// «Read Dynamic Register» custom command code (DS10925 Table 101,
  /// ST25DV-I2C custom commands).
  static const int _cmdReadDynamicRegister = 0xB2;

  /// Candidate addresses of EH_CTRL_Dyn. ST25DV-I2C (DS13943): 0001h.
  /// KC generation: GPO1_CTRL_Dyn 0000h, GPO2_CTRL_Dyn 0001h, ACT_CTRL_Dyn
  /// 0002h — the probe validates each candidate through the FIELD_ON bit
  /// (an RF field IS present while this command runs) so the layout
  /// difference is detected on the real chip, not assumed.
  static const List<int> _ehCtrlDynCandidates = [0x01, 0x02];

  @override
  Future<int?> readDynamicRegister(int address) async {
    final uidBytes = <int>[
      for (var i = 0; i + 1 < _rawUidHex.length; i += 2)
        int.tryParse(_rawUidHex.substring(i, i + 2), radix: 16) ?? 0,
    ];
    final frame = [
      _customCommandFlags,
      _stIcMfgCode,
      _cmdReadDynamicRegister,
      address & 0xFF,
      ...uidBytes,
    ];
    try {
      final body = await _respBody(frame, 'reg[${address.toRadixString(16)}]');
      if (body.length < 2) {
        _event('reg[${address.toRadixString(16)}]: short register response');
        return null;
      }
      return body[1];
    } on TagLinkException catch (e) {
      // Command not implemented by this tag / busy RF — reported, not
      // raised: the caller decides the fallback.
      _event('reg[${address.toRadixString(16)}] read failed: ${e.message} '
          'code=${e.errorCode == null ? '-' : '0x${e.errorCode!.toRadixString(16)}'}');
      return null;
    }
  }

  /// Reads the EH_CTRL_Dyn power-supply status. Returns null when neither
  /// candidate address yields a register whose FIELD_ON bit is set (which
  /// is mandatory — the RF field carrying this very command is on).
  @override
  Future<TagPowerStatus?> readPowerStatus() async {
    for (final address in _ehCtrlDynCandidates) {
      final raw = await readDynamicRegister(address);
      if (raw == null) continue;
      final status = TagPowerStatus(address, raw);
      if (status.fieldOn) {
        _event('power register found: $status');
        return status;
      }
      _event('power register probe @$address rejected (FIELD_ON=0) — trying next');
    }
    _event('power register: EH_CTRL_Dyn not found — fallback required');
    return null;
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
    // Closes the NfcV session only — the native reader mode stays active
    // for the app lifetime, so the tag is never handed back to the
    // system dispatch (v4.3: no more browser hijack between sessions).
    try {
      await NativeNfcTransport.instance.finish();
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
    // v4.3 — the default identity models the production ST25DV16KC
    // (human-order UID of the field-test tag), so the protocol step-1
    // UID-signature check passes exactly like on the real hardware.
    String uid = 'E0:02:26:00:D7:AD:24:AF',
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

  /// Dynamic-register image for the tests — address → value. When an
  /// address is seeded the fake answers the custom command like the real
  /// ST25DV16KC; when the map is empty the register read fails and the
  /// protocol falls back to the logger heuristic (same as hardware
  /// without EH_CTRL_Dyn support).
  final Map<int, int> dynamicRegisters = {};

  @override
  Future<int?> readDynamicRegister(int address) async => dynamicRegisters[address];

  @override
  Future<TagPowerStatus?> readPowerStatus() async {
    // Same probe semantics as the real link: the candidate register must
    // carry FIELD_ON (an RF field is present during the read) to be
    // accepted as EH_CTRL_Dyn.
    for (final address in const [0x01, 0x02]) {
      final raw = dynamicRegisters[address];
      if (raw == null) continue;
      final status = TagPowerStatus(address, raw);
      if (status.fieldOn) return status;
    }
    return null;
  }

  @override
  Future<void> close() async {
    open = false;
  }
}
