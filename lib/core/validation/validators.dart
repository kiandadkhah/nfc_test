/// Pure validation logic — Q-06 field ranges, Q-10 same-minute conflicts and
/// the four command-chain rules R-01..R-04 (user-defined, formal wording in
/// the l10n deck), plus the v4.1 chain-sorting strategy and the annual
/// fixed↔solar overlap analysis. No Flutter imports: fully unit-testable. [§7.3]
library;

import '../constants/domain.dart';
import '../models/program.dart';
import '../solar/solar_events.dart';

class ConflictPair {
  const ConflictPair(this.firstIndex, this.secondIndex, this.minute);

  final int firstIndex;
  final int secondIndex;
  final int? minute;
}

/// The four user-defined chain rules, in evaluation priority order.
enum ChainRule {
  /// R-01 — two commands with the same run time (anywhere in the chain).
  sameTime,

  /// R-02 — two consecutive commands less than 5 minutes apart.
  minGap,

  /// R-03 — two consecutive commands with the same relay action (on→on/off→off).
  sameAct,

  /// R-04 — two consecutive commands with identical timer settings.
  sameTimer,
}

/// One rule violation. [a] and [b] are indices into the evaluated chain
/// (a < b). [minute]/[gap] carry extra context for the user-facing message.
class ChainViolation {
  const ChainViolation(this.rule, this.a, this.b, {this.minute, this.gap});

  final ChainRule rule;
  final int a;
  final int b;
  final int? minute;
  final int? gap;

  @override
  bool operator ==(Object other) =>
      other is ChainViolation &&
      other.rule == rule &&
      other.a == a &&
      other.b == b &&
      other.minute == minute &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(rule, a, b, minute, gap);
}

// =====================================================================
// v4.1 chain sorting strategy
//
// Solar command times (sunrise / sunset) drift through the year, so they
// cannot be interleaved with fixed times by a static minute-of-day key.
// The deterministic, year-stable order groups the chain as:
//   1. sunrise-anchored commands (sorted by effective offset),
//   2. fixed-time commands (sorted by minute of day from 00:00),
//   3. sunset-anchored commands (sorted by effective offset).
// The same order is used by the UI, the validators and the device payload
// (see buildProgramWritePlan) — one order everywhere.
// =====================================================================

/// Execution group of an event: 0 = sunrise, 1 = fixed, 2 = sunset.
int chainGroupOf(Event ev) => ev.type == EventType.astro
    ? (ev.astro == SolarBase.sunrise ? 0 : 2)
    : 1;

/// In-group sort key: fixed → minute of day; solar → effective offset
/// («قبل از» sorts before the base, i.e. negative).
int chainSortKeyOf(Event ev) => ev.type == EventType.fixed
    ? ev.fixedMinute!
    : (ev.offsetDirection == OffsetDirection.before
        ? -ev.offsetMinutes
        : ev.offsetMinutes);

/// Stable sorted copy of a chain — group, then sort key, then the original
/// insertion order for ties. The list is re-sorted automatically on every
/// add / edit / delete, so the displayed and executed order is always
/// time-based. [v4.1 user report: «لیست با هر دستور جدید مرتب شود»]
List<Event> sortChain(List<Event> events) {
  final indexed = <(int, Event)>[
    for (var i = 0; i < events.length; i++) (i, events[i]),
  ];
  indexed.sort((x, y) {
    final g = chainGroupOf(x.$2).compareTo(chainGroupOf(y.$2));
    if (g != 0) return g;
    final k = chainSortKeyOf(x.$2).compareTo(chainSortKeyOf(y.$2));
    if (k != 0) return k;
    return x.$1.compareTo(y.$1);
  });
  return [for (final e in indexed) e.$2];
}

/// Q-06: timer phase must be 5..720 minutes, multiple of 5.
bool isPhaseValid(TimerPhase phase) => phase.isValid;

/// Q-10 / C-01 (R-01): two events must not fire in the same minute.
/// Fixed events are compared by exact minute; solar events share the
/// (base, direction, offset) key because their real time depends on the day.
/// Zero offsets are normalised (sunrise+before-0 == sunrise+after-0).
List<ConflictPair> findChainConflicts(List<Event> events) {
  final out = <ConflictPair>[];
  for (var i = 0; i < events.length; i++) {
    for (var j = i + 1; j < events.length; j++) {
      final a = events[i];
      final b = events[j];
      if (a.type == EventType.fixed && b.type == EventType.fixed) {
        if (a.fixedMinute == b.fixedMinute) {
          out.add(ConflictPair(i, j, a.fixedMinute));
        }
      } else if (a.type == EventType.astro && b.type == EventType.astro) {
        if (solarKeyOf(a) == solarKeyOf(b)) {
          out.add(ConflictPair(i, j, null));
        }
      }
    }
  }
  return out;
}

