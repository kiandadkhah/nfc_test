import 'package:flutter_test/flutter_test.dart';

import 'package:kianex_pts50n1_app/core/utils/jalali.dart';

void main() {
  group('Jalali ⇄ Gregorian conversion (verified vectors)', () {
    test('known dates', () {
      expect(gregorianToJalali(DateTime(2025, 11, 22)), const JalaliDate(1404, 9, 1));
      expect(gregorianToJalali(DateTime(2024, 3, 20)), const JalaliDate(1403, 1, 1));
      expect(gregorianToJalali(DateTime(2026, 3, 21)), const JalaliDate(1405, 1, 1));
      expect(gregorianToJalali(DateTime(2026, 11, 22)), const JalaliDate(1405, 9, 1));
    });

    test('leap year Esfand 30 (1403 is leap)', () {
      expect(gregorianToJalali(DateTime(2025, 3, 20)), const JalaliDate(1403, 12, 30));
    });

    test('round trip over a 4-year window', () {
      var day = DateTime(2024, 1, 1);
      final end = DateTime(2028, 1, 1);
      while (day.isBefore(end)) {
        final j = gregorianToJalali(day);
        final back = jalaliToGregorian(j);
        expect(back.year, day.year, reason: 'year mismatch for $j');
        expect(back.month, day.month, reason: 'month mismatch for $j');
        expect(back.day, day.day, reason: 'day mismatch for $j');
        day = day.add(const Duration(days: 1));
      }
    });
  });

  group('Current-year leap awareness (device annual cycle contract)', () {
    test('leap years of the current cycle are 1403 and 1408', () {
      expect(isJalaliLeap(1403), isTrue);
      expect(isJalaliLeap(1404), isFalse);
      expect(isJalaliLeap(1405), isFalse);
      expect(isJalaliLeap(1406), isFalse);
      expect(isJalaliLeap(1407), isFalse);
      expect(isJalaliLeap(1408), isTrue);
    });

    test('Esfand length follows the CURRENT year leap state', () {
      expect(jalaliMonthLength(1403, 12), 30); // leap
      expect(jalaliMonthLength(1404, 12), 29);
      expect(jalaliMonthLength(1405, 12), 29);
      expect(jalaliMonthLength(1408, 12), 30); // leap
      expect(jalaliYearLength(1403), 366);
      expect(jalaliYearLength(1405), 365);
    });

    test('day-of-year mapping across month lengths (non-leap year)', () {
      // 1405: months 1-6 = 31, months 7-11 = 30, month 12 = 29.
      expect(jalaliDayOfYear(1405, 1, 1), 1);
      expect(jalaliDayOfYear(1405, 6, 31), 186);
      expect(jalaliDayOfYear(1405, 7, 1), 187);
      expect(jalaliDayOfYear(1405, 9, 1), 247); // 186 + 30 + 30 + 1
      expect(jalaliDayOfYear(1405, 12, 29), 365);
    });

    test('day-of-year includes Esfand 30 in the leap year 1403', () {
      expect(jalaliDayOfYear(1403, 12, 30), 366);
      expect(jalaliFromDayOfYear(1403, 366), (12, 30));
      expect(jalaliFromDayOfYear(1403, 1), (1, 1));
      expect(jalaliFromDayOfYear(1405, 365), (12, 29));
      // Round-trip over the whole leap year.
      for (var doy = 1; doy <= 366; doy++) {
        final (m, d) = jalaliFromDayOfYear(1403, doy);
        expect(jalaliDayOfYear(1403, m, d), doy, reason: 'doy $doy');
      }
    });
  });
}
