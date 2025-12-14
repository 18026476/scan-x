import 'dart:math';

class IpRange {
  static List<String> expand(String cidrOrHost) {
    final s = cidrOrHost.trim();
    if (!s.contains('/')) return [s];

    final parts = s.split('/');
    final base = parts[0];
    final prefix = int.parse(parts[1]);

    final baseParts = base.split('.').map(int.parse).toList();
    if (baseParts.length != 4) return [base];

    final ipInt = (baseParts[0] << 24) | (baseParts[1] << 16) | (baseParts[2] << 8) | baseParts[3];
    final mask = prefix == 0 ? 0 : 0xFFFFFFFF << (32 - prefix);
    final net = ipInt & mask;

    final hostBits = 32 - prefix;
    final count = pow(2, hostBits).toInt();

    final maxHosts = 4096;
    final actual = min(count, maxHosts);

    final out = <String>[];
    for (int i = 1; i < actual - 1; i++) {
      final v = net + i;
      out.add('${(v >> 24) & 255}.${(v >> 16) & 255}.${(v >> 8) & 255}.${v & 255}');
    }
    return out;
  }
}
