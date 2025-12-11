// lib/features/router/router_iot_card.dart
//
// Dashboard card that visualises Router & IoT security status.

import 'package:flutter/material.dart';
import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/features/router/router_iot_security.dart';

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

    // Use whatever hosts the current scan engine has produced.
    final hosts = (scanService as dynamic).detectedHosts ?? const <dynamic>[];
    final summary = securityService.buildSummary(hosts);

    Color badgeColor;
    String label;

    if (summary.issues.any((i) => i.isHighSeverity)) {
      badgeColor = Colors.redAccent;
      label = 'ACTION NEEDED';
    } else if (summary.issues.isNotEmpty) {
      badgeColor = Colors.orangeAccent;
      label = 'REVIEW';
    } else {
      badgeColor = Colors.greenAccent;
      label = 'GOOD';
    }

    return Card(
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
              summary.routerHost != null
                  ? 'Router: ${(summary.routerHost as dynamic).ip ?? "unknown IP"}'
                  : 'Router not identified from scan.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'IoT devices: ${summary.totalIotDevices}  '
              '(High: ${summary.highRiskIotDevices}, Med: ${summary.mediumRiskIotDevices})',
              style: theme.textTheme.bodySmall,
            ),

            const SizedBox(height: 12),
            const Divider(),

            // Issues list
            if (summary.issues.isEmpty)
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
                  final color =
                      issue.isHighSeverity ? Colors.redAccent : Colors.orangeAccent;

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
          ],
        ),
      ),
    );
  }
}
