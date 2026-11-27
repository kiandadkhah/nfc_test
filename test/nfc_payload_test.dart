/// Tests for the shared-memory payload layer: byte layout round-trips,
/// APP_CRC32 domain, Chebyshev/Q14 fit accuracy and the §4.10 logger decode.
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:kianex_pts50n1_app/core/constants/domain.dart';
import 'package:kianex_pts50n1_app/core/crypto/crc32_stm32.dart';
import 'package:kianex_pts50n1_app/core/models/program.dart';
import 'package:kianex_pts50n1_app/core/nfc/memory_map.dart';
import 'package:kianex_pts50n1_app/core/nfc/nfc_service.dart';
import 'package:kianex_pts50n1_app/core/nfc/sot_protocol.dart';
import 'package:kianex_pts50n1_app/core/nfc/tag_link.dart';
import 'package:kianex_pts50n1_app/core/solar/chebyshev.dart';
import 'package:kianex_pts50n1_app/core/solar/solar_events.dart';
import 'package:kianex_pts50n1_app/core/utils/jalali.dart';

Event _fixed(int hh, int mm, {RelayCommand cmd = RelayCommand.on}) => Event(
      type: EventType.fixed,
      hh: hh,
      mm: mm,
      cmd: cmd,
      onPhase: TimerPhase(hours: 0, minutes: 30),
      offPhase: TimerPhase(hours: 0, minutes: 15),
    );

/// Seeds the onboarding area of [link] with a valid Type 5 CC file and the
/// factory NDEF URI pointing at the KIANEX product page (the URI payload
/// carries the URL WITHOUT the https:// prefix — prefix code 0x04 provides
/// it, exactly like the factory write).
void seedOnboarding(FakeTagLink link) {
  link.seedBlock(0, [0xE1, 0x40, 0x00, 0x00]); // CC: Type 5 v1.0
  final uri = NdefContract.productUrl.substring('https://'.length).codeUnits;
  final message = <int>[0xD1, 0x01, uri.length + 1, 0x55, 0x04, ...uri];
  final tlv = <int>[0x03, message.length, ...message, 0xFE];
  while (tlv.length < 60) {
    tlv.add(0x00); // padding TLV-free bytes
  }
  for (var i = 0; i < 15; i++) {
    link.seedBlock(1 + i, tlv.sublist(i * 4, i * 4 + 4));
  }
}

/// Seeds a healthy powered logger: run version 3 and a valid LOG_CRC32.
void seedPoweredLogger(FakeTagLink link) {
  final loggerBlocks = <int>[
    0x14, 0x00, 0x00, 0x00, // 504 operating hour = 20
    0x0A, 0x00, 0x00, 0x00, // 505 on hour = 10
    0x07, 0x00, 0x00, 0x00, // 506 relay ops = 7
    0x00, 0x00, 0x00, 0x00, // 507 ongoing = none
    0x00, 0x00, 0x00, 0x00, // 508 internal error = none
    0x03, 0x00, 0x00, 0x00, // 509 RUN_Program_Counter = 3
  ];
  final crc = crc32Stm32(loggerBlocks); // domain = blocks 504..509
  for (var i = 0; i < 6; i++) {
    link.seedBlock(504 + i, loggerBlocks.sublist(i * 4, i * 4 + 4));
  }
  link.seedBlock(510, [0xC3, 0x00, 0x00, 0x00]); // Process_Record_LOG = end
  link.seedBlock(511, [crc & 0xFF, (crc >> 8) & 0xFF, (crc >> 16) & 0xFF, (crc >> 24) & 0xFF]);
}

