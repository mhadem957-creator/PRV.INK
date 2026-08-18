import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Wraps WebView data-clearing calls (cookies, cache, local/web storage)
/// behind one convenience method for the Settings screen.
class StorageService {
  static Future<void> clearAllBrowsingData() async {
    await CookieManager.instance().deleteAllCookies();
    await InAppWebViewController.clearAllCache();
    try {
      await WebStorageManager.instance().deleteAllData();
    } catch (_) {
      // Not available on every platform/WebView version — safe to ignore.
    }
  }
}
