/// Time & duration edit fields (v4.1 UX rework) — replaces the vertical
/// up/down steppers whose value disappeared under the finger while
/// incrementing (v4.0.1 field report).
///
///  · [TimeOfDayField] — «ساعت مشخص»: opens a wheel-picker sheet; the
///    value stays fully visible while scrolling, one gesture to any time.
///  · [MinutesField] — «انحراف از طلوع/غروب» و «مدت روشن/خاموش بودن»:
///    opens a sheet with a 5-minute-step slider, quick-value chips and
///    ±5-minute fine buttons — reaching 720 minutes is one drag instead
///    of 144 taps.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

/// Formal duration text — «۲ ساعت و ۱۵ دقیقه» / "2 h 15 min".
String durationText(bool fa, int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  if (fa) {
    if (h == 0) return '${faNumInt(fa, m)} دقیقه';
    if (m == 0) return '${faNumInt(fa, h)} ساعت';
    return '${faNumInt(fa, h)} ساعت و ${faNumInt(fa, m)} دقیقه';
  }
  if (h == 0) return '${faNumInt(fa, m)} min';
  if (m == 0) return '${faNumInt(fa, h)} h';
  return '${faNumInt(fa, h)} h ${faNumInt(fa, m)} min';
}

// ---------------------------------------------------------------------------
// TimeOfDayField — hour:minute picker (wheel pickers, value always visible)
// ---------------------------------------------------------------------------

class TimeOfDayField extends StatelessWidget {
  const TimeOfDayField({
    super.key,
    required this.label,
    required this.hh,
    required this.mm,
    required this.hint,
    required this.onChanged,
    required this.title,
    required this.confirmLabel,
  });

  final String label;
  final int hh;
  final int mm;
  final String hint;
  final String title;
  final String confirmLabel;
  final void Function(int hh, int mm) onChanged;

  @override
  Widget build(BuildContext context) {
    final fa = Localizations.localeOf(context).languageCode == 'fa';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pick(context, fa),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor, width: 1.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, size: 20, color: AppTheme.orangeDeep),
                const SizedBox(width: 10),
                Text(
                  '${num2(fa, hh)}:${num2(fa, mm)}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Icon(Icons.expand_more, size: 20, color: Theme.of(context).hintColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(hint, style: TextStyle(fontSize: 9.5, color: Theme.of(context).hintColor)),
      ],
    );
  }

  Future<void> _pick(BuildContext context, bool fa) async {
    var h = hh;
    var m = mm;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  '${num2(fa, h)}:${num2(fa, m)}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                      color: AppTheme.orangeDeep),
                ),
                SizedBox(
                  height: 190,
                  child: Row(
                    children: [
                      Expanded(
                        child: CupertinoPicker(
                          key: const ValueKey('hour-picker'),
                          itemExtent: 42,
                          scrollController:
                              FixedExtentScrollController(initialItem: hh),
                          onSelectedItemChanged: (i) => setSheet(() => h = i),
                          children: [
                            for (var i = 0; i < 24; i++)
                              Center(
                                child: Text(num2(fa, i),
                                    style: const TextStyle(fontSize: 19)),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CupertinoPicker(
                          key: const ValueKey('minute-picker'),
                          itemExtent: 42,
                          scrollController:
                              FixedExtentScrollController(initialItem: mm),
                          onSelectedItemChanged: (i) => setSheet(() => m = i),
                          children: [
                            for (var i = 0; i < 60; i++)
                              Center(
                                child: Text(num2(fa, i),
                                    style: const TextStyle(fontSize: 19)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () {
                    onChanged(h, m);
                    Navigator.of(sheetContext).pop();
                  },
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// MinutesField — duration / offset picker (slider + chips + fine buttons)
// ---------------------------------------------------------------------------

class MinutesField extends StatelessWidget {
  const MinutesField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.quickValues,
    required this.hint,
    required this.title,
    required this.confirmLabel,
    required this.plusLabel,
    required this.minusLabel,
    required this.onChanged,
    this.icon = Icons.timer_outlined,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final List<int> quickValues;
  final String hint;
  final String title;
  final String confirmLabel;
  final String plusLabel;
  final String minusLabel;
  final IconData icon;
  final void Function(int minutes) onChanged;

  int _snap(int raw) {
    final steps = ((raw - min) / step).round();
    return (min + steps * step).clamp(min, max);
  }

  @override
  Widget build(BuildContext context) {
    final fa = Localizations.localeOf(context).languageCode == 'fa';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _pick(context, fa),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor, width: 1.4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.orangeDeep),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    durationText(fa, value),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                Icon(Icons.expand_more, size: 20, color: Theme.of(context).hintColor),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(hint, style: TextStyle(fontSize: 9.5, color: Theme.of(context).hintColor)),
      ],
    );
  }

  Future<void> _pick(BuildContext context, bool fa) async {
    var v = _snap(value);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheet) => SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  durationText(fa, v),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800,
                      color: AppTheme.orangeDeep),
                ),
                Slider(
                  value: v.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: ((max - min) / step).round(),
                  label: durationText(fa, v),
                  onChanged: (raw) => setSheet(() => v = _snap(raw.round())),
                ),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final q in quickValues)
                      if (q >= min && q <= max)
                        InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () => setSheet(() => v = q),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
                            decoration: BoxDecoration(
                              color: v == q
                                  ? AppTheme.orange.withValues(alpha: 0.16)
                                  : Theme.of(context).dividerColor.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                  color: v == q
                                      ? AppTheme.orange
                                      : Theme.of(context).dividerColor),
                            ),
                            child: Text(
                              durationText(fa, q),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: v == q ? AppTheme.orangeDeep : null,
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setSheet(() => v = _snap(v - step)),
                        child: Text('$minusLabel $step'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setSheet(() => v = _snap(v + step)),
                        child: Text('$plusLabel $step'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: () {
                    onChanged(v);
                    Navigator.of(sheetContext).pop();
                  },
                  child: Text(confirmLabel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
