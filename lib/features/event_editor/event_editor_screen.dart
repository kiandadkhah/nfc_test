import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/domain.dart';
import '../../core/models/program.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/validation/validators.dart';
import '../../state/providers.dart';

/// Event editor — fixed / solar / timer forms with Q-06 clamping
/// and Q-10 conflict prevention on save.
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

  void _save() {
    final l = L(context);
    final fa = isFa(context);
    final programs = ref.read(programsProvider);
    if (!_phasesValid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.timerErr)));
      return;
    }
    final existing = programs.draft?.events ?? [];
    // R-01..R-04 — the candidate is checked in the exact position it will
    // occupy, so adjacency is only evaluated against its real neighbours.
    final violations = violationsWithCandidate(_ev, existing, skipIndex: widget.editIndex);
    if (violations.isNotEmpty) {
      final v = violations.first;
      final other = v.a == _candidateIndex(existing) ? v.b : v.a;
      final message = switch (v.rule) {
        ChainRule.sameTime =>
          v.minute != null
              ? l.evRuleSameTime(faNumInt(fa, other + 1), '${num2(fa, v.minute! ~/ 60)}:${num2(fa, v.minute! % 60)}')
              : l.evRuleSameTimeSolar(faNumInt(fa, other + 1)),
        ChainRule.minGap => l.evRuleMinGap(
            faNumInt(fa, other + 1),
            faNumInt(fa, v.gap ?? 0),
          ),
        ChainRule.sameAct => l.evRuleSameAct(
            faNumInt(fa, other + 1),
            _actName(l, _ev),
          ),
        ChainRule.sameTimer => l.evRuleSameTimer(faNumInt(fa, other + 1)),
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    if (widget.editIndex >= 0) {
      programs.replaceDraftEvent(widget.editIndex, _ev);
    } else {
      programs.addDraftEvent(_ev);
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.eventSaved)));
    context.pop();
  }

  int _candidateIndex(List<Event> existing) =>
      widget.editIndex >= 0 && widget.editIndex < existing.length ? widget.editIndex : existing.length;

  String _actName(AppLocalizationsX l, Event ev) => switch (ev.cmd) {
        RelayCommand.on => l.cmdOn,
        RelayCommand.off => l.cmdOff,
        RelayCommand.timer => l.cmdTimer,
  };

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

  List<Widget> _fixedForm(AppLocalizationsX l, bool fa) => [
        // v3.0 — unified hour/minute setting: the value lives between its
        // increase/decrease buttons (same pattern as «فاصله زمانی» and
        // «مدت زمان روشن بودن»). No separate hour:minute display above.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _stepper(
              l,
              fa,
              value: num2(fa, _ev.hh),
              unit: l.hourUnit,
              label: l.hourRange,
              onUp: () => _update(() => _ev.hh = (_ev.hh + 1) % 24),
              onDown: () => _update(() => _ev.hh = (_ev.hh + 23) % 24),
            ),
            const SizedBox(width: 20),
            _stepper(
              l,
              fa,
              value: num2(fa, _ev.mm),
              unit: l.minUnit,
              label: l.minuteRange,
              onUp: () => _update(() => _ev.mm = (_ev.mm + 1) % 60),
              onDown: () => _update(() => _ev.mm = (_ev.mm + 59) % 60),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(l.evTimeFmt,
              style: TextStyle(fontSize: 11, color: Theme.of(context).hintColor)),
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
        Center(
          child: _stepper(
            l,
            fa,
            value: faNumInt(fa, _ev.offsetMinutes),
            unit: l.minUnit,
            label: l.offsetLabel,
            onUp: () => _update(() => _ev.offsetMinutes =
                (_ev.offsetMinutes + DomainLimits.timerStepMinutes)
                    .clamp(0, DomainLimits.astroOffsetMaxMinutes)),
            onDown: () => _update(() => _ev.offsetMinutes =
                (_ev.offsetMinutes - DomainLimits.timerStepMinutes)
                    .clamp(0, DomainLimits.astroOffsetMaxMinutes)),
          ),
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
    // v3.0 — minutes-only duration setting: step 5 minutes, range 5..720,
    // to remove the hour/minute ambiguity.
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
        Center(
          child: _stepper(
            l,
            fa,
            value: faNumInt(fa, total),
            unit: l.minUnit,
            label: l.phaseRange,
            onUp: () => _update(() => phase.totalMinutes =
                (phase.totalMinutes + DomainLimits.timerStepMinutes)
                    .clamp(DomainLimits.timerStepMinutes, DomainLimits.timerPhaseMaxMinutes)),
            onDown: () => _update(() => phase.totalMinutes =
                (phase.totalMinutes - DomainLimits.timerStepMinutes)
                    .clamp(DomainLimits.timerStepMinutes, DomainLimits.timerPhaseMaxMinutes)),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            phase.isValid ? l.phaseSum(faNumInt(fa, total)) : l.phaseInvalid,
            style: TextStyle(
              fontSize: 10.5,
              color: phase.isValid ? Theme.of(context).hintColor : const Color(0xFFC0392B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepper(
    AppLocalizationsX l,
    bool fa, {
    required String value,
    required String unit,
    required String label,
    required VoidCallback onUp,
    required VoidCallback onDown,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onUp,
          icon: const Icon(Icons.keyboard_arrow_up),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.slate900,
            foregroundColor: Colors.white,
          ),
        ),
        Container(
          width: 76,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor, width: 1.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        IconButton(
          onPressed: onDown,
          icon: const Icon(Icons.keyboard_arrow_down),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.slate900,
            foregroundColor: Colors.white,
          ),
        ),
        // Unit caption under the value — part of the unified stepper pattern.
        Text(unit, style: TextStyle(fontSize: 10.5, color: Theme.of(context).hintColor)),
        const SizedBox(height: 2),
        Text(label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9.5, color: Theme.of(context).hintColor)),
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
