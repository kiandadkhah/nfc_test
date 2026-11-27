import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kianex_pts50n1_app/app.dart';
import 'package:kianex_pts50n1_app/core/settings/settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kianex_pts50n1_app/state/programs_provider.dart';
import 'package:kianex_pts50n1_app/state/providers.dart';

import 'helpers/sample_data.dart';

/// Stubs the platform channels the v4.1/v4.3 startup gate touches, so the
/// smoke test runs the REAL gate without native plugins: the v4.3 native
/// NFC channel (`kianex/nfc`) reports the adapter as present and on, the
/// location permission as granted and the location service as enabled —
/// the gate completes silently and no guidance dialog pops up over the
/// home screen. [v4.1 → v4.3]
void stubSystemChannels() {
  const nfcChannel = MethodChannel('kianex/nfc');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(nfcChannel, (call) async {
    if (call.method == 'availability') return 'available';
    if (call.method == 'enable') return true;
    return null;
  });
  // geolocator: in widget tests the federated plugin is NOT registered, so
  // the default MethodChannelGeolocator (channel flutter.baseflow.com/
  // geolocator) handles the calls — the same frames geolocator_android
  // uses at runtime (int permission index, bool service state).
  const geoChannel = MethodChannel('flutter.baseflow.com/geolocator');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(geoChannel, (call) async {
    switch (call.method) {
      case 'checkPermission':
      case 'requestPermission':
        return 3; // granted — maps to LocationPermission.always
      case 'isLocationServiceEnabled':
        return true;
    }
    return null;
  });
}

void main() {
  testWidgets('app boots to home and renders the seeded program list', (tester) async {
    stubSystemChannels();
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
