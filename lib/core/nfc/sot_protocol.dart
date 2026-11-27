/// The 8-step write protocol engine of SOT table 4-4, executed over a
/// [TagLink]. Emits the same [WriteProgress] stream the UI consumes, and
/// implements the §4.10 consistent logger read. Deterministic and
/// unit-testable against [FakeTagLink].
library;

import 'dart:typed_data';

import '../constants/domain.dart';
import '../crypto/crc32_stm32.dart';
import '../logging/app_logger.dart';
import '../models/program.dart';
import '../solar/chebyshev.dart';
import '../solar/solar_events.dart';
import '../utils/jalali.dart';
import '../validation/validators.dart' show programNeedsDays;
import 'memory_map.dart';
import 'nfc_service.dart';
import 'tag_link.dart';

/// Inputs required to build one write payload.
class SotWriteRequest {
  SotWriteRequest({
    required this.mode,
    required this.enabledPrograms,
    required this.deviceTime,
    required this.latitude,
    required this.longitude,
    required this.utcOffsetHours,
  });

  final WriteMode mode;
  final List<Program> enabledPrograms;
  final DateTime deviceTime;
  final double latitude;
  final double longitude;
  final double utcOffsetHours;
}

/// Result of one completed protocol run.
class SotWriteResult {
  const SotWriteResult({required this.newVersion, required this.appCrc32});
  final int newVersion;
  final int appCrc32;
}

/// The protocol engine. All step timings (except RF round-trips) follow the
/// mandatory order of table 4-4; every failure restarts from step 1 per the
/// retry policy (handled by the caller after two attempts).
class SotProtocol {
  SotProtocol(this._link, {AppLogger? logger}) : _log = logger ?? AppLogger.instance;

  final TagLink _link;
  final AppLogger _log;

  bool _cancelled = false;
  void cancel() => _cancelled = true;

  /// CRC-32/MPEG-2 over 1656 zero bytes (blocks 16..429) — the value the
  /// v4.2.0 field analysis read from the real tag. Used as a sentinel to
  /// detect a write that never committed.
  static const int payloadEmptyCrc = 0x0993D8D7;

  /// Reads a contiguous block range (chunked multi-block reads), Byte_0..
  /// Byte_3 per block, with progress ticks.
  Future<List<Uint8List>> _readRange(
      int first, int last, void Function(int done, int total)? onTick) async {
    final out = <Uint8List>[];
    const chunk = 32;
    var b = first;
    final total = last - first + 1;
    while (b <= last) {
      final end = (b + chunk - 1) > last ? last : (b + chunk - 1);
      final part = await _link.readBlockRange(b, end);
      out.addAll(part);
      onTick?.call(out.length, total);
      b = end + 1;
    }
    return out;
  }

  Future<void> _writeRange(List<int> blocks, Uint8List Function(int block) dataOf,
      void Function(int done, int total)? onTick) async {
    final total = blocks.length;
    const verifyChunk = 8;
    var done = 0;
    for (var i = 0; i < total; i += verifyChunk) {
      final end = (i + verifyChunk) > total ? total : (i + verifyChunk);
      final chunk = blocks.sublist(i, end);
      // Write the chunk with a small breathing room per block — respects
      // the EEPROM write-cycle window (arbitration with the MCU's I²C).
      for (final b in chunk) {
        await _link.writeBlock(b, dataOf(b));
        await Future<void>.delayed(const Duration(milliseconds: 4));
      }
      // Read the chunk back and compare byte-exactly against the plan.
      var stale = await _verifyChunk(chunk, dataOf);
      for (var round = 0; round < 2 && stale.isNotEmpty; round++) {
        _log.nfc('step4: verify — ${stale.length} stale block(s) '
            '[${stale.take(6).join(',')}] — rewriting (round ${round + 1})');
        for (final b in stale) {
          await _link.writeBlock(b, dataOf(b));
          await Future<void>.delayed(const Duration(milliseconds: 4));
        }
        stale = await _verifyChunk(chunk, dataOf);
      }
      if (stale.isNotEmpty) {
        throw TagLinkException('write_verify_failed:${stale.first}');
      }
      done = end;
      onTick?.call(done, total);
    }
  }

