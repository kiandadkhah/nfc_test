/// Riverpod providers for the app (change-notifier based, no codegen).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/logging/app_logger.dart';
import '../core/nfc/nfc_service.dart';
import '../core/nfc/real_nfc_service.dart';
import '../core/settings/settings_controller.dart';
import 'device_status_provider.dart';
import 'programs_provider.dart';
import 'write_flow_provider.dart';

/// Overridden in main.dart with the controller backed by shared_preferences:
/// `settingsProvider.overrideWith((ref) => settings)`.
final settingsProvider = ChangeNotifierProvider<SettingsController>(
  (ref) => throw UnimplementedError('override settingsProvider in main.dart'),
);

final programsProvider =
    ChangeNotifierProvider<ProgramsController>((ref) => ProgramsController());

/// Application logger (file-backed JSONL) — shared singleton.
final appLoggerProvider = Provider<AppLogger>((ref) => AppLogger.instance);

/// The production NFC service — real ST25DV16KC transport (ISO 15693).
/// The design-review simulator of the earlier prototypes was removed; every
/// NFC operation talks to the physical tag.
final nfcServiceProvider = Provider<NfcService>((ref) {
  final service = RealNfcService(logger: ref.watch(appLoggerProvider));
  ref.onDispose(() => service.cancelActiveOperation());
  return service;
});

final writeFlowProvider =
    ChangeNotifierProvider<WriteFlowController>((ref) => WriteFlowController(ref));

final deviceStatusProvider =
    ChangeNotifierProvider<DeviceStatusController>((ref) => DeviceStatusController(ref));
