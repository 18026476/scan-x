import 'package:flutter/material.dart';
import 'package:scanx_app/core/services/services.dart';

import 'package:scanx_app/features/router/router_iot_card.dart';
import 'package:scanx_app/features/router/router_iot_security.dart';

import 'device_details_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final result = ScanService().lastResult;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Devices',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result == null
                    ? 'Run a Smart or Full Scan to discover devices on your network.'
                    : 'Showing devices from the last scan.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              if (result == null)
                Expanded(
                  child: Center(
                    child: Text(
                      'No scan results.\nGo to the Scan tab and run a scan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: [
                      RouterIotCard(
                        scanService: ScanService(),
                        securityService: RouterIotSecurityService(),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: result.hosts.length,
                          itemBuilder: (context, index) {
                            final host = result.hosts[index];
                            final openPorts = host.openPorts;
                            final risk = host.risk;

                            final title = host.hostname ?? host.ip;

                            final subtitle = host.hostname == null
                                ? 'IP: ${host.ip}'
                                : 'IP: ${host.ip} - Hostname resolved';

                            return InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DeviceDetailsScreen(host: host),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: cs.outlineVariant.withOpacity(0.6),
                                  ),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.devices_other,
                                      color: cs.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: theme.textTheme.titleMedium?.copyWith(
                                                    color: cs.onSurface,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              _buildRiskChip(context, risk),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            subtitle,
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            openPorts.isEmpty
                                                ? 'No open ports detected.'
                                                : '${openPorts.length} open port(s): '
                                                '${openPorts.take(3).map((p) => '${p.port}/${p.protocol}').join(', ')}'
                                                '${openPorts.length > 3 ? '...' : ''}',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskChip(BuildContext context, RiskLevel risk) {
    final cs = Theme.of(context).colorScheme;
    final label = _riskLabel(risk);
    final fg = _riskColor(risk);
    final bg = fg.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _riskLabel(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return 'High risk';
      case RiskLevel.medium:
        return 'Medium risk';
      case RiskLevel.low:
      default:
        return 'Low risk';
    }
  }

  Color _riskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return const Color(0xFFFF5252);
      case RiskLevel.medium:
        return const Color(0xFFFFC107);
      case RiskLevel.low:
      default:
        return const Color(0xFF1ECB7B);
    }
  }
}
