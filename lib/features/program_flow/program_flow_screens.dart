import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/domain.dart';
import '../../core/models/program.dart';
import '../../core/solar/solar_events.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/jalali.dart';
import '../../core/validation/validators.dart';
import '../../core/widgets/rule_popup.dart';
import '../../state/providers.dart';
import '../../core/widgets/app_toasts.dart';

/// Main run-time text of an event — shared by the chain list and the
/// rule-violation messages.
String eventMainText(AppLocalizationsX l, bool fa, Event ev) {
  if (ev.type == EventType.fixed) return '${num2(fa, ev.hh)}:${num2(fa, ev.mm)}';
  final base = ev.astro == SolarBase.sunrise ? l.sunriseBase : l.sunsetBase;
  if (ev.offsetMinutes == 0) return base;
  return l.astroFmt(
    base,
    ev.offsetDirection == OffsetDirection.after ? '+' : '−',
    faNumInt(fa, ev.offsetMinutes),
  );
}

/// User-facing, formal text of one chain-rule violation (R-01..R-04).
String violationText(AppLocalizationsX l, bool fa, ChainViolation v, List<Event> events) {
  final a = events[v.a];
  final b = events[v.b];
  final n1 = faNumInt(fa, v.a + 1);
  final n2 = faNumInt(fa, v.b + 1);
  final t1 = eventMainText(l, fa, a);
  final t2 = eventMainText(l, fa, b);
  final actName = switch (a.cmd) {
    RelayCommand.on => l.cmdOn,
    RelayCommand.off => l.cmdOff,
    RelayCommand.timer => l.cmdTimer,
  };
  final timerFmt = l.ruleTimerFmt(
      phaseDurationText(l, fa, a.onPhase), phaseDurationText(l, fa, a.offPhase));
  return switch (v.rule) {
    ChainRule.sameTime => a.type == EventType.fixed && v.minute != null
        ? l.ruleSameTime(n1, n2, '${num2(fa, v.minute! ~/ 60)}:${num2(fa, v.minute! % 60)}')
        : l.ruleSameTimeSolar(n1, n2),
    ChainRule.minGap => l.ruleMinGap(n1, n2, faNumInt(fa, v.gap ?? 0), t1, t2),
    ChainRule.sameAct => l.ruleSameAct(n1, n2, actName, t1, t2),
    ChainRule.sameTimer => l.ruleSameTimer(n1, n2, t1, t2, timerFmt),
  };
}

String phaseDurationText(AppLocalizationsX l, bool fa, TimerPhase phase) {
  final m = phase.totalMinutes;
  final h = m ~/ 60;
  final r = m % 60;
  if (h > 0 && r > 0) return l.minFmt(faNumInt(fa, h), faNumInt(fa, r));
  if (h > 0) return l.hourFmt(faNumInt(fa, h));
  return l.minOnlyFmt(faNumInt(fa, r));
}

/// Formal text of one program-rule violation (P-01..P-05) — the popup
/// and the banners share the same wording. [year] is the current Jalali
/// year used to decode annual day-of-year numbers into real dates.
String programViolationText(
  AppLocalizationsX l,
  bool fa,
  ProgramViolation v, {
  required int year,
}) {
  final weekNames = [l.w0, l.w1, l.w2, l.w3, l.w4, l.w5, l.w6];
  final monthNames = [l.m0, l.m1, l.m2, l.m3, l.m4, l.m5, l.m6, l.m7, l.m8, l.m9, l.m10, l.m11];
  final daysText = switch (v.rule) {
    ProgramRule.weeklyOverlap => v.days.map((d) => weekNames[d.clamp(0, 6)]).join('، '),
    ProgramRule.monthlyOverlap => v.days.map((d) => faNumInt(fa, d)).join('، '),
    ProgramRule.annualOverlap => v.days
        .map((d) {
          final (m, day) = jalaliFromDayOfYear(year, d);
          return '${faNumInt(fa, day)} ${monthNames[m - 1]}';
        })
        .join('، '),
    _ => '',
  };
  return switch (v.rule) {
    ProgramRule.duplicateDaily => l.progP1(v.a, v.b),
    ProgramRule.weeklyOverlap => l.progP2(v.a, v.b, daysText),
    ProgramRule.monthlyOverlap => l.progP3(v.a, v.b, daysText),
    ProgramRule.annualOverlap => l.progP4(v.a, v.b, daysText),
    ProgramRule.dailyShadowed => l.progP5(v.a, v.b),
  };
}

/// Step 2 — cycle selection.
class CycleScreen extends ConsumerWidget {
  const CycleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L(context);
    final programs = ref.watch(programsProvider);
    final draft = programs.draft;

