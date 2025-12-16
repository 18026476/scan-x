import 'package:flutter/material.dart';
import '../../core/services/scan_service.dart';

class DeviceDetailsScreen extends StatelessWidget {
  final DetectedHost host;

  const DeviceDetailsScreen({
    super.key,
    required this.host,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ports = host.openPorts;

    return Scaffold(
      appBar: AppBar(
        title: Text(host.hostname ?? host.ip),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            Text(
              'Open ports',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (ports.isEmpty)
              const Text(
                'No open ports detected on this device in the last scan.',
              )
            else
              Expanded(
                child: ListView.separated(
                  itemCount: ports.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = ports[index];
                    return ListTile(
                      dense: true,
                      title: Text('${p.port}/${p.protocol}'),
                      subtitle: Text(p.serviceName),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  host.hostname ?? host.ip,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _buildRiskChip(context, host.risk),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'IP: ${host.ip}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          if (host.hostname != null) ...[
            const SizedBox(height: 4),
            Text(
              'Hostname resolved',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRiskChip(BuildContext context, RiskLevel risk) {
    final label = _riskLabel(risk);
    final color = _riskColor(risk);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.7)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
