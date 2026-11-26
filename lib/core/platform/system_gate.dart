/// System readiness gate (v4.1) — the startup permission flow requested in
/// the v4.0.1 field report:
///   · the location permission is requested at the first start;
///   · when the phone's location service is off, the user is guided into
///     the system location settings;
///   · when the permission is denied forever, the user is guided into the
///     app settings;
///   · when the phone has NFC hardware but the adapter is off, the user is
///     guided into the NFC settings;
///   · phones without NFC hardware get an explanatory notice.
///
/// Every state change is reported to the application logger, and the home
/// screen keeps a compact status strip while something is not ready.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:geolocator/geolocator.dart';

import '../logging/app_logger.dart';
import '../state/app_providers.dart';
import '../widgets/app_toasts.dart';

/// Native bridge for the system screens Flutter cannot reach directly
/// (the Android NFC settings panel). Implemented in MainActivity.kt.
const MethodChannel _systemChannel = MethodChannel('kianex/system');

/// NFC/Location readiness snapshot shown on the home screen.
class SystemReadiness {
  const SystemReadiness({
    required this.nfcSupported,
    required this.nfcEnabled,
    required this.locationGranted,
    required this.locationServiceOn,
  });

  final bool nfcSupported;
  final bool nfcEnabled;
  final bool locationGranted;
  final bool locationServiceOn;

  bool get allGood => nfcSupported && nfcEnabled && locationGranted && locationServiceOn;
}

/// Checks the hardware/permission state (no dialogs).
Future<SystemReadiness> readSystemReadiness() async {
  var nfcSupported = false;
  var nfcEnabled = false;
  try {
    final a = await FlutterNfcKit.nfcAvailability;
    nfcSupported = a != NFCAvailability.not_supported;
    nfcEnabled = a == NFCAvailability.available;
  } catch (_) {
    // detection unavailable — treat as supported-but-off so the user can
    // still reach the settings screen
    nfcSupported = true;
    nfcEnabled = false;
  }
  var granted = false;
  var serviceOn = false;
  try {
    final p = await Geolocator.checkPermission();
    granted = p == LocationPermission.always || p == LocationPermission.whileInUse;
    serviceOn = await Geolocator.isLocationServiceEnabled();
  } catch (_) {
    // geolocator unavailable (unit tests) — keep defaults
  }
  return SystemReadiness(
    nfcSupported: nfcSupported,
    nfcEnabled: nfcEnabled,
    locationGranted: granted,
    locationServiceOn: serviceOn,
  );
}

/// Opens the Android NFC settings panel; silently ignores devices without
/// the corresponding intent handler.
Future<void> openNfcSettings() async {
  try {
    await _systemChannel.invokeMethod<void>('openNfcSettings');
  } catch (_) {
    // platform channel unavailable — nothing else to try
  }
}

/// Runs the startup gate — once per app session, so the dialogs re-appear
/// on every app start while something is not ready (the requested
/// behaviour: «اپلیکیشن باید در ابتدا مجوزها را بگیرد») but never twice in
/// one session.
Future<void> runStartupGate(BuildContext context) async {
  final logger = AppLogger.instance;
  final readiness = await readSystemReadiness();
  logger.action('startup gate: nfc=${readiness.nfcSupported ? (readiness.nfcEnabled ? 'on' : 'off') : 'absent'} '
      'locPerm=${readiness.locationGranted} locService=${readiness.locationServiceOn}');
  if (!context.mounted) return;

  // 1 — NFC hardware present but adapter off → guide to NFC settings.
  if (readiness.nfcSupported && !readiness.nfcEnabled) {
    await _guide(
      context,
      title: L(context).gateNfcOffTitle,
      text: L(context).gateNfcOffText,
      actionLabel: L(context).gateGoSettings,
      open: openNfcSettings,
    );
  }
  // 2 — no NFC hardware → informational notice only.
  if (!readiness.nfcSupported) {
    logger.action('startup gate: device has no NFC hardware');
    if (context.mounted) {
      showAppMessage(context, L(context).gateNfcMissing, isError: true);
    }
  }
  if (!context.mounted) return;

  // 3 — location permission. Every platform call is guarded: a plugin
  // hiccup (or the unit-test environment without native channels) must
  // never crash the gate — the step is skipped and logged instead.
  var permission = LocationPermission.unableToDetermine;
  try {
    permission = await Geolocator.checkPermission();
  } catch (e) {
    logger.gps('startup gate: permission check failed: $e');
  }
  if (permission == LocationPermission.denied) {
    try {
      permission = await Geolocator.requestPermission();
      logger.gps('startup gate: permission requested -> ${permission.name}');
      if (context.mounted) {
        showAppMessage(context, L(context).gateLocAsked);
      }
    } catch (e) {
      logger.gps('startup gate: permission request failed: $e');
    }
  }
  if (!context.mounted) return;

  // 4 — permission denied forever → app settings.
  if (permission == LocationPermission.deniedForever) {
    await _guide(
      context,
      title: L(context).gateLocPermTitle,
      text: L(context).gateLocPermText,
      actionLabel: L(context).gateGoSettings,
      open: () async => Geolocator.openAppSettings(),
    );
    if (!context.mounted) return;
  }

  // 5 — location service off → location settings.
  if (!context.mounted) return;
  var serviceOn = readiness.locationServiceOn;
  try {
    serviceOn = await Geolocator.isLocationServiceEnabled();
  } catch (e) {
    logger.gps('startup gate: service check failed: $e');
  }
  if (!serviceOn) {
    await _guide(
      context,
      title: L(context).gateLocServiceTitle,
      text: L(context).gateLocServiceText,
      actionLabel: L(context).gateGoSettings,
      open: () async => Geolocator.openLocationSettings(),
    );
  }
}

/// Reusable guidance dialog → system screen.
Future<void> _guide(
  BuildContext context, {
  required String title,
  required String text,
  required String actionLabel,
  required Future<void> Function() open,
}) async {
  if (!context.mounted) return;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings_suggest_outlined,
              color: Color(0xFFE8720A), size: 22),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
        ],
      ),
      content: Text(text, style: const TextStyle(fontSize: 12.5, height: 1.9)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(L(dialogContext).gateLater),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(actionLabel),
        ),
      ],
    ),
  );
  if (ok == true) {
    try {
      await open();
    } catch (_) {
      // settings screen unavailable on this device
    }
  }
}

/// Compact readiness strip for the home screen — visible only while
/// something is not ready; the action button re-runs the startup gate.
class SystemStatusStrip extends StatefulWidget {
  const SystemStatusStrip({super.key});

  @override
  State<SystemStatusStrip> createState() => _SystemStatusStripState();
}

class _SystemStatusStripState extends State<SystemStatusStrip> {
  SystemReadiness? _readiness;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final r = await readSystemReadiness();
    if (mounted) setState(() => _readiness = r);
  }

  @override
  Widget build(BuildContext context) {
    final r = _readiness;
    if (r == null || r.allGood) return const SizedBox.shrink();
    final l = L(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFB4570A).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
            color: const Color(0xFFE8720A).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 18, color: Color(0xFFB4570A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.gateStripHint,
              style: const TextStyle(
                  fontSize: 11, height: 1.7, color: Color(0xFFB4570A),
                  fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              await runStartupGate(context);
              _refresh();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 34),
            ),
            child: Text(l.gateGoSettings,
                style: const TextStyle(
                    fontSize: 11.5, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
