// lib/core/services/two_factor_service.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:otp/otp.dart';
import 'package:scanx_app/core/services/two_factor_store.dart';

class TwoFactorService {
  /// Generates a Base32-like secret (A-Z2-7).
  static String generateBase32Secret({int length = 32}) {
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rnd = Random.secure();
    return List.generate(length, (_) => alphabet[rnd.nextInt(alphabet.length)]).join();
  }

  static Future<bool> verifyCode(String code) async {
    final secret = await TwoFactorStore.getSecret();
    if (secret.isEmpty) return false;

    final now = DateTime.now().millisecondsSinceEpoch;

    String totp(int offsetMs) {
      return OTP.generateTOTPCodeString(
        secret,
        now + offsetMs,
        interval: 30,
        length: 6,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    }

    final v = code.trim();
    return v == totp(0) || v == totp(-30 * 1000) || v == totp(30 * 1000);
  }

  static Future<bool> promptForCode(BuildContext context) async {
    final controller = TextEditingController();
    bool ok = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Two-factor authentication'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '6-digit code',
            hintText: '123456',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              ok = await verifyCode(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );

    return ok;
  }

  /// Ensures a secret exists and returns it (for display/setup).
  static Future<String> ensureSecretExists() async {
    final current = await TwoFactorStore.getSecret();
    if (current.isNotEmpty) return current;

    final secret = generateBase32Secret();
    await TwoFactorStore.setSecret(secret);
    return secret;
  }
}
