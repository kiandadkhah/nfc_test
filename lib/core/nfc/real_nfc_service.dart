/// The production NFC service — executes the SOT protocol over a physical
/// ST25DV16KC tag through [Iso15693TagLink].
///
/// Contract notes:
///  · A blank logger identifies an unpowered relay (the MCU never wrote
///    it) — the protocol halts and the UI shows the approved power-off
///    decision (settings → block; programs → cancel / continue without
///    clock & date update).
///  · Any protocol failure surfaces as [FailureKind.stepFailed] with the
///    failed step; the app restarts from step 1 and offers guidance after
///    two attempts (RC-10).
///  · Every operation is reported to [AppLogger] so field tests return a
///    complete diagnostic log with the test report.
library;

import 'dart:async';

import '../constants/domain.dart';
import '../logging/app_logger.dart';
import '../models/program.dart';
import 'memory_map.dart';
import 'nfc_service.dart';
import 'sot_protocol.dart';
import 'tag_link.dart';

class RealNfcService implements NfcService {
  RealNfcService({AppLogger? logger}) : _log = logger ?? AppLogger.instance;

  final AppLogger _log;

  Iso15693TagLink? _link;
  SotProtocol? _engine;

  /// Payload inputs — wired by the app layer before every transfer.
  List<Program> enabledProgramsSource = const [];
  double latitude = 35.6892;
  double longitude = 51.3890;
  double utcOffsetHours = 3.5;