/// Static key of a solar event: same base + direction + offset = same real
/// minute every day. Zero offsets are normalised so «قبل از طلوع ۰» and
/// «بعد از طلوع ۰» are correctly detected as the same instant.
String solarKeyOf(Event ev) {
  final sign = ev.offsetMinutes == 0 ? OffsetDirection.after : ev.offsetDirection;
  return '${ev.astro.name}|${sign.name}|${ev.offsetMinutes}';
}

/// Static key of a timer configuration (ON/OFF durations + start phase).
String timerKeyOf(Event ev) =>
    '${ev.onPhase.totalMinutes}|${ev.offPhase.totalMinutes}|${ev.start.name}';

/// The four chain rules R-01..R-04 evaluated on one chain.
///
/// «متوالی / پشت‌سرهم» = adjacent in the chain list order — the order the
/// user arranges, the app displays and numbers, and the device executes.
/// A command with a different relay action between two same-action commands
/// breaks adjacency, so that pair is NOT checked (regression guard for the
/// adjacent-pair bug report). One violation per pair; priority:
/// sameTime > minGap > sameTimer > sameAct.
List<ChainViolation> chainRuleViolations(List<Event> events) {
  final out = <ChainViolation>[];
  final seen = <String>{};
  final pairBlocked = <String>{}; // pairs already carrying a violation

  void push(ChainRule rule, int x, int y, {int? minute, int? gap}) {
    final lo = x < y ? x : y;
    final hi = x < y ? y : x;
    final key = '${rule.name}|$lo|$hi';
    if (seen.contains(key)) return;
    seen.add(key);
    pairBlocked.add('$lo|$hi');
    out.add(ChainViolation(rule, lo, hi, minute: minute, gap: gap));
  }

  final evs = events;

  // R-01 — any pair with the identical run time (fixed↔fixed / solar↔solar).
  for (var i = 0; i < evs.length; i++) {
    for (var j = i + 1; j < evs.length; j++) {
      final a = evs[i];
      final b = evs[j];
      if (a.type == EventType.fixed && b.type == EventType.fixed) {
        if (a.fixedMinute == b.fixedMinute) {
          push(ChainRule.sameTime, i, j, minute: a.fixedMinute);
        }
      } else if (a.type == EventType.astro && b.type == EventType.astro) {
        if (solarKeyOf(a) == solarKeyOf(b)) {
          push(ChainRule.sameTime, i, j);
        }
      }
    }
  }

  // R-02 / R-03 / R-04 — consecutive = adjacent in the chain list order.
  for (var i = 0; i + 1 < evs.length; i++) {
    final a = evs[i];
    final b = evs[i + 1];
    if (pairBlocked.contains('$i|${i + 1}')) continue; // already reported as R-01

    if (a.type == EventType.fixed && b.type == EventType.fixed) {
      final am = a.fixedMinute!;
      final bm = b.fixedMinute!;
      // Forward distance inside the daily cycle: 23:59 → 00:02 = 3 min.
      final gap = ((bm - am) % 1440 + 1440) % 1440;
      if (gap == 0) continue; // already reported as R-01
      if (gap < DomainLimits.minGapMinutes) {
        push(ChainRule.minGap, i, i + 1, gap: gap);
        continue;
      }
    }

    if (a.type == EventType.astro && b.type == EventType.astro) {
      // Same base → their offset keys order the real minutes; a small
      // offset distance is a R-02 violation. Different bases (sunrise↔
      // sunset) are always hours apart — nothing to check statically.
      if (a.astro == b.astro) {
        final gap = (chainSortKeyOf(b) - chainSortKeyOf(a)).abs();
        if (gap == 0) continue; // already reported as R-01
        if (gap < DomainLimits.minGapMinutes) {
          push(ChainRule.minGap, i, i + 1, gap: gap);
        }
      }
      continue; // [v4.1] R-03 is exempt for solar commands — their real
      // time moves through the year, so a static same-action adjacency
      // cannot be a device error (user-approved separation from R-3).
    }

    if (a.type == EventType.astro || b.type == EventType.astro) {
      // Fixed↔solar adjacency — not statically decidable (the solar time
      // sweeps across the year). The annual overlap analysis below
      // reports the exact coinciding date range instead.
      continue;
    }

    if (a.cmd == RelayCommand.timer && b.cmd == RelayCommand.timer) {
      if (timerKeyOf(a) == timerKeyOf(b)) push(ChainRule.sameTimer, i, i + 1);
      continue; // a timer has no static relay state — R-03 does not apply
    }
    if ((a.cmd == RelayCommand.on || a.cmd == RelayCommand.off) && a.cmd == b.cmd) {
      push(ChainRule.sameAct, i, i + 1);
    }
  }
  return out;
}

