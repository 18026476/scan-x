enum ScanxAlertSeverity {
  info,
  low,
  medium,
  high,
  critical,
}

class ScanxAlertDefinition {
  final String id;
  final String title;
  final ScanxAlertSeverity severity;
  final String shortSummary;
  final String explanation;
  final List<String> benignCauses;
  final List<String> recommendedActions;

  const ScanxAlertDefinition({
    required this.id,
    required this.title,
    required this.severity,
    required this.shortSummary,
    required this.explanation,
    required this.benignCauses,
    required this.recommendedActions,
  });

  String get severityLabel {
    switch (severity) {
      case ScanxAlertSeverity.info:
        return 'Info';
      case ScanxAlertSeverity.low:
        return 'Low Risk';
      case ScanxAlertSeverity.medium:
        return 'Medium Risk';
      case ScanxAlertSeverity.high:
        return 'High Risk';
      case ScanxAlertSeverity.critical:
        return 'Critical Risk';
    }
  }

  String get resultsBannerText => '$title — $shortSummary';
}

class ScanxResolvedAlert {
  final String rawKey;
  final ScanxAlertDefinition definition;

  const ScanxResolvedAlert({
    required this.rawKey,
    required this.definition,
  });
}

class ScanxAlertCatalog {
  static const Map<String, ScanxAlertDefinition> _definitions = {
    'possible_arp_spoofing': ScanxAlertDefinition(
      id: 'possible_arp_spoofing',
      title: 'Possible ARP Spoofing Detected',
      severity: ScanxAlertSeverity.medium,
      shortSummary: 'Multiple devices may be responding as the network gateway.',
      explanation:
          'SCAN-X detected conflicting address resolution behaviour on your local network. '
          'This can happen when more than one device appears to claim the same gateway identity. '
          'In some cases this may indicate ARP spoofing or man-in-the-middle behaviour, where a device attempts to intercept traffic between your computer and the router.',
      benignCauses: [
        'Mesh Wi-Fi systems or extenders',
        'Virtual machines or bridged adapters',
        'Router firmware quirks',
        'Recent IP/MAC changes after reconnecting devices',
      ],
      recommendedActions: [
        'Open your router admin page and review connected devices',
        'Restart the router and re-scan',
        'Remove devices you do not recognize',
        'Ensure WPA2 or WPA3 is enabled',
        'If the alert persists, inspect the gateway MAC address and compare it with the router label or vendor',
      ],
    ),

    'open_smb_service': ScanxAlertDefinition(
      id: 'open_smb_service',
      title: 'SMB Service Exposed',
      severity: ScanxAlertSeverity.medium,
      shortSummary: 'File sharing is available on the device over port 445.',
      explanation:
          'SCAN-X detected an active SMB service. SMB is commonly used for Windows file and printer sharing. '
          'If this service is exposed unnecessarily, it can increase the attack surface of the device.',
      benignCauses: [
        'Normal Windows file sharing',
        'NAS devices',
        'Printer sharing on trusted LANs',
      ],
      recommendedActions: [
        'Disable SMB if you do not use file sharing',
        'Restrict file sharing to trusted devices only',
        'Keep Windows and NAS firmware updated',
        'Avoid exposing SMB outside your local network',
      ],
    ),

    'router_outdated_firmware': ScanxAlertDefinition(
      id: 'router_outdated_firmware',
      title: 'Router Firmware May Be Outdated',
      severity: ScanxAlertSeverity.medium,
      shortSummary: 'Your router may require a firmware update.',
      explanation:
          'Outdated router firmware can leave known vulnerabilities unpatched. '
          'Keeping firmware current reduces the chance of compromise and improves device stability.',
      benignCauses: [
        'Version detection may be incomplete',
        'Vendor firmware naming may vary by region',
      ],
      recommendedActions: [
        'Check the router vendor website or admin panel for updates',
        'Back up router settings before upgrading',
        'Install updates only from the official vendor source',
      ],
    ),

    'unknown_device_detected': ScanxAlertDefinition(
      id: 'unknown_device_detected',
      title: 'Unknown Device Detected',
      severity: ScanxAlertSeverity.low,
      shortSummary: 'A device was found that could not be confidently identified.',
      explanation:
          'SCAN-X found a device on the network but could not confidently map it to a known hostname, vendor, or profile. '
          'This may be harmless, but unknown devices should be reviewed.',
      benignCauses: [
        'Phones using MAC randomization',
        'IoT devices with generic chip vendors',
        'Devices with hostnames disabled',
      ],
      recommendedActions: [
        'Compare the device MAC/vendor against your known devices',
        'Rename trusted devices in the router admin panel',
        'Remove or isolate devices you do not recognize',
      ],
    ),

    'suspicious_port_exposure': ScanxAlertDefinition(
      id: 'suspicious_port_exposure',
      title: 'Unexpected Service Exposure',
      severity: ScanxAlertSeverity.medium,
      shortSummary: 'A device is exposing a service that may not be needed.',
      explanation:
          'SCAN-X detected one or more open ports associated with remotely reachable services. '
          'Unnecessary open services can increase the attack surface of the device.',
      benignCauses: [
        'Legitimate media servers',
        'Developer tools running locally',
        'Printer, NAS, or camera services',
      ],
      recommendedActions: [
        'Review whether the service is required',
        'Disable unused services',
        'Restrict access using firewall rules where possible',
      ],
    ),
  };

