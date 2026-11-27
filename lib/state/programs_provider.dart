/// Programs state — the repository of timer programs plus the draft
/// used by the 3-step creation flow (name → cycle → chain). Riverpod.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/domain.dart';
import '../core/logging/app_logger.dart';
import '../core/models/program.dart';
import '../core/validation/validators.dart';

class ProgramsController extends ChangeNotifier {
  ProgramsController([SharedPreferences? prefs]) : _prefs = prefs;

  final SharedPreferences? _prefs;

  static const _kData = 'programs.data';

  final List<Program> _programs = <Program>[];
  int _nextId = 1;

  void _persist() {
    final p = _prefs;
    if (p == null) return;
    p.setString(_kData, jsonEncode(toJsonForPersistence()));
  }

  /// The program under construction / edit (3-step flow).
  Program? _draft;
  int _draftEditIndex = -1;

  List<Program> get programs => List.unmodifiable(_programs);

  /// Enabled programs only — the write payload never contains a disabled
  /// program (Q-05: «برنامه غیرفعال به رله ارسال نمی‌شود»).
  List<Program> get enabledPrograms =>
      _programs.where((p) => p.enabled).toList(growable: false);

  int get activeCount => _programs.where((p) => p.enabled).length;
  int get disabledCount => _programs.length - activeCount;

  int get enabledEventUsage => eventPoolUsage(enabledPrograms);
  int get enabledTimerUsage => timerPoolUsage(enabledPrograms);

  Program? get draft => _draft;
  int get draftEditIndex => _draftEditIndex;
  bool get hasDraft => _draft != null;

  /// v4.3 — program-rule violations of the last [saveDraft] attempt (also
  /// filled by the Chain/Assign screens through [draftProgramViolations]).
  List<ProgramViolation> _lastProgramViolations = const [];
  List<ProgramViolation> get lastProgramViolations => _lastProgramViolations;

  /// Program-rule violations of the current draft against the saved list —
  /// the exact set the next transfer would carry. [includeAdvisory] adds
  /// the non-blocking P-05 daily-shadowing notice.
  List<ProgramViolation> draftProgramViolations({bool includeAdvisory = true}) =>
      programRuleViolations(
        _programs,
        draft: _draft,
        draftEditIndex: _draftEditIndex,
        includeAdvisory: includeAdvisory,
      );

  int get eventUsage => eventPoolUsage(_programs);
  int get timerUsage => timerPoolUsage(_programs);

  /// Projected payload usage with the open draft — enabled programs only,
  /// the program being edited replaced by the draft (matches exactly what
  /// the next NFC transfer writes to the relay).
  int get projectedEventUsage {
    final editing = _draftEditIndex >= 0 && _draftEditIndex < _programs.length;
    final replaceEnabled = editing && _programs[_draftEditIndex].enabled;
    final base = eventPoolUsage(enabledPrograms) -
        (replaceEnabled ? _programs[_draftEditIndex].events.length : 0);
    return base + (_draft?.events.length ?? 0);
  }

  int get projectedTimerUsage {
    final editing = _draftEditIndex >= 0 && _draftEditIndex < _programs.length;
    var list = enabledPrograms;
    if (editing && _programs[_draftEditIndex].enabled) {
      final editedId = _programs[_draftEditIndex].id;
      list = list.where((p) => p.id != editedId).toList();
    }
    if (_draft != null) list = [...list, _draft!];
    return timerPoolUsage(list);
  }

  void startDraft() {
    // id is assigned at save time; -1 marks the unsaved draft.
    _draft = Program(
      id: -1,
      name: '',
      cycle: CycleType.daily,
      events: [],
      assign: Assignment(),
    );
    _draftEditIndex = -1;
    notifyListeners();
  }

  void editProgramAt(int index) {
    final p = _programs[index].copy();
    _draft = p;
    _draftEditIndex = index;
    notifyListeners();
  }

  void setDraftName(String name) {
    if (_draft == null) return;
    _draft!.name = name;
    notifyListeners();
  }

  void setDraftCycle(CycleType cycle) {
    if (_draft == null) return;
    _draft!.cycle = cycle;
    notifyListeners();
  }

  void addDraftEvent(Event e) {
    _draft?.events.add(e);
    _sortDraftEvents();
    notifyListeners();
  }

  void replaceDraftEvent(int index, Event e) {
    if (_draft == null) return;
    _draft!.events[index] = e;
    _sortDraftEvents();
    notifyListeners();
  }

  void removeDraftEvent(int index) {
    _draft?.events.removeAt(index);
    notifyListeners();
  }

  /// [v4.1] The chain is always kept in time order (sunrise group → fixed
  /// times → sunset group) — every add/edit re-sorts it, so the list the
  /// user sees, the numbering and the device payload stay in sync.
  void _sortDraftEvents() {
    if (_draft == null || _draft!.events.length < 2) return;
    // Sort a COPY of the list: the cascade evaluates its argument AFTER
    // clear() runs, so sorting the live list here read the already-emptied
    // list and silently wiped the whole chain (v4.1.0 field bug — creating
    // the second event deleted every event).
    final sorted = sortChain(List<Event>.from(_draft!.events));
    _draft!.events
      ..clear()
      ..addAll(sorted);
  }

