/// Pure validation logic — Q-06 field ranges, Q-10 same-minute conflicts and
/// the four command-chain rules R-01..R-04 (user-defined, formal wording in
/// the l10n deck). No Flutter imports: fully unit-testable. [§7.3]
library;

import '../constants/domain.dart';
import '../models/program.dart';

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

/// Violations introduced by placing [candidate] into [list].
///
/// When editing ([skipIndex] ≥ 0) the candidate replaces that position;
/// otherwise it is appended at the end — exactly the position the user sees.
List<ChainViolation> violationsWithCandidate(
  Event candidate,
  List<Event> list, {
  int skipIndex = -1,
}) {
  final merged = <Event>[];
  final insertAt = skipIndex >= 0 && skipIndex < list.length ? skipIndex : list.length;
  for (var i = 0; i < list.length; i++) {
    if (i == insertAt) {
      merged.add(candidate);
    }
    if (i != skipIndex) merged.add(list[i]);
  }
  if (insertAt >= list.length || list.isEmpty) merged.add(candidate);
  final pos = insertAt >= merged.length ? merged.length - 1 : insertAt;
  final all = chainRuleViolations(merged);
  return all.where((v) => v.a == pos || v.b == pos).toList();
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
