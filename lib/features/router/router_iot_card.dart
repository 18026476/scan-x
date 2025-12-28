// lib/features/router/router_iot_card.dart
//
// Dashboard/Devices card that visualises Router & IoT security status.
// Forward-only: reads from ScanService().lastResult.hosts (does not touch ScanService itself).

import 'package:flutter/material.dart';
import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/features/router/router_iot_security.dart';
import 'package:scanx_app/core/services/security_ai_service.dart';
import 'package:scanx_app/core/services/settings_service.dart';

class RouterIotCard extends StatelessWidget {
  final ScanService scanService;
  final RouterIotSecurityService securityService;

  const RouterIotCard({
    super.key,
    required this.scanService,
    required this.securityService,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Correct source of truth: ScanService.lastResult.hosts
    final result = scanService.lastResult;
    final hosts = result?.hosts ?? const <DetectedHost>[];

    final summary = securityService.buildSummary(hosts);

    final settings = SettingsService();
    final aiInsights = SecurityAiService().networkInsights(
      result: result,
      routerSummary: summary,
    );

    Color badgeColor;
    String label;

    if (hosts.isEmpty) {
      badgeColor = Colors.grey;
      label = 'NO SCAN';
    } else if (summary.issues.any((i) => i.isHighSeverity)) {
      badgeColor = Colors.redAccent;
      label = 'ACTION NEEDED';
    } else if (summary.issues.isNotEmpty) {
      badgeColor = Colors.orangeAccent;
      label = 'REVIEW';
    } else {
      badgeColor = Colors.greenAccent;
      label = 'GOOD';
    }

    String routerLine;
    if (hosts.isEmpty) {
      routerLine = 'Run a scan to detect your router and IoT risks.';
    } else if (summary.routerHost != null) {
      routerLine = 'Router: ${summary.routerHost!.ip}';
    } else {
      routerLine =
      'Router not identified from scan (check your target subnet in Settings).';
    }

    return Card(
      key: const Key('router_iot_card'),

      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Router & IoT Security',
                  style: theme.textTheme.titleMedium,
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Router + IoT summary line
            Text(
              routerLine,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              hosts.isEmpty
                  ? 'IoT devices: 0 (High: 0, Med: 0)'
                  : 'IoT devices: ${summary.totalIotDevices}  '
                  '(High: ${summary.highRiskIotDevices}, Med: ${summary.mediumRiskIotDevices})',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Issues list
            if (hosts.isEmpty)
              Text(
                'No scan results yet. Go to the Scan tab and run a Smart or Full Scan.',
                style: theme.textTheme.bodySmall,
              )
            else if (summary.issues.isEmpty)
              Text(
                'No router / IoT issues detected based on current scan.',
                style: theme.textTheme.bodySmall,
              )
            else
              Column(
                children: summary.issues.map((issue) {
                  final icon = issue.isHighSeverity
                      ? Icons.warning_amber_rounded
                      : Icons.info_outline;
                  final color = issue.isHighSeverity
                      ? Colors.redAccent
                      : Colors.orangeAccent;

                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(icon, color: color),
                    title: Text(
                      issue.title,
                      style: theme.textTheme.bodyMedium,
                    ),
                    subtitle: Text(
                      issue.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                }).toList(),
              ),
            // AI hardening (settings-gated)
            if (hosts.isNotEmpty && settings.aiAssistantEnabled && aiInsights.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'AI hardening',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ...aiInsights.take(2).map((i) {
                final icon = i.severity == AiSeverity.high
                    ? Icons.warning_amber_rounded
                    : i.severity == AiSeverity.medium
                        ? Icons.info_outline
                        : Icons.lightbulb_outline;
                return ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(icon, color: theme.colorScheme.primary),
                  title: Text(i.title, style: theme.textTheme.bodyMedium),
                  subtitle: Text(i.summary, style: theme.textTheme.bodySmall),
                );
              }),
            ],

          ],
        ),
      ),
    );
  }
}