  void toggleWeekly(int day) => _toggle(_draft?.assign.weekly, day);
  void toggleMonthly(int day) => _toggle(_draft?.assign.monthly, day);
  void toggleAnnual(int dayOfYear) => _toggle(_draft?.assign.annualDays, dayOfYear);

  void clearAssignment() {
    final a = _draft?.assign;
    if (a == null) return;
    a.weekly.clear();
    a.monthly.clear();
    a.annualDays.clear();
    notifyListeners();
  }

  void _toggle(List<int>? list, int value) {
    if (list == null) return;
    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }
    notifyListeners();
  }

  /// Saves the draft. Returns false when validation fails (Q-10 / capacity
  /// / v4.3 program-overlap rules) or when the edited program no longer
  /// exists — the draft is discarded so a deleted program can never be
  /// resurrected by «ذخیره برنامه» (bug fix: «در حالت ویرایش نباید آثاری
  /// از برنامه حذف‌شده باقی بماند»). The blocking rule set is exposed via
  /// [lastProgramViolations] so the caller can show the formal popup.
  bool saveDraft() {
    final d = _draft;
    if (d == null || d.name.isEmpty || d.events.isEmpty) return false;
    if (chainRuleViolations(d.events).isNotEmpty) return false;
    // Capacity is checked against the REAL write payload: enabled programs
    // only, the edited program replaced by the draft.
    final editing = _draftEditIndex >= 0 && _draftEditIndex < _programs.length;
    final replaceEnabled = editing && _programs[_draftEditIndex].enabled;
    final projected = eventPoolUsage(enabledPrograms) -
        (replaceEnabled ? _programs[_draftEditIndex].events.length : 0) +
        d.events.length;
    if (projected > DomainLimits.maxEvents) return false;
    // v4.3 program rules — a day slot of the device memory can hold only
    // ONE chain pointer; an overlapping save would silently overwrite the
    // first program. The violations are kept for the UI popup.
    _lastProgramViolations = programRuleViolations(
      _programs,
      draft: d,
      draftEditIndex: _draftEditIndex,
    );
    if (_lastProgramViolations.any((v) => v.blocking)) return false;
    if (_draftEditIndex >= 0) {
      if (_draftEditIndex >= _programs.length) {
        // The edited program was deleted while the editor was open.
        _draft = null;
        _draftEditIndex = -1;
        notifyListeners();
        return false;
      }
      _programs[_draftEditIndex] = d..id = _programs[_draftEditIndex].id;
    } else {
      d.id = _nextId++;
      _programs.add(d);
    }
    _draft = null;
    _draftEditIndex = -1;
    _persist();
    AppLogger.instance.action(
        'program saved: id=${d.id}, name="${d.name}", cycle=${d.cycle.name}, '
        'events=${d.events.length}, enabled=${d.enabled}');
    notifyListeners();
    return true;
  }

  void cancelDraft() {
    _draft = null;
    _draftEditIndex = -1;
    notifyListeners();
  }

  /// Deletes a program and clears every editing-session trace of it:
  /// the open draft is dropped when it belongs to the deleted program, and
  /// the edit index is re-based for the remaining programs.
  void deleteAt(int index) {
    if (index < 0 || index >= _programs.length) return;
    final removed = _programs.removeAt(index);
    AppLogger.instance.action(
        'program deleted: id=${removed.id}, name="${removed.name}"');
    if (_draftEditIndex == index) {
      // Bug fix: after deleting the program being edited, no trace of the
      // draft may remain — «ذخیره برنامه» must not rebuild it.
      _draft = null;
      _draftEditIndex = -1;
    } else if (_draftEditIndex > index) {
      _draftEditIndex -= 1;
    }
    _persist();
    notifyListeners();
  }

  /// Master switch of a program — greyed-out card, same size. [Q-05]
  void toggleEnabled(int index) {
    if (index < 0 || index >= _programs.length) return;
    _programs[index].enabled = !_programs[index].enabled;
    final stateTxt = _programs[index].enabled ? 'enabled' : 'disabled';
    AppLogger.instance.action(
        'program $stateTxt: id=${_programs[index].id}, name="${_programs[index].name}"');
    _persist();
    notifyListeners();
  }

  List<Map<String, dynamic>> toJsonForPersistence() =>
      _programs.map((p) => p.toJson()).toList();

  void restoreFrom(List<Map<String, dynamic>> data) {
    _programs
      ..clear()
      ..addAll(data.map(Program.fromJson));
    _nextId = _programs.fold<int>(1, (m, p) => p.id >= m ? p.id + 1 : m);
    _persist();
    notifyListeners();
  }

  /// Loads the locally persisted list (silently skips corrupt payloads).
  /// Events of every program are re-sorted so chains created by older app
  /// versions also follow the v4.1 time order.
  void restoreFromLocalJson(String? raw) {
    if (raw == null || raw.isEmpty) return;
    try {
      final data = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      _programs
        ..clear()
        ..addAll(data.map(Program.fromJson));
      for (final p in _programs) {
        // Sort a COPY (see _sortDraftEvents) — sorting the live list after
        // clear() would wipe every persisted event on every app start.
        final sorted = sortChain(List<Event>.from(p.events));
        p.events
          ..clear()
          ..addAll(sorted);
      }
      _nextId = _programs.fold<int>(1, (m, p) => p.id >= m ? p.id + 1 : m);
    } catch (_) {
      // Corrupt payload — start fresh instead of crashing.
    }
    notifyListeners();
  }
}
