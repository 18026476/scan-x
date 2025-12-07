// lib/features/settings/settings_screen.dart

import 'package:flutter/material.dart';
import '../../core/services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _service = SettingsService();

  late ScanSettings _s;

  final TextEditingController _cidrController = TextEditingController();
  final TextEditingController _customPortController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _s = _service.settings;
    _cidrController.text = _s.defaultTargetCidr;
  }

  @override
  void dispose() {
    _cidrController.dispose();
    _customPortController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    // 🔹 Ensure the latest CIDR text is saved even if onChanged didn't fire
    _s = _s.copyWith(defaultTargetCidr: _cidrController.text.trim());

    _service.updateSettings(_s);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Settings saved")),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _subtitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---------------- NETWORK PROFILE ----------------
          _sectionTitle("Network Profile"),
          TextField(
            controller: _cidrController,
            decoration: const InputDecoration(
              labelText: "Default Target CIDR",
              hintText: "Example: 192.168.1.0/24",
              border: OutlineInputBorder(),
            ),
            onChanged: (v) {
              _s = _s.copyWith(defaultTargetCidr: v);
            },
          ),

          // ---------------- SCAN BEHAVIOUR ----------------
          _sectionTitle("Scan Behaviour"),

          _subtitle("Scan Mode"),
          Column(
            children: [
              RadioListTile<ScanMode>(
                title: const Text("Performance (fastest)"),
                value: ScanMode.performance,
                groupValue: _s.scanMode,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _s = _s.copyWith(scanMode: v));
                },
              ),
              RadioListTile<ScanMode>(
                title: const Text("Balanced (default)"),
                value: ScanMode.balanced,
                groupValue: _s.scanMode,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _s = _s.copyWith(scanMode: v));
                },
              ),
              RadioListTile<ScanMode>(
                title: const Text("Paranoid (deep scans)"),
                value: ScanMode.paranoid,
                groupValue: _s.scanMode,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _s = _s.copyWith(scanMode: v));
                },
              ),
            ],
          ),

          SwitchListTile(
            title: const Text("Host Discovery (nmap -sn)"),
            subtitle: const Text("Scan only live hosts first"),
            value: _s.hostDiscoveryEnabled,
            onChanged: (v) {
              setState(() => _s = _s.copyWith(hostDiscoveryEnabled: v));
            },
          ),

          SwitchListTile(
            title: const Text("Full Scan All Hosts"),
            subtitle: const Text("Disable to deep-scan only risky hosts"),
            value: _s.fullScanAllHosts,
            onChanged: (v) {
              setState(() => _s = _s.copyWith(fullScanAllHosts: v));
            },
          ),

          _subtitle("Max Deep Scan Hosts (1–50)"),
          Slider(
            value: _s.maxDeepHosts.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: _s.maxDeepHosts.toString(),
            onChanged: (v) {
              setState(() => _s = _s.copyWith(maxDeepHosts: v.toInt()));
            },
          ),

          _subtitle("Ports per Phase (1000–15000)"),
          Slider(
            value: _s.portsPerPhase.toDouble(),
            min: 1000,
            max: 15000,
            divisions: 14,
            label: "${_s.portsPerPhase}",
            onChanged: (v) {
              setState(() => _s = _s.copyWith(portsPerPhase: v.toInt()));
            },
          ),

          // ---------------- RISK MODEL ----------------
          _sectionTitle("Risk Model"),

          _subtitle("High Risk — High-Risk Port Count (1–10)"),
          Slider(
            value: _s.highRiskHighPorts.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: "${_s.highRiskHighPorts}",
            onChanged: (v) {
              setState(() =>
              _s = _s.copyWith(highRiskHighPorts: v.toInt()));
            },
          ),

          _subtitle("High Risk — Total Open Ports (5–50)"),
          Slider(
            value: _s.highRiskTotalPorts.toDouble(),
            min: 5,
            max: 50,
            divisions: 45,
            label: "${_s.highRiskTotalPorts}",
            onChanged: (v) {
              setState(() =>
              _s = _s.copyWith(highRiskTotalPorts: v.toInt()));
            },
          ),

          _subtitle("Medium Risk — High-Risk Port Count (1–5)"),
          Slider(
            value: _s.mediumRiskHighPorts.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: "${_s.mediumRiskHighPorts}",
            onChanged: (v) {
              setState(() =>
              _s = _s.copyWith(mediumRiskHighPorts: v.toInt()));
            },
          ),

          _subtitle("Medium Risk — Total Open Ports (2–20)"),
          Slider(
            value: _s.mediumRiskTotalPorts.toDouble(),
            min: 2,
            max: 20,
            divisions: 18,
            label: "${_s.mediumRiskTotalPorts}",
            onChanged: (v) {
              setState(() =>
              _s = _s.copyWith(mediumRiskTotalPorts: v.toInt()));
            },
          ),

          _subtitle("Custom High-Risk Ports"),
          Wrap(
            spacing: 6,
            children: [
              for (final p in _s.customHighRiskPorts)
                Chip(
                  label: Text("$p"),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () {
                    final updated =
                    List<int>.from(_s.customHighRiskPorts)..remove(p);
                    setState(() => _s =
                        _s.copyWith(customHighRiskPorts: updated));
                  },
                ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customPortController,
                  decoration: const InputDecoration(
                    hintText: "Add port (e.g., 23)",
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  final port = int.tryParse(_customPortController.text);
                  if (port == null) return;

                  final updated =
                  List<int>.from(_s.customHighRiskPorts)..add(port);

                  setState(() {
                    _s = _s.copyWith(customHighRiskPorts: updated);
                  });

                  _customPortController.clear();
                },
              ),
            ],
          ),

          // ---------------- AUTOMATION ----------------
          _sectionTitle("Automation"),

          SwitchListTile(
            title: const Text("Auto Quick Scan on Startup"),
            value: _s.autoQuickScanOnStartup,
            onChanged: (v) {
              setState(() =>
              _s = _s.copyWith(autoQuickScanOnStartup: v));
            },
          ),

          // ---------------- HISTORY ----------------
          _sectionTitle("Scan History"),

          SwitchListTile(
            title: const Text("Keep Only Last Scan"),
            subtitle: const Text(
              "Disable to enable scan history (coming soon)",
            ),
            value: _s.keepOnlyLastScan,
            onChanged: (v) {
              setState(() => _s = _s.copyWith(keepOnlyLastScan: v));
            },
          ),
        ],
      ),
    );
  }
}
