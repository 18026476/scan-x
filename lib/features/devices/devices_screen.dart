import 'package:flutter/material.dart';
import 'package:scanx_app/core/services/services.dart';

import 'package:scanx_app/features/router/router_iot_card.dart';
import 'package:scanx_app/features/router/router_iot_security.dart';

import 'device_details_screen.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = ScanService().lastResult;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Devices',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result == null
                    ? 'Run a Smart or Full Scan to discover devices.'
                    : 'Showing devices from the last scan.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              if (result == null)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No scan results.\nGo to Scan and run a scan.',
                      textAlign: TextAlign.center,
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

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DeviceDetailsScreen(host: host),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                margin:
                                const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color:
                                  theme.colorScheme.surface,
                                  borderRadius:
                                  BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.devices_other,
                                      color: Color(0xFF1ECB7B),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  host.hostname ??
                                                      host.ip,
                                                  style: theme
                                                      .textTheme
                                                      .titleMedium
                                                      ?.copyWith(
                                                    fontWeight:
                                                    FontWeight
                                                        .bold,
                                                  ),
                                                ),
                                              ),
                                              _buildRiskChip(
                                                  host.risk),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'IP: ${host.ip}'
                                                '${host.hostname != null ? ' · Hostname resolved' : ''}',
                                            style: theme
                                                .textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            host.openPorts.isEmpty
                                                ? 'No open ports detected.'
                                                : '${host.openPorts.length} open port(s): '
                                                '${host.openPorts.take(3).map((p) => '${p.port}/${p.protocol}').join(', ')}'
                                                '${host.openPorts.length > 3 ? '…' : ''}',
                                            style: theme
                                                .textTheme.bodySmall,
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

  Widget _buildRiskChip(RiskLevel risk) {
    final color = _riskColor(risk);

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(
        _riskLabel(risk),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
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
        return const Color(0xFF1ECB7B);
    }
  }
}