// =====================================================================
// v4.1 annual fixed↔solar overlap analysis
// =====================================================================

/// One annual coincidence: the fixed command fires in the same minute as
/// the solar command on [days] days of the year, between [firstDate] and
/// [lastDate]. Indices refer to the SORTED chain.
class AstroOverlap {
  const AstroOverlap({
    required this.fixedIndex,
    required this.astroIndex,
    required this.days,
    required this.firstDate,
    required this.lastDate,
  });

  final int fixedIndex;
  final int astroIndex;
  final int days;
  final DateTime firstDate;
  final DateTime lastDate;
}

/// Finds the fixed-time commands that coincide with a solar command on
/// specific days of the year. Sunrise/sunset sweep a minute range across
/// the year, so a fixed command inside that range collides with the solar
/// command on the days the sweep crosses its exact minute — the strategy
/// chosen for «یک دستور با ساعت مشخص در برخی روزهای سال با طلوع/غروب
/// همپوشانی دارد». The result is advisory (non-blocking): the chain order
/// decides which command wins at the shared instant.
/// [events] must be the sorted chain (sortChain), so the indices match the
/// displayed order. Pure Dart — uses the same NOAA model as the payload.
List<AstroOverlap> astroOverlapWarnings(
  List<Event> events, {
  required double latitude,
  required double longitude,
  required double utcOffsetHours,
  DateTime? now,
}) {
  final ref = now ?? DateTime.now();
  final year = ref.year;
  final daysInYear =
      (year % 4 == 0 && year % 100 != 0) || year % 400 == 0 ? 366 : 365;
  final jan1 = DateTime(year, 1, 1);
  final sunrise = List<int>.filled(daysInYear, 0);
  final sunset = List<int>.filled(daysInYear, 0);
  for (var d = 0; d < daysInYear; d++) {
    final date = jan1.add(Duration(days: d));
    final t = solarTimesFor(
      year: date.year,
      month: date.month,
      day: date.day,
      latitude: latitude,
      longitude: longitude,
      utcOffsetHours: utcOffsetHours,
    );
    sunrise[d] = t.sunriseMinutes;
    sunset[d] = t.sunsetMinutes;
  }

  final out = <AstroOverlap>[];
  for (var ai = 0; ai < events.length; ai++) {
    final astro = events[ai];
    if (astro.type != EventType.astro) continue;
    final base = astro.astro == SolarBase.sunrise ? sunrise : sunset;
    final sign = astro.offsetDirection == OffsetDirection.before ? -1 : 1;
    for (var fi = 0; fi < events.length; fi++) {
      final fixedEv = events[fi];
      if (fixedEv.type != EventType.fixed) continue;
      if (fixedEv.cmd == RelayCommand.timer) continue; // timers have no instant
      final target = fixedEv.fixedMinute!;
      var first = -1;
      var last = -1;
      var count = 0;
      for (var d = 0; d < daysInYear; d++) {
        final eff = (base[d] + sign * astro.offsetMinutes) % 1440;
        if (eff == target) {
          count += 1;
          if (first < 0) first = d;
          last = d;
        }
      }
      if (count > 0) {
        out.add(AstroOverlap(
          fixedIndex: fi,
          astroIndex: ai,
          days: count,
          firstDate: jan1.add(Duration(days: first)),
          lastDate: jan1.add(Duration(days: last)),
        ));
      }
    }
  }
  return out;
}

/// Result of checking one candidate event against a chain.
class CandidateCheckResult {
  const CandidateCheckResult({required this.position, required this.violations});

  /// Position of the candidate in the SORTED chain — the position the UI
  /// displays after the automatic re-sort.
  final int position;
  final List<ChainViolation> violations;
}