  @override
  Future<bool> pollUntilFree() async {
    // §4.1 arbitration: try twice within the 5 s budget before reporting
    // the tag as busy (OI-02).
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    var attempt = 0;
    while (DateTime.now().isBefore(deadline)) {
      attempt += 1;
      Iso15693TagLink? link;
      try {
        link = await Iso15693TagLink.open(
          timeout: const Duration(seconds: 45),
          onEvent: _log.nfc,
        );
        if (link == null) {
          // open() returns null when the poll window ended without a tag.
          _log.nfc('poll: no tag presented (attempt $attempt)');
          if (attempt >= 2) break;
          await Future<void>.delayed(const Duration(milliseconds: 400));
          continue;
        }
        // Probe: a successful onboarding read means the tag is reachable.
        await link.readBlock(SotMemoryMap.blockCc);
        _link = link;
        _log.nfc('poll: tag reachable (attempt $attempt)');
        return true;
      } on TagLinkException catch (e) {
        await link?.close();
        if (e.message == 'nfc_disabled') {
          // Fail fast — retrying cannot fix a disabled NFC adapter.
          rethrow;
        }
        _log.nfc('poll: probe failed (attempt $attempt)');
      } catch (e) {
        await link?.close();
        _log.nfc('poll: no tag presented (attempt $attempt): $e');
      }
      if (attempt >= 2) break;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return false;
  }

  @override
  Stream<WriteProgress> write(WriteMode mode,
      {int fromStep = 1, bool skipClock = false}) {
    final controller = StreamController<WriteProgress>();
    Future<void>(() async {
      try {
        var link = _link;
        if (link == null || !link.isOpen) {
          _log.nfc('write: opening tag session (poll phase)');
          final ok = await pollUntilFree();
          if (!ok) {
            _log.nfc('write: tag never became free — RC-10 path');
            controller.add(const WriteProgress(
              step: 0,
              status: StepStatus.failed,
              failure: FailureKind.tagBusy,
            ));
            return;
          }
          link = _link;
        }
        final request = SotWriteRequest(
          mode: mode,
          enabledPrograms: enabledProgramsSource,
          deviceTime: DateTime.now(),
          latitude: latitude,
          longitude: longitude,
          utcOffsetHours: utcOffsetHours,
        );
        _log.nfc('write: protocol start mode=${mode.name} fromStep=$fromStep '
            'skipClock=$skipClock programs=${enabledProgramsSource.length} '
            'lat=$latitude lng=$longitude utc=$utcOffsetHours');
        final engine = SotProtocol(link!, logger: _log);
        _engine = engine;
        try {
          await engine.run(
            request,
            fromStep: fromStep,
            skipClock: skipClock,
            onProgress: (p) => controller.add(p),
          );
        } finally {
          await link.close();
          _link = null;
          _engine = null;
        }
      } on TagLinkException catch (e) {
        // The engine already emitted the per-step failure; close cleanly.
        await _link?.close();
        _link = null;
        _engine?.cancel();
        _engine = null;
        _log.nfc('write: aborted — ${e.message} code=${e.errorCode}');
        controller.add(WriteProgress(
          step: 0,
          status: StepStatus.failed,
          failure: e.message.contains('busy') || e.message.contains('no_tag')
              ? FailureKind.tagBusy
              : FailureKind.stepFailed,
          failedStep: e.message.contains('busy') || e.message.contains('no_tag')
              ? null
              : 0,
        ));
      } catch (e) {
        await _link?.close();
        _link = null;
        _engine = null;
        _log.nfc('write: unexpected failure — $e');
        controller.add(const WriteProgress(
          step: 0,
          status: StepStatus.failed,
          failure: FailureKind.stepFailed,
          failedStep: 0,
        ));
      } finally {
        await controller.close();
      }
    });
    return controller.stream;
  }

  /// §4.10 consistent logger read mapped onto the dashboard model.
  @override
  Future<DeviceStatus> readLogger(DeviceStatus current) async {
    _log.nfc('readLogger: opening tag session');
    final link = _link ??
        await Iso15693TagLink.open(
          timeout: const Duration(seconds: 30),
          onEvent: _log.nfc,
        );
    if (link == null) {
      _log.nfc('readLogger: no tag presented');
      throw const TagLinkException('no_tag');
    }
    _link = link;
    try {
      final engine = SotProtocol(link, logger: _log);
      final blocks = await engine.readLoggerBlocks();
      final snap = LoggerSnapshot.fromBlocks(blocks);
      _log.nfc('readLogger: run=${snap.runProgramCounter} ongoing=${snap.ongoingEvent} '
          'oh=${snap.operatingHour} ohOn=${snap.operatingHourOn} cn=${snap.operatingHourCn} '
          'err=${snap.internalError} logCrc=0x${snap.logCrc32.toRadixString(16)} '
          'planningCode=0x${snap.processRecordLog.toRadixString(16)}');
      final unpowered = snap.runProgramCounter == 0 ||
          snap.runProgramCounter == 0xFFFF ||
          snap.logCrc32 == 0 ||
          snap.logCrc32 == 0xFFFFFFFF;
      var runVersion = unpowered ? 0 : snap.runProgramCounter;
      var pending = current.pendingAccept;
      if (pending && !unpowered) {
        // The MCU adopts the pending version once it is running again.
        runVersion = current.writtenVersion;
        pending = false;
      }
      return DeviceStatus(
        runVersion: runVersion,
        writtenVersion: current.writtenVersion,
        pendingAccept: pending,
        hasOngoing: snap.ongoingEvent != 0,
        // SOT defines Ongoing_Event as the event number only — the relay
        // state of the ongoing event is not exposed by the logger area.
        ongoingRelayOn: false,
        operatingHour: snap.operatingHour,
        outputOnHour: snap.operatingHourOn,
        relayOps: snap.operatingHourCn,
        internalError: snap.internalError,
        logCrc: snap.logCrc32,
        lastRead: DateTime.now(),
      );
    } finally {
      await link.close();
      _link = null;
    }
  }

  /// Reads the onboarding area (blocks 0..15) + tag system info and
  /// identifies the device model. Used by the device sheet and as the
  /// «بررسی و شناسایی رله» entry point.
  @override
  Future<TagIdentity> identify({Duration timeout = const Duration(seconds: 45)}) async {
    _log.nfc('identify: opening tag session');
    final link = await Iso15693TagLink.open(timeout: timeout, onEvent: _log.nfc);
    if (link == null) {
      _log.nfc('identify: no tag presented');
      throw const TagLinkException('no_tag');
    }
    _link = link;
    try {
      final engine = SotProtocol(link, logger: _log);
      final ndefUri = await engine.readOnboardingUri();
      final info = TagSystemInfo(
        totalBlocks: link.totalBlocks,
        blockSize: link.blockSize,
        icRef: link.icRef,
        dsfid: 0,
        afid: 0,
        twoByteAddressing: link.totalBlocks > 256,
      );
      const requiredBlocks = SotMemoryMap.planningEndBlock + 1;
      final enoughMemory = link.totalBlocks >= requiredBlocks;
      // The factory NDEF URI identifies the product — the accepted prefix
      // is the KIANEX PTS50 product page (NdefContract). [v4.1: exact URL]
      final modelMatched = NdefContract.uriMatchesProduct(ndefUri);
      _log.nfc('identify: uri="$ndefUri" expected="${NdefContract.productUrl}" '
          'prefix="${NdefContract.productUrlPrefix}" '
          'model=${info.modelName} '
          'blocks=${link.totalBlocks}/${link.blockSize}B '
          'icRef=0x${link.icRef.toRadixString(16)} '
          'enoughMemory=$enoughMemory modelMatched=$modelMatched');
      return TagIdentity(
        uid: link.tagUid,
        modelName: info.modelName,
        totalBlocks: link.totalBlocks,
        blockSize: link.blockSize,
        icRef: link.icRef,
        ndefUri: ndefUri,
        enoughMemory: enoughMemory,
        modelMatched: modelMatched,
      );
    } finally {
      await link.close();
      _link = null;
    }
  }

  /// Cancels a running protocol (the «لغو» button).
  @override
  Future<void> cancelActiveOperation() async {
    _engine?.cancel();
    await _link?.close();
    _link = null;
    _engine = null;
    _log.nfc('cancel: active operation stopped');
  }
}
