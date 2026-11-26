/// NFC write-flow state — mirrors the 8-step protocol UX
/// (attempt counter, per-step statuses, outcome, RC-10 path) plus the
/// v2.7 relay-unpowered decision (settings → block; programs →
/// continue without clock update / cancel). Runs the real transport only.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/nfc/nfc_service.dart';
import '../core/nfc/real_nfc_service.dart';
import 'providers.dart';

class WriteFlowController extends ChangeNotifier {
  WriteFlowController(this._ref);

  final Ref _ref;
  StreamSubscription<WriteProgress>? _sub;

  WriteMode? mode;
  int attempt = 0;

  final List<StepStatus> stepStatus =
      List<StepStatus>.filled(8, StepStatus.pending);

  bool running = false;
  bool polling = false;
  FailureKind? failure;
  int? failedStep;
  bool completed = false;
  int? newVersion;

  /// True after the relay was detected without a power supply and the
  /// protocol halted at the identification step.
  bool powerOffDetected = false;

  /// True once the user chose «ادامه ارسال» on the unpowered relay —
  /// clock/date/location are NOT updated in this operation.
  bool skipClock = false;

  void begin(WriteMode m) {
    mode = m;
    attempt = 0;
    completed = false;
    failure = null;
    failedStep = null;
    newVersion = null;
    powerOffDetected = false;
    skipClock = false;
    _resetSteps();
    notifyListeners();
  }

  void _resetSteps() {
    for (var i = 0; i < stepStatus.length; i++) {
      stepStatus[i] = StepStatus.pending;
    }
    running = false;
    polling = false;
    failure = null;
    failedStep = null;
    completed = false;
    powerOffDetected = false;
  }

  Future<void> start() async {
    if (mode == null || running) return;
    _resetSteps();
    attempt += 1;
    running = true;
    polling = true;
    notifyListeners();

    final service = _ref.read(nfcServiceProvider);
    final logger = _ref.read(appLoggerProvider);
    // Payload inputs for the real transport.
    final programs = _ref.read(programsProvider);
    final settings = _ref.read(settingsProvider);
    if (service is RealNfcService) {
      service
        ..enabledProgramsSource = programs.enabledPrograms
        ..latitude = settings.gpsLat
        ..longitude = settings.gpsLng
        ..utcOffsetHours = settings.utcOffsetHours;
    }
    logger.action('write started — mode=${mode!.name}, attempt=$attempt, '
        'programs=${programs.enabledPrograms.length}');

    _sub?.cancel();
    _sub = service.write(mode!, fromStep: 1, skipClock: skipClock).listen((p) {
      _handle(p);
    });
  }

  void _handle(WriteProgress p) {
    final logger = _ref.read(appLoggerProvider);
    if (p.step == 0) {
      polling = false;
      running = false;
      failure = p.failure;
      logger.warn('write flow: pre-protocol failure (${p.failure})');
      notifyListeners();
      return;
    }
    polling = false;
    if (p.powerOff) {
      // Step 1/2 halted — relay has no power supply.
      running = false;
      powerOffDetected = true;
      logger.warn('write flow halted: relay without power supply');
      notifyListeners();
      return;
    }
    if (p.step >= 1 && p.step <= 8) {
      stepStatus[p.step - 1] = p.status;
    }
    if (p.status == StepStatus.failed) {
      running = false;
      failure = p.failure;
      failedStep = p.failedStep;
    }
    if (p.completed) {
      running = false;
      completed = true;
      newVersion = p.newVersion;
      logger.action('write completed — new version=${p.newVersion}');
    }
    notifyListeners();
  }

  /// «ادامه ارسال» on the unpowered relay: step 1 is marked done and the
  /// protocol resumes from step 2 without updating clock/date/location.
  Future<void> continueWithoutClock() async {
    if (mode == null || running || !powerOffDetected) return;
    powerOffDetected = false;
    skipClock = true;
    stepStatus[0] = StepStatus.done;
    running = true;
    notifyListeners();

    final service = _ref.read(nfcServiceProvider);
    final logger = _ref.read(appLoggerProvider);
    logger.action('write continues without clock sync (unpowered relay)');
    _sub?.cancel();
    _sub = service.write(mode!, fromStep: 2, skipClock: true).listen((p) {
      _handle(p);
    });
  }

  /// «متوجه شدم» on the settings-only unpowered dialog — back to confirm.
  void ackSettingsBlocked() {
    _sub?.cancel();
    _sub = null;
    _resetSteps();
    notifyListeners();
  }

  /// Cancels a running transfer (the «لغو» button) — stops the stream and
  /// returns the flow to the idle state.
  void cancel() {
    _sub?.cancel();
    _sub = null;
    _resetSteps();
    notifyListeners();
  }

  void resetForConfirm() {
    completed = false;
    failure = null;
    failedStep = null;
    newVersion = null;
    _resetSteps();
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
