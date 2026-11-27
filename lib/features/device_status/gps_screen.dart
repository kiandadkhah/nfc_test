import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/map/map_tiles.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_toasts.dart';
import '../../state/providers.dart';

/// Location settings — the real GPS position of the relay is the basis for
/// the solar (Chebyshev) coefficients. The position is shown on a REAL map
/// and manual entry is marker picking on the same map.
///
/// v4.3 fixes of the field report:
///  · the tiles come from the Iranian map.ir service (fast inside Iran),
///    with an automatic OpenStreetMap fallback;
///  · the map camera FOLLOWS the marker — a fresh GPS fix moves both, so
///    the marker can no longer sit in another city than the visible tiles
///    («مکان نما در مشهد ولی تصویر اصفهان»);
///  · the map picker's GPS button fetches the REAL current position and
///    re-centers both the camera and the marker.
class GpsScreen extends ConsumerStatefulWidget {
  const GpsScreen({super.key});

  @override
  ConsumerState<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends ConsumerState<GpsScreen> {
  final MapController _mapController = MapController();
  bool _fixing = false;
  double? _lastAccuracy;
  double? _cameraLat;
  double? _cameraLng;

  /// Keeps the map camera glued to the marker — called whenever the stored
  /// device location changes (fresh GPS fix or a picked point), so the
  /// marker is always inside the visible map area.
  void _followMarker(LatLng point) {
    final same =
        _cameraLat != null && _cameraLng != null &&
            (point.latitude - _cameraLat!).abs() < 1e-9 &&
            (point.longitude - _cameraLng!).abs() < 1e-9;
    if (same) return;
    _cameraLat = point.latitude;
    _cameraLng = point.longitude;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(point, _zoomOf(point));
      } catch (_) {
        // controller not attached yet — the initialCenter already matches
      }
    });
  }

  double _zoomOf(LatLng point) => 12;

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final fa = isFa(context);
    final settings = ref.watch(settingsProvider);
    final latLng = LatLng(settings.gpsLat, settings.gpsLng);
    // v4.3 — the camera follows every location change (GPS fix / pick).
    ref.listen(settingsProvider, (_, __) {
      final s = ref.read(settingsProvider);
      _followMarker(LatLng(s.gpsLat, s.gpsLng));
    });
    _followMarker(latLng);

    return Scaffold(
      appBar: AppBar(title: Text(l.gpsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.gpsSub, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            margin: EdgeInsets.zero,
            child: SizedBox(
              height: 240,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: latLng,
                      initialZoom: _zoomOf(latLng),
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      KianexTileLayer(
                        onSourceFellBack: () {
                          if (mounted) {
                            showAppMessage(context, l.mapIrFallback, isError: true);
                          }
                        },
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: latLng,
                            width: 60,
                            height: 60,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on,
                                    color: AppTheme.orange, size: 34),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.72),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(l.gpsPin,
                                      style: const TextStyle(
                                          fontSize: 9, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        _fixing
                            ? l.gpsFixing
                            : (_lastAccuracy != null
                                ? l.gpsAccm(
                                    faNumInt(fa, _lastAccuracy!.round()))
                                : l.gpsAccuracy),
                        style: const TextStyle(
                            fontSize: 10, color: Color(0xFFD6DDE4)),
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
                      onPressed: () => _pickOnMap(context, latLng, l),
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
  /// persists it for the solar coefficients. The map follows the new
  /// marker through [ref.listen] → [_followMarker]. When the service is
  /// off or the permission was denied, the user is guided to the matching
  /// system-settings screen. [v4.1 field report]
  Future<void> _getRealFix(AppLocalizationsX l) async {
    final logger = ref.read(appLoggerProvider);
    setState(() => _fixing = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        logger.gps('GPS fix failed: location service disabled');
        await _guideToSettings(
          title: l.gateLocServiceTitle,
          text: l.gateLocServiceText,
          actionLabel: l.gateGoSettings,
          open: () async => Geolocator.openLocationSettings(),
        );
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        logger.gps('GPS permission requested -> ${permission.name}');
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        logger.gps('GPS fix failed: permission ${permission.name}');
        await _guideToSettings(
          title: l.gateLocPermTitle,
          text: l.gateLocPermText,
          actionLabel: l.gateGoSettings,
          open: () async => Geolocator.openAppSettings(),
        );
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
      showAppMessage(context, l.gpsUpdatedToast);
    } catch (e) {
      logger.gps('GPS fix failed: $e');
      if (mounted) showAppMessage(context, l.gpsTimeout, isError: true);
    } finally {
      if (mounted) setState(() => _fixing = false);
    }
  }

  /// Guidance dialog → the matching system settings screen.
  Future<void> _guideToSettings({
    required String title,
    required String text,
    required String actionLabel,
    required Future<void> Function() open,
  }) async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.settings_suggest_outlined,
                color: AppTheme.orangeDeep, size: 22),
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
        // settings screen unavailable on this device — ignore
      }
    }
  }

  /// Manual entry — marker picking on the real map. [v4.1 field report:
  /// «ورودی دستی باید انتخاب نشانگر روی نقشه باشد»]
  Future<void> _pickOnMap(BuildContext context, LatLng initial, AppLocalizationsX l) async {
    final picked = await Navigator.of(context).push<LatLng>(
      MaterialPageRoute(builder: (_) => MapPickerScreen(initial: initial)),
    );
    if (picked != null) {
      await ref.read(settingsProvider).setLocation(
            latitude: picked.latitude,
            longitude: picked.longitude,
          );
      ref.read(appLoggerProvider).gps(
          'manual location set on map: lat=${picked.latitude} lng=${picked.longitude}');
      if (context.mounted) {
        showAppMessage(context, l.gpsUpdatedToast);
      }
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

/// Full-screen map picker — tap moves the marker, «تأیید» returns the
/// picked coordinates.
///
/// v4.3: the GPS button now fetches the REAL current position of the phone
/// (permission + service checks included) and re-centers both the camera
/// and the marker — the old button only jumped back to the stale opening
/// point, so «دریافت موقعیت با GPS» never showed the current coordinates.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({required this.initial, super.key});

  final LatLng initial;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng _picked = widget.initial;
  late final MapController _controller = MapController();
  bool _fixing = false;

  Future<void> _usePhoneGps(AppLocalizationsX l) async {
    if (_fixing) return;
    setState(() => _fixing = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) showAppMessage(context, l.gpsTimeout, isError: true);
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) showAppMessage(context, l.gpsTimeout, isError: true);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final here = LatLng(pos.latitude, pos.longitude);
      _controller.move(here, 14);
      setState(() => _picked = here);
    } catch (_) {
      if (mounted) showAppMessage(context, l.gpsTimeout, isError: true);
    } finally {
      if (mounted) setState(() => _fixing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.gpsMapTitle)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: widget.initial,
                    initialZoom: 12,
                    onTap: (_, point) => setState(() => _picked = point),
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    KianexTileLayer(
                      onSourceFellBack: () {
                        if (mounted) {
                          showAppMessage(context, l.mapIrFallback, isError: true);
                        }
                      },
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _picked,
                          width: 46,
                          height: 46,
                          child: const Icon(Icons.location_on,
                              color: AppTheme.orange, size: 42),
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  top: 8,
                  left: 10,
                  child: _fixing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(18)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${l.gpsLat}: ${_picked.latitude.toStringAsFixed(4)}   '
                    '${l.gpsLng}: ${_picked.longitude.toStringAsFixed(4)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  Text(l.gpsMapHint,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 10.5,
                          height: 1.8,
                          color: Theme.of(context).hintColor)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _fixing ? null : () => _usePhoneGps(l),
                          icon: _fixing
                              ? const SizedBox(
                                  width: 15,
                                  height: 15,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.my_location, size: 17),
                          label: Text(l.gpsPhonePos),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(_picked),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(l.confirm),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