void main() {
  group('PlanningImage byte layout', () {
    test('event record encodes time, command, chain and timer address', () {
      final img = PlanningImage();
      final ev = _fixed(6, 30, cmd: RelayCommand.on);
      img.setEvent(1, ev, 2, null);
      // Event 1 lives in block 119; Byte_0/1 = 390 minutes (LE 11-bit).
      expect(img.getByte(119, 0), 390 & 0xFF);
      expect(img.getByte(119, 1) & 0x07, 390 >> 8); // EVENT_TIME_H
      expect(img.getByte(119, 1) & 0x08, 0x08); // EVENT_CMD = on
      expect(img.getByte(119, 1) & 0x10, 0x00); // ASTRO_EVENT = 0
      expect(img.getByte(119, 2), 2); // EVENT_CHAIN
      expect(img.getByte(119, 3), 0); // no timer
    });

    test('solar event encodes astro flags and offset magnitude', () {
      final img = PlanningImage();
      final ev = _fixed(0, 0)
        ..type = EventType.astro
        ..astro = SolarBase.sunrise
        ..offsetDirection = OffsetDirection.before
        ..offsetMinutes = 20;
      img.setEvent(3, ev, null, null);
      final b1 = img.getByte(119 + 3 - 1, 1);
      expect(b1 & 0x10, 0x10); // ASTRO_EVENT
      expect(b1 & 0x20, 0x20); // sunrise
      expect(b1 & 0x40, 0x40); // negative offset
      expect(img.getByte(119 + 3 - 1, 0), 20); // offset magnitude
    });

    test('timer pool packs ON/OFF units two timers per block', () {
      final img = PlanningImage();
      final ev = _fixed(0, 0, cmd: RelayCommand.timer)
        ..onPhase = TimerPhase(hours: 0, minutes: 60)
        ..offPhase = TimerPhase(hours: 0, minutes: 30);
      img.setTimer(1, ev);
      // Timer 1 → block 375: B0 = ON units (12), B1 = OFF units (6).
      expect(img.getByte(375, 0), 12);
      expect(img.getByte(375, 1), 6);
      img.setTimer(2, ev);
      expect(img.getByte(375, 2), 12);
      expect(img.getByte(375, 3), 6);
    });

    test('day pointers: annual day 366 lands in block 107 Byte_1', () {
      final img = PlanningImage();
      // Day-of-year is 1-based: day 1 → block 16 Byte_0 … day 366 →
      // block 107 Byte_1 (Esfand 30 of a leap year).
      img.setAnnualDay(1, 5);
      expect(img.getByte(16, 0), 5);
      img.setAnnualDay(366, 7);
      expect(img.getByte(107, 1), 7);
      img.setWeeklyDay(6, 9);
      expect(img.getByte(117, 2), 9);
      img.setMonthlyDay(30, 4);
      expect(img.getByte(115, 2), 4);
      img.setDailyHead(11);
      expect(img.getByte(118, 0), 11);
    });

    test('APP_CRC32 covers blocks 16..429 and is stable', () {
      final img = PlanningImage();
      img.setAnnualDay(10, 3);
      final crc1 = img.appCrc32;
      expect(crc1, img.appCrc32);
      img.setAnnualDay(10, 4);
      expect(img.appCrc32, isNot(crc1));
    });
  });

  group('write plan build (enabled programs only)', () {
    test('disabled programs are excluded from the payload', () {
      final enabled = Program(
        id: 1,
        name: 'on',
        cycle: CycleType.daily,
        events: [_fixed(6, 30), _fixed(7, 0, cmd: RelayCommand.off)],
        assign: Assignment(),
      );
      // A disabled program exists in the list but must never reach the plan.
      final disabled = Program(
        id: 2,
        name: 'off',
        cycle: CycleType.daily,
        events: [_fixed(12, 0)],
        assign: Assignment(),
      )..enabled = false;

      final plan = buildProgramWritePlan(
        enabledPrograms: [enabled],
        deviceTime: DateTime(2025, 11, 25, 9, 0),
        jalali: const JalaliClock(year2: 4, month: 9, day: 4),
        sunriseQ14: List<int>.filled(12, 0),
        sunsetQ14: List<int>.filled(12, 0),
        newProgramCounter: 4,
      );
      expect(disabled.enabled, isFalse);
      // The daily head of the ENABLED program is event 1.
      expect(plan.dataOf(118)![0], 1);
      // Block 430 carries the start code.
      expect(plan.dataOf(430)![0], ProcessCodes.programStart);
      // Program_Counter = 4 (LE in Byte_2/3).
      expect(plan.dataOf(430)![2], 4);
    });
  });

  group('LoggerSnapshot decode', () {
    test('parses the §4.10 logger blocks (LE fields)', () {
      Uint8List block(List<int> b) => Uint8List.fromList(b);
      final snap = LoggerSnapshot.fromBlocks([
        block([0x14, 0x00, 0x00, 0x00]), // 504 operating hour = 20
        block([0x0A, 0x00, 0x00, 0x00]), // 505 on hour = 10
        block([0x07, 0x00, 0x00, 0x00]), // 506 relay ops = 7
        block([0x03, 0x00, 0x00, 0x00]), // 507 ongoing = 3
        block([0x00, 0x00, 0x00, 0x00]), // 508 no error
        block([0x05, 0x00, 0x00, 0x00]), // 509 run version = 5
        block([0xC3, 0x00, 0x00, 0x00]), // 510 process log = end code
        block([0xBC, 0x11, 0x2A, 0x3F]), // 511 log crc LE
      ]);
      expect(snap.operatingHour, 20);
      expect(snap.operatingHourOn, 10);
      expect(snap.operatingHourCn, 7);
      expect(snap.runProgramCounter, 5);
      expect(snap.processRecordLog, 0xC3);
      expect(snap.logCrc32, 0x3F2A11BC);
    });
  });

  group('SotProtocol over FakeTagLink', () {
    test('full 8-step run writes and verifies a valid image', () async {
      final link = FakeTagLink();
      seedOnboarding(link);
      seedPoweredLogger(link);

      final engine = SotProtocol(link);
      final progress = <String>[];
      final result = await engine.run(
        SotWriteRequest(
          mode: WriteMode.programAndSettings,
          enabledPrograms: [
            Program(
              id: 1,
              name: 'p',
              cycle: CycleType.daily,
              events: [_fixed(6, 30), _fixed(7, 0, cmd: RelayCommand.off)],
              assign: Assignment(),
            ),
          ],
          deviceTime: DateTime(2025, 11, 25, 9, 0),
          latitude: 35.6892,
          longitude: 51.3890,
          utcOffsetHours: 3.5,
        ),
        fromStep: 1,
        onProgress: (p) => progress.add('${p.step}:${p.status.name}'),
      );

      expect(result, isNotNull);
      expect(result!.newVersion, 4);
      expect(progress.first, '1:active');
      expect(progress[1], '1:done');
      expect(progress.last, '8:done');
      // The planning register ends with the end code and the new counter.
      final reg = await link.readBlock(430);
      expect(reg[0], ProcessCodes.programEnd);
      expect(reg[2], 4);
      // The daily head points at event 1.
      final daily = await link.readBlock(118);
      expect(daily[0], 1);
      await link.close();
    });

    test('blank logger halts the protocol with the power-off signal', () async {
      final link = FakeTagLink();
      seedOnboarding(link);
      // Logger area is blank (0xFF) — unpowered relay.
      for (var b = 504; b <= 511; b++) {
        link.seedBlock(b, [0xFF, 0xFF, 0xFF, 0xFF]);
      }
      final engine = SotProtocol(link);
      WriteProgress? last;
      final result = await engine.run(
        SotWriteRequest(
          mode: WriteMode.settingsOnly,
          enabledPrograms: const [],
          deviceTime: DateTime(2025, 11, 25, 9, 0),
          latitude: 35.6892,
          longitude: 51.3890,
          utcOffsetHours: 3.5,
        ),
        fromStep: 1,
        onProgress: (p) => last = p,
      );
      expect(result, isNull);
      expect(last, isNotNull);
      expect(last!.powerOff, isTrue);
    });

    test('v4.4 — EH_CTRL_Dyn VCC_ON=0 halts even with a healthy logger', () async {
      // The power-supply status comes from the ST25DV16KC register, not
      // from the logger heuristic: a healthy-looking logger (run=3, valid
      // LOG_CRC32) must NOT override a live VCC_ON=0 report.
      final link = FakeTagLink();
      seedOnboarding(link);
      seedPoweredLogger(link);
      link.dynamicRegisters[0x01] = 0x04; // FIELD_ON=1, VCC_ON=0
      final engine = SotProtocol(link);
      WriteProgress? last;
      final result = await engine.run(
        SotWriteRequest(
          mode: WriteMode.programAndSettings,
          enabledPrograms: [
            Program(
              id: 1,
              name: 'p',
              cycle: CycleType.daily,
              events: [_fixed(6, 30)],
              assign: Assignment(),
            ),
          ],
          deviceTime: DateTime(2025, 11, 25, 9, 0),
          latitude: 35.6892,
          longitude: 51.3890,
          utcOffsetHours: 3.5,
        ),
        fromStep: 1,
        onProgress: (p) => last = p,
      );
      expect(result, isNull);
      expect(last!.powerOff, isTrue);
    });

    test('v4.4 — EH_CTRL_Dyn VCC_ON=1 lets a blank-logger relay proceed', () async {
      final link = FakeTagLink();
      seedOnboarding(link);
      for (var b = 504; b <= 511; b++) {
        link.seedBlock(b, [0xFF, 0xFF, 0xFF, 0xFF]);
      }
      link.dynamicRegisters[0x01] = 0x0C; // FIELD_ON=1, VCC_ON=1
      final engine = SotProtocol(link);
      final result = await engine.run(
        SotWriteRequest(
          mode: WriteMode.programAndSettings,
          enabledPrograms: [
            Program(
              id: 1,
              name: 'p',
              cycle: CycleType.daily,
              events: [_fixed(6, 30), _fixed(7, 0, cmd: RelayCommand.off)],
              assign: Assignment(),
            ),
          ],
          deviceTime: DateTime(2025, 11, 25, 9, 0),
          latitude: 35.6892,
          longitude: 51.3890,
          utcOffsetHours: 3.5,
        ),
        fromStep: 1,
        onProgress: (_) {},
      );
      expect(result, isNotNull); // no power-off halt
      await link.close();
    });

    test('v4.4 — skipClock continue writes the FULL program image', () async {
      // THE v4.3.0 field bug regression: on the unpowered-continue path
      // the plan was silently downgraded to the 14-block settings-only
      // payload — every program value stayed zero on the real tag
      // (APP_CRC32 = 0x0993D8D7). The full image must be written in this
      // path too, with the SET bytes preserved from the tag.
      final link = FakeTagLink();
      seedOnboarding(link);
      for (var b = 504; b <= 511; b++) {
        link.seedBlock(b, [0xFF, 0xFF, 0xFF, 0xFF]);
      }
      link.dynamicRegisters[0x01] = 0x04; // FIELD_ON=1, VCC_ON=0
      // A live device clock the continue path must preserve.
      link.seedBlock(428, [12, 34, 21, 0]); // sec/min/hour/week
      link.seedBlock(429, [4, 9, 4, 0]); // day/month/year2/RES

      final programs = [
        Program(
          id: 1,
          name: 'p',
          cycle: CycleType.daily,
          events: [_fixed(6, 30), _fixed(7, 0, cmd: RelayCommand.off)],
          assign: Assignment(),
        ),
        Program(
          id: 2,
          name: 'w',
          cycle: CycleType.weekly,
          events: [_fixed(12, 0, cmd: RelayCommand.on)],
          assign: Assignment(weekly: [0]), // Saturday
        ),
      ];
      final engine = SotProtocol(link);
      final halted = await engine.run(
        SotWriteRequest(
          mode: WriteMode.programAndSettings,
          enabledPrograms: programs,
          deviceTime: DateTime(2025, 11, 25, 9, 0),
          latitude: 35.6892,
          longitude: 51.3890,
          utcOffsetHours: 3.5,
        ),
        fromStep: 1,
        onProgress: (_) {},
      );
      expect(halted, isNull); // power-off halt at step 2

      final result = await engine.run(
        SotWriteRequest(
          mode: WriteMode.programAndSettings,
          enabledPrograms: programs,
          deviceTime: DateTime(2025, 11, 25, 9, 0),
          latitude: 35.6892,
          longitude: 51.3890,
          utcOffsetHours: 3.5,
        ),
        fromStep: 2,
        skipClock: true,
        onProgress: (_) {},
      );
      expect(result, isNotNull);

      // Daily chain: head = event 1, written to block 118.
      final daily = await link.readBlock(118);
      expect(daily[0], 1);
      // Event 1 lands in block 119 with a REAL time (390 min = 06:30).
      final ev = await link.readBlock(119);
      expect(ev[0], 390 & 0xFF);
      expect(ev[1] & 0x07, 390 >> 8);
      // Weekly Saturday slot points at the weekly program's chain.
      final weekly = await link.readBlock(116);
      expect(weekly[0], 3); // head of the second program (2 events + 1)
      // Chebyshev coefficients are non-zero (16-bit-safe scale).
      final coef = await link.readBlock(416);
      expect(coef[0] | coef[1] << 8, isNot(0));
      // The SET bytes were preserved from the tag, not overwritten with
      // the phone clock (skipClock).
      final setBlock = await link.readBlock(428);
      expect(setBlock[0], 12);
      expect(setBlock[1], 34);
      // The stored APP_CRC32 is NOT the all-zero payload sentinel.
      final crcBlock = await link.readBlock(431);
      final storedCrc = crcBlock[0] |
          (crcBlock[1] << 8) |
          (crcBlock[2] << 16) |
          (crcBlock[3] << 24);
      expect(storedCrc, isNot(0x0993D8D7));
      await link.close();
    });

    test('v4.4 — a day-less weekly program is refused at transfer time', () async {
      final link = FakeTagLink();
      seedOnboarding(link);
      seedPoweredLogger(link);
      link.dynamicRegisters[0x01] = 0x0C; // powered
      final engine = SotProtocol(link);
      await expectLater(
        engine.run(
          SotWriteRequest(
            mode: WriteMode.programAndSettings,
            enabledPrograms: [
              Program(
                id: 1,
                name: 'w',
                cycle: CycleType.weekly,
                events: [_fixed(6, 30)],
                assign: Assignment(), // NO days assigned
              ),
            ],
            deviceTime: DateTime(2025, 11, 25, 9, 0),
            latitude: 35.6892,
            longitude: 51.3890,
            utcOffsetHours: 3.5,
          ),
          fromStep: 1,
          onProgress: (_) {},
        ),
        throwsA(isA<TagLinkException>()
            .having((e) => e.message, 'message', contains('program_without_days'))),
      );
      await link.close();
    });
  });

  group('Chebyshev / solar', () {
    test('Q14 fit reproduces a smooth seasonal curve within ±2 minutes', () {
      // Sunrise-like seasonal drift: a smooth cosine over the year.
      final table = List<int>.generate(
          366, (i) => (330 + 90 * math.cos(math.pi * i / 365)).round());
      final coeffs = fitChebyshevQ14FromTable(table);
      for (final day in [1, 30, 90, 180, 270, 366]) {
        final approx = evaluateChebyshevQ14(coeffs, dayToChebyshevX(day));
        expect((approx - table[day - 1]).abs(), lessThan(2.0));
      }
    });

    test('v4.4 — Q14 coefficients fit the 16-bit signed container', () {
      // The fraction-of-day scale must keep EVERY coefficient inside the
      // signed 16-bit word — the plain minutes-Q14 overflowed (c0 ≈ 363
      // min × 16384 = 5.9 M) and produced garbage/zeros on the real tag.
      for (final base in [330, 720, 1100]) {
        final table = List<int>.generate(
            366, (i) => (base + 90 * math.cos(math.pi * i / 365)).round());
        for (final c in fitChebyshevQ14FromTable(table)) {
          expect(c, inInclusiveRange(-32768, 32767));
        }
      }
    });

    test('sunrise/sunset sanity for Tehran (2025-06-21, UTC+3:30)', () {
      final t = solarTimesFor(
        year: 2025, month: 6, day: 21,
        latitude: 35.6892, longitude: 51.3890, utcOffsetHours: 3.5,
      );
      // NOAA cross-checked: solar noon ≈ 12:06, half-day ≈ 7h18m →
      // sunrise ≈ 04:49, sunset ≈ 19:24 local (no DST since 1401).
      expect(t.sunriseMinutes, inInclusiveRange(283, 295));
      expect(t.sunsetMinutes, inInclusiveRange(1155, 1173));
      expect(t.sunsetMinutes - t.sunriseMinutes, inInclusiveRange(860, 880));
    });

    test('Jalali round-trip keeps the SET block fields in range', () {
      final g = DateTime(2025, 11, 25);
      final j = gregorianToJalali(g);
      expect(j.year, 1404);
      expect(j.month, inInclusiveRange(1, 12));
      expect(j.day, inInclusiveRange(1, 30));
      expect(j.year % 100, lessThan(100));
    });
  });
}
