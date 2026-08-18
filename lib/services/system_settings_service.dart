import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';

/// Deep-links into Android system settings screens. Used to send the user
/// straight to "Private DNS" so secure DNS applies device-wide (and
/// therefore to every page the WebView loads) — see the limitation
/// documented in [DnsService].
class SystemSettingsService {
  static Future<void> openPrivateDnsSettings() async {
    if (!Platform.isAndroid) return;
    try {
      const intent = AndroidIntent(
        action: 'android.settings.WIFI_PRIVATE_DNS_SETTINGS',
      );
      await intent.launch();
    } catch (e) {
      debugPrint('Could not open Private DNS settings, trying fallback: $e');
      try {
        const fallback = AndroidIntent(
          action: 'android.settings.NETWORK_OPERATOR_SETTINGS',
        );
        await fallback.launch();
      } catch (e2) {
        debugPrint('Could not open network settings either: $e2');
      }
    }
  }
}
