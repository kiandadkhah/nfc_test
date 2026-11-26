/// Settings (locale + theme + onboarding + device location) with
/// shared_preferences persistence.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._prefs);

  final SharedPreferences _prefs;

  static const _kLocale = 'settings.locale';
  static const _kTheme = 'settings.theme';
  static const _kOnboarded = 'settings.onboarded';
  static const _kGpsLat = 'settings.gpsLat';
  static const _kGpsLng = 'settings.gpsLng';
  static const _kUtcOffset = 'settings.utcOffset';

  Locale locale = const Locale('fa');
  ThemeMode themeMode = ThemeMode.light;
  bool onboarded = false;

  /// Device location — the basis for sunrise/sunset (Chebyshev) coefficients.
  /// Defaults to Tehran; the user can store exact coordinates on the
  /// Location screen. Iran has no DST since 1401 → fixed +03:30 offset.
  static const double defaultLatitude = 35.6892;
  static const double defaultLongitude = 51.3890;
  static const double defaultUtcOffsetHours = 3.5;

  double gpsLat = defaultLatitude;
  double gpsLng = defaultLongitude;
  double utcOffsetHours = defaultUtcOffsetHours;

  Future<void> load() async {
    final l = _prefs.getString(_kLocale);
    if (l == 'en') {
      locale = const Locale('en');
    } else if (l == 'fa') {
      locale = const Locale('fa');
    }
    final t = _prefs.getString(_kTheme);
    if (t == 'light') {
      themeMode = ThemeMode.light;
    } else if (t == 'dark') {
      themeMode = ThemeMode.dark;
    }
    onboarded = _prefs.getBool(_kOnboarded) ?? false;
    gpsLat = _prefs.getDouble(_kGpsLat) ?? defaultLatitude;
    gpsLng = _prefs.getDouble(_kGpsLng) ?? defaultLongitude;
    utcOffsetHours = _prefs.getDouble(_kUtcOffset) ?? defaultUtcOffsetHours;
    notifyListeners();
  }

  Future<void> setLocale(Locale value) async {
    locale = value;
    await _prefs.setString(_kLocale, value.languageCode);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    themeMode = value;
    await _prefs.setString(_kTheme, value.name);
    notifyListeners();
  }

  Future<void> finishOnboarding() async {
    onboarded = true;
    await _prefs.setBool(_kOnboarded, true);
    notifyListeners();
  }

  /// Persists the device location used to fit the solar coefficients.
  Future<void> setLocation({required double latitude, required double longitude, double? utcOffset}) async {
    gpsLat = latitude;
    gpsLng = longitude;
    if (utcOffset != null) utcOffsetHours = utcOffset;
    await _prefs.setDouble(_kGpsLat, gpsLat);
    await _prefs.setDouble(_kGpsLng, gpsLng);
    await _prefs.setDouble(_kUtcOffset, utcOffsetHours);
    notifyListeners();
  }
}
