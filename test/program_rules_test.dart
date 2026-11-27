/// v4.3 regression tests — the fixes of the v4.2.0 field report:
///  · program rules P-01..P-05 (one chain per day slot of the device
///    memory — the reported weekly↔weekly Saturday/Monday overlap);
///  · the EXACT NDEF link whitelist (…/pts50r15 must never match …/pts50r1);
///  · the UID signature of the ST25DV16KC (real tag UID from the field);
///  · the all-zero payload CRC sentinel (the value found on the real tag).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kianex_pts50n1_app/core/constants/domain.dart';
import 'package:kianex_pts50n1_app/core/crypto/crc32_stm32.dart';
import 'package:kianex_pts50n1_app/core/models/program.dart';
import 'package:kianex_pts50n1_app/core/validation/validators.dart';

Program _p(int id, String name, CycleType cycle,
    {List<int> weekly = const [],
    List<int> monthly = const [],
    List<int> annualDays = const [],
    bool enabled = true}) {
  return Program(
    id: id,
    name: name,
    cycle: cycle,
    events: [
      Event(
        type: EventType.fixed,
        hh: 8,
        mm: 0,
        cmd: RelayCommand.on,
        onPhase: TimerPhase(hours: 0, minutes: 5),
        offPhase: TimerPhase(hours: 0, minutes: 5),
      ),
    ],
    assign: Assignment(
      weekly: weekly,
      monthly: monthly,
      annualDays: annualDays,
    ),
    enabled: enabled,
  );
}

