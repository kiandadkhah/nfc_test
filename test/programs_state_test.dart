/// v4.2 regression tests for the programs state — the cascade wipe bug of
/// v4.1.0 («ساخت رویداد دوم باعث حذف تمام رویدادها می‌شود»): the draft
/// re-sort evaluated its argument AFTER clear(), so the second addDraftEvent
/// emptied the whole chain. The same bug in restoreFromLocalJson wiped every
/// persisted event on every app start. Both are fixed by sorting a COPY.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:kianex_pts50n1_app/core/constants/domain.dart';
import 'package:kianex_pts50n1_app/core/models/program.dart';
import 'package:kianex_pts50n1_app/state/programs_provider.dart';

Event _fixed(int hh, int mm, {RelayCommand cmd = RelayCommand.on}) => Event(
      type: EventType.fixed,
      hh: hh,
      mm: mm,
      cmd: cmd,
      onPhase: TimerPhase(hours: 0, minutes: 30),
      offPhase: TimerPhase(hours: 0, minutes: 15),
    );

Program _sampleProgram({required int id, required String name}) => Program(
      id: id,
      name: name,
      cycle: CycleType.daily,
      events: [_fixed(6, 30, cmd: RelayCommand.on), _fixed(7, 0, cmd: RelayCommand.off)],
      assign: Assignment(),
    );

void main() {
  group('draft chain — second event must NOT wipe the first', () {
    test('two addDraftEvent calls keep both events', () {
      final c = ProgramsController();
      c.startDraft();
      c.setDraftName('روزانه');
      c.addDraftEvent(_fixed(6, 30, cmd: RelayCommand.on));
      expect(c.draft!.events.length, 1);
      c.addDraftEvent(_fixed(7, 0, cmd: RelayCommand.off));
      // The v4.1.0 bug dropped this to 0 the moment the second event
      // triggered the re-sort.
      expect(c.draft!.events.length, 2);
    });

    test('saveDraft stores the full chain and clears the draft', () {
      final c = ProgramsController();
      c.startDraft();
      c.setDraftName('روزانه');
      c.addDraftEvent(_fixed(6, 30, cmd: RelayCommand.on));
      c.addDraftEvent(_fixed(7, 0, cmd: RelayCommand.off));
      expect(c.saveDraft(), isTrue);
      expect(c.programs.length, 1);
      expect(c.programs.first.events.length, 2);
      expect(c.hasDraft, isFalse);
    });

    test('editing an existing program keeps the previous events', () {
      final c = ProgramsController();
      c.startDraft();
      c.setDraftName('روزانه');
      c.addDraftEvent(_fixed(6, 30, cmd: RelayCommand.on));
      c.addDraftEvent(_fixed(7, 0, cmd: RelayCommand.off));
      c.saveDraft();
      c.editProgramAt(0);
      c.addDraftEvent(_fixed(18, 0, cmd: RelayCommand.on));
      c.saveDraft();
      expect(c.programs.first.events.length, 3);
    });
  });

  group('persistence round-trip', () {
    test('restoreFromLocalJson keeps every event of every program', () {
      final source = ProgramsController();
      source.startDraft();
      source.setDraftName('روزانه');
      source.addDraftEvent(_fixed(6, 30, cmd: RelayCommand.on));
      source.addDraftEvent(_fixed(7, 0, cmd: RelayCommand.off));
      source.saveDraft();
      final raw = jsonEncode(source.toJsonForPersistence());

      final restored = ProgramsController();
      restored.restoreFromLocalJson(raw);
      expect(restored.programs.length, 1);
      // The v4.1.0 bug emptied this list on EVERY app start.
      expect(restored.programs.first.events.length, 2);
    });

    test('restore re-sorts chains created by older versions', () {
      final program = _sampleProgram(id: 1, name: 'روزانه');
      // Deliberately store the events in reverse order — the restore must
      // normalise the chain into the time order.
      program.events = program.events.reversed.toList();
      final raw = jsonEncode([program.toJson()]);

      final restored = ProgramsController();
      restored.restoreFromLocalJson(raw);
      final events = restored.programs.first.events;
      expect(events.length, 2);
      expect(events.first.fixedMinute, lessThan(events.last.fixedMinute!));
    });
  });
}
