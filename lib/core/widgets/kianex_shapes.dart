import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// KIANEX brand mark — orange octagon with the dark mountain path
/// (mirrors the approved LOGO_INNER SVG).
class KianexLogoMark extends StatelessWidget {
  const KianexLogoMark({super.key, this.size = 36, this.dark = false});

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(dark: dark),
    );
  }
}

class _LogoPainter extends CustomPainter {
  const _LogoPainter({this.dark = false});

  final bool dark;

  static Path _octagon(Size size) {
    // OCT polygon on a 64×64 viewBox.
    final p = Path()
      ..moveTo(20, 3)
      ..lineTo(44, 3)
      ..lineTo(61, 20)
      ..lineTo(61, 44)
      ..lineTo(44, 61)
      ..lineTo(20, 61)
      ..lineTo(3, 44)
      ..lineTo(3, 20)
      ..close();
    final s = size.width / 64;
    final sy = size.height / 64;
    return p.transform(_scale(s, sy));
  }

  static Float64List _scale(double sx, double sy) => Float64List.fromList(<double>[
        sx, 0, 0, 0, //
        0, sy, 0, 0,
        0, 0, 1, 0,
        0, 0, 0, 1,
      ]);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(_octagon(size), Paint()..color = AppTheme.orange);
    final ink = Paint()
      ..color = dark ? Colors.black : const Color(0xFF0C0E10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.081
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final s = size.width / 64;
    final sy = size.height / 64;
    final mountain = Path()
      ..moveTo(12 * s, 45 * sy)
      ..lineTo(23.5 * s, 26 * sy)
      ..lineTo(30 * s, 34.5 * sy)
      ..lineTo(37 * s, 14 * sy)
      ..lineTo(44.5 * s, 31 * sy)
      ..lineTo(52 * s, 45 * sy);
    canvas.drawPath(mountain, ink);
    canvas.drawCircle(Offset(37 * s, 14 * sy), size.width * 0.05, Paint()..color = ink.color);
  }

  @override
  bool shouldRepaint(covariant _LogoPainter oldDelegate) => oldDelegate.dark != dark;
}

/// Ghost hexagon + mountain outline used on the empty state.
class HexGhostIcon extends StatelessWidget {
  const HexGhostIcon({super.key, this.size = 84, this.color = const Color(0xFF8A939C)});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _GhostPainter(color: color),
    );
  }
}

class _GhostPainter extends CustomPainter {
  const _GhostPainter({this.color = const Color(0xFF8A939C)});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 64;
    final outline = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.041
      ..strokeJoin = StrokeJoin.round;
    final hex = Path()
      ..moveTo(32 * s, 8 * s) // flattened top hexagon (empty-state ghost)
      ..lineTo(50 * s, 18 * s)
      ..lineTo(50 * s, 42 * s)
      ..lineTo(32 * s, 52 * s)
      ..lineTo(14 * s, 42 * s)
      ..lineTo(14 * s, 18 * s)
      ..close();
    canvas.drawPath(hex, outline);
    final mountain = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.047
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final m = Path()
      ..moveTo(19 * s, 41 * s)
      ..lineTo(28 * s, 27 * s)
      ..lineTo(33 * s, 34 * s)
      ..lineTo(39 * s, 19 * s)
      ..lineTo(45 * s, 34 * s)
      ..lineTo(47 * s, 41 * s);
    canvas.drawPath(m, mountain);
  }

  @override
  bool shouldRepaint(covariant _GhostPainter oldDelegate) => oldDelegate.color != color;
}

/// Small donut gauge used by the fixed chart cards under the header.
class GaugeDonut extends StatelessWidget {
  const GaugeDonut({super.key, required this.percent, this.size = 46, this.stroke = 5.5});

  final double percent; // 0..100
  final double size;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    final warn = percent > 85;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(percent: percent, stroke: stroke, warn: warn),
          ),
          Text(
            '${percent.round()}٪',
            style: TextStyle(
              fontSize: size * 0.23,
              fontWeight: FontWeight.w700,
              color: warn ? const Color(0xFFC0392B) : const Color(0xFF38414C),
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.percent, required this.stroke, required this.warn});

  final double percent;
  final double stroke;
  final bool warn;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Paint()
      ..color = const Color(0xFFEDEEF0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    final r = (size.width - stroke) / 2;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, r, track);
    if (percent <= 0) return;
    final fill = Paint()
      ..color = warn ? const Color(0xFFC0392B) : AppTheme.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final sweep = 2 * math.pi * (percent.clamp(0.0, 100.0) / 100);
    canvas.drawArc(Rect.fromCircle(center: c, radius: r), -math.pi / 2, sweep, false, fill);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.warn != warn;
}

/// Dashed rounded-rectangle border (the «add new program» card).
class DashedRRectBorder extends CustomPainter {
  const DashedRRectBorder({
    this.color = const Color(0xFFC8CFD6),
    this.radius = 14,
    this.dash = 6,
    this.gap = 5,
    this.width = 1.4,
  });

  final Color color;
  final double radius;
  final double dash;
  final double gap;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final metric in path.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        final end = math.min(dist + dash, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant DashedRRectBorder oldDelegate) =>
      oldDelegate.color != color;
}