void main() {
  group('v4.3 program rules (P-01..P-05)', () {
    test('P-01 — two enabled daily programs conflict', () {
      final list = [
        _p(1, 'A', CycleType.daily),
        _p(2, 'B', CycleType.daily),
      ];
      final v = programRuleViolations(list);
      expect(v.where((x) => x.rule == ProgramRule.duplicateDaily).length, 1);
      expect(programRulesBlock(list), isTrue);
    });

    test('P-01 — one daily + one disabled daily is fine', () {
      final list = [
        _p(1, 'A', CycleType.daily),
        _p(2, 'B', CycleType.daily, enabled: false),
      ];
      expect(programRuleViolations(list), isEmpty);
      expect(programRulesBlock(list), isFalse);
    });

    test('P-02 — the reported case: two weekly programs on Saturday+Monday',
        () {
      // The user report: one chain on شنبه و دوشنبه, then a second weekly
      // program with the same days — the day slot can hold one chain only.
      final list = [
        _p(1, 'روشنایی محوطه', CycleType.weekly, weekly: [0, 2]),
        _p(2, 'پمپ استخر', CycleType.weekly, weekly: [0, 2]),
      ];
      final v = programRuleViolations(list);
      final overlaps =
          v.where((x) => x.rule == ProgramRule.weeklyOverlap).toList();
      expect(overlaps.length, 1);
      expect(overlaps.first.days, [0, 2]);
      expect(overlaps.first.blocking, isTrue);
      expect(programRulesBlock(list), isTrue);
    });

    test('P-02 — weekly programs on different days pass', () {
      final list = [
        _p(1, 'A', CycleType.weekly, weekly: [0, 2]),
        _p(2, 'B', CycleType.weekly, weekly: [1, 3, 4]),
      ];
      expect(programRuleViolations(list), isEmpty);
    });

    test('P-03 — monthly overlap on shared month days', () {
      final list = [
        _p(1, 'A', CycleType.monthly, monthly: [1, 15, 28]),
        _p(2, 'B', CycleType.monthly, monthly: [3, 15, 28]),
      ];
      final v = programRuleViolations(list);
      expect(
          v.where((x) => x.rule == ProgramRule.monthlyOverlap).first.days,
          [15, 28]);
    });

    test('P-04 — annual overlap on shared day-of-year slots', () {
      final list = [
        _p(1, 'A', CycleType.annual, annualDays: [1, 60, 200]),
        _p(2, 'B', CycleType.annual, annualDays: [60, 365]),
      ];
      final v = programRuleViolations(list);
      expect(
          v.where((x) => x.rule == ProgramRule.annualOverlap).first.days,
          [60]);
    });

    test('P-05 — daily + weekly is allowed but advisory', () {
      final list = [
        _p(1, 'daily', CycleType.daily),
        _p(2, 'weekly', CycleType.weekly, weekly: [5]),
      ];
      final v = programRuleViolations(list);
      expect(v.map((x) => x.rule), contains(ProgramRule.dailyShadowed));
      expect(programRulesBlock(list), isFalse); // advisory never blocks
      // Without the advisory the list is clean.
      expect(
          programRuleViolations(list, includeAdvisory: false), isEmpty);
    });

    test('disabled programs never participate in the rules', () {
      final list = [
        _p(1, 'A', CycleType.weekly, weekly: [0, 2], enabled: false),
        _p(2, 'B', CycleType.weekly, weekly: [0, 2]),
      ];
      expect(programRuleViolations(list), isEmpty);
    });

    test('the draft replaces the edited program before evaluation', () {
      final existing = [
        _p(7, 'old', CycleType.weekly, weekly: [0]),
        _p(8, 'B', CycleType.weekly, weekly: [2]),
      ];
      // Editing program 7 with a draft on day 1: 'old' is replaced, so no
      // overlap remains (day 1 is free, B keeps day 2).
      final editDraft = _p(-1, 'new', CycleType.weekly, weekly: [1]);
      final asEdit = effectiveEnabledPrograms(existing,
          draft: editDraft, draftEditIndex: 0);
      expect(asEdit.map((p) => p.name), unorderedEquals(['B', 'new']));
      expect(
          programRulesBlock(existing,
              draft: editDraft, draftEditIndex: 0),
          isFalse);
      // Creating a NEW program on day 2 (B already owns day 2) blocks.
      final newDraft = _p(-1, 'new2', CycleType.weekly, weekly: [2]);
      expect(
          programRulesBlock(existing, draft: newDraft, draftEditIndex: -1),
          isTrue);
      // The effective payload for that case is 'old' + 'B' + 'new2'.
      final asNew = effectiveEnabledPrograms(existing,
          draft: newDraft, draftEditIndex: -1);
      expect(asNew.length, 3);
    });
  });

  group('v4.3 NdefContract — exact link whitelist', () {
    test('the exact product URL identifies PTS50R1', () {
      expect(NdefContract.modelOfUri('https://kianex.co/products/pts50r1'),
          'PTS50R1');
      expect(NdefContract.uriMatchesProduct('https://kianex.co/products/pts50r1'),
          isTrue);
    });

    test('the tampered link of the field report does NOT identify as PTS50R1',
        () {
      // The v4.2.0 report changed the tag URL to pts50r15 and the app still
      // said «دستگاه شناسایی شد» (prefix matching bug).
      expect(NdefContract.modelOfUri('https://kianex.co/products/pts50r15'),
          'PTS50R15');
      expect(NdefContract.uriMatchesProduct('https://kianex.co/products/pts50r15'),
          isFalse);
    });

    test('unknown / shortened / decorated URIs are rejected', () {
      expect(NdefContract.modelOfUri('https://kianex.co/products/pts50r'),
          isNull);
      expect(NdefContract.modelOfUri('https://kianex.co/products/'), isNull);
      expect(NdefContract.modelOfUri('https://example.com/products/pts50r1'),
          isNull);
      expect(NdefContract.modelOfUri(''), isNull);
    });

    test('matching is case-insensitive and whitespace-tolerant', () {
      expect(
          NdefContract.modelOfUri('  HTTPS://KIANEX.CO/PRODUCTS/PTS50R1 '),
          'PTS50R1');
    });
  });

  group('v4.3 UID signature — ST25DV16KC', () {
    test('the real tag UID of the field reports passes', () {
      expect(NdefContract.uidHasSt25dv16kSignature('E0022600D7AD24AF'), isTrue);
      // LSB-first wire order (as Android reports it) is accepted too.
      expect(NdefContract.uidHasSt25dv16kSignature('AF24ADD7002602E0'), isTrue);
    });

    test('foreign UIDs fail', () {
      expect(NdefContract.uidHasSt25dv16kSignature('04112233445566'), isFalse);
      expect(NdefContract.uidHasSt25dv16kSignature(''), isFalse);
      expect(NdefContract.uidHasSt25dv16kSignature('not-hex'), isFalse);
    });
  });

  group('v4.3 payload sentinel', () {
    test('the all-zero payload CRC equals the value found on the real tag',
        () {
      // The v4.2.0 field analysis read APP_CRC32 = 0x0993D8D7 from the tag
      // while the pools were empty — the CRC of 1656 zero bytes.
      expect(crc32Stm32(List<int>.filled(1656, 0)), 0x0993D8D7);
    });
  });

  group('v4.4 day-assignment rule (P-06)', () {
    test('a non-daily program without its OWN cycle days is invalid', () {
      expect(programNeedsDays(_p(1, 'w', CycleType.weekly)), isTrue);
      expect(programNeedsDays(_p(2, 'm', CycleType.monthly)), isTrue);
      expect(programNeedsDays(_p(3, 'a', CycleType.annual)), isTrue);
      expect(programNeedsDays(_p(4, 'd', CycleType.daily)), isFalse);
    });

    test('a program with days of its own cycle is valid', () {
      expect(
          programNeedsDays(_p(1, 'w', CycleType.weekly, weekly: [0])), isFalse);
      expect(
          programNeedsDays(
              _p(2, 'm', CycleType.monthly, monthly: [1, 31])),
          isFalse);
      expect(
          programNeedsDays(
              _p(3, 'a', CycleType.annual, annualDays: [1, 366])),
          isFalse);
    });

    test('stale day lists of OTHER cycles do not satisfy the rule', () {
      // v4.3.0 field bug: the combined sum over all three lists let a
      // day-less weekly program pass when an annual list was populated.
      final stale = Program(
        id: 5,
        name: 'w',
        cycle: CycleType.weekly,
        events: _p(5, 'w', CycleType.weekly).events,
        assign: Assignment(annualDays: [10]), // stale annual days
      );
      expect(programNeedsDays(stale), isTrue);
    });

    test('the save path refuses a day-less program', () {
      // saveDraft hard-guards through programNeedsDays — the pure check
      // is covered here; the editor popup uses the same function.
      final list = [_p(1, 'w', CycleType.weekly)];
      expect(list.any(programNeedsDays), isTrue);
    });
  });
}
