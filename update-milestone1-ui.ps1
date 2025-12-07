# update-milestone1-ui.ps1
# Updates Dashboard, Scan, and Devices screens to the Milestone 1 versions.

Write-Host "`n=== SCAN-X: Updating Milestone 1 UI screens ===`n" -ForegroundColor Cyan

$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$dashboardPath = Join-Path $root "lib\features\dashboard\dashboard_screen.dart"
$scanPath      = Join-Path $root "lib\features\scan\scan_screen.dart"
$devicesPath   = Join-Path $root "lib\features\devices\devices_screen.dart"

# Make sure directories exist
$dirs = @(
    (Split-Path $dashboardPath -Parent)
    (Split-Path $scanPath -Parent)
    (Split-Path $devicesPath -Parent)
)

foreach ($d in $dirs) {
    if (-not (Test-Path $d)) {
        Write-Host "Creating directory: $d" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $d -Force | Out-Null
    }
}

Write-Host "Writing dashboard_screen.dart..." -ForegroundColor Yellow
$dashboardContent = @"
import 'package:flutter/material.dart';
import '../../core/services/scan_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScanService _scanService = ScanService();

  bool _isScanning = false;
  ScanResult? _result;

  @override
  void initState() {
    super.initState();
    _result = _scanService.lastResult;
  }

  Future<void> _runScan() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);
    final res = await _scanService.runSmartScan();
    setState(() {
      _result = res;
      _isScanning = false;
    });
  }

  int _countByRisk(RiskLevel level) {
    final hosts = _result?.hosts ?? const [];
    return hosts.where((h) => h.riskLevel == level).length;
  }

  @override
  Widget build(BuildContext context) {
    final hosts = _result?.hosts ?? const [];
    final total = hosts.length;

    return Scaffold(
      appBar: AppBar(title: const Text("SCAN-X Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              _statCard("Devices", "$total", Colors.blue),
              const SizedBox(width: 12),
              _statCard("High", "${_countByRisk(RiskLevel.high)}", Colors.red),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _statCard("Medium", "${_countByRisk(RiskLevel.medium)}",
                  Colors.orange),
              const SizedBox(width: 12),
              _statCard("Low", "${_countByRisk(RiskLevel.low)}", Colors.green),
            ]),

            const SizedBox(height: 16),

            Card(
              child: ListTile(
                title: const Text("Last Scan"),
                subtitle: Text(_result == null
                    ? "No scan yet"
                    : "Finished: ${_result!.finishedAt.toLocal()}"),
                trailing: _isScanning
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _runScan,
                        child: const Text("Run Smart Scan"),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: hosts.isEmpty
                  ? const Center(child: Text("Run a scan to see devices"))
                  : ListView.builder(
                      itemCount: hosts.length,
                      itemBuilder: (context, i) {
                        final h = hosts[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _color(h.riskLevel),
                            ),
                            title: Text(
                                h.displayName ?? h.hostname ?? h.ip),
                            subtitle: Text(h.ip),
                            trailing: Text(
                              h.risk.toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _color(h.riskLevel),
                              ),
                            ),
                          ),
                        );
                      }),
            )
          ],
        ),
      ),
    );
  }

  Color _color(RiskLevel? level) {
    switch (level) {
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.medium:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _statCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(title),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
"@
Set-Content -Path $dashboardPath -Value $dashboardContent -Encoding UTF8 -Force

Write-Host "Writing scan_screen.dart..." -ForegroundColor Yellow
$scanContent = @"
import 'package:flutter/material.dart';
import '../../core/services/scan_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScanService _service = ScanService();

  bool _isScanning = false;
  double _progress = 0.0;

  ScanResult? _result;

  Future<void> _runScan(bool full) async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _progress = 0;
    });

    for (int i = 1; i <= 5; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _progress = i / 5);
    }

    final res =
        full ? await _service.runFullScan() : await _service.runSmartScan();

    if (!mounted) return;
    setState(() {
      _result = res;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hosts = _result?.hosts ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text("Network Scan")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _runScan(false),
                  child: const Text("Smart Scan"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _runScan(true),
                  child: const Text("Full Scan"),
                ),
              ),
            ]),
            const SizedBox(height: 16),

            if (_isScanning) ...[
              LinearProgressIndicator(value: _progress),
              const SizedBox(height: 12),
            ],

            Expanded(
              child: hosts.isEmpty
                  ? const Center(child: Text("Run a scan to detect devices"))
                  : ListView.builder(
                      itemCount: hosts.length,
                      itemBuilder: (_, i) {
                        final h = hosts[i];
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _color(h.riskLevel),
                              child: Text(
                                h.ip.split(".").last,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.white),
                              ),
                            ),
                            title: Text(
                                h.displayName ?? h.hostname ?? h.ip),
                            subtitle: Text(h.ip),
                            trailing: Text(
                              h.risk.toUpperCase(),
                              style: TextStyle(
                                color: _color(h.riskLevel),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
            )
          ],
        ),
      ),
    );
  }

  Color _color(RiskLevel? level) {
    switch (level) {
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.medium:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
"@
Set-Content -Path $scanPath -Value $scanContent -Encoding UTF8 -Force

Write-Host "Writing devices_screen.dart..." -ForegroundColor Yellow
$devicesContent = @"
import 'package:flutter/material.dart';
import '../../core/services/scan_service.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = ScanService();
    final hosts = service.lastHosts;

    return Scaffold(
      appBar: AppBar(title: const Text("Devices")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: hosts.isEmpty
            ? const Center(child: Text("Run a scan to list devices"))
            : ListView.builder(
                itemCount: hosts.length,
                itemBuilder: (_, i) {
                  final h = hosts[i];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _color(h.riskLevel),
                        child: const Icon(Icons.devices, color: Colors.white),
                      ),
                      title: Text(
                        h.displayName ?? h.hostname ?? h.ip,
                      ),
                      subtitle: Text(
                        [
                          h.ip,
                          if (h.osName != null) h.osName!,
                          if (h.macVendor != null) h.macVendor!,
                        ].join(" · "),
                      ),
                      trailing: Text(
                        h.risk.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _color(h.riskLevel),
                        ),
                      ),
                    ),
                  );
                }),
      ),
    );
  }

  Color _color(RiskLevel? level) {
    switch (level) {
      case RiskLevel.high:
        return Colors.red;
      case RiskLevel.medium:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}
"@
Set-Content -Path $devicesPath -Value $devicesContent -Encoding UTF8 -Force

Write-Host "`n=== Milestone 1 UI screens updated ? ===`n" -ForegroundColor Green