    final cycles = <(CycleType, String, String)>[
      (CycleType.daily, l.daily, l.dailyD),
      (CycleType.weekly, l.weekly, l.weeklyD),
      (CycleType.monthly, l.monthly, l.monthlyD),
      (CycleType.annual, l.annual, l.annualD),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(l.cycleTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (draft != null)
            Text(
              l.cycleSub(draft.name),
              style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
            ),
          const SizedBox(height: 10),
          for (final (kind, title, desc) in cycles)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _selectCard(
                context,
                selected: draft?.cycle == kind,
                icon: switch (kind) {
                  CycleType.daily => Icons.autorenew,
                  CycleType.weekly => Icons.date_range,
                  CycleType.monthly => Icons.calendar_view_month,
                  CycleType.annual => Icons.calendar_today_outlined,
                },
                title: title,
                desc: desc,
                onTap: () => ref.read(programsProvider).setDraftCycle(kind),
              ),
            ),
          Text(l.poolNote,
              style: TextStyle(
                  fontSize: 11, height: 1.9, color: Theme.of(context).hintColor)),
          const SizedBox(height: 8),
          Text(l.priorityNote,
              style: TextStyle(
                  fontSize: 11, height: 1.9, color: Theme.of(context).hintColor)),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: draft == null
                ? null
                : () => context.push('/programs/new/chain'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l.cycleNext),
                const SizedBox(width: 6),
                const Icon(Icons.arrow_back_ios, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectCard(
    BuildContext context, {
    required bool selected,
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return Card(
      color: selected ? AppTheme.orange.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: selected ? AppTheme.orange : Theme.of(context).dividerColor,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: selected
                      ? AppTheme.orange.withValues(alpha: 0.15)
                      : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                ),
                child: Icon(icon,
                    size: 22,
                    color: selected ? AppTheme.orange : Theme.of(context).hintColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(desc,
                        style: TextStyle(
                            fontSize: 11, height: 1.7, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_off,
                color: selected ? AppTheme.orange : Theme.of(context).dividerColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Step 3 — the event chain.
class ChainScreen extends ConsumerWidget {
  const ChainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L(context);
    final fa = isFa(context);
    final programs = ref.watch(programsProvider);
    final draft = programs.draft;
    if (draft == null) {
      // Direct navigation without a draft — send back home.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const SizedBox.shrink();
    }
    final violations = chainRuleViolations(draft.events);
    // v4.1 — today's resolved sunrise/sunset for the solar commands of the
    // chain (the saved location feeds the same NOAA model as the payload).
    final settings = ref.watch(settingsProvider);
    final today = solarTimesFor(
      year: DateTime.now().year,
      month: DateTime.now().month,
      day: DateTime.now().day,
      latitude: settings.gpsLat,
      longitude: settings.gpsLng,
      utcOffsetHours: settings.utcOffsetHours,
    );
    // v4.3 — current Jalali year for the annual day decoding of the
    // program-rule texts.
    final jalaliYear = gregorianToJalali(DateTime.now()).year;
    // v4.3 — program rules (P-01..P-05) evaluated against the SAVED list
    // with the draft replacing the edited program: one chain per day slot.
    final programViolations = programs.draftProgramViolations();
    final blockingProgramViolations =
        programViolations.where((v) => v.blocking).toList();
    final advisoryProgramViolations =
        programViolations.where((v) => !v.blocking).toList();
    // v4.4 day rule — strictly per-cycle: a non-daily program needs at
    // least one day in ITS OWN cycle list. The former combined sum over
    // all three lists let a day-less weekly/monthly/annual program pass
    // whenever a stale list of another cycle was non-empty (v4.3.0 field
    // bug). The save flow pops the rule dialog; this flag only drives the
    // inline hint under the save button.
    final needsDays = programNeedsDays(draft);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.chainTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text(
            l.chainSub(draft.name, _cycleName(l, draft.cycle)),
            style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          // v4.1 — the chain auto-sorts by time on every add/edit; solar
          // commands keep their own groups (sunrise → fixed → sunset).
          Text(
            l.chainSortNote,
            style: TextStyle(
                fontSize: 10.5, height: 1.9, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 12),
          if (draft.events.isEmpty)
            _empty(context, ref, l)
          else
            for (var i = 0; i < draft.events.length; i++)
              _chainStep(context, ref, l, fa, draft.events[i], i,
                  astroToday: draft.events[i].type == EventType.astro
                      ? (draft.events[i].astro == SolarBase.sunrise
                          ? today.sunriseMinutes
                          : today.sunsetMinutes)
                      : null),
          if (violations.isNotEmpty) ...[
            const SizedBox(height: 8),
            _banner(
              context,
              color: const Color(0xFFC0392B),
              icon: Icons.rule_outlined,
              text: l.rulesBlock(faNumInt(fa, violations.length)),
            ),
            const SizedBox(height: 6),
            // Formal violation messages — one per violating pair, ordered by
            // the chain positions (R-01 first, per the priority contract).
            for (final v in violations)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _banner(
                  context,
                  color: const Color(0xFFC0392B),
                  icon: Icons.warning_amber_rounded,
                  text: violationText(l, fa, v, draft.events),
                ),
              ),
          ],
          // v4.3 — program-rule banners: blocking (red) and the advisory
          // daily-shadowing notice (amber). The same texts appear in the
          // «متوجه شدم» popup when the save is attempted.
          if (blockingProgramViolations.isNotEmpty) ...[
            const SizedBox(height: 8),
            _banner(
              context,
              color: const Color(0xFFC0392B),
              icon: Icons.rule_outlined,
              text: l.progRulesBlock(faNumInt(fa, blockingProgramViolations.length)),
            ),
            const SizedBox(height: 6),
            for (final v in blockingProgramViolations)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _banner(
                  context,
                  color: const Color(0xFFC0392B),
                  icon: Icons.warning_amber_rounded,
                  text: programViolationText(l, fa, v, year: jalaliYear),
                ),
              ),
          ],
          if (advisoryProgramViolations.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 6),
              child: _banner(
                context,
                color: const Color(0xFFB4570A),
                icon: Icons.info_outline,
                text: programViolationText(
                    l, fa, advisoryProgramViolations.first,
                    year: jalaliYear),
              ),
            ),
          const SizedBox(height: 10),
          _rulesCard(context, l, fa),
          if (draft.cycle == CycleType.daily) ...[
            const SizedBox(height: 8),
            Text(l.dailyAutoNote,
                style: TextStyle(
                    fontSize: 11, height: 1.9, color: Theme.of(context).hintColor)),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              '${l.currentAssignment} ${_assignSummary(l, fa, draft)}',
              style: TextStyle(
                  fontSize: 11.5, height: 1.9, color: Theme.of(context).hintColor),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _capChip(
                context,
                l.capacityEvents(faNumInt(fa, programs.projectedEventUsage)),
                programs.projectedEventUsage / DomainLimits.maxEvents,
              ),
              _capChip(
                context,
                l.capacityTimers(faNumInt(fa, programs.projectedTimerUsage)),
                programs.projectedTimerUsage / DomainLimits.maxTimers,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/programs/new/chain/event'),
                  icon: const Icon(Icons.add),
                  label: Text(l.addEvent),
                ),
              ),
              if (draft.cycle != CycleType.daily) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/programs/new/chain/assign'),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      switch (draft.cycle) {
                        CycleType.weekly => l.assignWeekly,
                        CycleType.monthly => l.assignMonthly,
                        CycleType.annual => l.assignAnnual,
                        CycleType.daily => '',
                      },
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          FilledButton(
            // v4.3 — the button stays tappable so a blocked save opens the
            // rule POPUP with «متوجه شدم» instead of a silent dead button.
            onPressed: () => _saveDraft(context, ref, l, fa),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check),
                const SizedBox(width: 6),
                Text(l.saveProgram),
              ],
            ),
          ),
          if (needsDays) ...[
            const SizedBox(height: 8),
            Text(
              l.needDaysHint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11,
                  height: 1.8,
                  color: Color(0xFFB4570A),
                  fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: 6),
          TextButton(
            onPressed: () {
              ref.read(programsProvider).cancelDraft();
              context.go('/home');
            },
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }

  String _cycleName(AppLocalizationsX l, CycleType c) => switch (c) {
        CycleType.daily => l.daily,
        CycleType.weekly => l.weekly,
        CycleType.monthly => l.monthly,
        CycleType.annual => l.annual,
      };

  /// v4.3 save flow — chain rules and program rules open as POPUPS with
  /// «متوجه شدم»; only a fully valid draft is persisted.
  Future<void> _saveDraft(
    BuildContext context,
    WidgetRef ref,
    AppLocalizationsX l,
    bool fa,
  ) async {
    final programs = ref.read(programsProvider);
    final draft = programs.draft;
    if (draft == null || draft.events.isEmpty) {
      showAppMessage(context, l.capacityBlock, isError: true);
      return;
    }
    // v4.4 day rule — P-06: a non-daily program without at least one day
    // in its OWN cycle list is meaningless (the device day tables would
    // hold no pointer to its chain) and is refused with the rule popup.
    if (programNeedsDays(draft)) {
      await showRuleViolationPopup(
        context,
        title: l.progRuleTitle,
        messages: [switch (draft.cycle) {
          CycleType.weekly => l.noDaysWeekly(draft.name),
          CycleType.monthly => l.noDaysMonthly(draft.name),
          CycleType.annual => l.noDaysAnnual(draft.name),
          CycleType.daily => '',
        }],
      );
      return;
    }
    final chainViolations = chainRuleViolations(draft.events);
    if (chainViolations.isNotEmpty) {
      await showRuleViolationPopup(
        context,
        title: l.ruleTitle,
        messages: [
          for (final v in chainViolations) violationText(l, fa, v, draft.events),
        ],
      );
      return;
    }
    final programViolations = programs.draftProgramViolations();
    final blocking = programViolations.where((v) => v.blocking).toList();
    if (blocking.isNotEmpty) {
      final year = gregorianToJalali(DateTime.now()).year;
      await showRuleViolationPopup(
        context,
        title: l.progRuleTitle,
        messages: [
          for (final v in blocking) programViolationText(l, fa, v, year: year),
        ],
      );
      return;
    }
    final advisory = programViolations.where((v) => !v.blocking).toList();
    if (advisory.isNotEmpty) {
      // P-05 — informational, requires an explicit acknowledgement.
      final year = gregorianToJalali(DateTime.now()).year;
      await showRuleViolationPopup(
        context,
        title: l.progRuleTitle,
        messages: [
          for (final v in advisory) programViolationText(l, fa, v, year: year),
        ],
      );
    }
    final ok = programs.saveDraft();
    if (!ok || !context.mounted) {
      if (context.mounted) {
        showAppMessage(context, l.capacityBlock, isError: true);
      }
      return;
    }
    showAppMessage(context, l.programSaved(draft.name));
    context.go('/home');
  }

  String _assignSummary(AppLocalizationsX l, bool fa, Program draft) {
    final a = draft.assign;
    return switch (draft.cycle) {
      CycleType.weekly => a.weekly.isEmpty
          ? l.noAssign
          : a.weekly.map((i) => _weekName(l, i)).join('، '),
      CycleType.monthly => a.monthly.isEmpty
          ? l.noAssign
          : l.monthDaysOf(faNumInt(fa, a.monthly.length)),
      CycleType.annual => a.annualDays.isEmpty
          ? l.noAssign
          : l.yearDaysOf(faNumInt(fa, a.annualDays.length)),
      CycleType.daily => l.allDays,
    };
  }

  String _weekName(AppLocalizationsX l, int i) => switch (i) {
        0 => l.w0, 1 => l.w1, 2 => l.w2, 3 => l.w3,
        4 => l.w4, 5 => l.w5, _ => l.w6,
      };

  Widget _empty(BuildContext context, WidgetRef ref, AppLocalizationsX l) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(Icons.link_off, size: 50, color: Colors.grey.shade500),
          const SizedBox(height: 12),
          Text(l.chainEmptyTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            l.chainEmptyText,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.9, color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => context.push('/programs/new/chain/event'),
            icon: const Icon(Icons.add),
            label: Text(l.chainEmptyCta),
          ),
        ],
      ),
    );
  }

