import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/logging/app_logger.dart';
import '../../core/state/app_providers.dart';
import '../../state/providers.dart';

/// Settings — UI language, visual theme and the application logger
/// (all operations are recorded and can be exported for the test report).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.seTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l.seSub, style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor)),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language, color: Color(0xFFE8720A)),
              title: Text(l.seLang, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              subtitle: Text(l.seLangD, style: const TextStyle(fontSize: 11)),
              trailing: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'fa', label: Text(l.seFa)),
                  ButtonSegment(value: 'en', label: Text(l.seEn)),
                ],
                selected: {settings.locale.languageCode},
                onSelectionChanged: (s) {
                  ref.read(settingsProvider).setLocale(Locale(s.first));
                },
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(
                settings.themeMode == ThemeMode.light
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: const Color(0xFFE8720A),
              ),
              title: Text(l.seTheme, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              subtitle: Text(l.seThemeD, style: const TextStyle(fontSize: 11)),
              trailing: SegmentedButton<String>(
                segments: [
                  ButtonSegment(value: 'light', label: Text(l.seLight)),
                  ButtonSegment(value: 'dark', label: Text(l.seDark)),
                ],
                selected: <String>{
                  settings.themeMode == ThemeMode.dark ? 'dark' : 'light',
                },
                onSelectionChanged: (s) {
                  ref.read(settingsProvider).setThemeMode(
                        s.first == 'dark' ? ThemeMode.dark : ThemeMode.light,
                      );
                },
              ),
            ),
          ),
          // Application logger — records every operation; the test
          // engineer exports the log with the field-test report.
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Color(0xFFE8720A)),
              title: Text(l.seLogs, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              subtitle: Text(l.seLogsD, style: const TextStyle(fontSize: 11)),
              trailing: ListenableBuilder(
                listenable: AppLogger.instance,
                builder: (context, _) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8720A).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${AppLogger.instance.count}',
                    style: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFB4570A)),
                  ),
                ),
              ),
              onTap: () => context.push('/logs'),
            ),
          ),
        ],
      ),
    );
  }
}
