/// Jalali (Shamsi) calendar conversion — faithful port of the jalaali
/// algorithm (JSTCC-compatible, leap years included). Used for the
/// user-facing Persian date on the write-confirm screen.
library;

/// A Jalali date: year (e.g. 1404), month (1..12), day (1..31/30/29).
class JalaliDate {
  final int year;
  final int month;
  final int day;

  const JalaliDate(this.year, this.month, this.day);

  @override
  bool operator ==(Object other) =>
      other is JalaliDate && other.year == year && other.month == month && other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => '$year/$month/$day';
}

// JS-compatible integer division/remainder (the jalaali algorithm relies
// on truncation toward zero and JS-style remainder for negative values).
int _div(int a, int b) => a ~/ b;
int _mod(int a, int b) => a - _div(a, b) * b;

class _JalCal {
  final int leap;
  final int gy;
  final int march;
  const _JalCal(this.leap, this.gy, this.march);
}

const List<int> _breaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, //
  1635, 2060, 2097, 2192, 2262, 2324, 2394, 2456, 3178,
];

_JalCal _jalCal(int jy) {
  final gy = jy + 621;
  var leapJ = -14;
  var jp = _breaks[0];
  var jump = 0;
  assert(jy >= jp && jy < _breaks[_breaks.length - 1], 'Invalid Jalali year $jy');
  for (var i = 1; i < _breaks.length; i++) {
    final jm = _breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
    jp = jm;
  }
  var n = jy - jp;
  leapJ += _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
  if (_mod(jump, 33) == 4 && jump - n == 4) leapJ += 1;
  final leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;
  final march = 20 + leapJ - leapG;
  if (jump - n < 6) n = n - jump + _div(jump + 4, 33) * 33;
  var leap = _mod(_mod(n + 1, 33) - 1, 4);
  if (leap == -1) leap = 4;
  return _JalCal(leap, gy, march);
}

/// Gregorian → JDN (Julian Day Number).
int _g2d(int gy, int gm, int gd) {
  var d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
      _div(153 * _mod(gm + 9, 12) + 2, 5) +
      gd -
      34840408;
  d = d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
  return d;
}

/// JDN → Gregorian (year, month, day).
(int, int, int) _d2g(int jdn) {
  var j = 4 * jdn + 139361631;
  j = j + _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
  final i = _div(_mod(j, 1461), 4) * 5 + 308;
  final gd = _div(_mod(i, 153), 5) + 1;
  final gm = _mod(_div(i, 153), 12) + 1;
  final gy = _div(j, 1461) - 100100 + _div(8 - gm, 6);
  return (gy, gm, gd);
}

/// Converts a Gregorian [DateTime] (any time of day; the date part is used)
/// to the corresponding Jalali date.
JalaliDate gregorianToJalali(DateTime g) {
  final jdn = _g2d(g.year, g.month, g.day);
  final gy = _d2g(jdn).$1;
  var jy = gy - 621;
  final r = _jalCal(jy);
  final jdn1f = _g2d(gy, 3, r.march);
  var k = jdn - jdn1f;
  if (k >= 0) {
    if (k <= 185) {
      return JalaliDate(jy, 1 + _div(k, 31), _mod(k, 31) + 1);
    }
    k -= 186;
  } else {
    jy -= 1;
    k += 179;
    if (r.leap == 1) k += 1;
  }
  return JalaliDate(jy, 7 + _div(k, 30), _mod(k, 30) + 1);
}

/// Converts a Jalali date to the corresponding Gregorian [DateTime]
/// (midnight of that day).
DateTime jalaliToGregorian(JalaliDate j) {
  final r = _jalCal(j.year);
  final jdn = _g2d(r.gy, 3, r.march) +
      (j.month - 1) * 31 -
      _div(j.month, 7) * (j.month - 7) +
      j.day -
      1;
  final g = _d2g(jdn);
  return DateTime(g.$1, g.$2, g.$3);
}

/// True when [year] is a leap year (Esfand has 30 days) — 1403 and 1408
/// are the current-cycle leap years. The ported jalaali algorithm marks a
/// leap year with `leap == 0`.
bool isJalaliLeap(int year) => _jalCal(year).leap == 0;

/// Number of days of one Jalali month in the given year — the leap state
/// of the CURRENT year decides the length of Esfand (30 in a leap year).
int jalaliMonthLength(int year, int month) {
  assert(month >= 1 && month <= 12, 'Invalid Jalali month $month');
  if (month <= 6) return 31;
  if (month <= 11) return 30;
  return isJalaliLeap(year) ? 30 : 29;
}

/// Total days of the Jalali year (365, or 366 in a leap year).
int jalaliYearLength(int year) => isJalaliLeap(year) ? 366 : 365;

/// 1-based day-of-year of a Jalali date — the device contract for the
/// annual cycle slots (Annual_Cycl_Day, day 1..366).
int jalaliDayOfYear(int year, int month, int day) {
  assert(month >= 1 && month <= 12, 'Invalid Jalali month $month');
  assert(day >= 1 && day <= jalaliMonthLength(year, month),
      'Invalid Jalali day $day/$month/$year');
  var doy = 0;
  for (var m = 1; m < month; m++) {
    doy += jalaliMonthLength(year, m);
  }
  return doy + day;
}

/// Returns (month, day) for a 1-based day-of-year of the given year.
(int, int) jalaliFromDayOfYear(int year, int dayOfYear) {
  assert(dayOfYear >= 1 && dayOfYear <= jalaliYearLength(year),
      'Invalid day-of-year $dayOfYear for year $year');
  var rest = dayOfYear;
  for (var m = 1; m <= 12; m++) {
    final len = jalaliMonthLength(year, m);
    if (rest <= len) return (m, rest);
    rest -= len;
  }
  return (12, jalaliMonthLength(year, 12));
}
