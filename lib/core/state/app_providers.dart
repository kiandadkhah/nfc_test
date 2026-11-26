import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';

/// Convenience accessors used across the UI.
typedef AppLocalizationsX = AppLocalizations;

AppLocalizations L(BuildContext context) => AppLocalizations.of(context)!;

bool isFa(BuildContext context) =>
    Localizations.localeOf(context).languageCode == 'fa';
