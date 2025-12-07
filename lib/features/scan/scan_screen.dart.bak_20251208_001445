// lib/features/scan/scan_screen.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/services/scan_service.dart';
import '../../core/services/settings_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ScanService _scanService = ScanService();
  final SettingsService _settingsService = SettingsService();

  final TextEditingController _targetController = TextEditingController();

  bool _isScanning = false;
  String? _errorMessage;
  ScanResult? _lastResult;

  double _gaugeValue = 0.0; // 0.0 – 1.0
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();

    final defaultTarget = _settingsService.settings.defaultTargetCidr;
    _targetController.text = defaultTarget;
    _lastResult = _scanService.lastResult;
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _targetController.dispose();
    super.dispose();
  }

  void _startFakeProgress() {
    _progressTimer?.cancel();
    setState(() {
      _gaugeValue = 0.0;
    });

    _progressTimer = Timer.periodic(const Duration(milliseconds: 250), (t) {
      setState(() {
        // creep towards ~90% max while scanning
        _gaugeValue += 0.03;
        if (_gaugeValue > 0.9) _gaugeValue = 0.9;
      });
    });
  }

  void _stopProgress(double finalValue) {
    _progressTimer?.cancel();
    setState(() {
      _gaugeValue = finalValue.clamp(0.0, 1.0);
    });
  }

  Future<void> _runSmartScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    _startFakeProgress();
    final target = _targetController.text.trim();

    try {
      final result = await _scanService.runSmartScan(target);

      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _lastResult = result;
      });

      _stopProgress(0.8); // feels “mostly done”

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Smart scan completed for $target')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = e.toString();
      });

      _stopProgress(0.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Smart scan failed: $e')),
      );
    }
  }

  Future<void> _runFullScan() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });

    _startFakeProgress();
    final target = _targetController.text.trim();

    try {
      final result = await _scanService.runFullScan(target);

      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _lastResult = result;
      });

      _stopProgress(1.0); // full send

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Full scan completed for $target')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isScanning = false;
        _errorMessage = e.toString();
      });

      _stopProgress(0.0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Full scan failed: $e')),
      );
    }
  }

  Color _riskColor(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.high:
        return Colors.redAccent;
      case RiskLevel.medium:
        return Colors.orangeAccent;
      case RiskLevel.low:
        return Colors.greenAccent;
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
    final theme = Theme.of(context);
    final result = _lastResult;
    final hosts = result?.hosts ?? [];

    final highRisk = hosts.where((h) => h.risk == RiskLevel.high).length;
    final mediumRisk = hosts.where((h) => h.risk == RiskLevel.medium).length;
    final lowRisk = hosts.where((h) => h.risk == RiskLevel.low).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------------- SCAN-O-METER GAUGE ------------------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 6,
              child: SizedBox(
                height: 220,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: _ScanGauge(
                          value: _gaugeValue,
                          isActive: _isScanning,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // no status text here (by your request)
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---------------- TARGET + BUTTONS ---------------------------
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _targetController,
                      decoration: const InputDecoration(
                        labelText: 'Target (CIDR or host)',
                        hintText: 'e.g. 192.168.1.0/24',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isScanning ? null : _runSmartScan,
                            icon: _isScanning
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.bolt),
                            label: Text(
                              _isScanning ? 'Scanning…' : 'Smart Scan',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isScanning ? null : _runFullScan,
                            icon: const Icon(Icons.all_inclusive),
                            label: const Text('Full Scan'),
                          ),
                        ),
                      ],
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ---------------- SUMMARY -----------------------------------
            if (result == null)
              Expanded(
                child: Center(
                  child: Text(
                    'No scans yet.\nRun a Smart or Full Scan to see devices.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Results summary',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _summaryChip(
                          label: 'Devices',
                          value: hosts.length.toString(),
                          color: Colors.blueAccent,
                        ),
                        const SizedBox(width: 8),
                        _summaryChip(
                          label: 'High',
                          value: highRisk.toString(),
                          color: Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        _summaryChip(
                          label: 'Medium',
                          value: mediumRisk.toString(),
                          color: Colors.orangeAccent,
                        ),
                        const SizedBox(width: 8),
                        _summaryChip(
                          label: 'Low',
                          value: lowRisk.toString(),
                          color: Colors.greenAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Spacer(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        child: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
        ),
      ),
      label: Text(label),
      backgroundColor: color.withOpacity(0.08),
    );
  }
}

// ---------------------------------------------------------------------------
// SCAN-O-METER GAUGE (TOP SEMICIRCLE 0–100 LEFT→RIGHT)
// ---------------------------------------------------------------------------

class _ScanGauge extends StatelessWidget {
  final double value; // 0.0–1.0
  final bool isActive;

  const _ScanGauge({
    required this.value,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _GaugePainter(
            value: value,
            isActive: isActive,
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value; // 0.0–1.0
  final bool isActive;

  _GaugePainter({
    required this.value,
    required this.isActive,
  });

  double _degToRad(double deg) => deg * math.pi / 180.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Center slightly lower, so the arc sits above it (rainbow style).
    final center = Offset(size.width / 2, size.height * 0.65);
    final radius = math.min(size.width, size.height) * 0.45;

    // TOP semicircle (arc above center, open downwards):
    // 180° (left) -> 360°/0° (right) across the top.
    final startAngle = _degToRad(180);
    final sweepAngle = _degToRad(180); // positive sweep along the top

    // --- Base & active arcs ---
    final basePaint = Paint()
      ..color = const Color(0xFF222831)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final activePaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Colors.greenAccent,
          Colors.orangeAccent,
          Colors.redAccent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(rect, startAngle, sweepAngle, false, basePaint);

    final clampedValue = value.clamp(0.0, 1.0);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * clampedValue,
      false,
      activePaint,
    );

    // --- Tick marks ---
    final tickPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final majorTickPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const tickCount = 20;
    for (int i = 0; i <= tickCount; i++) {
      final t = i / tickCount;
      final angle = startAngle + sweepAngle * t;
      final isMajor = i % 5 == 0;

      final outerRadius = radius;
      final innerRadius = radius - (isMajor ? 18.0 : 10.0);

      final start = Offset(
        center.dx + outerRadius * math.cos(angle),
        center.dy + outerRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + innerRadius * math.cos(angle),
        center.dy + innerRadius * math.sin(angle),
      );

      canvas.drawLine(start, end, isMajor ? majorTickPaint : tickPaint);
    }

    // --- Numeric labels: 0 (left), 50 (top middle), 100 (right) ---
    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    void drawLabel(double t, String label) {
      final angle = startAngle + sweepAngle * t;
      final labelRadius = radius + 20;

      final pos = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      textPainter.text = TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
        ),
      );
      textPainter.layout();

      final offset = Offset(
        pos.dx - textPainter.width / 2,
        pos.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, offset);
    }

    drawLabel(0.0, '0');
    drawLabel(0.5, '50');
    drawLabel(1.0, '100');

    // --- Needle ---
    final needleAngle = startAngle + sweepAngle * clampedValue;
    final needleLength = radius * 0.9;

    final needlePaint = Paint()
      ..color = isActive ? Colors.greenAccent : Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    canvas.drawLine(center, needleEnd, needlePaint);

    if (isActive) {
      final glowPaint = Paint()
        ..color = Colors.greenAccent.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.drawLine(center, needleEnd, glowPaint);
    }

    // --- Center knob ---
    final knobPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 9, knobPaint);

    final knobBorder = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 9, knobBorder);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value || oldDelegate.isActive != isActive;
  }
}