  static const ScanxAlertDefinition _genericDefinition = ScanxAlertDefinition(
    id: 'generic_security_notice',
    title: 'Security Notice',
    severity: ScanxAlertSeverity.info,
    shortSummary: 'SCAN-X detected a condition worth reviewing.',
    explanation:
        'SCAN-X identified a network or device condition that may require review. '
        'The condition may be harmless or environment-specific, but it should be checked before being ignored.',
    benignCauses: [
      'Local network topology',
      'Device-specific behaviour',
      'Temporary scan visibility changes',
    ],
    recommendedActions: [
      'Open the alert details',
      'Review the affected device or router configuration',
      'Re-scan after any network changes',
    ],
  );

  static ScanxResolvedAlert resolve(String rawKey) {
    final normalized = normalizeKey(rawKey);
    final definition = _definitions[normalized] ?? _genericDefinition;
    return ScanxResolvedAlert(rawKey: rawKey, definition: definition);
  }

  static String resolveTitle(String rawKey) {
    return resolve(rawKey).definition.title;
  }

  static String resolveSummary(String rawKey) {
    return resolve(rawKey).definition.shortSummary;
  }

  static String resolveBannerText(String rawKey) {
    return resolve(rawKey).definition.resultsBannerText;
  }

  static String normalizeKey(String rawKey) {
    var k = rawKey.trim().toLowerCase();

    // Remove localization suffix leakage like ".title", ".subtitle", etc.
    k = k.replaceAll('.title', '');
    k = k.replaceAll('.subtitle', '');
    k = k.replaceAll('.message', '');
    k = k.replaceAll('.description', '');

    // Normalize spacing and separators
    k = k.replaceAll('-', '_');
    k = k.replaceAll('/', '_');
    k = k.replaceAll(RegExp(r'\s+'), '_');
    k = k.replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
    k = k.replaceAll(RegExp(r'_+'), '_');
    k = k.replaceAll(RegExp(r'^_+|_+$'), '');

    // Known aliases
    if (k == 'possible_arp_spoofing') return 'possible_arp_spoofing';
    if (k == 'arp_spoofing') return 'possible_arp_spoofing';
    if (k == 'possible_arp_spoofing_detected') return 'possible_arp_spoofing';

    if (k == 'smb_service_exposed') return 'open_smb_service';
    if (k == 'smb_exposed') return 'open_smb_service';
    if (k == 'open_smb') return 'open_smb_service';

    if (k == 'router_firmware_outdated') return 'router_outdated_firmware';
    if (k == 'outdated_router_firmware') return 'router_outdated_firmware';

    if (k == 'unknown_device') return 'unknown_device_detected';
    if (k == 'unknown_device_found') return 'unknown_device_detected';

    if (k == 'unexpected_open_ports') return 'suspicious_port_exposure';
    if (k == 'unexpected_service_exposure') return 'suspicious_port_exposure';

    return k;
  }
}