  Widget _chainStep(BuildContext context, WidgetRef ref, AppLocalizationsX l, bool fa,
      Event ev, int index,
      {int? astroToday}) {
    final icon = ev.type == EventType.fixed
        ? Icons.schedule
        : (ev.astro == SolarBase.sunrise ? Icons.wb_twilight : Icons.nightlight_round);
    final main = ev.type == EventType.fixed
        ? '${num2(fa, ev.hh)}:${num2(fa, ev.mm)}'
        : (ev.offsetMinutes == 0
            ? (ev.astro == SolarBase.sunrise ? l.sunriseBase : l.sunsetBase)
            : l.astroFmt(
                ev.astro == SolarBase.sunrise ? l.sunriseBase : l.sunsetBase,
                ev.offsetDirection == OffsetDirection.after ? '+' : '−',
                faNumInt(fa, ev.offsetMinutes),
              ));
    final cmd = switch (ev.cmd) {
      RelayCommand.on => l.onCmd,
      RelayCommand.off => l.offCmd,
      RelayCommand.timer => l.timerCmd(
          _phaseText(l, fa, ev.onPhase),
          _phaseText(l, fa, ev.offPhase),
          ev.start == TimerStart.onPhase ? l.startOnTxt : l.startOffTxt,
        ),
    };
    final isLast = index == (ref.read(programsProvider).draft?.events.length ?? 0) - 1;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppTheme.slate900,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  faNumInt(fa, index + 1),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.6,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: Theme.of(context).dividerColor,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon, size: 17, color: AppTheme.orangeDeep),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(main,
                              style: const TextStyle(
                                  fontSize: 14.5, fontWeight: FontWeight.w700)),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              context.push('/programs/new/chain/event?index=$index'),
                          icon: const Icon(Icons.edit_outlined, size: 17),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            ref.read(programsProvider).removeDraftEvent(index);
                            showAppMessage(context, l.eventRemoved);
                          },
                          icon: const Icon(Icons.delete_outline, size: 17),
                        ),
                      ],
                    ),
                    Text(cmd,
                        style: TextStyle(
                            fontSize: 11, height: 1.7, color: Theme.of(context).hintColor)),
                    // v4.1 — the solar command's real time today, so the
                    // moving astronomical base is always transparent.
                    if (astroToday != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          l.astroToday(
                              '${num2(fa, astroToday ~/ 60)}:${num2(fa, astroToday % 60)}'),
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context).hintColor),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _phaseText(AppLocalizationsX l, bool fa, TimerPhase phase) =>
      phaseDurationText(l, fa, phase);

  /// Formal chain-rules card — the four rules exactly as defined in the
  /// reviewed copy deck (R-01..R-04).
  Widget _rulesCard(BuildContext context, AppLocalizationsX l, bool fa) {
    final rules = [l.ruleR1, l.ruleR2, l.ruleR3, l.ruleR4];
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).dividerColor.withValues(alpha: 0.18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_outlined, size: 16, color: AppTheme.orangeDeep),
              const SizedBox(width: 7),
              Text(l.ruleTitle,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 6),
          Text(l.ruleIntro,
              style: TextStyle(fontSize: 10.5, height: 1.9, color: Theme.of(context).hintColor)),
          const SizedBox(height: 8),
          for (var i = 0; i < rules.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 20,
                    alignment: Alignment.center,
                    margin: const EdgeInsetsDirectional.only(end: 8, top: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.orange.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text('R-${i + 1}',
                        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppTheme.orangeDeep)),
                  ),
                  Expanded(
                    child: Text(rules[i],
                        style: TextStyle(
                            fontSize: 10.5, height: 1.9, color: Theme.of(context).hintColor)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _capChip(BuildContext context, String label, double ratio) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700,
              color: Theme.of(context).hintColor)),
    );
  }

  Widget _banner(BuildContext context,
      {required Color color, required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: TextStyle(fontSize: 11.5, height: 1.8, color: color,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

/// Programs management screen.
class ProgramsEditScreen extends ConsumerWidget {
  const ProgramsEditScreen({super.key});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, AppLocalizationsX l, bool fa, Program p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(l.delTitle)),
          ],
        ),
        content: Text(l.delText(p.name), style: const TextStyle(fontSize: 12.5, height: 1.9)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.orange),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      ref.read(programsProvider).deleteAt(ref.read(programsProvider).programs.indexOf(p));
      if (context.mounted) {
        showAppMessage(context, l.programDeleted(p.name));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L(context);
    final fa = isFa(context);
    final programs = ref.watch(programsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.peTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (programs.programs.isEmpty) Text(l.emptyTitle),
          for (final p in programs.programs)
            Card(
              child: ListTile(
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(l.peSummary(
                  switch (p.cycle) {
                    CycleType.daily => l.daily,
                    CycleType.weekly => l.weekly,
                    CycleType.monthly => l.monthly,
                    CycleType.annual => l.annual,
                  },
                  faNumInt(fa, p.events.length),
                  p.assign.weekly.isEmpty && p.assign.monthly.isEmpty && p.assign.annualDays.isEmpty
                      ? l.noAssign
                      : l.allDays,
                )),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () {
                        ref.read(programsProvider).editProgramAt(
                            programs.programs.indexOf(p));
                        context.push('/programs/new/chain');
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _confirmDelete(context, ref, l, fa, p),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final controller = TextEditingController();
              final ok = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l.nameDialogTitle),
                  content: TextField(controller: controller, autofocus: true),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(l.cancel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(l.confirm)),
                  ],
                ),
              );
              if (ok == true && controller.text.trim().isNotEmpty && context.mounted) {
                ref.read(programsProvider)
                  ..startDraft()
                  ..setDraftName(controller.text.trim());
                context.push('/programs/new');
              }
            },
            icon: const Icon(Icons.add),
            label: Text(l.newProgram),
          ),
        ],
      ),
    );
  }
}
