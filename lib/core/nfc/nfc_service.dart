/// NFC service abstraction. `RealNfcService` executes the SOT protocol over
/// a physical ST25DV16KC tag (ISO 15693 / NFC Type 5). The QA simulator of
/// the earlier design-review builds was removed — the production app talks
/// to the real tag only. [§4.5, §4.10]
library;

import 'dart:async';

import '../models/program.dart';

enum WriteMode { settingsOnly, programAndSettings }

enum StepStatus { pending, active, done, failed }

enum FailureKind { tagBusy, stepFailed }

class WriteProgress {
  const WriteProgress({
    required this.step,
    required this.status,
    this.failure,
    this.failedStep,
    this.completed = false,
    this.newVersion,
    this.powerOff = false,
    this.doneCount,
  });

  final int step; // 1..8 (0 = polling phase)
  final StepStatus status;
  final FailureKind? failure;
  final int? failedStep;
  final bool completed;
  final int? newVersion;

  /// Raised once when the relay answers but has no power supply — the
  /// caller decides: settings → block; programs → cancel / continue
  /// without clock & date update. [v2.7 QA scenario]
  final bool powerOff;

  /// Number of steps already done (progress arc), when known.
  final int? doneCount;
}

/// Result of a successful tag identification (device sheet / onboarding).
class TagIdentity {
  const TagIdentity({
    required this.uid,
    required this.modelName,
    required this.totalBlocks,
    required this.blockSize,
    required this.icRef,
    required this.ndefUri,
    required this.enoughMemory,
    required this.modelMatched,
  });

  final String uid;
  final String modelName;
  final int totalBlocks;
  final int blockSize;
  final int icRef;
  final String ndefUri;

  /// False when the tag exists but is too small for the shared-memory
  /// layout (blocks 0..431 + logger area).
  final bool enoughMemory;

  /// True when the factory NDEF payload carries the KIANEX model marker.
  final bool modelMatched;
}

/// The eight protocol steps of SOT table 4-4, in mandatory order.
const List<String> protocolStepKeys = [
  'readOnboarding',
  'readLogger',
  'writeStartCode',
  'writeData',
  'writeCompleteCode',
  'readBackData',
  'compareCrc',
  'writeEndCode',
];

abstract class NfcService {
  /// Polls tag availability in 200–500 ms cycles up to 5 s (§4.10).
  /// Returns false when the tag never becomes free (RC-10 path).
  Future<bool> pollUntilFree();

  /// Runs the 8-step write protocol, emitting progress events.
  /// [fromStep] > 1 resumes an interrupted protocol (relay-unpowered
  /// continue path); [skipClock] suppresses the clock/date sections of the
  /// payload when the device is known to be unpowered.
  Stream<WriteProgress> write(WriteMode mode, {int fromStep = 1, bool skipClock = false});

  /// Consistent logger read per §4.10: register → data + LOG_CRC32 →
  /// re-read register → restart if a process began mid-read → CRC check.
  Future<DeviceStatus> readLogger(DeviceStatus current);

  /// Reads the onboarding area + system info and identifies the device
  /// model (the «بررسی و شناسایی رله» flow of the device sheet).
  Future<TagIdentity> identify({Duration timeout = const Duration(seconds: 45)});

  /// Cancels a running protocol / session (the «لغو» button).
  Future<void> cancelActiveOperation();
}
