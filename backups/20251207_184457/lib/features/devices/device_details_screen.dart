// lib/features/devices/device_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scanx_app/core/services/services.dart';

class DeviceDetailsScreen extends StatefulWidget {
  final DetectedHost host;

  const DeviceDetailsScreen({
    super.key,
    required this.host,
  });

  @override
  State<DeviceDetailsScreen> createState() => _DeviceDetailsScreenState();
}

class _DeviceDetailsScreenState extends State<DeviceDetailsScreen> {
  final ScanService _scanService = ScanService();

  late DetectedHost _host;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _host = widget.host;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final risk = _host.risk;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _host.hostname ?? _host.ip,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ListView(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF222222)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1ECB7B),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.devices_other,
                            size: 22,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _host.hostname ?? 'Unknown host',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _host.ip,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildRiskChip(risk),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          '${_host.openPorts.length} open port'
                              '${_host.openPorts.length == 1 ? '' : 's'}',
                        ),
                        if (_host.hostname != null)
                          _buildInfoChip('Hostname resolved'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyIp,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('Copy IP'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.greenAccent,
                              side: const BorderSide(
                                color: Color(0xFF1ECB7B),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : _runSingleHostScan,
                            icon: _isScanning
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.bolt, size: 18),
                            label: Text(
                              _isScanning ? 'Scanning...' : 'Scan this host',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1ECB7B),
                              foregroundColor: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Open Ports',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              if (_host.openPorts.isEmpty)
                Text(
                  'No open ports detected for this host.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
                )
              else
                Column(
                  children: _host.openPorts
                      .map(
                        (p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF222222)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${p.port}/${p.protocol}',
                              style: const TextStyle(
                                color: Colors.greenAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.serviceName.isNotEmpty
                                      ? p.serviceName
                                      : 'Unknown service',
                                  style: theme.textTheme.bodyMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Service detected by scan',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyIp() async {
    await Clipboard.setData(ClipboardData(text: _host.ip));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('IP address copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _runSingleHostScan() async {
    setState(() {
      _isScanning = true;
    });

    try {
      final result = await _scanService.runSmartScan(_host.ip);

      DetectedHost updatedHost;
      try {
        updatedHost = result.hosts.firstWhere((h) => h.ip == _host.ip);
      } catch (_) {
        updatedHost = result.hosts.isNotEmpty ? result.hosts.first : _host;
      }

      if (!mounted) return;

      setState(() {
        _host = updatedHost;
        _isScanning = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Single-host scan completed'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Scan failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.greenAccent.withOpacity(0.4),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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
