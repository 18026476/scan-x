import 'package:flutter/material.dart';

import '../../core/services/scan_service.dart';
import '../../core/services/services.dart'; // if you have a barrel file
import 'device_details_screen.dart';

// ------------------------------------------------------------------
// Device classification helper (Milestone 1)
// ------------------------------------------------------------------

String classifyDeviceLabel(DetectedHost host) {
  final name = (host.hostname ?? "").toLowerCase();
  final ip = host.ip;
  final os = (host.osName ?? "").toLowerCase();
  final vendor = (host.macVendor ?? "").toLowerCase();
  final ports = host.openPorts ?? const <int>[];

  bool hasAny(Iterable<int> wanted) =>
      ports.any((p) => wanted.contains(p));

  // 1) Router
  if (host.hostType == HostType.router ||
      name.contains("router") ||
      name.contains("gateway") ||
      ip.endsWith(".1")) {
    return "Router";
  }

  // 2) Phones (Android / iOS)
  final phoneHints = [
    "iphone",
    "ipad",
    "android",
    "samsung",
    "galaxy",
    "pixel",
    "oppo",
    "oneplus",
    "xiaomi",
    "redmi",
  ];

  if (phoneHints.any((h) =>
  name.contains(h) || os.contains(h) || vendor.contains(h))) {
    return "Phone";
  }

  // ADB / Google Play related – weak but helpful
  if (hasAny(const [5555, 5228, 5229, 5230])) {
    return "Phone";
  }

  // 3) Desktop / laptop
  final desktopHints = [
    "desktop-",
    "laptop-",
    "lenovo",
    "dell",
    "hp",
    "msi",
    "asus",
    "acer",
  ];

  if (desktopHints.any((h) =>
  name.contains(h) || vendor.contains(h))) {
    return "Computer";
  }

  // Classic Windows SMB ports
  if (hasAny(const [135, 139, 445])) {
    return "Computer";
  }

  // 4) Smart TV / media devices
  final tvHints = [
    "tv",
    "chromecast",
    "roku",
    "fire tv",
    "bravia",
    "lgwebos",
  ];

  if (tvHints.any((h) =>
  name.contains(h) || vendor.contains(h))) {
    return "Smart TV / Media device";
  }

  // 5) Printers
  if (host.hostType == HostType.printer ||
      name.contains("printer") ||
      hasAny(const [515, 9100, 631])) {
    return "Printer";
  }

  // 6) IoT / smart home
  final iotHints = [
    "cam",
    "camera",
    "cctv",
    "doorbell",
    "hue",
    "tplink",
    "tuya",
    "bosch",
    "honeywell",
    "izone",
  ];

  if (iotHints.any((h) =>
  name.contains(h) || vendor.contains(h))) {
    return "IoT device";
  }

  // 7) Fallback to explicit hostType if set
  switch (host.hostType) {
    case HostType.phone:
      return "Phone";
    case HostType.computer:
      return "Computer";
    case HostType.tablet:
      return "Tablet";
    case HostType.iot:
      return "IoT device";
    case HostType.router:
      return "Router";
    case HostType.printer:
      return "Printer";
    default:
      return "Device";
  }
}

// ------------------------------------------------------------------
// Devices Screen
// ------------------------------------------------------------------

class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});

  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final ScanService _scanService = ScanService();

  Future<List<DetectedHost>> _loadHosts() async {
    // Adjust this to match your ScanService API if different
    final scan = await _scanService.getLastScan();
    return scan?.hosts ?? <DetectedHost>[];
  }

  Color _riskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:
        return Colors.greenAccent.shade400;
      case RiskLevel.medium:
        return Colors.orangeAccent.shade400;
      case RiskLevel.high:
        return Colors.redAccent.shade400;
    }
  }

  String _riskLabel(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:
        return "Low risk";
      case RiskLevel.medium:
        return "Medium risk";
      case RiskLevel.high:
        return "High risk";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Devices"),
        centerTitle: true,
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                "Showing devices from the last scan.",
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<DetectedHost>>(
                future: _loadHosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Failed to load devices: ${snapshot.error}",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    );
                  }

                  final hosts = snapshot.data ?? <DetectedHost>[];

                  if (hosts.isEmpty) {
                    return const Center(
                      child: Text(
                        "No devices from last scan.\nRun a scan to populate this list.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: hosts.length,
                    itemBuilder: (context, index) {
                      final host = hosts[index];

                      final label = classifyDeviceLabel(host); // CHANGED
                      final title = host.displayName ?? host.hostname ?? host.ip;
                      final ip = host.ip;
                      final openPorts = host.openPorts ?? const <int>[];
                      final risk = host.risk ?? RiskLevel.low;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Card(
                          color: const Color(0xFF141414),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DeviceDetailsScreen(
                                    host: host,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.center,
                                children: [
                                  // Leading icon
                                  Container(
                                    width: 46,
                                    height: 46,
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius:
                                      BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.devices_other,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "$label • IP: $ip", // CHANGED
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          openPorts.isEmpty
                                              ? "No open ports detected."
                                              : "${openPorts.length} open port(s): ${openPorts.take(3).join(",")}tcp...",
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: Colors.white54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Risk badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _riskColor(risk)
                                          .withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(999),
                                      border: Border.all(
                                        color: _riskColor(risk),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _riskLabel(risk),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
