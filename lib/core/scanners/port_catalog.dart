class PortCatalog {
  // Smart scan: keep it short and meaningful for novices.
  static const List<int> smartPorts = [
    21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445, 3389,
    5900, 8080, 8443, 1900, 5353,
  ];

  // Full scan for MVP: still curated; expand later.
  static const List<int> fullPorts = [
    // Common TCP ports (subset). Expand as needed.
    20,21,22,23,25,53,67,68,69,80,81,88,110,111,123,135,137,138,139,143,161,389,443,445,
    465,587,631,993,995,1433,1521,2049,3306,3389,5432,5900,5985,5986,8000,8080,8443,9000,
  ];

  static const Map<int, String> serviceNames = {
    21: 'FTP',
    22: 'SSH',
    23: 'Telnet',
    25: 'SMTP',
    53: 'DNS',
    80: 'HTTP',
    110: 'POP3',
    135: 'MS RPC',
    139: 'NetBIOS',
    143: 'IMAP',
    443: 'HTTPS',
    445: 'SMB',
    3389: 'RDP',
    5900: 'VNC',
    8080: 'HTTP-Alt',
    8443: 'HTTPS-Alt',
    1900: 'SSDP',
    5353: 'mDNS',
  };

  static String nameFor(int port) => serviceNames[port] ?? 'Unknown';
}