import 'dart:io';

class WindowsStartupService {
  static const String appName = 'SCAN-X';

  static bool get isWindows => Platform.isWindows;

  static Future<void> setEnabled(bool enabled) async {
    if (!isWindows) return;

    final exePath = Platform.resolvedExecutable;
    const key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';

    try {
      if (enabled) {
        await Process.run(
          'reg',
          ['add', key, '/v', appName, '/t', 'REG_SZ', '/d', '"$exePath"', '/f'],
          runInShell: true,
        );
      } else {
        await Process.run(
          'reg',
          ['delete', key, '/v', appName, '/f'],
          runInShell: true,
        );
      }
    } catch (_) {
      // Never crash release build because of startup registration failure.
    }
  }
}
