enum ToggleConsumer {
  scanEngine,
  routerIotAnalyzer,
  alertsEngine,
  notifier,
  reportingPdf,
  none,
}

class ToggleWiring {
  final String key;
  final ToggleConsumer consumer;
  final String notes;
  const ToggleWiring(this.key, this.consumer, this.notes);
}

class ToggleWiringRegistry {
  static const toggles = <ToggleWiring>[
    // Scan & detection
    ToggleWiring('stealthScan', ToggleConsumer.scanEngine, 'Used to build scan profile/args.'),
    ToggleWiring('fullScanEnabled', ToggleConsumer.scanEngine, 'Controls full scan mode.'),
    ToggleWiring('smartScanEnabled', ToggleConsumer.scanEngine, 'Controls smart scan mode.'),

    // Router checks
    ToggleWiring('routerWeakPassword', ToggleConsumer.routerIotAnalyzer, 'Router/IoT advisory.'),
    ToggleWiring('routerOpenPorts', ToggleConsumer.routerIotAnalyzer, 'Router/IoT advisory.'),
    ToggleWiring('routerOutdatedFirmware', ToggleConsumer.routerIotAnalyzer, 'Router advisory.'),
    ToggleWiring('routerUpnpCheck', ToggleConsumer.routerIotAnalyzer, 'UPnP advisory.'),
    ToggleWiring('routerWpsCheck', ToggleConsumer.routerIotAnalyzer, 'WPS advisory.'),
    ToggleWiring('routerDnsHijack', ToggleConsumer.routerIotAnalyzer, 'DNS advisory.'),

    // IoT checks
    ToggleWiring('iotOutdatedFirmware', ToggleConsumer.routerIotAnalyzer, 'IoT advisory.'),
    ToggleWiring('iotDefaultPasswords', ToggleConsumer.routerIotAnalyzer, 'IoT advisory.'),
    ToggleWiring('iotVulnDbMatch', ToggleConsumer.routerIotAnalyzer, 'CVE matching (if enabled).'),
    ToggleWiring('iotAutoRecommendations', ToggleConsumer.routerIotAnalyzer, 'Recommendation surfacing.'),

    // Alerts - detection rules
    ToggleWiring('alertNewDevice', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('alertMacChange', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('alertArpSpoof', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('alertPortScanAttempts', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),

    // Alerts - notifications
    ToggleWiring('notifyNewDevice', ToggleConsumer.notifier, 'InAppNotifier gating'),
    ToggleWiring('notifyUnknownDevice', ToggleConsumer.notifier, 'InAppNotifier gating'),
    ToggleWiring('notifyRouterVulnerability', ToggleConsumer.notifier, 'InAppNotifier gating'),
    ToggleWiring('notifyIotWarning', ToggleConsumer.notifier, 'InAppNotifier gating'),
    ToggleWiring('notifyHighRisk', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('notifyScanCompleted', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),
    ToggleWiring('notifyAutoScanResults', ToggleConsumer.notifier, 'InAppNotifier gating'),

    // Alert style
    ToggleWiring('alertSoundEnabled', ToggleConsumer.notifier, 'InAppNotifier'),
    ToggleWiring('alertVibrationEnabled', ToggleConsumer.notifier, 'InAppNotifier'),
    ToggleWiring('alertSilentMode', ToggleConsumer.notifier, 'InAppNotifier'),
    ToggleWiring('alertSensitivity', ToggleConsumer.alertsEngine, 'AlertRulesEngine'),

    // Reporting
    ToggleWiring('exportPdfEnabled', ToggleConsumer.reportingPdf, 'PDF export button'),
  ];
}