import 'package:flutter/material.dart';

import 'package:scanx_app/core/services/scan_service.dart';
import 'package:scanx_app/core/services/security_ai_service.dart';

class DeviceDetailsScreen extends StatelessWidget {
  final DetectedHost host;

  const DeviceDetailsScreen({
    super.key,
    required this.host,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // FIX: construct with no args (avoids positional-arg compile errors)
    final ai = SecurityAiService();

    final insights = ai.deviceInsights(
      host: host,
      result: ScanService().lastResult,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(host.hostname?.trim().isNotEmpty == true ? host.hostname!.trim() : host.ip),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _headerCard(context),
          const SizedBox(height: 14),
          _portsCard(context),
          const SizedBox(height: 14),
          _aiInsightsCard(theme, insights),
        ],
      ),
    );
  }

  Widget _headerCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final title = host.hostname?.trim().isNotEmpty == true ? host.hostname!.trim() : host.ip;
    final subtitle = host.hostname?.trim().isNotEmpty == true ? 'IP: ${host.ip}' : 'Hostname: (not resolved)';

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
          Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          _riskPill(context, host.risk),
        ],
      ),
    );
  }

  Widget _portsCard(BuildContext context) {
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
          Text('Open ports', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (host.openPorts.isEmpty)
            Text(
              'No open ports detected.',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            ...host.openPorts.map((p) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: cs.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${p.port}/${p.protocol} • ${p.serviceName}',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _aiInsightsCard(ThemeData theme, List<AiInsight> insights) {
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
          Text('AI insights', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          if (insights.isEmpty)
            Text(
              'No AI insights available for this device.',
              style: theme.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            )
          else
            ...insights.map((i) => _insightTile(theme, i)).toList(),
        ],
      ),
    );
  }

  Widget _insightTile(ThemeData theme, AiInsight i) {
    final cs = theme.colorScheme;

    final Color accent = (i.severity == AiSeverity.high)
        ? cs.error
        : (i.severity == AiSeverity.medium ? cs.tertiary : cs.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.smart_toy_outlined, color: accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(i.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(i.message, style: theme.textTheme.bodyMedium),
                if (i.action != null && i.action!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Next: ${i.action}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskPill(BuildContext context, RiskLevel risk) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    late final String label;
    late final Color color;

    switch (risk) {
      case RiskLevel.high:
        label = 'High risk';
        color = cs.error;
        break;
      case RiskLevel.medium:
        label = 'Medium risk';
        color = cs.tertiary;
        break;
      case RiskLevel.low:
      default:
        label = 'Low risk';
        color = cs.secondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.30)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}
