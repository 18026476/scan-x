import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/services/scan_service.dart';
import '../../core/services/settings_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isScanning = false;

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
                    Icon(Icons.shield_outlined,
                        color: theme.colorScheme.primary),
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
                        label: Text(_isScanning
                            ? 'Scanning...'
                            : 'Quick Smart Scan'),
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

              Expanded(
                child: Row(
                  children: [
                    Expanded(
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
                    const SizedBox(width: 16),
                    Expanded(
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
                ),
              ),
            ],
          ),
        ),
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
    setState(() => _isScanning = true);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _ScanProgressDialog(),
      );
    }

    try {
      // Use the ScanService helper so Dashboard does NOT depend on a specific settings field name.
      await ScanService()
          .runQuickSmartScanFromDefaults()
          .timeout(const Duration(minutes: 4));

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
        border: Border.all(
          color: theme.dividerColor.withOpacity(0.35),
        ),
      ),
      child: child,
    );
  }

  Widget _statTile(BuildContext context,
      {required String title, required String value, required IconData icon}) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  )),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  )),
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
              Text(
                'Quick Smart Scan running.',
                style: theme.textTheme.bodyMedium,
              ),
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
