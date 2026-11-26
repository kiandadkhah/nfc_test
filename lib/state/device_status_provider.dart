/// Device status state — consistent logger read per §4.10 against the real
/// ST25DV16KC tag. Failures surface as an error state with a retry path;
/// the earlier simulator fallback was removed with the QA simulator.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/models/program.dart';
import 'providers.dart';

class DeviceStatusController extends ChangeNotifier {
  DeviceStatusController(this._ref);

  final Ref _ref;
  DeviceStatus? status;

  /// Human-readable failure of the last read (null when the last read
  /// succeeded or no read was attempted yet).
  String? lastError;

  bool reading = false;

  Future<void> refresh() async {
    if (reading) return;
    final logger = _ref.read(appLoggerProvider);
    reading = true;
    lastError = null;
    notifyListeners();
    final current = status ??
        DeviceStatus(
          runVersion: 0,
          writtenVersion: 0,
          pendingAccept: false,
          hasOngoing: false,
          ongoingRelayOn: false,
          operatingHour: 0,
          outputOnHour: 0,
          relayOps: 0,
          internalError: 0,
          logCrc: 0,
          lastRead: DateTime.now(),
        );
    try {
      // Real §4.10 consistent read over ISO 15693.
      status = await _ref.read(nfcServiceProvider).readLogger(current);
      logger.nfc('device status refreshed — run=${status!.runVersion} '
          'pending=${status!.pendingAccept}');
    } on Exception catch (e) {
      lastError = e.toString();
      logger.error('device status read failed: $e');
    }
    reading = false;
    notifyListeners();
  }
}
