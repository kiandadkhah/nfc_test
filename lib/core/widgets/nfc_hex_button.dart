import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The approved NFC button iconography: a rounded flat-top hexagon with
/// white broadcast waves (hollow centre ring + two arcs on each side).
/// [NfcHexButton] is the interactive footer button; [NfcHexBadge] is the
/// static/pulsing badge used on the progress and identify overlays.
class _NfcHexPainter extends CustomPainter {
  const _NfcHexPainter({this.color = AppTheme.orange});

  final Color color;

  static Path hexPath(Size size) {
    // Approved HEX_PATH on a 64×64 viewBox, scaled to the target size:
    // M56.5 25.94 Q60 32 56.5 38.06 L49.5 50.19 Q46 56.25 39 56.25
    // L25 56.25 Q18 56.25 14.5 50.19 L7.5 38.06 Q4 32 7.5 25.94
    // L14.5 13.81 Q18 7.75 25 7.75 L39 7.75 Q46 7.75 49.5 13.81 Z
    Path path = Path()
      ..moveTo(56.5, 25.94)
      ..quadraticBezierTo(60, 32, 56.5, 38.06)
      ..lineTo(49.5, 50.19)
      ..quadraticBezierTo(46, 56.25, 39, 56.25)
      ..lineTo(25, 56.25)
      ..quadraticBezierTo(18, 56.25, 14.5, 50.19)
      ..lineTo(7.5, 38.06)
      ..quadraticBezierTo(4, 32, 7.5, 25.94)
      ..lineTo(14.5, 13.81)
      ..quadraticBezierTo(18, 7.75, 25, 7.75)
      ..lineTo(39, 7.75)
      ..quadraticBezierTo(46, 7.75, 49.5, 13.81)
      ..close();
    // Column-major uniform scale matrix (version-proof; no Matrix4 API drift).
    path = path.transform(Float64List.fromList(<double>[
      size.width / 64, 0, 0, 0, //
      0, size.height / 64, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1,
    ]));
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final hex = hexPath(size);
    canvas.drawPath(hex, Paint()..color = color);

    final wave = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.062
      ..strokeCap = StrokeCap.round;

    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    // Hollow centre ring
    canvas.drawCircle(Offset(cx, cy), size.width * 0.085, wave);

    // Two arcs on each side (reference icon: waves facing outward)
    final r1 = size.width * 0.155;
    final r2 = size.width * 0.225;
    const span = 38 * math.pi / 180;
    // Right side: around 0° (+x axis)
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r1), -span, span * 2, false, wave);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r2), -span, span * 2, false, wave);
    // Left side: around 180° (-x axis)
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r1), math.pi - span, span * 2, false, wave);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r2), math.pi - span, span * 2, false, wave);
  }

  @override
  bool shouldRepaint(covariant _NfcHexPainter oldDelegate) => oldDelegate.color != color;
}

/// Interactive hexagonal NFC button (home footer, per the approved design:
/// a protruding orange hexagon on the black bottom bar).
class NfcHexButton extends StatefulWidget {
  const NfcHexButton({super.key, this.size = 58, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  State<NfcHexButton> createState() => _NfcHexButtonState();
}

class _NfcHexButtonState extends State<NfcHexButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      // Approved v3.0: the footer NFC button has NO glow / shine effect —
      // only a subtle press scale for touch feedback.
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: CustomPaint(
          size: Size.square(widget.size),
          painter: const _NfcHexPainter(),
        ),
      ),
    );
  }
}

/// Static hexagonal NFC badge with an optional pulsing halo — used on the
/// write/read progress overlay and the device identify overlay.
class NfcHexBadge extends StatefulWidget {
  const NfcHexBadge(
      {super.key, this.size = 64, this.pulse = false, this.color = AppTheme.orange});

  final double size;
  final bool pulse;
  final Color color;

  @override
  State<NfcHexBadge> createState() => _NfcHexBadgeState();
}

class _NfcHexBadgeState extends State<NfcHexBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _ctrl.repeat();
  }

  @override
  void didUpdateWidget(covariant NfcHexBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_ctrl.isAnimating) {
      _ctrl.repeat();
    } else if (!widget.pulse && _ctrl.isAnimating) {
      _ctrl.stop();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 1.5,
      height: widget.size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing halo rings
          AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) {
              final t = _ctrl.value;
              final t2 = (t + 0.5) % 1.0;
              return Stack(alignment: Alignment.center, children: [
                Container(
                  width: widget.size * (1.15 + 0.35 * t),
                  height: widget.size * (1.15 + 0.35 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withValues(alpha: 0.45 * (1 - t)),
                      width: 2.2,
                    ),
                  ),
                ),
                if (widget.pulse)
                  Container(
                    width: widget.size * (1.15 + 0.35 * t2),
                    height: widget.size * (1.15 + 0.35 * t2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.45 * (1 - t2)),
                        width: 2.2,
                      ),
                    ),
                  ),
              ]);
            },
          ),
          // Steady ring behind the hexagon
          Container(
            width: widget.size * 1.32,
            height: widget.size * 1.32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: widget.color.withValues(alpha: 0.85), width: 3),
              color: Colors.black.withValues(alpha: 0.25),
            ),
          ),
          CustomPaint(
            size: Size.square(widget.size),
            painter: _NfcHexPainter(color: widget.color),
          ),
        ],
      ),
    );
  }
}
