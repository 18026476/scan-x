// lib/core/services/windows_startup_service.dart

import 'dart:io';

class WindowsStartupService {
  static const _runKey = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';
  static const _valueName = 'SCANX';

  static Future<void> enable() async {
    if (!Platform.isWindows) return;

    // In debug this may point to dart.exe; in release it will be the app exe.
    final exe = Platform.resolvedExecutable;

    await Process.run(
      'reg',
      ['add', _runKey, '/v', _valueName, '/t', 'REG_SZ', '/d', exe, '/f'],
      runInShell: true,
    );
  }

  static Future<void> disable() async {
    if (!Platform.isWindows) return;

    await Process.run(
      'reg',
      ['delete', _runKey, '/v', _valueName, '/f'],
      runInShell: true,
    );
  }
}
