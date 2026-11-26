/// Sunrise / sunset computation (NOAA solar-position algorithm, pure Dart).
/// Used to fit the Q14 Chebyshev coefficients written to blocks 416..427
/// and to sanity-check them in tests. Accuracy at Iran latitudes ≈ ±1 min.
library;

import 'dart:math' as math;

class SolarTimes {
  const SolarTimes({required this.sunriseMinutes, required this.sunsetMinutes});

  /// Minutes from local midnight (0..1439).
  final int sunriseMinutes;
  final int sunsetMinutes;
}

/// Julian day for a Gregorian date (UT-midnight based).
double _julianDay(int year, int month, int day) {
  if (month <= 2) {
    year -= 1;
    month += 12;
  }
  final a = (year / 100).floor();
  final b = (a / 4).floor();
  final c = 2 - a + b;
  final e = (365.25 * (year + 4716)).floor();
  final f = (30.6001 * (month + 1)).floor();
  return c + day + e + f - 1524.5;
}

(double, double) _sunPosition(double jd) {
  final t = (jd - 2451545.0) / 36525.0;
  final l0 = _norm360(280.46646 + t * (36000.76983 + t * 0.0003032));
  final m = 357.52911 + t * (35999.05029 - 0.0001537 * t);
  final e = 0.016708634 - t * (0.000042037 + 0.0000001267 * t);
  final mr = _rad(m);
  final ctr =
      math.sin(mr) * (1.914602 - t * (0.004817 + 0.000014 * t)) +
          math.sin(2 * mr) * (0.019993 - 0.000101 * t) +
          math.sin(3 * mr) * 0.000289;
  final trueLong = l0 + ctr;
  final omega = 125.04 - 1934.136 * t;
  final lambda = trueLong - 0.00569 - 0.00478 * math.sin(_rad(omega));
  // Mean obliquity of the ecliptic.
  final seconds = 21.448 - t * (46.8150 + t * (0.00059 - t * 0.001813));
  final e0 = 23.0 + (26.0 + seconds / 60.0) / 60.0;
  final eps = e0 + 0.00256 * math.cos(_rad(omega));
  final decl = _deg(math.asin(math.sin(_rad(eps)) * math.sin(_rad(lambda))));
  var y = math.tan(_rad(eps / 2));
  y *= y;
  final eqOfTime = 4.0 *
      _deg(y * math.sin(2 * _rad(l0)) -
          2 * e * math.sin(mr) +
          4 * e * y * math.sin(mr) * math.cos(2 * _rad(l0)) -
          0.5 * y * y * math.sin(4 * _rad(l0)) -
          1.25 * e * e * math.sin(2 * mr));
  return (decl, eqOfTime);
}

double _norm360(double x) {
  var v = x % 360.0;
  if (v < 0) v += 360.0;
  return v;
}

double _rad(double deg) => deg * math.pi / 180.0;
double _deg(double rad) => rad * 180.0 / math.pi;

/// Standard −0.833° zenith (sun disc + refraction).
const double _zenith = 90.833;

/// Computes sunrise/sunset in **local minutes-of-day** for a north-east
/// positive coordinate pair. [utcOffsetHours] includes DST if applicable.
SolarTimes solarTimesFor({
  required int year,
  required int month,
  required int day,
  required double latitude,
  required double longitude,
  required double utcOffsetHours,
}) {
  final jd = _julianDay(year, month, day);
  final (decl, eqOfTime) = _sunPosition(jd);
  final noonLocal = 720.0 - 4.0 * longitude - eqOfTime + utcOffsetHours * 60.0;

  final haDeg = _deg(math.acos(
    (math.cos(_rad(_zenith)) /
            (math.cos(_rad(latitude)) * math.cos(_rad(decl)))) -
        (math.tan(_rad(latitude)) * math.tan(_rad(decl))),
  ));
  final halfDay = 4.0 * haDeg; // minutes
  return SolarTimes(
    sunriseMinutes: _wrapMinute(noonLocal - halfDay),
    sunsetMinutes: _wrapMinute(noonLocal + halfDay),
  );
}

int _wrapMinute(double m) {
  var v = m.round() % 1440;
  if (v < 0) v += 1440;
  return v;
}