  /// Byte-level comparison of a written chunk against the plan; returns
  /// the block numbers whose content on the tag does not match yet.
  Future<List<int>> _verifyChunk(
      List<int> chunk, Uint8List Function(int block) dataOf) async {
    final readBack = await _link.readBlockRange(chunk.first, chunk.last);
    final stale = <int>[];
    for (var k = 0; k < chunk.length; k++) {
      final want = dataOf(chunk[k]);
      final got = readBack[k];
      for (var j = 0; j < 4; j++) {
        final expected = j < want.length ? want[j] : 0;
        if (j >= got.length || got[j] != expected) {
          stale.add(chunk[k]);
          break;
        }
      }
    }
    return stale;
  }

  /// Computes CRC-32/MPEG-2 over blocks 16..429 for one read-back image
  /// — exactly the bytes the MCU will hash on the tag (SOT §4.11). No
  /// override: the verification only counts when it hashes the CONTENT
  /// actually read back from the tag.
  int _crcOverPlanning(List<Uint8List> blocks16to429) {
    final bytes = <int>[];
    for (final block in blocks16to429) {
      bytes.addAll(block);
    }
    return crc32Stm32(bytes);
  }

  /// Builds the coefficient payload for the request location/time.
  ///
  /// The table always covers the 366 device slots of the CURRENT Jalali
  /// year: days 1..366 map onto the real calendar (leap years keep the
  /// 30th day of Esfand); in a common year the 366th slot mirrors day 365
  /// because that slot does not exist in the calendar. The MCU evaluates
  /// days 1..365 (divisor 364) per Q-12, so this only keeps the table
  /// physically meaningful.
  static (List<int>, List<int>) solarCoefficientsFor(SotWriteRequest req) {
    final now = req.deviceTime;
    final j = gregorianToJalali(now);
    final yearLen = jalaliYearLength(j.year);
    final sr = List<int>.filled(366, 0);
    final ss = List<int>.filled(366, 0);
    for (var day = 1; day <= 366; day++) {
      final realDay = day > yearLen ? yearLen : day;
      final (m, d) = jalaliFromDayOfYear(j.year, realDay);
      final g = jalaliToGregorian(JalaliDate(j.year, m, d));
      final t = solarTimesFor(
        year: g.year,
        month: g.month,
        day: g.day,
        latitude: req.latitude,
        longitude: req.longitude,
        utcOffsetHours: req.utcOffsetHours,
      );
      sr[day - 1] = t.sunriseMinutes;
      ss[day - 1] = t.sunsetMinutes;
    }
    return (fitChebyshevQ14FromTable(sr), fitChebyshevQ14FromTable(ss));
  }

  /// Reads the onboarding area (blocks 0..15) and decodes the factory
  /// NDEF product URI — used by the identification flow and by protocol
  /// step 1.
  Future<String> readOnboardingUri() async {
    final ndefBlocks = await _readRange(
        SotMemoryMap.onboardingStartBlock, SotMemoryMap.onboardingEndBlock, null);
    final ndefBytes = <int>[];
    for (final b in ndefBlocks) {
      ndefBytes.addAll(b);
    }
    final text = ndefProductUri(Uint8List.fromList(ndefBytes));
    _log.nfc('onboarding: NDEF URI decoded = "$text"');
    return text;
  }

