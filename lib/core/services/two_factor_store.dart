// lib/core/services/two_factor_store.dart

import 'package:shared_preferences/shared_preferences.dart';

class TwoFactorStore {
  static const _prefix = 'scanx.';
  static const _kEnabled = '${_prefix}twoFactorEnabled';
  static const _kSecret = '${_prefix}twoFactorSecret';
  static const _kVerifiedUntilMs = '${_prefix}twoFactorVerifiedUntilMs';

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<bool> isEnabled() async {
    final p = await _prefs();
    return p.getBool(_kEnabled) ?? false;
  }

  static Future<void> setEnabled(bool v) async {
    final p = await _prefs();
    await p.setBool(_kEnabled, v);
  }

  static Future<String> getSecret() async {
    final p = await _prefs();
    return p.getString(_kSecret) ?? '';
  }

  static Future<void> setSecret(String secret) async {
    final p = await _prefs();
    await p.setString(_kSecret, secret);
  }

  static Future<DateTime?> getVerifiedUntil() async {
    final p = await _prefs();
    final ms = p.getInt(_kVerifiedUntilMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> setVerifiedUntil(DateTime? v) async {
    final p = await _prefs();
    if (v == null) {
      await p.remove(_kVerifiedUntilMs);
      return;
    }
    await p.setInt(_kVerifiedUntilMs, v.millisecondsSinceEpoch);
  }
}
