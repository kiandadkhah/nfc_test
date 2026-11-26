import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/logging/app_logger.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../state/providers.dart';
import '../../core/widgets/app_toasts.dart';

/// Application log viewer — the in-app logger of the settings screen.
/// Lists the recorded events, and lets the test engineer export the full
/// log file (share sheet) or copy it to the clipboard and send it back to
/// the development team with the test report.
class LogViewerScreen extends ConsumerStatefulWidget {
  const LogViewerScreen({super.key});

  @override
  ConsumerState<LogViewerScreen> createState() => _LogViewerScreenState();
}

class _LogViewerScreenState extends ConsumerState<LogViewerScreen> {
  final Set<LogLevel> _filter = <LogLevel>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appLoggerProvider).loadFromFile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = L(context);
    final fa = isFa(context);
    final logger = ref.watch(appLoggerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l.logTitle)),
      body: StreamBuilder<void>(
        stream: logger.changes,
        builder: (context, _) {
          final all = logger.entries;
          final visible = _filter.isEmpty
              ? all
              : all.where((e) => _filter.contains(e.level)).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.logSub,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(context).hintColor)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final level in LogLevel.values)
                          FilterChip(
                            label: Text(levelLabel(l, level)),
                            selected: _filter.contains(level),
                            onSelected: (on) {
                              setState(() {
                                on
                                    ? _filter.add(level)
                                    : _filter.remove(level);
                              });
                            },
                            selectedColor: AppTheme.orange,
                            labelStyle: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _filter.contains(level)
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.logCount(faNumInt(fa, all.length), faNumInt(fa, visible.length)),
                      style: TextStyle(
                          fontSize: 11, color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          l.logEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12,
                              height: 1.9,
                              color: Theme.of(context).hintColor),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Theme.of(context).dividerColor),
                        itemBuilder: (context, i) {
                          final e = visible.reversed.toList()[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 62,
                                  child: Text(e.timeText,
                                      style: TextStyle(
                                          fontSize: 10.5,
                                          fontFamily: 'monospace',
                                          color: Theme.of(context).hintColor)),
                                ),
                                Container(
                                  width: 34,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 1),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: levelColor(e.level)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(e.levelText,
                                      style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                          color: levelColor(e.level))),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.message,
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        height: 1.5,
                                        color:
                                            Theme.of(context).colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: FilledButton.icon(
                          onPressed: () => _export(context, ref, l),
                          icon: const Icon(Icons.ios_share, size: 18),
                          label: Text(l.logExport),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          onPressed: () => _copy(context, ref, l),
                          icon: const Icon(Icons.copy, size: 17),
                          label: Text(l.logCopy),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFC0392B),
                          ),
                          onPressed: () => _confirmClear(context, ref, l),
                          icon: const Icon(Icons.delete_outline, size: 17),
                          label: Text(l.logClear),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String levelLabel(AppLocalizationsX l, LogLevel level) {
    switch (level) {
      case LogLevel.nfc:
        return l.logLevelNfc;
      case LogLevel.gps:
        return l.logLevelGps;
      case LogLevel.action:
        return l.logLevelAction;
      case LogLevel.error:
        return l.logLevelError;
      case LogLevel.warn:
        return l.logLevelWarn;
      case LogLevel.info:
        return l.logLevelInfo;
    }
  }

  Color levelColor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return const Color(0xFFC0392B);
      case LogLevel.warn:
        return const Color(0xFFB4570A);
      case LogLevel.nfc:
        return AppTheme.orange;
      case LogLevel.gps:
        return const Color(0xFF1B7F4D);
      case LogLevel.action:
        return const Color(0xFF2B6CB0);
      case LogLevel.info:
        return const Color(0xFF667085);
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref, AppLocalizationsX l) async {
    final logger = ref.read(appLoggerProvider);
    try {
      final text = logger.exportText();
      await SharePlus.instance.share(
        ShareParams(text: text, subject: l.logShareSubject),
      );
      logger.action('log exported (share sheet)');
    } catch (e) {
      logger.error('log export failed: $e');
      if (context.mounted) {
        showAppMessage(context, l.logExportFailed);
      }
    }
  }

  Future<void> _copy(BuildContext context, WidgetRef ref, AppLocalizationsX l) async {
    final logger = ref.read(appLoggerProvider);
    await Clipboard.setData(ClipboardData(text: logger.exportText()));
    logger.action('log copied to clipboard');
    if (context.mounted) {
      showAppMessage(context, l.logCopiedToast);
    }
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref, AppLocalizationsX l) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.logClearTitle),
        content: Text(l.logClearText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l.confirm),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(appLoggerProvider).clear();
      if (context.mounted) {
        showAppMessage(context, l.logClearedToast);
      }
    }
  }
}