  /// Runs steps [fromStep]..8 of the protocol and emits progress.
  Future<SotWriteResult?> run(
    SotWriteRequest req, {
    required void Function(WriteProgress progress) onProgress,
    int fromStep = 1,
    bool skipClock = false,
  }) async {
    _cancelled = false;
    // v4.3 guard — a program transfer with zero enabled programs would
    // produce an empty event/timer pool; refuse it instead of "successfully"
    // writing an empty payload (field report: the pools were empty on the
    // tag after a supposedly complete transfer).
    if (req.mode == WriteMode.programAndSettings && req.enabledPrograms.isEmpty) {
      _log.nfc('run: refused — program mode with no enabled programs');
      throw const TagLinkException('no_programs');
    }
    // v4.4 guard — an enabled non-daily program without its own cycle days
    // would encode orphan events that no day-table slot ever points at
    // (the v4.3.0 field report: «ثبت برنامه بدون اختصاص روز»). The editor
    // already blocks this; the transfer refuses it as the last defence.
    if (req.mode == WriteMode.programAndSettings) {
      final dayless = req.enabledPrograms.where(programNeedsDays).toList();
      if (dayless.isNotEmpty) {
        _log.nfc('run: refused — program(s) without assigned days: '
            '${dayless.map((p) => '"${p.name}"').join(', ')}');
        throw TagLinkException(
            'program_without_days:${dayless.map((p) => p.name).join('|')}');
      }
    }
    final startCode =
        req.mode == WriteMode.programAndSettings ? ProcessCodes.programStart : ProcessCodes.settingsStart;
    final completeCode =
        req.mode == WriteMode.programAndSettings ? ProcessCodes.programCompleteWrite : ProcessCodes.settingsCompleteWrite;
    final endCode = req.mode == WriteMode.programAndSettings ? ProcessCodes.programEnd : ProcessCodes.settingsEnd;

    var runVersion = 0;
    var appCrc = 0;
    _readBackImage = null;
    var doneCount = fromStep - 1;

    void emit(int step, StepStatus status, {bool completed = false, int? newVersion, FailureKind? failure, int? failedStep, bool powerOff = false, String? failureCode}) {
      onProgress(WriteProgress(
        step: step,
        status: status,
        completed: completed,
        newVersion: newVersion,
        failure: failure,
        failedStep: failedStep,
        powerOff: powerOff,
        doneCount: doneCount,
        failureCode: failureCode,
      ));
    }

    for (var step = fromStep; step <= 8; step++) {
      if (_cancelled) return null;
      emit(step, StepStatus.active);

      try {
        switch (step) {
          case 1:
            // Read the onboarding area (blocks 0..15) and identify the tag:
            // CC file must be a valid Type 5 CC (magic E1/E2), the factory
            // NDEF URI must be the EXACT whitelisted product link of the
            // supported model (NdefContract — prefix matching is FORBIDDEN,
            // v4.2.0 report: a …/pts50r15 tag must fail), the UID must
            // carry the ST25DV16KC signature, and the tag memory must cover
            // the shared-memory layout.
            final cc = await _link.readBlock(SotMemoryMap.blockCc);
            final magic = cc[0];
            _log.nfc('step1: CC magic=0x${magic.toRadixString(16)} '
                'tagModel=${_link.totalBlocks}x${_link.blockSize}B '
                'icRef=0x${_link.icRef.toRadixString(16)}');
            if (magic != 0xE1 && magic != 0xE2) {
              throw const TagLinkException('not_type5_tag');
            }
            final ndefUri = await readOnboardingUri();
            final model = NdefContract.modelOfUri(ndefUri);
            if (model == null) {
              _log.nfc('step1: URI is not a whitelisted product link — got "$ndefUri"');
              throw TagLinkException('link_invalid:$ndefUri');
            }
            if (model != NdefContract.supportedModel) {
              _log.nfc('step1: recognized model $model is not supported '
                  '(${NdefContract.supportedModel} required)');
              throw TagLinkException('model_unsupported:$model');
            }
            final uidOk = NdefContract.uidHasSt25dv16kSignature(_link.tagUid);
            if (!uidOk) {
              _log.nfc('step1: UID signature mismatch — uid=${_link.tagUid} '
                  'expected prefix E0 02 26 (ST25DV16KC)');
              throw const TagLinkException('uid_signature');
            }
            const requiredBlocks = SotMemoryMap.planningEndBlock + 1;
            if (_link.totalBlocks > 0 && _link.totalBlocks < requiredBlocks) {
              throw TagLinkException(
                  'memory_too_small:${_link.totalBlocks}x${_link.blockSize}');
            }
            doneCount += 1;
            emit(step, StepStatus.done);

          case 2:
            // Read Internal_Error and RUN_Program_Counter from the logger.
            final logger = await readLoggerBlocks();
            final snap = LoggerSnapshot.fromBlocks(logger);
            runVersion = snap.runProgramCounter;
            // v4.4 — the power-supply state comes from the ST25DV16KC
            // itself: EH_CTRL_Dyn carries the live FIELD_ON/EH_ON/VCC_ON
            // status bits (field report: «برای بررسی تغذیه تگ باید از
            // رجیسترهای st25dv16kc استفاده کنی»). The logger heuristic only
            // runs when the tag does not answer the custom register command.
            final power = await _link.readPowerStatus();
            bool unpowered;
            if (power != null) {
              _log.nfc('step2: power register $power → '
                  'relay ${power.vccOn ? 'powered' : 'UNPOWERED'}');
              unpowered = !power.vccOn;
            } else {
              unpowered = snap.runProgramCounter == 0 ||
                  snap.runProgramCounter == 0xFFFF ||
                  snap.logCrc32 == 0 ||
                  snap.logCrc32 == 0xFFFFFFFF;
              _log.nfc('step2: power register unavailable — logger heuristic '
                  '(run=${snap.runProgramCounter}, logCrc=${snap.logCrc32}) '
                  '→ ${unpowered ? 'UNPOWERED' : 'powered'}');
            }
            // The protocol halts here on an unpowered relay and the caller
            // decides how to continue.
            if (unpowered && !skipClock) {
              _log.nfc('step2: relay without power supply detected');
              emit(step, StepStatus.active, powerOff: true);
              return null;
            }
            doneCount += 1;
            emit(step, StepStatus.done);

          case 3:
            // Write the start code into Process_Record_Planning, keeping the
            // current Program_Counter bytes intact.
            final reg = await _link.readBlock(SotMemoryMap.blockPlanningRegister);
            final newImage = Uint8List.fromList(reg);
            newImage[0] = startCode; // Byte_0
            // Byte_1 = RES (0), Byte_2..3 = Program_Counter unchanged.
            await _link.writeBlock(SotMemoryMap.blockPlanningRegister, newImage);
            _log.nfc('step3: start code 0x${startCode.toRadixString(16)} written');
            doneCount += 1;
            emit(step, StepStatus.done);

          case 4:
            // Build and write the target area; RES bytes are already 0x00.
            // v4.3 hardening: every chunk is READ BACK and compared right
            // after it is written, stale blocks are rewritten twice — the
            // v4.2.0 field analysis (APP_CRC32 = CRC of an all-zero payload
            // = 0x0993D8D7 on the real tag) proved that silent write loss
            // was being validated as success before.
            final plan = await _buildPlan(req, runVersion + 1, skipClock);
            await _writeRange(plan.blocks, plan.dataOf, (done, total) {
              _log.nfc('step4: blocks $done/$total written+verified');
            });
            doneCount += 1;
            emit(step, StepStatus.done);

          case 5:
            // Store APP_CRC32 and write the complete-write code. The CRC
            // is computed over the content actually on the tag right now
            // (freshly written data + retained old data in settings-only
            // mode) — identical to what the MCU will hash.
            final baseBlocks = await _readRange(
                SotMemoryMap.planningStartBlock, SotMemoryMap.blockSetDate, null);
            appCrc = _crcOverPlanning(baseBlocks);
            final crcBlock = Uint8List(4);
            crcBlock[0] = appCrc & 0xFF;
            crcBlock[1] = (appCrc >> 8) & 0xFF;
            crcBlock[2] = (appCrc >> 16) & 0xFF;
            crcBlock[3] = (appCrc >> 24) & 0xFF;
            await _link.writeBlock(SotMemoryMap.blockAppCrc32, crcBlock);
            _log.nfc('step5: APP_CRC32=0x${appCrc.toRadixString(16)} written');

            final reg = await _link.readBlock(SotMemoryMap.blockPlanningRegister);
            final newImage = Uint8List.fromList(reg);
            newImage[0] = completeCode;
            await _link.writeBlock(SotMemoryMap.blockPlanningRegister, newImage);
            doneCount += 1;
            emit(step, StepStatus.done);

          case 6:
            // Read back the whole written area for verification.
            final blocks = await _readRange(
                SotMemoryMap.planningStartBlock, SotMemoryMap.blockSetDate, (done, total) {
              _log.nfc('step6: blocks $done/$total read back');
            });
            // Step 7 reuses this read-back image — one pass, one CRC check.
            _readBackImage = blocks;
            doneCount += 1;
            emit(step, StepStatus.done);

          case 7:
            // Compare CRC computed from the read-back with APP_CRC32.
            final baseBlocks = _readBackImage ??
                await _readRange(
                    SotMemoryMap.planningStartBlock, SotMemoryMap.blockSetDate, null);
            _readBackImage = null;
            final crcBlock = await _link.readBlock(SotMemoryMap.blockAppCrc32);
            final storedCrc =
                crcBlock[0] | (crcBlock[1] << 8) | (crcBlock[2] << 16) | (crcBlock[3] << 24);
            final recomputed = _crcOverPlanning(baseBlocks);
            _log.nfc('step7: read-back CRC=0x${recomputed.toRadixString(16)} '
                'stored=0x${storedCrc.toRadixString(16)}');
            if (recomputed != storedCrc) {
              throw TagLinkException('crc_mismatch:${recomputed.toRadixString(16)}!=${storedCrc.toRadixString(16)}');
            }
            // v4.4 sentinel — the CRC of an ALL-ZERO planning payload is
            // 0x0993D8D7 (proven by the v4.2.0 field analysis). A complete
            // program transfer can never produce that value: the solar
            // coefficients and the clock bytes alone are non-zero. With the
            // v4.4 full-image plan this guard holds for BOTH paths (clock
            // sync and the unpowered continue) — the coefficients are
            // always part of the payload.
            if (req.mode == WriteMode.programAndSettings &&
                req.enabledPrograms.isNotEmpty &&
                recomputed == payloadEmptyCrc) {
              _log.nfc('step7: payload sentinel hit — read-back CRC equals the '
                  'all-zero payload CRC; the programs were not stored');
              throw const TagLinkException('payload_not_written');
            }
            doneCount += 1;
            emit(step, StepStatus.done);

          case 8:
            // End code + new Program_Counter (RUN version read at step 2 + 1).
            final newVersion = runVersion + 1;
            final reg = Uint8List(4);
            reg[0] = endCode;
            reg[1] = 0x00; // RES
            reg[2] = newVersion & 0xFF;
            reg[3] = (newVersion >> 8) & 0xFF;
            await _link.writeBlock(SotMemoryMap.blockPlanningRegister, reg);
            _log.nfc('step8: end code 0x${endCode.toRadixString(16)} + '
                'Program_Counter=$newVersion written — protocol complete');
            doneCount += 1;
            emit(step, StepStatus.done, completed: true, newVersion: newVersion);
            return SotWriteResult(newVersion: newVersion, appCrc32: appCrc);
        }
      } on TagLinkException catch (e) {
        _log.error('protocol step $step failed: ${e.message} code=${e.errorCode}');
        emit(step, StepStatus.failed,
            failure: FailureKind.stepFailed,
            failedStep: step,
            failureCode: e.message);
        rethrow;
      }
    }
    return null;
  }

