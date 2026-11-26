import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/logging/app_logger.dart';
import 'core/settings/settings_controller.dart';
import 'state/programs_provider.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final settings = SettingsController(prefs);
  await settings.load();

  // In-app logger: file persistence + session marker (the field-test
  // report references this log).
  final logger = AppLogger.instance;
  await logger.initFile();
  logger.sessionStart(appVersion: '4.1.0', locale: settings.locale.languageCode);

  final programs = ProgramsController(prefs)
    ..restoreFromLocalJson(prefs.getString('programs.data'));

  runApp(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith((ref) => settings),
        programsProvider.overrideWith((ref) => programs),
      ],
      child: const KianexApp(),
    ),
  );
}
