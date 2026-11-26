import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/domain.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/utils/jalali.dart';
import '../../state/providers.dart';
import '../../core/widgets/app_toasts.dart';

/// Day assignment — weekly / monthly / annual grids, each followed by the
/// «selected days» list (per-day remove), per the approved v2.2 design.
class AssignScreen extends ConsumerWidget {
  const AssignScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L(context);
    final fa = isFa(context);
    final draft = ref.watch(programsProvider).draft;
    if (draft == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/home');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(switch (draft.cycle) {
          CycleType.weekly => l.asWeekly,
          CycleType.monthly => l.asMonthly,
          CycleType.annual => l.asAnnual,
          CycleType.daily => l.asWeekly,
        }),
      ),
      body: switch (draft.cycle) {
        CycleType.weekly => _weeklyGrid(context, ref, l, fa, draft.assign.weekly),
        CycleType.monthly => _monthlyGrid(context, ref, l, fa, draft.assign.monthly),
        CycleType.annual => _annualView(context, ref, l, fa, draft.assign.annualDays),
        CycleType.daily => const SizedBox.shrink(),
      },
    );
  }

  Widget _weeklyGrid(BuildContext context, WidgetRef ref, AppLocalizationsX l, bool fa,
      List<int> selected) {
    final names = [l.w0, l.w1, l.w2, l.w3, l.w4, l.w5, l.w6];
    final sorted = selected.toList()..sort();
    return _wrap(
      context,
      ref,
      l,
      fa,
      count: selected.length,
      items: [for (final i in sorted) (names[i], i)],
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.4,
        children: [
          for (var i = 0; i < 7; i++)
            _dayCell(
              context,
              label: names[i],
              on: selected.contains(i),
              onTap: () => ref.read(programsProvider).toggleWeekly(i),
            ),
        ],
      ),
    );
  }

  Widget _monthlyGrid(BuildContext context, WidgetRef ref, AppLocalizationsX l, bool fa,
      List<int> selected) {
    final sorted = selected.toList()..sort();
    return _wrap(
      context,
      ref,
      l,
      fa,
      count: selected.length,
      items: [for (final d in sorted) (l.asDayN(faNumInt(fa, d)), d)],
      child: GridView.count(
        crossAxisCount: 5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.15,
        children: [
          for (var d = 1; d <= DomainLimits.monthlyDays; d++)
            _dayCell(
              context,
              label: faNumInt(fa, d),
              on: selected.contains(d),
              onTap: () => ref.read(programsProvider).toggleMonthly(d),
            ),
        ],
      ),
    );
  }

  Widget _annualView(BuildContext context, WidgetRef ref, AppLocalizationsX l, bool fa,
      List<int> selected) {
    final monthNames = [l.m0, l.m1, l.m2, l.m3, l.m4, l.m5, l.m6, l.m7, l.m8, l.m9, l.m10, l.m11];
    // The annual grid follows the CURRENT Persian year — the leap state of
    // this year decides the length of Esfand (30 days) and therefore the
    // day-of-year mapping of the device annual cycle (1..366).
    final year = gregorianToJalali(DateTime.now()).year;
    final monthLengths = [
      for (var m = 1; m <= 12; m++) jalaliMonthLength(year, m),
    ];
    final month = ref.watch(_assignMonthProvider);
    final sorted = selected.toList()..sort();
    return _wrap(
      context,
      ref,
      l,
      fa,
      count: selected.length,
      extraNote: isJalaliLeap(year)
          ? l.asAnnualLeapNote(faNumInt(fa, year))
          : l.asAnnualNote,
      items: [
        for (final v in sorted)
          if (v >= 1 && v <= 366)
            _annualLabel(year, v, monthNames),
      ],
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (var m = 0; m < 12; m++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(monthNames[m]),
                      selected: month == m,
                      onSelected: (_) =>
                          ref.read(_assignMonthProvider.notifier).state = m,
                      selectedColor: AppTheme.orange,
                      labelStyle: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: month == m ? Colors.white : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 7,
            crossAxisSpacing: 7,
            childAspectRatio: 1.0,
            children: [
              for (var d = 1; d <= monthLengths[month]; d++)
                _dayCell(
                  context,
                  label: faNumInt(fa, d),
                  on: selected.contains(jalaliDayOfYear(year, month + 1, d)),
                  onTap: () => ref
                      .read(programsProvider)
                      .toggleAnnual(jalaliDayOfYear(year, month + 1, d)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Chip label of an annual day — decodes the 1-based day-of-year back to
  /// the real (month, day) pair of the current year.
  (String, int) _annualLabel(int year, int dayOfYear, List<String> monthNames) {
    final (m, d) = jalaliFromDayOfYear(year, dayOfYear);
    return ('${monthNames[m - 1]} — ${faNum(dayOfYear)} ($d)', dayOfYear);
  }

  Widget _wrap(
    BuildContext context,
    WidgetRef ref,
    AppLocalizationsX l,
    bool fa, {
    required int count,
    required List<(String, int)> items,
    required Widget child,
    String? extraNote,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l.asSub, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
        const SizedBox(height: 10),
        child,
        const SizedBox(height: 14),
        Row(
          children: [
            Text(l.asSelTitle, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
            const SizedBox(width: 8),
            Chip(
              visualDensity: VisualDensity.compact,
              backgroundColor: AppTheme.orange.withValues(alpha: 0.12),
              label: Text(
                l.asRequired,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFFB4570A)),
              ),
            ),
            const Spacer(),
            Text(l.asCount(faNumInt(fa, count)),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Text(
              l.asNoneSelected,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11.5, height: 1.8, color: Theme.of(context).hintColor),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: Theme.of(context).dividerColor),
                  ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    leading: const Icon(Icons.event_available, size: 18, color: AppTheme.orangeDeep),
                    title: Text(items[i].$1,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    trailing: IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: l.asRemoveOne,
                      icon: Icon(Icons.delete_outline,
                          size: 18, color: Theme.of(context).colorScheme.error),
                      onPressed: () {
                        _remove(context, ref, l, items[i].$2);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (extraNote != null) ...[
          const SizedBox(height: 10),
          Text(extraNote,
              style: TextStyle(fontSize: 11, height: 1.9, color: Theme.of(context).hintColor)),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  context.pop();
                  showAppMessage(context, l.asSaved);
                },
                icon: const Icon(Icons.check),
                label: Text(l.asOk),
              ),
            ),
            const SizedBox(width: 10),
            TextButton(
              onPressed: () {
                ref.read(programsProvider).clearAssignment();
              },
              child: Text(l.asClear),
            ),
          ],
        ),
      ],
    );
  }

  void _remove(BuildContext context, WidgetRef ref, AppLocalizationsX l, int value) {
    final draft = ref.read(programsProvider).draft;
    if (draft == null) return;
    switch (draft.cycle) {
      case CycleType.weekly:
        ref.read(programsProvider).toggleWeekly(value);
      case CycleType.monthly:
        ref.read(programsProvider).toggleMonthly(value);
      case CycleType.annual:
        ref.read(programsProvider).toggleAnnual(value);
      case CycleType.daily:
        break;
    }
    showAppMessage(context, l.asRemovedOne);
  }

  Widget _dayCell(BuildContext context,
      {required String label, required bool on, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppTheme.orange : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: on ? AppTheme.orange : Theme.of(context).dividerColor,
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: on ? Colors.white : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}

/// Local UI state for the annual month tab.
final _assignMonthProvider = StateProvider<int>((ref) => 0);