  List<Uint8List>? _readBackImage;

  /// Builds the write plan for the requested mode and payload.
  ///
  /// v4.4 — the program mode builds the FULL planning image (blocks
  /// 16..431) in EVERY case. The former `skipClock → settings-only plan`
  /// branch was the root cause of the v4.3.0 field bug: when the user
  /// continued on an unpowered relay, only the 14 coefficient/SET blocks
  /// were written and every program value stayed at zero
  /// (APP_CRC32 = 0x0993D8D7 = CRC of the empty image). `skipClock` now
  /// ONLY decides whether the SET blocks carry a new clock (powered path)
  /// or the bytes currently stored on the tag are preserved unchanged
  /// (unpowered-continue path).
  Future<_Plan> _buildPlan(SotWriteRequest req, int newCounter, bool skipClock) async {
    final (sr, ss) = solarCoefficientsFor(req);
    final jalali = gregorianToJalali(req.deviceTime);
    final clock = JalaliClock(year2: jalali.year % 100, month: jalali.month, day: jalali.day);

    if (req.mode == WriteMode.settingsOnly) {
      // Settings-only transfer (coefficients + clock, blocks 416..429).
      // The settings flow never reaches this point with skipClock — the
      // power-off halt blocks it before the transfer starts.
      final img = PlanningImage();
      img.setSolarCoefficients(sunriseQ14: sr, sunsetQ14: ss);
      if (!skipClock) {
        img.setClock(req.deviceTime,
            jalaliYear2: clock.year2, jalaliMonth: clock.month, jalaliDay: clock.day);
      }
      final blocks = List<int>.generate(14, (i) => SotMemoryMap.blockChebyshevSrStart + i);
      final override = img.bytes;
      return _Plan(blocks, (b) => Uint8List.sublistView(override, (b - SotMemoryMap.blockChebyshevSrStart) * 4));
    }

    List<int>? preservedSet;
    if (skipClock) {
      // Preserve the clock/calendar bytes currently stored on the tag so
      // the full-image rewrite never destroys a running device clock —
      // also the only safe behaviour if the register check ever
      // misclassifies a powered device as unpowered.
      final setBlocks = await _readRange(
          SotMemoryMap.blockSet, SotMemoryMap.blockSetDate, null);
      preservedSet = <int>[
        ...setBlocks[0],
        ...setBlocks[1],
      ];
      _log.nfc('step4: skipClock — SET bytes preserved from the tag '
          '(${preservedSet.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ')})');
    }

    final plan = buildProgramWritePlan(
      enabledPrograms: req.enabledPrograms,
      deviceTime: req.deviceTime,
      jalali: clock,
      sunriseQ14: sr,
      sunsetQ14: ss,
      newProgramCounter: newCounter,
      writeClock: !skipClock,
      preservedSetBytes: preservedSet,
    );
    return _Plan(
        List<int>.generate(416, (i) => SotMemoryMap.planningStartBlock + i),
        (b) => plan.dataOf(b)!);
  }

  /// §4.10 consistent logger read — retried when an MCU write begins
  /// mid-read; verifies LOG_CRC32 over blocks 504..509.
  Future<List<Uint8List>> readLoggerBlocks() async {
    for (var attempt = 0; attempt < 3; attempt++) {
      final reg0 = await _link.readBlock(SotMemoryMap.blockProcessRecordLog);
      final mid = reg0[0] == ProcessCodes.settingsStart || reg0[0] == ProcessCodes.settingsCompleteWrite;
      final blocks = await _readRange(SotMemoryMap.loggerStartBlock, SotMemoryMap.loggerEndBlock, null);
      final reg1 = await _link.readBlock(SotMemoryMap.blockProcessRecordLog);
      if (mid || reg0[0] != reg1[0]) {
        _log.nfc('logger read restarted — MCU write began mid-read');
        continue; // an MCU write started during the read — restart
      }
      final crcBytes = blocks[7]; // block 511
      final stored = crcBytes[0] | (crcBytes[1] << 8) | (crcBytes[2] << 16) | (crcBytes[3] << 24);
      final domain = <int>[];
      for (var i = 0; i <= 5; i++) {
        domain.addAll(blocks[i]);
      }
      if (stored != 0 && stored != 0xFFFFFFFF && crc32Stm32(domain) != stored) {
        throw const TagLinkException('log_crc_mismatch');
      }
      return blocks;
    }
    throw const TagLinkException('logger_busy');
  }

  /// Decodes the NDEF product-page URI out of the onboarding blocks
  /// (NDEF TLV → well-known URI record → text). Defensive: returns '' on
  /// any structural mismatch — the factory message is a single SR URI record.
  static String ndefProductUri(Uint8List raw) {
    // Skip the Type 5 CC file when present (block 0, 4 bytes E1|E2 …) —
    // on the factory ST25DV configuration the NDEF TLV area starts right
    // after the CC, so the TLV scan must begin at byte offset 4.
    var i = 0;
    if (raw.length > 4 && (raw[0] == 0xE1 || raw[0] == 0xE2)) {
      i = 4;
    }
    while (i + 1 < raw.length) {
      final t = raw[i];
      if (t == 0xFE) break; // TLV terminator
      final len = raw[i + 1];
      if (t == 0x03 && len > 0 && i + 2 + len <= raw.length) {
        return _decodeUriRecord(Uint8List.sublistView(raw, i + 2, i + 2 + len));
      }
      i += 2 + len;
    }
    return '';
  }

  static String _decodeUriRecord(Uint8List msg) {
    try {
      // Typical factory message: one short URI record —
      // 0xD1 (MB|ME|SR|TNF=1) 0x01 (type len) [len] 0x55 'U' [prefix] ...
      for (var i = 0; i + 4 <= msg.length; i++) {
        if (msg[i] == 0xD1 && msg[i + 1] == 0x01 && msg[i + 3] == 0x55) {
          final payloadLen = msg[i + 2];
          final start = i + 4;
          if (payloadLen <= 1 || start + payloadLen > msg.length) return '';
          final payload = msg.sublist(start, start + payloadLen);
          final prefix = _uriPrefixes[payload[0].clamp(0, _uriPrefixes.length - 1)];
          return '$prefix${String.fromCharCodes(payload.sublist(1))}';
        }
      }
    } catch (_) {
      // fall through
    }
    return '';
  }

  static const List<String> _uriPrefixes = [
    '', 'http://www.', 'https://www.', 'http://', 'https://', 'tel:', 'mailto:',
    'ftp://anonymous:anonymous@', 'ftp://ftp.', 'ftps://', 'sftp://', 'smb://',
    'nfs://', 'ftp://', 'dav://', 'news:', 'telnet://', 'imap:', 'rtsp://',
    'urn:', 'pop:', 'sip:', 'sips:', 'tftp:', 'bps:', 'bitcoin:', 'geo:',
    'smsto:', 'im:', 'mms:', 'ms-browser', 'market:', 'itms-services://',
    'ivyto:', 'psns://', 'share:', 'bbmi://', 'androidapp://', 'chrome://',
    'quic://', 'dict://', 'nip:', 'web3://',
  ];
}

class _Plan {
  _Plan(this.blocks, this._dataOf);
  final List<int> blocks;
  final Uint8List Function(int block) _dataOf;
  Uint8List dataOf(int block) => _dataOf(block);
}
