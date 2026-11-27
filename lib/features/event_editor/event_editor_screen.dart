import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/domain.dart';
import '../../core/models/program.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/jalali.dart';
import '../../core/validation/validators.dart';
import '../../core/widgets/app_toasts.dart';
import '../../core/widgets/rule_popup.dart';
import '../../core/widgets/time_edit_fields.dart';
import '../../state/providers.dart';

/// Event editor — fixed / solar / timer forms with Q-06 clamping
/// and Q-10 conflict prevention on save. v4.1: wheel/slider time fields,
/// sorted-chain rule checking and the annual fixed↔solar overlap notice.
class EventEditorScreen extends ConsumerStatefulWidget {
  const EventEditorScreen({required this.editIndex, super.key});

  final int editIndex; // -1 = new event

  @override
  ConsumerState<EventEditorScreen> createState() => _EventEditorScreenState();
}

class _EventEditorScreenState extends ConsumerState<EventEditorScreen> {
  late Event _ev;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(programsProvider).draft;
    if (widget.editIndex >= 0 && draft != null && widget.editIndex < draft.events.length) {
      _ev = draft.events[widget.editIndex].copy();
    } else {
      _ev = Event(
        type: EventType.fixed,
        hh: 6,
        mm: 30,
        cmd: RelayCommand.on,
        onPhase: TimerPhase(hours: 0, minutes: 30),
        offPhase: TimerPhase(hours: 0, minutes: 15),
      );
    }
  }

  void _update(VoidCallback fn) {
    setState(fn);
  }

  bool get _phasesValid => _ev.cmd != RelayCommand.timer ||
      (isPhaseValid(_ev.onPhase) && isPhaseValid(_ev.offPhase));

  /// Jalali month names for the overlap notice (formal, no abbreviations).
  static const List<String> _faMonths = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور',
    'مهر', 'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];
  static const List<String> _enMonths = [
    'Farvardin', 'Ordibehesht', 'Khordad', 'Tir', 'Mordad', 'Shahrivar',
    'Mehr', 'Aban', 'Azar', 'Dey', 'Bahman', 'Esfand',
  ];

  String _jalaliDate(bool fa, DateTime g) {
    final j = gregorianToJalali(g);
    final monthName = fa ? _faMonths[j.month - 1] : _enMonths[j.month - 1];
    return '${faNumInt(fa, j.day)} $monthName';
  }

  String _actName(AppLocalizationsX l, Event ev) => switch (ev.cmd) {
        RelayCommand.on => l.cmdOn,
        RelayCommand.off => l.cmdOff,
        RelayCommand.timer => l.cmdTimer,
      };

  /// Astro/fixed annual overlap notice — non-blocking; the user approves
  /// it explicitly before the event is saved. [v4.1 strategy S]
  Future<bool> _confirmOverlaps(AppLocalizationsX l, bool fa, List<Event> sortedMerged) async {
    final settings = ref.read(settingsProvider);
    final overlaps = astroOverlapWarnings(
      sortedMerged,
      latitude: settings.gpsLat,
      longitude: settings.gpsLng,
      utcOffsetHours: settings.utcOffsetHours,
    );
    final involvingCandidate = overlaps
        .where((o) => o.fixedIndex == _candidatePos || o.astroIndex == _candidatePos)
        .toList();
    if (involvingCandidate.isEmpty) return true;

    final astroEv = sortedMerged[involvingCandidate.first.astroIndex];
    final fixedEv = sortedMerged[involvingCandidate.first.fixedIndex];
    final o = involvingCandidate.first;
    final detail = l.overlapDetail(
      '${num2(fa, fixedEv.hh)}:${num2(fa, fixedEv.mm)}',
      astroEv.astro == SolarBase.sunrise ? l.sunriseShort : l.sunsetShort,
      faNumInt(fa, o.days),
      _jalaliDate(fa, o.firstDate),
      _jalaliDate(fa, o.lastDate),
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.orangeDeep, size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(l.overlapTitle, style: const TextStyle(fontSize: 15))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(detail, style: const TextStyle(fontSize: 12.5, height: 2)),
            const SizedBox(height: 8),
            Text(l.overlapNote, style: TextStyle(fontSize: 11, height: 1.9,
                color: Theme.of(context).hintColor)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.overlapAccept),
          ),
        ],
      ),
    );
    return ok == true;
  }

  /// Position the candidate will occupy in the sorted chain (recomputed on
  /// every rebuild; identical() lookup in candidateCheck is deterministic).
  int get _candidatePos {
    final programs = ref.read(programsProvider);
    final existing = programs.draft?.events ?? [];
    final without = <Event>[
      for (var i = 0; i < existing.length; i++)
        if (i != widget.editIndex) existing[i],
    ];
    final sorted = sortChain([...without, _ev]);
    final pos = sorted.indexWhere((e) => identical(e, _ev));
    return pos < 0 ? sorted.length - 1 : pos;
  }

  void _save() async {
    final l = L(context);
    final fa = isFa(context);
    final programs = ref.read(programsProvider);
    if (!_phasesValid) {
      showAppMessage(context, l.timerErr, isError: true);
      return;
    }
    final existing = programs.draft?.events ?? [];
    // R-01..R-04 — the candidate is checked in the exact position it will
    // occupy after the automatic time-based sort. [v4.1]
    final check = candidateCheck(_ev, existing, skipIndex: widget.editIndex);
    if (check.violations.isNotEmpty) {
      // v4.3 — the rule messages open as a POPUP with «متوجه شدم» (the top
      // toast disappeared before the user could read them). Every violation
      // involving the candidate is listed, in chain order.
      final messages = <String>[];
      final actName = _actName(l, _ev);
      for (final v in check.violations) {
        final other = v.a == check.position ? v.b : v.a;
        messages.add(switch (v.rule) {
          ChainRule.sameTime => v.minute != null
              ? l.evRuleSameTime(faNumInt(fa, other + 1),
                  '${num2(fa, v.minute! ~/ 60)}:${num2(fa, v.minute! % 60)}')
              : l.evRuleSameTimeSolar(faNumInt(fa, other + 1)),
          ChainRule.minGap => l.evRuleMinGap(
              faNumInt(fa, other + 1),
              faNumInt(fa, v.gap ?? 0),
            ),
          ChainRule.sameAct => l.evRuleSameAct(
              faNumInt(fa, other + 1),
              actName,
            ),
          ChainRule.sameTimer => l.evRuleSameTimer(faNumInt(fa, other + 1)),
        });
      }
      await showRuleViolationPopup(
        context,
        title: l.ruleTitle,
        messages: messages,
      );
      return;
    }
    // Annual fixed↔solar coincidence — informational, explicit consent.
    final mergedSorted = sortChain([
      for (var i = 0; i < existing.length; i++)
        if (i != widget.editIndex) existing[i],
      _ev,
    ]);
    final approved = await _confirmOverlaps(l, fa, mergedSorted);
    if (!approved || !mounted) return;

    if (widget.editIndex >= 0) {
      programs.replaceDraftEvent(widget.editIndex, _ev);
    } else {
      programs.addDraftEvent(_ev);
    }
    showAppMessage(context, l.eventSaved);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final fa = isFa(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editIndex >= 0 ? l.evEdit : l.evNew),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.evSub, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.schedule, size: 17, color: AppTheme.orangeDeep),
                    const SizedBox(width: 7),
                    Text(l.evType, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))]),
                  const SizedBox(height: 12),
                  SegmentedButton<EventType>(
                    segments: [
                      ButtonSegment(value: EventType.fixed, label: Text(l.evFixed), icon: const Icon(Icons.schedule, size: 16)),
                      ButtonSegment(value: EventType.astro, label: Text(l.evAstro), icon: const Icon(Icons.wb_twilight, size: 16)),
                    ],
                    selected: {_ev.type},
                    onSelectionChanged: (s) => _update(() => _ev.type = s.first),
                  ),
                  const SizedBox(height: 16),
                  if (_ev.type == EventType.fixed) ..._fixedForm(l, fa)
                  else ..._astroForm(l, fa),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [const Icon(Icons.bolt, size: 17, color: AppTheme.orangeDeep),
                    const SizedBox(width: 7),
                    Text(l.cmdTitle, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))]),
                  const SizedBox(height: 12),
                  SegmentedButton<RelayCommand>(
                    segments: [
                      ButtonSegment(value: RelayCommand.on, label: Text(l.cmdOn)),
                      ButtonSegment(value: RelayCommand.off, label: Text(l.cmdOff)),
                      ButtonSegment(value: RelayCommand.timer, label: Text(l.cmdTimer)),
                    ],
                    selected: {_ev.cmd},
                    onSelectionChanged: (s) => _update(() => _ev.cmd = s.first),
                  ),
                  const SizedBox(height: 14),
                  if (_ev.cmd == RelayCommand.on)
                    Text(l.cmdOnD, style: TextStyle(fontSize: 11.5, height: 1.9, color: Theme.of(context).hintColor))
                  else if (_ev.cmd == RelayCommand.off)
                    Text(l.cmdOffD, style: TextStyle(fontSize: 11.5, height: 1.9, color: Theme.of(context).hintColor))
                  else ...[
                    Text(l.timerNote, style: TextStyle(fontSize: 11.5, height: 1.9, color: Theme.of(context).hintColor)),
                    const SizedBox(height: 14),
                    _phaseEditor(l, fa, true),
                    const SizedBox(height: 12),
                    _phaseEditor(l, fa, false),
                    const SizedBox(height: 14),
                    Text(l.startLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    SegmentedButton<TimerStart>(
                      segments: [
                        ButtonSegment(value: TimerStart.onPhase, label: Text(l.startOn, style: const TextStyle(fontSize: 11))),
                        ButtonSegment(value: TimerStart.offPhase, label: Text(l.startOff, style: const TextStyle(fontSize: 11))),
                      ],
                      selected: {_ev.start},
                      onSelectionChanged: (s) => _update(() => _ev.start = s.first),
                    ),
                    if (!_phasesValid) ...[
                      const SizedBox(height: 10),
                      Text(l.phaseErr,
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFC0392B), fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 8),
                    Text(l.cmdIgnored, style: TextStyle(fontSize: 11, height: 1.8, color: Theme.of(context).hintColor)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _save,
            child: Text(l.saveEvent),
          ),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(l.cancel),
          ),
        ],
      ),
    );
  }

  // v4.1 — one tappable field for hour:minute; the picker keeps the value
  // visible while scrolling (the old up/down steppers hid it under the
  // finger).
  List<Widget> _fixedForm(AppLocalizationsX l, bool fa) => [
        TimeOfDayField(
          label: l.evFixedTimeLabel,
          title: l.evFixedPickerTitle,
          confirmLabel: l.confirm,
          hh: _ev.hh,
          mm: _ev.mm,
          hint: l.evTimeFmt,
          onChanged: (hh, mm) => _update(() {
            _ev.hh = hh;
            _ev.mm = mm;
          }),
        ),
      ];

  List<Widget> _astroForm(AppLocalizationsX l, bool fa) => [
        _selectCard(
          context,
          selected: _ev.astro == SolarBase.sunrise,
          icon: Icons.wb_twilight_outlined,
          title: l.sunrise,
          desc: l.sunriseD,
          onTap: () => _update(() => _ev.astro = SolarBase.sunrise),
        ),
        const SizedBox(height: 8),
        _selectCard(
          context,
          selected: _ev.astro == SolarBase.sunset,
          icon: Icons.nightlight_outlined,
          title: l.sunset,
          desc: l.sunsetD,
          onTap: () => _update(() => _ev.astro = SolarBase.sunset),
        ),
        const SizedBox(height: 16),
        MinutesField(
          label: l.offsetLabel,
          title: l.offsetPickerTitle,
          confirmLabel: l.confirm,
          plusLabel: l.plusMinute,
          minusLabel: l.minusMinute,
          value: _ev.offsetMinutes,
          min: 0,
          max: DomainLimits.astroOffsetMaxMinutes,
          step: DomainLimits.timerStepMinutes,
          quickValues: const [0, 10, 15, 20, 30, 45, 60],
          icon: Icons.wb_twilight_outlined,
          hint: l.offsetHint,
          onChanged: (minutes) => _update(() => _ev.offsetMinutes = minutes),
        ),
        const SizedBox(height: 14),
        Text(l.signLabel, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        SegmentedButton<OffsetDirection>(
          segments: [
            ButtonSegment(
              value: OffsetDirection.after,
              label: Text(
                l.afterBase(_ev.astro == SolarBase.sunrise ? l.sunriseShort : l.sunsetShort),
                style: const TextStyle(fontSize: 11),
              ),
            ),
            ButtonSegment(
              value: OffsetDirection.before,
              label: Text(
                l.beforeBase(_ev.astro == SolarBase.sunrise ? l.sunriseShort : l.sunsetShort),
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ],
          selected: {_ev.offsetDirection},
          onSelectionChanged: (s) => _update(() => _ev.offsetDirection = s.first),
        ),
        const SizedBox(height: 8),
        Text(
          _ev.offsetMinutes == 0
              ? l.signZero
              : l.signExample(
                  _ev.astro == SolarBase.sunrise ? l.sunriseShort : l.sunsetShort,
                  _ev.offsetDirection == OffsetDirection.after ? '+' : '−',
                  faNumInt(fa, _ev.offsetMinutes),
                ),
          style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor),
        ),
      ];

  Widget _phaseEditor(AppLocalizationsX l, bool fa, bool onPhase) {
    final phase = onPhase ? _ev.onPhase : _ev.offPhase;
    final total = phase.totalMinutes;
    // v4.1 — slider + quick chips: the full 5..720 range is one drag;
    // common values (15/30/60/120 …) are single taps.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              onPhase ? Icons.power : Icons.power_off,
              size: 17,
              color: onPhase ? AppTheme.orangeDeep : Theme.of(context).hintColor,
            ),
            const SizedBox(width: 7),
            Text(
              onPhase ? l.phaseOn : l.phaseOff,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: onPhase ? AppTheme.orangeDeep : Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        MinutesField(
          label: onPhase ? l.phaseOnLabel : l.phaseOffLabel,
          title: onPhase ? l.phaseOnPickerTitle : l.phaseOffPickerTitle,
          confirmLabel: l.confirm,
          plusLabel: l.plusMinute,
          minusLabel: l.minusMinute,
          value: total,
          min: DomainLimits.timerStepMinutes,
          max: DomainLimits.timerPhaseMaxMinutes,
          step: DomainLimits.timerStepMinutes,
          quickValues: const [5, 15, 30, 60, 120, 240, 360, 720],
          icon: onPhase ? Icons.power : Icons.power_off,
          hint: l.phaseRange,
          onChanged: (minutes) => _update(() => phase.totalMinutes = minutes),
        ),
        const SizedBox(height: 6),
        Text(
          phase.isValid ? l.phaseSum(faNumInt(fa, total)) : l.phaseInvalid,
          style: TextStyle(
            fontSize: 10.5,
            color: phase.isValid ? Theme.of(context).hintColor : const Color(0xFFC0392B),
          ),
        ),
      ],
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
      margin: EdgeInsets.zero,
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
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppTheme.orange : Theme.of(context).hintColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    Text(desc,
                        style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.radio_button_off,
                color: selected ? AppTheme.orange : Theme.of(context).dividerColor,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
