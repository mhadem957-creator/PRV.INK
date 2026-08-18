import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Builds WebView [ContentBlocker] rules from the bundled domain lists in
/// `assets/adblock/`. Uses flutter_inappwebview's cross-platform content
/// blocker API (WKContentRuleList on iOS, an equivalent request-filtering
/// implementation on Android) so no native code is required.
class AdBlockService {
  AdBlockService._();
  static final AdBlockService instance = AdBlockService._();

  List<String>? _adDomains;
  List<String>? _trackerDomains;

  Future<void> _ensureLoaded() async {
    _adDomains ??= await _loadList('assets/adblock/ad_domains.txt');
    _trackerDomains ??= await _loadList('assets/adblock/tracker_domains.txt');
  }

  Future<List<String>> _loadList(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    return raw
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();
  }

  /// Returns the reload-ready content blocker list for the current toggles.
  /// Call this again (and re-apply via `controller.setSettings`) whenever
  /// the ad-block / tracker-block toggles change.
  Future<List<ContentBlocker>> buildContentBlockers({
    required bool blockAds,
    required bool blockTrackers,
  }) async {
    await _ensureLoaded();

    final domains = <String>{
      if (blockAds) ..._adDomains!,
      if (blockTrackers) ..._trackerDomains!,
    };

    return domains
        .map(
          (domain) => ContentBlocker(
            trigger: ContentBlockerTrigger(
              urlFilter: '.*${RegExp.escape(domain)}.*',
            ),
            action: ContentBlockerAction(
              type: ContentBlockerActionType.BLOCK,
            ),
          ),
        )
        .toList();
  }
}