/// Violations introduced by placing [candidate] into [list], evaluated on
/// the SORTED chain — the candidate is checked in the exact position it
/// will occupy after the automatic re-sort, so adjacency is only evaluated
/// against its real neighbours. When editing ([skipIndex] ≥ 0) the
/// candidate replaces that entry.
CandidateCheckResult candidateCheck(
  Event candidate,
  List<Event> list, {
  int skipIndex = -1,
}) {
  final without = <Event>[
    for (var i = 0; i < list.length; i++)
      if (i != skipIndex) list[i],
  ];
  final merged = [...without, candidate];
  final sorted = sortChain(merged);
  var pos = sorted.indexWhere((e) => identical(e, candidate));
  if (pos < 0) {
    // Defensive fallback — the sort keeps references, so this is not
    // expected; match structurally if a copy ever slips through.
    final key = candidate.toJson().toString();
    pos = sorted.indexWhere((e) => e.toJson().toString() == key);
  }
  final all = chainRuleViolations(sorted);
  return CandidateCheckResult(
    position: pos < 0 ? sorted.length - 1 : pos,
    violations: all.where((v) => v.a == pos || v.b == pos).toList(),
  );
}

/// Total events across all programs (each chain step occupies one pool slot).
int eventPoolUsage(List<Program> programs) {
  var n = 0;
  for (final p in programs) {
    n += p.events.length;
  }
  return n;
}

/// Total events across the enabled programs only — disabled programs are not
/// written to the relay, so they do not consume the transfer payload.
int enabledEventPoolUsage(List<Program> programs) =>
    eventPoolUsage(programs.where((p) => p.enabled).toList());

/// Distinct timer configurations currently referenced by timer events.
int timerPoolUsage(List<Program> programs) {
  final keys = <String>{};
  for (final p in programs) {
    for (final e in p.events) {
      if (e.cmd == RelayCommand.timer) {
        keys.add(timerKeyOf(e));
      }
    }
  }
  return keys.length;
}

/// Distinct timer configurations of the enabled programs only.
int enabledTimerPoolUsage(List<Program> programs) =>
    timerPoolUsage(programs.where((p) => p.enabled).toList());

/// Storage-check for the write payload: only ENABLED programs consume
/// device event slots (disabled programs are never sent — reported bug
/// fix). [draftEvents] is the program being built; when editing an
/// existing program, pass its id in [replacingId] so its events are not
/// counted twice.
bool eventCapacityOk(
  List<Program> programs, {
  List<Event> draftEvents = const [],
  int replacingId = -1,
}) {
  final usage = programs
          .where((p) => p.enabled && p.id != replacingId)
          .fold<int>(0, (n, p) => n + p.events.length) +
      draftEvents.length;
  return usage <= DomainLimits.maxEvents;
}

// =====================================================================
// v4.3 program rules — the day-slot architecture of the PTS50R1 memory
// (map_memory_2.csv) allows exactly ONE chain per cycle slot:
//   · block 118  — ONE daily head (the whole day table has one slot);
//   · block 116/117 — 7 weekly day slots, one chain pointer per day;
//   · block 108..110 — 31 monthly day slots;
//   · block 16..107 — 366 annual day slots.
// Writing two chains into the same slot silently overwrites the first
// one (the v4.2.0 report: «برای روزهای شنبه و دوشنبه دو زنجیره رویداد
// وجود دارد ولی از لحاظ معماری حافظه این امکان‌پذیر نیست»). The rules
// below make the conflict explicit BEFORE anything reaches the tag.
// =====================================================================

/// The five program rules in evaluation priority order.
enum ProgramRule {
  /// P-01 — more than one enabled program with the DAILY cycle (the
  /// daily day table holds a single head slot).
  duplicateDaily,

  /// P-02 — two enabled WEEKLY programs assigned to the same weekday.
  weeklyOverlap,

  /// P-03 — two enabled MONTHLY programs assigned to the same month day.
  monthlyOverlap,

  /// P-04 — two enabled ANNUAL programs assigned to the same year day.
  annualOverlap,

  /// P-05 (advisory, non-blocking) — an enabled DAILY program coexists
  /// with another cycle: per C-05 priority (annual > monthly > weekly >
  /// daily) the daily chain does NOT run on the days the other cycles
  /// claim. The transfer is allowed; the user is informed.
  dailyShadowed,
}

/// One program-rule violation. [a]/[b] are program names; [days] carries
/// the conflicting day numbers (weekly: 0..6, monthly: 1..31, annual:
/// 1..366) — the UI renders them with the localized day names.
class ProgramViolation {
  const ProgramViolation(
    this.rule,
    this.a,
    this.b, {
    this.days = const [],
  });

