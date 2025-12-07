// lib/features/devices/devices_screen.dart

import 'package:flutter/material.dart';
import 'package:scanx_app/core/services/services.dart';

import 'device_details_screen.dart';

class DevicesScreen extends StatelessWidget {
  DevicesScreen({super.key});

  final ScanService _scanService = ScanService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _scanService.lastResult;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Devices',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                result == null
                    ? 'Run a Smart or Full Scan to discover devices on your network.'
                    : 'Showing devices from the last scan.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[400],
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
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: result.hosts.length,
                    itemBuilder: (context, index) {
                      final host = result.hosts[index];
                      final openPorts = host.openPorts;
                      final risk = host.risk;

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
                            color: const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF222222),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.devices_other,
                                color: Color(0xFF1ECB7B),
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
                                            host.hostname ?? host.ip,
                                            style: theme
                                                .textTheme.titleMedium
                                                ?.copyWith(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _buildRiskChip(risk),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      host.hostname == null
                                          ? 'IP: ${host.ip}'
                                          : 'IP: ${host.ip} • Hostname resolved',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      openPorts.isEmpty
                                          ? 'No open ports detected.'
                                          : '${openPorts.length} open port(s): '
                                          '${openPorts.take(3).map((p) => '${p.port}/${p.protocol}').join(', ')}'
                                          '${openPorts.length > 3 ? '...' : ''}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: Colors.grey[400],
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
      ),
    );
  }

  Widget _buildRiskChip(RiskLevel risk) {
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
        return const Color(0xFFFF5252); // red
      case RiskLevel.medium:
        return const Color(0xFFFFC107); // amber
      case RiskLevel.low:
      default:
        return const Color(0xFF1ECB7B); // green
    }
  }
}
