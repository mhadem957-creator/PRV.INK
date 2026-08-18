import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Performs DNS-over-HTTPS (DoH) lookups.
///
/// ## Important limitation
/// Android's WebView (and therefore `flutter_inappwebview`) resolves
/// hostnames using the *operating system's* network stack, not this app's
/// Dart HTTP client. There is no public WebView API that lets an app
/// override DNS resolution for pages rendered inside it. This service is
/// still genuinely useful for:
///   - pre-resolving/validating a typed domain before navigation,
///   - showing the user which IP(s) a host resolves to,
///   - diagnosing DNS-level blocking or captive portals.
///
/// To make secure DNS apply to *every* request the WebView makes, the
/// reliable mechanism is Android's built-in "Private DNS" feature
/// (Settings > Network & Internet > Private DNS), available since
/// Android 9. See [SystemSettingsService.openPrivateDnsSettings].
class DnsService {
  DnsService({this.providerUrl = 'https://cloudflare-dns.com/dns-query'});

  final String providerUrl;

  Future<List<String>> resolve(String host, {String type = 'A'}) async {
    final uri = Uri.parse(providerUrl).replace(queryParameters: {
      'name': host,
      'type': type,
    });

    try {
      final response = await http
          .get(uri, headers: {'accept': 'application/dns-json'})
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final answers = data['Answer'] as List<dynamic>?;
      if (answers == null) return [];

      return answers
          .where((a) => a['type'] == 1 || a['type'] == 28) // A / AAAA
          .map<String>((a) => a['data'] as String)
          .toList();
    } catch (e) {
      debugPrint('DoH resolution failed for $host: $e');
      return [];
    }
  }

  Future<bool> isReachableViaDoh(String host) async {
    final ips = await resolve(host);
    return ips.isNotEmpty;
  }
}
