/// In-app application logger — records every operation of the app with a
/// timestamp (NFC sessions, protocol steps, GPS fixes, program edits,
/// failures) and persists them as a JSON Lines file so the field-test
/// report can be exported and sent back to the development team.
///
/// Design notes:
///  · Works without any platform channel — when path_provider is
///    unavailable (unit tests) the logger keeps entries in memory only.
///  · The file is append-only JSON Lines; one entry per line:
///    `{"ts":"2026-11-26T10:12:33.145","lvl":"NFC","msg":"..."}`
///  · Rotation: when the file passes ~512 KB it is renamed to `.1` and a
///    fresh file starts.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

enum LogLevel { info, nfc, gps, action, warn, error }

class LogEntry {
  const LogEntry(this.ts, this.level, this.message);

  final DateTime ts;
  final LogLevel level;
  final String message;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'ts': ts.toIso8601String(),
        'lvl': level.name.toUpperCase(),
        'msg': message,
      };

  factory LogEntry.fromJson(Map<String, dynamic> j) => LogEntry(
        DateTime.tryParse('${j['ts']}') ?? DateTime.now(),
        LogLevel.values.firstWhere(
          (l) => l.name.toUpperCase() == '${j['lvl']}',
          orElse: () => LogLevel.info,
        ),
        '${j['msg']}',
      );

  String get timeText {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(ts.hour)}:${two(ts.minute)}:${two(ts.second)}';
  }

  String get levelText {
    switch (level) {
      case LogLevel.error:
        return 'ERR';
      case LogLevel.warn:
        return 'WRN';
      case LogLevel.nfc:
        return 'NFC';
      case LogLevel.gps:
        return 'GPS';
      case LogLevel.action:
        return 'ACT';
      case LogLevel.info:
        return 'INF';
    }
  }
}

class AppLogger extends ChangeNotifier {
  AppLogger._();

  static final AppLogger instance = AppLogger._();

  static const int _maxMemoryEntries = 800;
  static const int _rotateBytes = 512 * 1024;

  final List<LogEntry> _entries = <LogEntry>[];
  File? _file;
  bool _fileFailed = false;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  /// Notifies the log viewer when new entries arrive.
  Stream<void> get changes => _changes.stream;

  List<LogEntry> get entries => List.unmodifiable(_entries);
  int get count => _entries.length;

  /// Session marker written once at startup.
  void sessionStart({required String appVersion, required String locale}) {
    log('session start — app v$appVersion, locale=$locale', LogLevel.action);
  }

  void info(String msg) => log(msg, LogLevel.info);
  void nfc(String msg) => log(msg, LogLevel.nfc);
  void gps(String msg) => log(msg, LogLevel.gps);
  void action(String msg) => log(msg, LogLevel.action);
  void warn(String msg) => log(msg, LogLevel.warn);
  void error(String msg) => log(msg, LogLevel.error);

  /// Core entry point — never throws.
  void log(String message, LogLevel level) {
    final entry = LogEntry(DateTime.now(), level, message);
    _entries.add(entry);
    if (_entries.length > _maxMemoryEntries) {
      _entries.removeRange(0, _entries.length - _maxMemoryEntries);
    }
    _changes.add(null);
    notifyListeners();
    _appendToFile(entry);
  }

  // ------------------------------------------------------------------
  // File persistence
  // ------------------------------------------------------------------

  /// Initializes the log file under the platform app-support directory.
  /// Safe to call multiple times; failures keep the memory-only mode.
  Future<void> initFile() async {
    if (_file != null || _fileFailed) return;
    try {
      final dir = await getApplicationSupportDirectory();
      final logDir = Directory('${dir.path}${Platform.pathSeparator}logs');
      if (!logDir.existsSync()) logDir.createSync(recursive: true);
      final f = File('${logDir.path}${Platform.pathSeparator}kianex_app_log.jsonl');
      _file = f;
      if (f.existsSync() && f.lengthSync() > _rotateBytes) {
        final old = File('${f.path}.1');
        if (old.existsSync()) old.deleteSync();
        f.renameSync('${f.path}.1');
      }
      _appendToFile(LogEntry(
        DateTime.now(),
        LogLevel.info,
        'log file opened at ${f.path}',
      ));
    } catch (e) {
      _fileFailed = true;
      log('log file init failed — memory only ($e)', LogLevel.warn);
    }
  }

  void _appendToFile(LogEntry entry) {
    final f = _file;
    if (f == null || _fileFailed) return;
    try {
      f.writeAsStringSync(
        '${jsonEncode(entry.toJson())}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (_) {
      _fileFailed = true;
    }
  }

  // ------------------------------------------------------------------
  // Viewer / export
  // ------------------------------------------------------------------

  /// Full log as plain text (oldest first) — the export payload.
  String exportText() {
    final b = StringBuffer();
    b.writeln('KIANEX PTS50N1 — application log');
    b.writeln('exported: ${DateTime.now().toIso8601String()}');
    b.writeln('entries: ${_entries.length}');
    b.writeln('----------------------------------------');
    for (final e in _entries) {
      b.writeln('${e.timeText} [${e.levelText}] ${e.message}');
    }
    return b.toString();
  }

  /// Loads previous sessions from the log file into memory (viewer).
  Future<void> loadFromFile() async {
    if (_file == null && !_fileFailed) await initFile();
    final f = _file;
    if (f == null || !f.existsSync()) return;
    try {
      final lines = f.readAsLinesSync();
      final prev = <LogEntry>[];
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          prev.add(LogEntry.fromJson(
            (jsonDecode(line) as Map).cast<String, dynamic>(),
          ));
        } catch (_) {
          // skip damaged lines
        }
      }
      _entries
        ..clear()
        ..addAll(prev);
      _changes.add(null);
      notifyListeners();
    } catch (_) {
      // unreadable file — keep the in-memory entries
    }
  }

  /// Clears the in-memory entries and truncates the file.
  Future<void> clear() async {
    _entries.clear();
    try {
      _file?.deleteSync();
      _file = null;
    } catch (_) {
      // nothing to delete
    }
    await initFile();
    log('log cleared by user', LogLevel.action);
  }
}
