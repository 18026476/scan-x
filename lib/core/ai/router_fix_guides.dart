// lib/core/ai/router_fix_guides.dart
//
// Plain-English router fix instructions for home/SOHO users.

class RouterFixGuide {
  final String title;
  final String summary;
  final List<String> steps;
  final String? note;

  const RouterFixGuide({
    required this.title,
    required this.summary,
    required this.steps,
    this.note,
  });
}

class RouterFixGuides {
  static List<RouterFixGuide> forCommonHomeRisks({
    required bool wps,
    required bool upnp,
    required bool dnsCheck,
    required bool adminHarden,
  }) {
    final out = <RouterFixGuide>[];

    if (wps) {
      out.add(const RouterFixGuide(
        title: 'Disable WPS',
        summary:
            'WPS is convenient but often insecure. Disabling it reduces brute-force risk.',
        steps: [
          'Open router admin page (e.g., http://192.168.1.1).',
          'Log in as administrator.',
          'Go to Wi-Fi / Wireless settings.',
          'Turn WPS OFF.',
          'Save and reboot router.',
        ],
      ));
    }

    if (upnp) {
      out.add(const RouterFixGuide(
        title: 'Disable UPnP',
        summary:
            'UPnP may open ports automatically and expose devices.',
        steps: [
          'Open router admin page.',
          'Navigate to Advanced / NAT / UPnP.',
          'Turn UPnP OFF.',
          'Save settings.',
        ],
        note:
            'If a console breaks, use manual port forwarding instead.',
      ));
    }

    if (dnsCheck) {
      out.add(const RouterFixGuide(
        title: 'Verify DNS servers',
        summary:
            'Unknown DNS servers may indicate hijacking.',
        steps: [
          'Open router admin page.',
          'Go to Internet / WAN / DNS.',
          'Use ISP DNS or trusted DNS (Cloudflare / Google).',
          'Save and reboot router.',
        ],
      ));
    }

    if (adminHarden) {
      out.add(const RouterFixGuide(
        title: 'Harden router admin access',
        summary:
            'Admin panels should be LAN-only and protected.',
        steps: [
          'Disable remote (WAN) admin access.',
          'Enable HTTPS for admin page.',
          'Set a strong admin password.',
          'Enable MFA if supported.',
        ],
      ));
    }

    return out;
  }
}