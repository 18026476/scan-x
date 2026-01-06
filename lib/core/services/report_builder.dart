import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/settings_service.dart';
import 'package:scanx_app/features/router/router_iot_security.dart';

class ReportBuilder {
  Map<String, dynamic> buildReportJson({
    required ScanResult result,
    required String scanModeLabel,
  }) {
    final s = SettingsService();
    final routerIot = RouterIotSecurityService().buildSummary(result.hosts);

    final findings = <Map<String, dynamic>>[];

    for (final issue in routerIot.issues) {
      final severity = issue.isHighSeverity ? 'High' : 'Medium';
      findings.add({
        'id': issue.type.name,
        'title': issue.title,
        'severity': severity,
        'status': 'Detected',
        'deviceIp': routerIot.routerHost?.address ?? '',
        'evidence': issue.description,
        'recommendation': _recommendationFor(issue.type),
      });
    }

    final highRisk = result.hosts.where((h) => h.risk == RiskLevel.high).length;
    final mediumRisk = result.hosts.where((h) => h.risk == RiskLevel.medium).length;

    int score = 0;
    score += highRisk * 15;
    score += mediumRisk * 8;
    score += routerIot.issues.length * 6;
    if (score > 100) score = 100;

    String rating;
    if (score >= 80) { rating = 'Critical'; }
    else if (score >= 50) { rating = 'High'; }
    else if (score >= 20) { rating = 'Medium'; }
    else { rating = 'Low'; }
    return {
      'scanMeta': {
        'appVersion': 'dev',
        'scanTimeUtc': DateTime.now().toUtc().toIso8601String(),
        'targetCidr': result.target,
        'scanMode': scanModeLabel,
      },
      'settingsSnapshot': {
        'routerWeakPassword': s.routerWeakPassword,
        'routerOpenPorts': s.routerOpenPorts,
        'routerOutdatedFirmware': s.routerOutdatedFirmware,
        'routerUpnpCheck': s.routerUpnpCheck,
        'routerWpsCheck': s.routerWpsCheck,
        'routerDnsHijack': s.routerDnsHijack,
        'iotOutdatedFirmware': s.iotOutdatedFirmware,
        'iotDefaultPasswords': s.iotDefaultPasswords,
        'iotVulnDbMatch': s.iotVulnDbMatch,
        'iotAutoRecommendations': s.iotAutoRecommendations,
      },
      'findings': findings,
      'riskScore': {'score': score, 'rating': rating},
      'summary': {
        'hosts': result.hosts.length,
        'highRiskHosts': highRisk,
        'mediumRiskHosts': mediumRisk,
      },
    };
  }

  String _recommendationFor(RouterIotIssueType t) {
    switch (t) {
      case RouterIotIssueType.iotMediumRisk:
        return 'Review IoT device security: update firmware, change passwords, and disable unused services. Consider isolating IoT to guest/VLAN.';
      case RouterIotIssueType.riskyRouterPorts:
        return 'Review router port forwarding. Close exposed management/WAN ports and disable remote admin unless required.';
      case RouterIotIssueType.possibleUpnp:
        return 'Disable UPnP unless you explicitly need it. Reboot router after changes.';
      case RouterIotIssueType.possibleWps:
        return 'Disable WPS. Use WPA2/WPA3 and a strong Wi-Fi password.';
      case RouterIotIssueType.possibleDnsHijack:
        return 'Verify router DNS settings and admin password. Update firmware if available.';
      case RouterIotIssueType.iotHighRisk:
        return 'Update IoT firmware, change default passwords, and isolate IoT to guest/VLAN if possible.';
      case RouterIotIssueType.routerNotFound:
        return 'Ensure you are scanning the correct CIDR range and that the router IP is within target.';
    }
  }
}