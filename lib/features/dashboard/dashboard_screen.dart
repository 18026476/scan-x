// lib/features/dashboard/dashboard_screen.dart

import 'package:flutter/material.dart';
import '../../core/services/scan_service.dart';
import '../../core/services/settings_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScanService _scanService = ScanService();
  final SettingsService _settingsService = SettingsService();

  bool _isScanning = false;
  String? _errorMessage;

  Future<void> _handleQuickScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    final target = _settingsService.settings.defaultTargetCidr;

    try {
      await _scanService.runSmartScan(target);

      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick scan completed for $target'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick scan failed: $e'),
        ),
      );
    }
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final result = _scanService.lastResult;
    final hasData = result != null && result.hosts.isNotEmpty;
    final hosts = result?.hosts ?? [];

    final highRiskCount =
        hosts.where((h) => h.risk == RiskLevel.high).length;
    final mediumRiskCount =
        hosts.where((h) => h.risk == RiskLevel.medium).length;
    final lowRiskCount =
        hosts.where((h) => h.risk == RiskLevel.low).length;

    final totalHosts = hosts.length;

    int securityScore = 100;
    securityScore -= highRiskCount * 20;
    securityScore -= mediumRiskCount * 10;
    if (securityScore < 0) securityScore = 0;
    if (!hasData) securityScore = 0;

    final sortedHosts = [...hosts]
      ..sort((a, b) {
        int riskWeight(RiskLevel r) {
          switch (r) {
            case RiskLevel.high:
              return 3;
            case RiskLevel.medium:
              return 2;
            case RiskLevel.low:
              return 1;
          }
        }

        final scoreA = riskWeight(a.risk) * 100 + a.openPorts.length;
        final scoreB = riskWeight(b.risk) * 100 + b.openPorts.length;
        return scoreB.compareTo(scoreA);
      });

    final lastScanTime = result?.finishedAt;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SCAN-X Dashboard'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _HeaderCard(
                score: securityScore,
                isScanning: _isScanning,
                totalHosts: totalHosts,
                highRisk: highRiskCount,
                mediumRisk: mediumRiskCount,
                lowRisk: lowRiskCount,
                onQuickScan: _handleQuickScan,
              ),
              const SizedBox(height: 16),
              if (_errorMessage != null) ...[
                _ErrorBanner(message: _errorMessage!),
                const SizedBox(height: 12),
              ],
              hasData
                  ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RiskSummaryRow(
                    highRisk: highRiskCount,
                    mediumRisk: mediumRiskCount,
                    lowRisk: lowRiskCount,
                  ),
                  const SizedBox(height: 16),
                  _LastScanInfo(lastScanTime: lastScanTime),
                  const SizedBox(height: 16),
                  _TopRiskyDevicesSection(
                    hosts: sortedHosts.take(5).toList(),
                  ),
                  const SizedBox(height: 24),
                  const _HintCard(),
                ],
              )
                  : const _EmptyState(),
            ],
          ),
        ),
      ),
    );
  }
}

/// HEADER CARD: meter + quick scan button
class _HeaderCard extends StatelessWidget {
  final int score;
  final bool isScanning;
  final int totalHosts;
  final int highRisk;
  final int mediumRisk;
  final int lowRisk;
  final VoidCallback onQuickScan;

  const _HeaderCard({
    required this.score,
    required this.isScanning,
    required this.totalHosts,
    required this.highRisk,
    required this.mediumRisk,
    required this.lowRisk,
    required this.onQuickScan,
  });

  Color _scoreColor() {
    if (score >= 80) return Colors.greenAccent;
    if (score >= 50) return Colors.orangeAccent;
    if (score > 0) return Colors.redAccent;
    return Colors.grey;
  }

  String _scoreLabel() {
    if (score >= 80) return 'Secure';
    if (score >= 50) return 'Moderate risk';
    if (score > 0) return 'High risk';
    return 'No data yet';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scoreColor = _scoreColor();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF141E30), Color(0xFF243B55)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 10,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    backgroundColor: Colors.transparent,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/100',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Network Health',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _scoreLabel(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Devices: $totalHosts\n'
                      'High: $highRisk   Medium: $mediumRisk   Low: $lowRisk',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  onPressed: isScanning ? null : onQuickScan,
                  icon: isScanning
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Icon(Icons.bolt),
                  label: Text(
                    isScanning ? 'Scanning…' : 'Quick Scan',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskSummaryRow extends StatelessWidget {
  final int highRisk;
  final int mediumRisk;
  final int lowRisk;

  const _RiskSummaryRow({
    required this.highRisk,
    required this.mediumRisk,
    required this.lowRisk,
  });

  @override
  Widget build(BuildContext context) {
    Widget buildCard(String title, int count, Color color) {
      return Expanded(
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildCard('High risk', highRisk, Colors.red),
        const SizedBox(width: 8),
        buildCard('Medium risk', mediumRisk, Colors.orange),
        const SizedBox(width: 8),
        buildCard('Low risk', lowRisk, Colors.green),
      ],
    );
  }
}

class _LastScanInfo extends StatelessWidget {
  final DateTime? lastScanTime;

  const _LastScanInfo({required this.lastScanTime});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.history),
        title: const Text('Last scan'),
        subtitle: Text(
          lastScanTime != null
              ? lastScanTime.toString()
              : 'No scan has been run yet',
        ),
      ),
    );
  }
}

class _TopRiskyDevicesSection extends StatelessWidget {
  final List<DetectedHost> hosts;

  const _TopRiskyDevicesSection({required this.hosts});

  Color _riskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.low:
        return Colors.green;
    }
  }

  String _riskLabel(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return 'High';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.low:
        return 'Low';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (hosts.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Text('No devices to show yet. Run a scan first.'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top risky devices',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hosts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final host = hosts[index];
              final riskColor = _riskColor(host.risk);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: riskColor.withOpacity(0.15),
                  child: Icon(
                    Icons.device_hub,
                    color: riskColor,
                  ),
                ),
                title: Text(host.hostname ?? host.ip),
                subtitle: Text(
                  '${host.ip} • ${host.openPorts.length} open ports',
                ),
                trailing: Container(
                  padding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _riskLabel(host.risk),
                    style: TextStyle(
                      color: riskColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Tip: Use Quick Scan for a fast overview of your network. '
              'For deeper analysis, run a full scan from the Scan tab.',
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No scans yet',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Run a Quick Scan from here or go to the Scan tab to start.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Colors.red.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
