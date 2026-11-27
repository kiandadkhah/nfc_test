/// Map tile source — v4.3 field report: «پیشنهاد می شود از سرویس های ایرانی
/// برای نقشه استفاده شود» (https://map.ir). The Iranian raster tiles load
/// fast inside Iran where the default OpenStreetMap endpoints crawl.
///
/// Design:
///   · The map.ir access key is injected at build time with
///     `--dart-define=MAP_IR_API_KEY=…`; when it is absent the layer falls
///     back to the key-less OpenStreetMap tiles automatically, so every
///     build keeps a working map.
///   · map.ir requires the key as an `x-api-key` HTTP header — the
///     [NetworkTileProvider] is created with it.
///   · If map.ir is unreachable (network change, expired key) the layer
///     counts the failed tiles and switches the session to OpenStreetMap
///     instead of leaving a grey map (the v4.1.0 grey-screen complaint).
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Build-time key (GitHub Actions passes it as a secret). The default is
/// empty — the delivered pipeline sets it; a local build without the key
/// simply renders the OSM fallback.
const String kMapIrApiKey = String.fromEnvironment('MAP_IR_API_KEY');

/// map.ir raster tile endpoint (Shiveh map tiles).
const String kMapIrUrlTemplate = 'https://map.ir/shiveh/{z}/{x}/{y}.png';

/// Key-less fallback tiles.
const String kOsmUrlTemplate = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

/// Number of consecutive failed tiles that flips the layer to OSM.
const int _kTileFailureSwitchAfter = 12;

/// The tile layer used by both map screens (location card + map picker).
/// Stateful: counts consecutive tile errors and switches map.ir → OSM.
class KianexTileLayer extends StatefulWidget {
  const KianexTileLayer({super.key, this.onSourceFellBack});

  /// Called once when the layer gives up on map.ir and switches to the
  /// OpenStreetMap fallback (the UI shows a hint).
  final void Function()? onSourceFellBack;

  @override
  State<KianexTileLayer> createState() => _KianexTileLayerState();
}

class _KianexTileLayerState extends State<KianexTileLayer> {
  bool _useFallback = kMapIrApiKey.isEmpty;
  int _failures = 0;

  void _noteFailure() {
    if (_useFallback) return;
    _failures += 1;
    if (_failures >= _kTileFailureSwitchAfter && mounted) {
      setState(() => _useFallback = true);
      widget.onSourceFellBack?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_useFallback) {
      return TileLayer(
        urlTemplate: kOsmUrlTemplate,
        userAgentPackageName: 'ir.kianex.kianex_pts50n1_app',
        errorTileCallback: (_, __, ___) {},
      );
    }
    return TileLayer(
      urlTemplate: kMapIrUrlTemplate,
      userAgentPackageName: 'ir.kianex.kianex_pts50n1_app',
      tileProvider: NetworkTileProvider(
        headers: const {'x-api-key': kMapIrApiKey},
      ),
      errorTileCallback: (_, __, ___) => _noteFailure(),
    );
  }
}
