// lib/core/ai/router_fix_guides.dart
//
// Purpose: Provide simple "plain-English" router fix instructions.
// This is deterministic and doesn't require ML.
// You can later enrich with router vendor detection.
//
// Output: RouterFixGuide objects shown in AI insights.

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
            'WPS makes Wi-Fi easier to join but is frequently insecure. Disabling it reduces brute-force risk.',
        steps: [
          'Open your router admin page (usually http://192.168.1.1).',
          'Log in with your admin credentials.',
          'Go to Wireless / Wi-Fi settings -> WPS.',
          'Turn WPS OFF.',
          'Save changes and reboot router if prompted.',
        ],
        note:
            'If you rely on WPS for pairing, switch to QR/WPA2/WPA3 pairing instead.',
      ));
    }

    if (upnp) {
      out.add(const RouterFixGuide(
        title: 'Disable UPnP',
        summary:
            'UPnP can automatically open ports for devices. Disabling it reduces accidental exposure.',
        steps: [
          'Open router admin page.',
          'Find Advanced / NAT / UPnP settings.',
          'Turn UPnP OFF.',
          'Save changes.',
          'If something breaks (e.g., a console), re-enable only temporarily or use manual port forwarding.',
        ],
      ));
    }

    if (dnsCheck) {
      out.add(const RouterFixGuide(
        title: 'Verify DNS Servers',
        summary:
            'DNS hijacking can redirect you to fake websites. Confirm DNS is set to a trusted provider.',
        steps: [
          'Open router admin page.',
          'Go to Internet / WAN / DHCP / DNS settings.',
          'Ensure DNS is set to your ISP or trusted public DNS (e.g., Cloudflare/Google).',
          'Save changes.',
          'Restart router if required.',
        ],
        note:
            'If you see unknown DNS servers, change them immediately and update your router admin password.',
      ));
    }

    if (adminHarden) {
      out.add(const RouterFixGuide(
        title: 'Harden Router Admin Access',
        summary:
            'Router admin panels should be LAN-only and HTTPS-only wherever possible.',
        steps: [
          'Open router admin page.',
          'Go to Administration / System / Management.',
          'Disable Remote Management (WAN admin).',
          'Enable HTTPS-only for the admin interface (if available).',
          'Set a strong admin password.',
          'Enable MFA (if the router supports it).',
        ],
      ));
    }

    return out;
  }
}