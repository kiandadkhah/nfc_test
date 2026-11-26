import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../state/providers.dart';

/// Location settings — the real GPS position of the relay is the basis for
/// the solar (Chebyshev) coefficients. The coordinates are persisted and
/// used by the real NFC write payload; manual entry stays available as a
/// fallback (e.g. emulators without GNSS).
class GpsScreen extends ConsumerStatefulWidget {
  const GpsScreen({super.key});

  @override
  ConsumerState<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends ConsumerState<GpsScreen> {
  bool _fixing = false;
  double? _lastAccuracy;

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final fa = isFa(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.gpsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.gpsSub, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
          const SizedBox(height: 12),
          Card(
            child: Container(
              height: 180,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF39424D), Color(0xFF232B33)],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.orange, size: 34),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(l.gpsPin,
                              style: const TextStyle(fontSize: 10, color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _fixing
                            ? l.gpsFixing
                            : (_lastAccuracy != null
                                ? l.gpsAccm(faNumInt(fa, _lastAccuracy!.round()))
                                : l.gpsAccuracy),
                        style: const TextStyle(fontSize: 10, color: Color(0xFFD6DDE4)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.gpsCoords, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 6),
                  _kv(context, l.gpsLat,
                      '${settings.gpsLat.toStringAsFixed(4)} N'),
                  _kv(context, l.gpsLng,
                      '${settings.gpsLng.toStringAsFixed(4)} E'),
                  _kv(context, l.gpsUpdated,
                      '${faNumInt(fa, settings.utcOffsetHours ~/ 1)}:${num2(fa, ((settings.utcOffsetHours % 1) * 60).round())} UTC'),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _fixing ? null : () => _getRealFix(l),
                      icon: _fixing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.my_location, size: 18),
                      label: Text(_fixing ? l.gpsFixing : l.gpsGetFix),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _editLocation(context, ref, l),
                      icon: const Icon(Icons.edit_location_alt_outlined),
                      label: Text(l.gpsManual),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(l.gpsUse,
              style: TextStyle(fontSize: 11, height: 1.95, color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }

  /// Real GPS fix — requests the location permission, reads the current
  /// position of the phone (the phone is mounted on/near the relay) and
  /// persists it for the solar coefficients.
  Future<void> _getRealFix(AppLocalizationsX l) async {
    final logger = ref.read(appLoggerProvider);
    setState(() => _fixing = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _fail(l.gpsServiceOff);
        logger.gps('GPS fix failed: location service disabled');
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        logger.gps('GPS permission requested -> ${permission.name}');
        if (permission == LocationPermission.denied) {
          _fail(l.gpsDenied);
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _fail(l.gpsDeniedForever);
        logger.gps('GPS fix failed: permission denied forever');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
      final offset = DateTime.now().timeZoneOffset;
      final utcHours = offset.inMinutes / 60.0;
      await ref.read(settingsProvider).setLocation(
            latitude: pos.latitude,
            longitude: pos.longitude,
            utcOffset: utcHours,
          );
      logger.gps('GPS fix: lat=${pos.latitude.toStringAsFixed(5)} '
          'lng=${pos.longitude.toStringAsFixed(5)} '
          'acc=${pos.accuracy.toStringAsFixed(1)}m '
          'utcOffset=$utcHours mocked=${pos.isMocked}');
      if (!mounted) return;
      setState(() => _lastAccuracy = pos.accuracy);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.gpsUpdatedToast)),
      );
    } catch (e) {
      logger.gps('GPS fix failed: $e');
      _fail(l.gpsTimeout);
    } finally {
      if (mounted) setState(() => _fixing = false);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Manual coordinate entry — persisted and used to fit the solar
  /// coefficients written to blocks 416..427.
  Future<void> _editLocation(BuildContext context, WidgetRef ref, AppLocalizationsX l) async {
    final settings = ref.read(settingsProvider);
    final latCtrl = TextEditingController(text: settings.gpsLat.toStringAsFixed(4));
    final lngCtrl = TextEditingController(text: settings.gpsLng.toStringAsFixed(4));
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.gpsCoords),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(labelText: l.gpsLat),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: lngCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(labelText: l.gpsLng),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    final lat = double.tryParse(latCtrl.text.replaceAll(',', '.'));
    final lng = double.tryParse(lngCtrl.text.replaceAll(',', '.'));
    if (ok == true && lat != null && lng != null && lat.abs() <= 90 && lng.abs() <= 180) {
      await ref.read(settingsProvider).setLocation(latitude: lat, longitude: lng);
      ref.read(appLoggerProvider).gps(
          'manual location set: lat=$lat lng=$lng');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.gpsUpdatedToast)),
        );
      }
    } else if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.gpsInvalid)),
      );
    }
  }

  Widget _kv(BuildContext context, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(k, style: TextStyle(fontSize: 12, color: Theme.of(context).hintColor))),
            Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..strokeWidth = 1;
    const step = 26.0;
    for (var x = 0.0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
