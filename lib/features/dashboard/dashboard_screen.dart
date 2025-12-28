import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/scan_service.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/security_ai_service.dart';
import '../devices/device_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isScanning = false;

  // -----------------------------
  // AI feature flags (defaults ON)
  // -----------------------------
  bool _aiAssistantEnabled = true;
  bool _aiExplainVulnsEnabled = true;
  bool _aiOneClickFixesEnabled = true; // guided fixes
  bool _aiRiskScoringEnabled = true;
  bool _aiRouterPlaybooksEnabled = true;
  bool _aiUnnecessaryServicesEnabled = true;
  bool _aiProactiveWarningsEnabled = true;

  // Cached AI insights for dashboard display (computed after scan)
  List<AiInsight> _aiInsights = const [];

  @override
  void initState() {
    super.initState();
    _loadAiFlags();
  }

  // ---------------------------------------------------------------------------
  // Unified AI flag loader: reads NEW + legacy keys, defaults to ON (release-safe)
  // ---------------------------------------------------------------------------
  Future<void> _loadAiFlags() async {
    final p = await SharedPreferences.getInstance();

    bool r(String newKey, String oldKey, bool def) =>
        p.getBool(newKey) ?? p.getBool(oldKey) ?? def;

    if (!mounted) return;
    setState(() {
      _aiAssistantEnabled = r('scanx.ai.assistant', 'aiAssistantEnabled', true);

      _aiExplainVulnsEnabled =
          r('scanx.ai.explain_vulns', 'aiExplainVuln', true);

      _aiOneClickFixesEnabled =
          r('scanx.ai.guided_fixes', 'aiOneClickFix', true);

      _aiRiskScoringEnabled =
          r('scanx.ai.risk_scoring', 'aiRiskScoring', true);

      _aiRouterPlaybooksEnabled =
          r('scanx.ai.router_playbooks', 'aiRouterHardening', true);

      _aiUnnecessaryServicesEnabled = r(
        'scanx.ai.unnecessary_services',
        'aiDetectUnnecessaryServices',
        true,
      );

      _aiProactiveWarningsEnabled =
          r('scanx.ai.proactive_warnings', 'aiProactiveWarnings', true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = ScanService().lastResult;

    // ✅ KEY FIX: Use a scrollable ListView (no Column overflow)
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'SCAN-X Dashboard',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 18),

            // Network health
            _card(
              context,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Network health',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          result == null
                              ? 'No scans yet. Run a Quick Smart Scan to get your first health score.'
                              : 'Your network health score is based on open ports and risk signals from your last scan.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    result == null ? 'No data' : '${_healthScore(result)}%',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick actions
            _card(
              context,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick actions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: _isScanning ? null : _runQuickSmartScan,
                      icon: _isScanning
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Icon(Icons.flash_on),
                      label:
                      Text(_isScanning ? 'Scanning...' : 'Quick Smart Scan'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Uses your default target from Settings (e.g. 192.168.1.0/24). You can inspect details in the Scan and Devices tabs.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ KEY FIX: Use Wrap instead of Expanded Row (prevents height issues)
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 880;
                final cardWidth = isNarrow
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 16) / 2;

                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _card(
                        context,
                        child: _statTile(
                          context,
                          title: 'Devices found',
                          value: result?.hosts.length.toString() ?? '0',
                          icon: Icons.devices_other,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _card(
                        context,
                        child: _statTile(
                          context,
                          title: 'Last target',
                          value: result?.target ?? _safeDefaultTargetPreview(),
                          icon: Icons.router,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // AI Panel (now scroll-safe)
            _buildAiPanel(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // AI Panel
  // ---------------------------------------------------------------------------
  Widget _buildAiPanel(BuildContext context) {
    final theme = Theme.of(context);
    final result = ScanService().lastResult;

    final statusText = _aiAssistantEnabled
        ? 'AI assistant is ON. Run a scan to generate insights.'
        : 'AI assistant is OFF in Settings. Turn it ON to see insights.';

    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _aiAssistantEnabled ? Icons.psychology : Icons.psychology_outlined,
                color: _aiAssistantEnabled
                    ? theme.colorScheme.primary
                    : theme.colorScheme.error,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI Security Insights',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                _aiAssistantEnabled ? 'ON' : 'OFF',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: _aiAssistantEnabled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            statusText,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 12),

          // Feature chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(theme, 'Explain', _aiExplainVulnsEnabled && _aiAssistantEnabled),
              _chip(theme, 'Guided fixes', _aiOneClickFixesEnabled && _aiAssistantEnabled),
              _chip(theme, 'Risk scoring', _aiRiskScoringEnabled && _aiAssistantEnabled),
              _chip(theme, 'Router playbooks', _aiRouterPlaybooksEnabled && _aiAssistantEnabled),
              _chip(theme, 'Unnecessary services', _aiUnnecessaryServicesEnabled && _aiAssistantEnabled),
              _chip(theme, 'Proactive warnings', _aiProactiveWarningsEnabled && _aiAssistantEnabled),
            ],
          ),

          const SizedBox(height: 14),

          if (!_aiAssistantEnabled)
            Text(
              'Turn ON AI Assistant in Settings → AI & Labs.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (result == null)
            Text(
              'No scan data yet. Run Quick Smart Scan to generate AI insights.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            _aiInsightsList(context),
        ],
      ),
    );
  }

  Widget _aiInsightsList(BuildContext context) {
    final theme = Theme.of(context);
    final result = ScanService().lastResult;

    if (_aiInsights.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No AI insights generated yet for the current scan. Tap Generate insights.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: _isScanning ? null : _runQuickSmartScan,
                icon: const Icon(Icons.refresh),
                label: const Text('Generate insights'),
              ),
              OutlinedButton.icon(
                onPressed: result == null || result.hosts.isEmpty
                    ? null
                    : () => _openTopRiskDevice(context),
                icon: const Icon(Icons.devices),
                label: const Text('Review device'),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._aiInsights.take(10).map((i) => _aiInsightCard(context, i)),
        const SizedBox(height: 10),
        if (result != null && result.hosts.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _openTopRiskDevice(context),
              icon: const Icon(Icons.security),
              label: const Text('Review highest risk device'),
            ),
          ),
      ],
    );
  }

  Widget _aiInsightCard(BuildContext context, AiInsight i) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Color accent;
    switch (i.severity) {
      case AiSeverity.high:
        accent = cs.error;
        break;
      case AiSeverity.medium:
        accent = cs.tertiary;
        break;
      case AiSeverity.low:
      default:
        accent = cs.primary;
        break;
    }

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
                Text(
                  i.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  i.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface,
                  ),
                ),
                if (i.action != null && i.action!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Next: ${i.action}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
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

  Widget _chip(ThemeData theme, String label, bool enabled) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: enabled ? cs.primary.withOpacity(0.12) : cs.surfaceVariant,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: enabled ? cs.primary.withOpacity(0.30) : cs.outlineVariant,
        ),
      ),
      child: Text(
        enabled ? '$label: ON' : '$label: OFF',
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: enabled ? cs.primary : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  void _openTopRiskDevice(BuildContext context) {
    final result = ScanService().lastResult;
    if (result == null || result.hosts.isEmpty) return;

    final sorted = [...result.hosts]
      ..sort((a, b) {
        final ra = a.risk.index;
        final rb = b.risk.index;
        if (ra != rb) return rb.compareTo(ra);
        return b.openPorts.length.compareTo(a.openPorts.length);
      });

    final host = sorted.first;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceDetailsScreen(host: host),
      ),
    );
  }

  String _safeDefaultTargetPreview() {
    try {
      final s = SettingsService().settings;
      return s.defaultTargetCidr;
    } catch (_) {
      return '192.168.1.0/24';
    }
  }

  int _healthScore(ScanResult r) {
    if (r.hosts.isEmpty) return 100;
    int score = 100;

    for (final h in r.hosts) {
      if (h.risk == RiskLevel.high) score -= 15;
      if (h.risk == RiskLevel.medium) score -= 7;
      if (h.openPorts.length > 10) score -= 5;
    }

    if (score < 0) score = 0;
    if (score > 100) score = 100;
    return score;
  }

  Future<void> _runQuickSmartScan() async {
    if (_isScanning) return;

    await _loadAiFlags();

    setState(() {
      _isScanning = true;
      _aiInsights = const [];
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ScanProgressDialog(),
      );
    }

    try {
      await ScanService()
          .runQuickSmartScanFromDefaults()
          .timeout(const Duration(minutes: 4));

      final result = ScanService().lastResult;

      if (_aiAssistantEnabled && result != null) {
        final ai = SecurityAiService();
        // Uses your existing AI generator. Router summary stays null for stability.
        final insights = ai.networkInsights(
          result: result,
          routerSummary: null,
        );

        _aiInsights = insights;
      }

      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        final target = ScanService().lastResult?.target ?? 'target';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan complete. Found devices for $target.')),
        );
      }

      if (mounted) setState(() {});
    } on TimeoutException {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Scan timed out. Try Performance mode or a smaller CIDR (e.g. /25 or /26).',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scan failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.35)),
      ),
      child: child,
    );
  }

  Widget _statTile(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
      }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanProgressDialog extends StatelessWidget {
  const _ScanProgressDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scanning…',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text('Quick Smart Scan running.', style: theme.textTheme.bodyMedium),
              const SizedBox(height: 14),
              const LinearProgressIndicator(),
              const SizedBox(height: 10),
              Text(
                'This can take a couple of minutes depending on network size.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
