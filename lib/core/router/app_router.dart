/// go_router route table with guards (onboarding gate, write-mode guard).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/nfc/nfc_service.dart';
import '../../features/assign/assign_screen.dart';
import '../../features/device_status/device_status_screen.dart';
import '../../features/device_status/gps_screen.dart';
import '../../features/event_editor/event_editor_screen.dart';
import '../../features/help/help_about_screens.dart';
import '../../features/home/home_screen.dart';
import '../../features/nfc_write/nfc_write_screens.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/program_flow/program_flow_screens.dart';
import '../../features/settings/log_viewer_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../state/providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final settings = ref.read(settingsProvider);
  return GoRouter(
    initialLocation: settings.onboarded ? '/home' : '/onboarding',
    refreshListenable: settings,
    redirect: (context, state) {
      final onboarded = settings.onboarded;
      final inOnboarding = state.matchedLocation == '/onboarding';
      if (!onboarded && !inOnboarding) return '/onboarding';
      if (onboarded && inOnboarding) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/programs',
        builder: (context, state) => const ProgramsEditScreen(),
      ),
      GoRoute(
        path: '/programs/new',
        builder: (context, state) => const CycleScreen(),
      ),
      GoRoute(
        path: '/programs/new/chain',
        builder: (context, state) => const ChainScreen(),
      ),
      GoRoute(
        path: '/programs/new/chain/event',
        builder: (context, state) {
          final idx = state.uri.queryParameters['index'];
          return EventEditorScreen(editIndex: idx == null ? -1 : int.tryParse(idx) ?? -1);
        },
      ),
      GoRoute(
        path: '/programs/new/chain/assign',
        builder: (context, state) => const AssignScreen(),
      ),
      GoRoute(
        path: '/device',
        builder: (context, state) => const DeviceStatusScreen(),
      ),
      GoRoute(
        path: '/write',
        builder: (context, state) {
          final mode = state.uri.queryParameters['mode'] == 'settings'
              ? WriteMode.settingsOnly
              : WriteMode.programAndSettings;
          return WriteConfirmScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/gps',
        builder: (context, state) => const GpsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/logs',
        builder: (context, state) => const LogViewerScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutScreen(),
      ),
    ],
  );
});
