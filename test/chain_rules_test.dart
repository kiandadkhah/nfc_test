/// Regression tests for the command-chain rules R-01..R-04 — including the
/// two equivalence chains from the adjacent-pair bug report (bug #3/#4):
/// a command with a different relay action BETWEEN two same-action commands
/// breaks adjacency, so neither chain may report R-03.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:kianex_pts50n1_app/core/constants/domain.dart';
import 'package:kianex_pts50n1_app/core/models/program.dart';
import 'package:kianex_pts50n1_app/core/validation/validators.dart';

Event fixed(int hh, int mm, {RelayCommand cmd = RelayCommand.on}) => Event(
      type: EventType.fixed,
      hh: hh,
      mm: mm,
      cmd: cmd,
      onPhase: TimerPhase(hours: 0, minutes: 30),
      offPhase: TimerPhase(hours: 0, minutes: 15),
    );

Event solar(SolarBase base, OffsetDirection dir, int offset,
        {RelayCommand cmd = RelayCommand.on}) =>
    Event(
      type: EventType.astro,
      astro: base,
      offsetMinutes: offset,
      offsetDirection: dir,
      cmd: cmd,
      onPhase: TimerPhase(hours: 0, minutes: 30),
      offPhase: TimerPhase(hours: 0, minutes: 15),
    );

void main() {
  group('adjacency regression (bug #3 / #4)', () {
    test('chain [06:30 ON, sunrise TIMER, 09:00 ON] has no R-03 violation', () {
      final chain = [
        fixed(6, 30, cmd: RelayCommand.on),
        solar(SolarBase.sunrise, OffsetDirection.after, 0, cmd: RelayCommand.timer),
        fixed(9, 0, cmd: RelayCommand.on),
      ];
      final violations = chainRuleViolations(chain);
      expect(violations.where((v) => v.rule == ChainRule.sameAct), isEmpty);
      expect(violations, isEmpty);
    });

    test('equivalent chain with different clock times behaves identically', () {
      final a = chainRuleViolations([
        fixed(6, 0, cmd: RelayCommand.on),
        solar(SolarBase.sunrise, OffsetDirection.after, 0, cmd: RelayCommand.timer),
        fixed(12, 0, cmd: RelayCommand.on),
      ]);
      final b = chainRuleViolations([
        fixed(6, 30, cmd: RelayCommand.on),
        solar(SolarBase.sunrise, OffsetDirection.after, 0, cmd: RelayCommand.timer),
        fixed(9, 0, cmd: RelayCommand.on),
      ]);
      expect(a, isEmpty);
      expect(b, isEmpty);
      expect(a.length, b.length);
    });
  });

  group('R-01 same run time', () {
    test('two fixed commands at the same minute are rejected anywhere', () {
      final chain = [
        fixed(8, 0, cmd: RelayCommand.on),
        fixed(9, 0, cmd: RelayCommand.off),
        fixed(8, 0, cmd: RelayCommand.on),
      ];
      final v = chainRuleViolations(chain);
      expect(v.where((x) => x.rule == ChainRule.sameTime), hasLength(1));
      expect(v.first.a, 0);
      expect(v.first.b, 2);
    });

    test('zero solar offsets normalise to the same instant', () {
      final chain = [
        solar(SolarBase.sunrise, OffsetDirection.before, 0),
        solar(SolarBase.sunrise, OffsetDirection.after, 0),
      ];
      expect(
        chainRuleViolations(chain).where((v) => v.rule == ChainRule.sameTime),
        hasLength(1),
      );
    });
  });

  group('R-02 minimum interval', () {
    test('adjacent fixed commands 3 minutes apart are rejected', () {
      final chain = [fixed(8, 0, cmd: RelayCommand.on), fixed(8, 3, cmd: RelayCommand.off)];
      expect(
        chainRuleViolations(chain).map((v) => v.rule),
        contains(ChainRule.minGap),
      );
    });

    test('exactly 5 minutes apart is allowed', () {
      final chain = [fixed(8, 0, cmd: RelayCommand.on), fixed(8, 5, cmd: RelayCommand.off)];
      expect(chainRuleViolations(chain), isEmpty);
    });

    test('the interval is measured forward in the daily cycle (23:59 → 00:02)', () {
      final chain = [fixed(23, 59, cmd: RelayCommand.on), fixed(0, 2, cmd: RelayCommand.off)];
      expect(
        chainRuleViolations(chain).map((v) => v.rule),
        contains(ChainRule.minGap),
      );
    });

    test('non-adjacent commands closer than 5 minutes are allowed', () {
      // 8:00 → 8:04 is 4 minutes apart, but a timer command sits between
      // them — adjacency is broken, so R-02 does not apply to that pair.
      final chain = [
        fixed(8, 0, cmd: RelayCommand.on),
        fixed(8, 10, cmd: RelayCommand.timer),
        fixed(8, 4, cmd: RelayCommand.off),
      ];
      expect(
        chainRuleViolations(chain).where((v) => v.rule == ChainRule.minGap),
        isEmpty,
      );
    });
  });

  group('R-03 same relay action', () {
    test('adjacent ON → ON is rejected', () {
      final chain = [fixed(8, 0), fixed(8, 10)];
      expect(
        chainRuleViolations(chain).map((v) => v.rule),
        contains(ChainRule.sameAct),
      );
    });

    test('adjacent OFF → OFF is rejected', () {
      final chain = [fixed(8, 0, cmd: RelayCommand.off), fixed(8, 10, cmd: RelayCommand.off)];
      expect(
        chainRuleViolations(chain).map((v) => v.rule),
        contains(ChainRule.sameAct),
      );
    });

    test('adjacent ON → OFF is allowed', () {
      final chain = [fixed(8, 0), fixed(8, 10, cmd: RelayCommand.off)];
      expect(chainRuleViolations(chain), isEmpty);
    });
  });

  group('R-04 identical timer settings', () {
    Event timer(int hh, int mm, {int on = 60, int off = 45}) => fixed(hh, mm, cmd: RelayCommand.timer)
      ..onPhase = TimerPhase(hours: on ~/ 60, minutes: on % 60)
      ..offPhase = TimerPhase(hours: off ~/ 60, minutes: off % 60);

    test('adjacent timers with identical settings are rejected', () {
      final chain = [timer(8, 0), timer(8, 30)];
      final rules = chainRuleViolations(chain).map((v) => v.rule).toList();
      expect(rules, contains(ChainRule.sameTimer));
      expect(rules, isNot(contains(ChainRule.sameAct)));
    });

    test('adjacent timers with different settings are allowed', () {
      final chain = [timer(8, 0), timer(8, 30, on: 120, off: 90)];
      expect(chainRuleViolations(chain), isEmpty);
    });
  });
}
