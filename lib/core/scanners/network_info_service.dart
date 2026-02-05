import 'dart:io';

class LocalNetworkInfo {
  final String ip;      // e.g., 192.168.1.10
  final String netmask; // e.g., 255.255.255.0
  final String cidr;    // e.g., 192.168.1.0/24

  const LocalNetworkInfo({required this.ip, required this.netmask, required this.cidr});
}

class NetworkInfoService {
  Future<LocalNetworkInfo?> getActiveIpv4Network() async {
    // Best-effort:
    // - Windows: parse ipconfig for IPv4 + Subnet Mask
    // - Fallback: assume /24 (255.255.255.0) if only IP is found
    if (!Platform.isWindows) {
      // You can extend later for macOS/Linux with ifconfig/ip route parsing.
      return await _fallbackFromInterfaces();
    }

    final res = await Process.run('ipconfig', [], runInShell: true);
    final out = (res.stdout ?? '').toString();

    // Heuristic parse: grab first IPv4 and subnet mask from a connected adapter section.
    final ipMatch = RegExp(r'IPv4 Address[. ]*: *([0-9]{1,3}(?:\.[0-9]{1,3}){3})').firstMatch(out);
    final maskMatch = RegExp(r'Subnet Mask[. ]*: *([0-9]{1,3}(?:\.[0-9]{1,3}){3})').firstMatch(out);

    if (ipMatch == null) return await _fallbackFromInterfaces();

    final ip = ipMatch.group(1)!;
    final mask = maskMatch?.group(1) ?? '255.255.255.0';

    final prefix = _netmaskToPrefix(mask);
    final network = _networkAddress(ip, mask);
    final cidr = '$network/$prefix';

    return LocalNetworkInfo(ip: ip, netmask: mask, cidr: cidr);
  }

  Future<LocalNetworkInfo?> _fallbackFromInterfaces() async {
    final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLinkLocal: false);
    for (final nic in ifaces) {
      for (final addr in nic.addresses) {
        final ip = addr.address;
        if (ip.startsWith('127.')) continue;
        // Fallback assumes /24
        const mask = '255.255.255.0';
        final network = _networkAddress(ip, mask);
        const prefix = 24;
        return LocalNetworkInfo(ip: ip, netmask: mask, cidr: '$network/$prefix');
      }
    }
    return null;
  }

  int _netmaskToPrefix(String mask) {
    final parts = mask.split('.').map(int.parse).toList();
    int bits = 0;
    for (final p in parts) {
      bits += _countOnes(p);
    }
    return bits;
  }

  int _countOnes(int b) {
    int x = b;
    int c = 0;
    while (x > 0) {
      c += (x & 1);
      x >>= 1;
    }
    return c;
  }

  String _networkAddress(String ip, String mask) {
    final ipParts = ip.split('.').map(int.parse).toList();
    final mParts = mask.split('.').map(int.parse).toList();
    final net = List<int>.generate(4, (i) => ipParts[i] & mParts[i]);
    return net.join('.');
  }
  String _prefixToNetmask(int prefix) {
    int p = prefix.clamp(0, 32);
    final bytes = <int>[];
    for (int i = 0; i < 4; i++) {
      final bits = (p >= 8) ? 8 : p;
      p -= bits;
      final val = bits == 0 ? 0 : (0xFF << (8 - bits)) & 0xFF;
      bytes.add(val);
    }
    return bytes.join('.');
  }

}



