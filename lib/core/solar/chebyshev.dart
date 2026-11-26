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

/// Fits [f] evaluated at the 12 Chebyshev nodes and returns the Q14
/// coefficients c0..c11 such that f(x) ≈ Σ c_k·T_k(x) for all x ∈ [−1, 1].
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
  return coeffs.map((c) => (c * q14One).round()).toList();
}

/// Evaluates the stored Q14 coefficients (minutes of day).
double evaluateChebyshevQ14(List<int> coeffsQ14, double x) {
  var sum = 0.0;
  for (var k = 0; k < coeffsQ14.length && k < chebyshevOrder; k++) {
    sum += (coeffsQ14[k] / q14One) * _t(k, x);
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
