/// App-wide constants and defaults for INK.
class AppConstants {
  AppConstants._();

  static const String appName = 'INK';
  static const String appTagline = 'Private. Fast. Yours.';

  static const String defaultSearxngUrl = 'https://searx.be/search?q=';
  static const String defaultHomePage = 'about:ink';

  /// Curated public SearXNG-style endpoints (must end with q=).
  static const List<Map<String, String>> searchPresets = [
    {'name': 'SearX.be', 'url': 'https://searx.be/search?q='},
    {'name': 'Tiekoetter', 'url': 'https://searx.tiekoetter.com/search?q='},
    {'name': 'SearchPL', 'url': 'https://search.pl/search?q='},
    {'name': 'Custom…', 'url': ''},
  ];

  static const List<Map<String, String>> dohProviders = [
    {'name': 'Cloudflare (1.1.1.1)', 'url': 'https://cloudflare-dns.com/dns-query'},
    {'name': 'Quad9 (Security)', 'url': 'https://dns.quad9.net:5053/dns-query'},
    {'name': 'AdGuard DNS', 'url': 'https://dns.adguard-dns.com/dns-query'},
    {'name': 'Mullvad', 'url': 'https://doh.mullvad.net/dns-query'},
    {'name': 'NextDNS', 'url': 'https://dns.nextdns.io/dns-query'},
    {'name': 'Google (fallback)', 'url': 'https://dns.google/resolve'},
  ];

  // Preference keys
  static const String prefsSearxngUrl = 'pref_searxng_url';
  static const String prefsHomePage = 'pref_home_page';
  static const String prefsDohProvider = 'pref_doh_provider';
  static const String prefsDohEnabled = 'pref_doh_enabled';
  static const String prefsAdBlockEnabled = 'pref_adblock_enabled';
  static const String prefsTrackerBlockEnabled = 'pref_trackerblock_enabled';
  static const String prefsJsEnabled = 'pref_js_enabled';
  static const String prefsDesktopMode = 'pref_desktop_mode';
  static const String prefsIncognito = 'pref_incognito';
  static const String prefsBiometric = 'pref_biometric';
  static const String prefsForceHttps = 'pref_force_https';
  static const String prefsForceDark = 'pref_force_dark';
  static const String prefsBlockPopups = 'pref_block_popups';
  static const String prefsMediaGesture = 'pref_media_gesture';
  static const String prefsLoadImages = 'pref_load_images';
  static const String prefsCloakSearch = 'pref_cloak_search';
  static const String prefsSaveHistory = 'pref_save_history';
  static const String prefsClearOnExit = 'pref_clear_on_exit';
  static const String prefsSafeSearch = 'pref_safe_search';
  /// 0 = system, 1 = light, 2 = dark
  static const String prefsThemeMode = 'pref_theme_mode';
}
