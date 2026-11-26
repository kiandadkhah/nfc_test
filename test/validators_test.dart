import 'package:flutter_test/flutter_test.dart';

import 'package:kianex_pts50n1_app/core/constants/domain.dart';
import 'package:kianex_pts50n1_app/core/models/program.dart';
import 'package:kianex_pts50n1_app/core/validation/validators.dart';

Event fixed(int hh, int mm) => Event(
      type: EventType.fixed,
      hh: hh,
      mm: mm,
      cmd: RelayCommand.on,
      onPhase: TimerPhase(hours: 0, minutes: 30),
      offPhase: TimerPhase(hours: 0, minutes: 15),
    );

Event solar(SolarBase base, OffsetDirection dir, int offset) => Event(
      type: EventType.astro,
      astro: base,
      offsetMinutes: offset,
      offsetDirection: dir,
      cmd: RelayCommand.on,
      onPhase: TimerPhase(hours: 0, minutes: 30),
      offPhase: TimerPhase(hours: 0, minutes: 15),
    );

void main() {
  group('Q-06 timer phase validation', () {
    test('valid phases', () {
      expect(isPhaseValid(TimerPhase(hours: 0, minutes: 5)), isTrue);
      expect(isPhaseValid(TimerPhase(hours: 12, minutes: 0)), isTrue); // 720 min
      expect(isPhaseValid(TimerPhase(hours: 1, minutes: 25)), isTrue); // 85, %5==0
    });

    test('invalid phases', () {
      expect(isPhaseValid(TimerPhase(hours: 0, minutes: 0)), isFalse); // zero forbidden
      expect(isPhaseValid(TimerPhase(hours: 0, minutes: 3)), isFalse); // not multiple of 5
      expect(isPhaseValid(TimerPhase(hours: 12, minutes: 5)), isFalse); // 725 > 720
    });
  });

  group('Q-10 same-minute conflict prevention', () {
    test('two fixed events at the same minute conflict', () {
      final conflicts = findChainConflicts([fixed(6, 30), fixed(6, 30)]);
      expect(conflicts, hasLength(1));
      expect(conflicts.first.minute, 390);
    });

    test('different minutes do not conflict', () {
      expect(findChainConflicts([fixed(6, 30), fixed(7, 0)]), isEmpty);
    });

    test('identical solar settings conflict (same real minute every day)', () {
      final conflicts =
          findChainConflicts([solar(SolarBase.sunset, OffsetDirection.after, 20),
              solar(SolarBase.sunset, OffsetDirection.after, 20)]);
      expect(conflicts, hasLength(1));
    });

    test('different solar settings do not conflict', () {
      expect(
        findChainConflicts([
          solar(SolarBase.sunset, OffsetDirection.after, 20),
          solar(SolarBase.sunrise, OffsetDirection.after, 20),
        ]),
        isEmpty,
      );
    });

    test('candidateCheck evaluates the exact sorted position', () {
      final list = [fixed(6, 30), fixed(7, 0)];
      // Editing event 0 keeps its own minute but sits next to an identical
      // relay action → the candidate introduces an R-03 violation.
      final edit = candidateCheck(fixed(6, 30), list, skipIndex: 0);
      expect(edit.violations, hasLength(1));
      expect(edit.position, 0);
      expect(edit.violations.first.rule, ChainRule.sameAct);

      // A new event at 7:00 conflicts with event 1 (R-01); the pre-existing
      // R-03 pair (0,1) is NOT reported because the candidate is not part of it.
      final add = candidateCheck(fixed(7, 0), list);
      expect(add.violations, hasLength(1));
      expect(add.violations.first.rule, ChainRule.sameTime);
      expect(add.violations.first.a, 1);
      expect(add.violations.first.b, 2);
    });
  });

  group('v4.1 chain sorting strategy', () {
    test('sortChain groups sunrise → fixed → sunset', () {
      final chain = [
        fixed(18, 0),
        solar(SolarBase.sunset, OffsetDirection.after, 10),
        solar(SolarBase.sunrise, OffsetDirection.after, 20),
        fixed(6, 0),
        solar(SolarBase.sunrise, OffsetDirection.before, 15),
      ];
      final sorted = sortChain(chain);
      expect(sorted[0].astro, SolarBase.sunrise);
      expect(sorted[0].offsetDirection, OffsetDirection.before);
      expect(sorted[1].astro, SolarBase.sunrise);
      expect(sorted[2].type, EventType.fixed);
      expect(sorted[2].fixedMinute, 360);
      expect(sorted[3].type, EventType.fixed);
      expect(sorted[3].fixedMinute, 1080);
      expect(sorted[4].astro, SolarBase.sunset);
    });

    test('sortChain is stable for equal keys', () {
      final a = fixed(6, 0);
      final b = fixed(6, 0);
      final sorted = sortChain([a, b]);
      expect(identical(sorted[0], a), isTrue);
      expect(identical(sorted[1], b), isTrue);
    });

    test('R-03 is exempt for solar commands', () {
      // sunrise-0 on followed by fixed 07:00 on — same action, adjacent in
      // the sorted chain, but the solar command is exempt from R-03.
      final violations = chainRuleViolations([
        solar(SolarBase.sunrise, OffsetDirection.after, 0),
        fixed(7, 0),
      ]);
      expect(violations, isEmpty);
    });

    test('same-base solar pairs with distinct offsets pass R-02', () {
      // Offsets use 5-minute steps, so two same-base solar commands with
      // different keys are always ≥ 5 minutes apart — no violation; the
      // identical-key case is already reported as R-01.
      final violations = chainRuleViolations([
        solar(SolarBase.sunrise, OffsetDirection.after, 10),
        solar(SolarBase.sunrise, OffsetDirection.after, 0),
      ]);
      expect(violations, isEmpty);
    });

    test('astroOverlapWarnings finds the exact annual coincidence', () {
      // Sunrise in Isfahan sweeps roughly 06:05–07:20 across the year; a
      // fixed 06:45 command lies inside the sweep and collides on some days.
      final overlaps = astroOverlapWarnings(
        [fixed(6, 45), solar(SolarBase.sunrise, OffsetDirection.after, 0)],
        latitude: 32.65,
        longitude: 51.67,
        utcOffsetHours: 3.5,
        now: DateTime(2026, 11, 26),
      );
      expect(overlaps, hasLength(1));
      expect(overlaps.first.fixedIndex, 0);
      expect(overlaps.first.astroIndex, 1);
      expect(overlaps.first.days, greaterThan(0));
      expect(overlaps.first.days, lessThan(366));
    });

    test('astroOverlapWarnings finds nothing outside the sweep', () {
      final overlaps = astroOverlapWarnings(
        [fixed(12, 0), solar(SolarBase.sunrise, OffsetDirection.after, 0)],
        latitude: 32.65,
        longitude: 51.67,
        utcOffsetHours: 3.5,
        now: DateTime(2026, 11, 26),
      );
      expect(overlaps, isEmpty);
    });
  });

  group('pool capacity', () {
    test('event usage counts every chain step', () {
      final p = Program(
        id: 1,
        name: 'p',
        cycle: CycleType.daily,
        events: [fixed(6, 30), fixed(7, 0)],
        assign: Assignment(),
      );
      expect(eventPoolUsage([p]), 2);
      expect(eventCapacityOk([p], draftEvents: List.generate(253, (_) => fixed(8, 0))),
          isTrue);
      expect(eventCapacityOk([p], draftEvents: List.generate(254, (_) => fixed(8, 0))),
          isFalse);
    });

    test('timer usage counts distinct configurations', () {
      final a = fixed(6, 0)..cmd = RelayCommand.timer;
      final b = fixed(7, 0)..cmd = RelayCommand.timer;
      b.onPhase = TimerPhase(hours: 1, minutes: 0);
      final p = Program(
        id: 1,
        name: 'p',
        cycle: CycleType.daily,
        events: [a, b],
        assign: Assignment(),
      );
      expect(timerPoolUsage([p]), 2);
      expect(timerPoolUsage([p]), lessThanOrEqualTo(DomainLimits.maxTimers));
    });
  });

  group('event JSON round-trip', () {
    test('fixed and solar events survive serialization', () {
      final ev = solar(SolarBase.sunset, OffsetDirection.before, 15)
        ..cmd = RelayCommand.timer
        ..start = TimerStart.offPhase;
      final back = Event.fromJson(ev.toJson());
      expect(back.type, EventType.astro);
      expect(back.astro, SolarBase.sunset);
      expect(back.offsetDirection, OffsetDirection.before);
      expect(back.offsetMinutes, 15);
      expect(back.cmd, RelayCommand.timer);
      expect(back.start, TimerStart.offPhase);
    });
  });
}
