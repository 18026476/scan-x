import 'dart:async';

import 'package:flutter/material.dart';
import 'package:scanx_app/core/services/services.dart';

import 'package:scanx_app/features/router/router_iot_card.dart';
import 'package:scanx_app/features/router/router_iot_security.dart';

import 'device_details_screen.dart';

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  ScanResult? _last;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _last = ScanService().lastResult;

    // Refresh when scans complete while user is on Devices tab
    _poll = Timer.periodic(const Duration(milliseconds: 700), (_) {
      final now = ScanService().lastResult;
      if (!mounted) return;

      final changed = (now != _last) ||
          (now?.finishedAt != _last?.finishedAt) ||
          (now?.hosts.length != _last?.hosts.length);

      if (changed) {
        setState(() => _last = now);
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final result = _last;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        // FIX: Make the entire page scrollable so Router card + AI section never overflows.
        child: result == null
            ? Padding(
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
                'Run a Smart or Full Scan to discover devices on your network.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
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
              ),
            ],
          ),
        )
            : ListView(
          padding: const EdgeInsets.all(24.0),
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
              'Showing devices from the last scan.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Router & IoT Security (includes AI hardening section internally)
            RouterIotCard(
              scanService: ScanService(),
              securityService: RouterIotSecurityService(),
            ),
            const SizedBox(height: 12),

            ...List.generate(result.hosts.length, (index) {
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
            }),
          ],
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