  final ProgramRule rule;
  final String a;
  final String b;
  final List<int> days;

  /// P-05 is an informational warning, the other rules block the save.
  bool get blocking => rule != ProgramRule.dailyShadowed;

  @override
  bool operator ==(Object other) =>
      other is ProgramViolation &&
      other.rule == rule &&
      other.a == a &&
      other.b == b &&
      other.days.length == days.length;

  @override
  int get hashCode => Object.hash(rule, a, b, days.length);
}

/// Effective list of ENABLED programs for the next transfer: the draft (if
/// any) replaces the program being edited. Shared by the save check and
/// the UI banners so both see the exact payload of the next NFC write.
List<Program> effectiveEnabledPrograms(
  List<Program> programs, {
  Program? draft,
  int draftEditIndex = -1,
}) {
  final out = <Program>[];
  for (var i = 0; i < programs.length; i++) {
    if (i == draftEditIndex) continue; // replaced by the draft
    final p = programs[i];
    if (p.enabled) out.add(p);
  }
  if (draft != null && draft.name.isNotEmpty) {
    // The draft counts as enabled when the user is actively creating it
    // (a disabled draft cannot exist — the master switch appears on the
    // saved card only).
    out.add(draft);
  }
  return out;
}

List<int> _sortedDays(Set<int> set) => (set.toList()..sort());

/// Evaluates the program rules on the effective enabled list.
/// [includeAdvisory] adds the P-05 daily-shadowing warning.
List<ProgramViolation> programRuleViolations(
  List<Program> programs, {
  Program? draft,
  int draftEditIndex = -1,
  bool includeAdvisory = true,
}) {
  final enabled = effectiveEnabledPrograms(
    programs,
    draft: draft,
    draftEditIndex: draftEditIndex,
  );
  final out = <ProgramViolation>[];

  // P-01 — only ONE daily program can exist.
  final dailies = enabled.where((p) => p.cycle == CycleType.daily).toList();
  if (dailies.length > 1) {
    out.add(ProgramViolation(
      ProgramRule.duplicateDaily,
      dailies.first.name,
      dailies[1].name,
    ));
  }

  // P-02..P-04 — same-cycle day overlap (day slots are unique).
  for (final cycle in const [
    (CycleType.weekly, ProgramRule.weeklyOverlap),
    (CycleType.monthly, ProgramRule.monthlyOverlap),
    (CycleType.annual, ProgramRule.annualOverlap),
  ]) {
    final kind = cycle.$1;
    final sameCycle =
        enabled.where((p) => p.cycle == kind).toList();
    for (var i = 0; i < sameCycle.length; i++) {
      for (var j = i + 1; j < sameCycle.length; j++) {
        final d1 = _daysOf(sameCycle[i]);
        final d2 = _daysOf(sameCycle[j]);
        final shared = d1.intersection(d2);
        if (shared.isNotEmpty) {
          out.add(ProgramViolation(
            cycle.$2,
            sameCycle[i].name,
            sameCycle[j].name,
            days: _sortedDays(shared),
          ));
        }
      }
    }
  }

  // P-05 — daily coexisting with another cycle (advisory only).
  if (includeAdvisory && dailies.isNotEmpty) {
    final others = enabled
        .where((p) =>
            p.cycle == CycleType.weekly ||
            p.cycle == CycleType.monthly ||
            p.cycle == CycleType.annual)
        .toList();
    if (others.isNotEmpty) {
      out.add(ProgramViolation(
        ProgramRule.dailyShadowed,
        dailies.first.name,
        others.map((p) => p.name).join('، '),
        days: _sortedDays({
          for (final p in others) ..._daysOf(p),
        }),
      ));
    }
  }
  return out;
}

/// True when at least one BLOCKING program rule violation exists.
bool programRulesBlock(
  List<Program> programs, {
  Program? draft,
  int draftEditIndex = -1,
}) =>
    programRuleViolations(programs, draft: draft, draftEditIndex: draftEditIndex)
        .any((v) => v.blocking);

Set<int> _daysOf(Program p) => switch (p.cycle) {
      CycleType.daily => const {0},
      CycleType.weekly => p.assign.weekly.toSet(),
      CycleType.monthly => p.assign.monthly.toSet(),
      CycleType.annual => p.assign.annualDays.toSet(),
    };
