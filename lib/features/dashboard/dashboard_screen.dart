import 'package:flutter/material.dart';

// Services
import 'package:scanx_app/core/services/scan_service.dart';

/// SCAN-X Dashboard (light, clean, efficient)
///
/// Goals:
/// - Light-themed layout (white cards + subtle borders)
/// - Quick Smart Scan works directly from Dashboard
/// - Avoids referencing ScanSettings.defaultTarget (which broke your build)
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isQuickScanning = false;

  // We intentionally do NOT read ScanSettings.defaultTarget here (it caused your build error).
  // If ScanService uses SettingsService internally (recommended), it will pull the target itself.
  static const String _fallbackTargetLabel = 'your default target from Settings';

  Future<void> _startQuickSmartScan() async {
    if (_isQuickScanning) return;

    setState(() => _isQuickScanning = true);

    // Progress modal (non-dismissible)
    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _QuickScanDialog(),
      );
    }

    try {
      // IMPORTANT:
      // - Do NOT enforce a short timeout here. Nmap on /24 can exceed 3 minutes depending on flags/network.
      // - Your ScanService should be the single source of truth for scan execution.
      //
      // This call assumes ScanService exposes a "quick smart scan" entry point.
      // If your ScanService method name differs, adjust ONLY the line below to match your API.
      await ScanService().runQuickSmartScanFromDefaults();

      if (!mounted) return;

      // Close the dialog
      Navigator.of(context, rootNavigator: true).pop();

      // Feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick Smart Scan started. Check the Scan/Devices tabs for results.'),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Close the dialog (if still open)
      Navigator.of(context, rootNavigator: true).maybePop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quick Smart Scan failed: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isQuickScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Light dashboard background
    final bg = cs.brightness == Brightness.dark ? Colors.white : const Color(0xFFF6F7F8);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 980;

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCAN-X Dashboard',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _CardShell(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, size: 28, color: Color(0xFF1B5E20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Network health',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'No data',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No scans yet. Run a Quick Smart Scan to get your first health score.',
                                style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54),
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(999),
                                child: LinearProgressIndicator(
                                  value: 0.0,
                                  minHeight: 10,
                                  backgroundColor: Colors.black12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  _CardShell(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick actions',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: _isQuickScanning ? null : _startQuickSmartScan,
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              backgroundColor: const Color(0xFF1B5E20),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                            ),
                            icon: _isQuickScanning
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Icon(Icons.flash_on),
                            label: Text(
                              _isQuickScanning ? 'Scanning…' : 'Quick Smart Scan',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Uses $_fallbackTargetLabel. You can inspect details in the Scan and Devices tabs.',
                          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _lastScanSummaryCard(theme)),
                        const SizedBox(width: 16),
                        Expanded(child: _releaseStatusCard(theme)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _lastScanSummaryCard(theme),
                        const SizedBox(height: 16),
                        _releaseStatusCard(theme),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _lastScanSummaryCard(ThemeData theme) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last scan summary',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No scans yet. Use Quick Smart Scan or go to the Scan tab to start.',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _releaseStatusCard(ThemeData theme) {
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Release status',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Integration tests: run\n'
                'Windows release build: run\n'
                'Next: theme toggle + settings wiring + error paths',
            style: theme.textTheme.bodyLarge?.copyWith(color: Colors.black54, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x08000000),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickScanDialog extends StatelessWidget {
  const _QuickScanDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scanning…'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Quick Smart Scan running using your default Settings target.'),
          SizedBox(height: 14),
          LinearProgressIndicator(minHeight: 10),
          SizedBox(height: 10),
          Text('This can take a few minutes depending on your network size.'),
        ],
      ),
    );
  }
}
