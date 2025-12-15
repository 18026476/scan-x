// lib/core/services/services.dart
export 'scan_service.dart';
export 'settings_service.dart';

import 'settings_service.dart';

/// Global singleton for settings.
/// This is initialised in main() before runApp.
late SettingsService settingsService;
