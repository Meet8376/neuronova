import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

/// Convenience extension so widgets can write `context.l.todaysTasks`
/// instead of the verbose `AppLocalizations.of(context).todaysTasks`.
extension BuildContextL10n on BuildContext {
  AppLocalizations get l => AppLocalizations.of(this);
}
