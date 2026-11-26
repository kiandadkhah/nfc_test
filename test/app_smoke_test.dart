import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kianex_pts50n1_app/app.dart';
import 'package:kianex_pts50n1_app/core/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kianex_pts50n1_app/state/programs_provider.dart';
import 'package:kianex_pts50n1_app/state/providers.dart';

import 'helpers/sample_data.dart';

void main() {
  testWidgets('app boots to home and renders the seeded program list', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsController(prefs);
    await settings.load();
    await settings.finishOnboarding();

    final programs = ProgramsController(prefs)..restoreFrom(samplePrograms);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsProvider.overrideWith((ref) => settings),
          programsProvider.overrideWith((ref) => programs),
        ],
        child: const KianexApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Header brand + the seeded program card are visible.
    expect(find.text('KIANEX'), findsOneWidget);
    expect(find.text('روشنایی محوطه'), findsOneWidget);
    expect(find.text('پمپ استخر'), findsOneWidget);
  });
}
