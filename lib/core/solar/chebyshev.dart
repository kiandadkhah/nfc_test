/// Chebyshev interpolation for the device solar coefficients.
///
/// The firmware evaluates sunrise/sunset every day from 2 × 12 sixteen-bit
/// Q14 Chebyshev coefficients (blocks 416..427) — SOT §3.2 «ضرایب چبیشف».
/// The app fits the polynomial over 12 Chebyshev–Gauss nodes spread over the
/// Persian year (366 days) and stores c0..c11 with the Q14 scale (1.0 = 16384).
library;

import 'dart:math' as math;

/// Number of coefficients per set (degree 11).
const int chebyshevOrder = 12;

const int q14One = 1 << 14; // 16384

/// Persian-year day index (1..366) → Chebyshev x ∈ [−1, +1].
double dayToChebyshevX(int dayOfYear, {int totalDays = 366}) {
  final t = ((dayOfYear - 1) / (totalDays - 1)) * 2.0 - 1.0; // −1..1
  return t.clamp(-1.0, 1.0);
}

int chebyshevXToDay(double x, {int totalDays = 366}) {
  final t = (x + 1.0) / 2.0;
  return (1 + t * (totalDays - 1)).round().clamp(1, totalDays);
}

/// The 12 Chebyshev–Gauss nodes of the first kind, ascending.
List<double> chebyshevNodes() {
  const n = chebyshevOrder;
  final nodes = <double>[];
  for (var k = 0; k < n; k++) {
    nodes.add(math.cos((2 * k + 1) * math.pi / (2 * n)));
  }
  nodes.sort();
  return nodes;
}

double _t(int k, double x) => math.cos(k * math.acos(x));

/// v4.4 coefficient scale — FRACTION-OF-DAY in Q14.
///
/// The device stores each coefficient in 16 bits (map_bit_2.csv:
/// Chebyshev_Coefficient_XX_L/H). A plain Q14 of MINUTES cannot fit: the
/// mean sunrise/sunset value (c0 ≈ 360…1100 min) would need up to 24 bits
/// (363 min × 16384 = 5.9 M) and the truncation to 16 bits produced
/// garbage/zeros on the real tag (v4.2.0/v4.3.0 field analysis). With the
/// fraction-of-day scale every coefficient fits comfortably in a SIGNED
/// 16-bit word (largest term ≈ 12 500 of ±32 767) and the reconstruction
/// is exact: minutes = stored × 1440 / 16384 (LSB ≈ 5.3 s).
/// [OI — the scale interpretation must be confirmed with the firmware
/// engineer; changing it only touches this file.]
const int dayMinutes = 1440;

/// Fits [f] evaluated at the 12 Chebyshev nodes and returns the Q14
/// coefficients c0..c11 such that
///   f(x) ≈ Σ (c_k / 16384) × 1440 × T_k(x)   [f in minutes of day]
/// for all x ∈ [−1, 1]. Stored values are SIGNED 16-bit Q14 of the
/// minutes/1440 fraction.
List<int> fitChebyshevQ14(double Function(double x) f) {
  final nodes = chebyshevNodes();
  final values = nodes.map(f).toList();
  final coeffs = List<double>.filled(chebyshevOrder, 0.0);
  for (var k = 0; k < chebyshevOrder; k++) {
    var sum = 0.0;
    for (var i = 0; i < chebyshevOrder; i++) {
      sum += values[i] * _t(k, nodes[i]);
    }
    final c = (2.0 / chebyshevOrder) * sum;
    coeffs[k] = k == 0 ? c / 2.0 : c;
  }
  return coeffs
      .map((c) => (c / dayMinutes * q14One).round().toSigned(16))
      .toList();
}

/// Evaluates the stored Q14 coefficients into minutes of day.
double evaluateChebyshevQ14(List<int> coeffsQ14, double x) {
  var sum = 0.0;
  for (var k = 0; k < coeffsQ14.length && k < chebyshevOrder; k++) {
    sum += (coeffsQ14[k] / q14One) * dayMinutes * _t(k, x);
  }
  return sum;
}

/// Fits a 366-day minute table (index 0 = day 1) and returns Q14 coefficients.
List<int> fitChebyshevQ14FromTable(List<int> minutesTable) {
  return fitChebyshevQ14((x) => minutesTable[chebyshevXToDay(x) - 1].toDouble());
}

/// Rounds a polynomial value to a wrapped minute-of-day.
int minutesOfDay(double v) {
  var r = v.round() % 1440;
  if (r < 0) r += 1440;
  return r;
}
