import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

/// App-wide persisted settings.
class BrowserSettings extends ChangeNotifier {
  String searxngUrl = AppConstants.defaultSearxngUrl;
  String homePage = AppConstants.defaultHomePage;
  String dohProviderUrl = AppConstants.dohProviders.first['url']!;
  bool dohEnabled = true;
  bool adBlockEnabled = true;
  bool trackerBlockEnabled = true;
  bool javascriptEnabled = true;
  bool desktopMode = false;
  bool incognitoMode = false;
  bool biometricLock = false;

  // Advanced
  bool forceHttps = true;
  bool forceDarkPages = false;
  bool blockPopups = true;
  bool mediaRequiresGesture = true;
  bool loadImages = true;
  bool cloakSearchBranding = true;
  bool saveHistory = true;
  bool clearDataOnExit = false;
  int safeSearch = 0; // 0 off, 1 moderate, 2 strict
  /// 0 = system, 1 = light, 2 = dark
  int themeModeIndex = 0;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    searxngUrl =
        prefs.getString(AppConstants.prefsSearxngUrl) ?? AppConstants.defaultSearxngUrl;
    homePage =
        prefs.getString(AppConstants.prefsHomePage) ?? AppConstants.defaultHomePage;
    dohProviderUrl = prefs.getString(AppConstants.prefsDohProvider) ??
        AppConstants.dohProviders.first['url']!;
    dohEnabled = prefs.getBool(AppConstants.prefsDohEnabled) ?? true;
    adBlockEnabled = prefs.getBool(AppConstants.prefsAdBlockEnabled) ?? true;
    trackerBlockEnabled =
        prefs.getBool(AppConstants.prefsTrackerBlockEnabled) ?? true;
    javascriptEnabled = prefs.getBool(AppConstants.prefsJsEnabled) ?? true;
    desktopMode = prefs.getBool(AppConstants.prefsDesktopMode) ?? false;
    incognitoMode = prefs.getBool(AppConstants.prefsIncognito) ?? false;
    biometricLock = prefs.getBool(AppConstants.prefsBiometric) ?? false;
    forceHttps = prefs.getBool(AppConstants.prefsForceHttps) ?? true;
    forceDarkPages = prefs.getBool(AppConstants.prefsForceDark) ?? false;
    blockPopups = prefs.getBool(AppConstants.prefsBlockPopups) ?? true;
    mediaRequiresGesture =
        prefs.getBool(AppConstants.prefsMediaGesture) ?? true;
    loadImages = prefs.getBool(AppConstants.prefsLoadImages) ?? true;
    cloakSearchBranding = prefs.getBool(AppConstants.prefsCloakSearch) ?? true;
    saveHistory = prefs.getBool(AppConstants.prefsSaveHistory) ?? true;
    clearDataOnExit = prefs.getBool(AppConstants.prefsClearOnExit) ?? false;
    safeSearch = prefs.getInt(AppConstants.prefsSafeSearch) ?? 0;
    themeModeIndex = prefs.getInt(AppConstants.prefsThemeMode) ?? 0;
    _loaded = true;
    notifyListeners();
  }

  Future<void> updateSearxngUrl(String value) async {
    if (value.trim().isEmpty) return;
    searxngUrl = value.trim();
    await _saveString(AppConstants.prefsSearxngUrl, searxngUrl);
  }

  Future<void> updateHomePage(String value) async {
    if (value.trim().isEmpty) return;
    homePage = value.trim();
    await _saveString(AppConstants.prefsHomePage, homePage);
  }

  Future<void> updateDohProvider(String value) async {
    dohProviderUrl = value;
    await _saveString(AppConstants.prefsDohProvider, value);
  }

  Future<void> updateSafeSearch(int value) async {
    safeSearch = value.clamp(0, 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefsSafeSearch, safeSearch);
    notifyListeners();
  }

  Future<void> toggleDoh(bool v) async {
    dohEnabled = v;
    await _saveBool(AppConstants.prefsDohEnabled, v);
  }

  Future<void> toggleAdBlock(bool v) async {
    adBlockEnabled = v;
    await _saveBool(AppConstants.prefsAdBlockEnabled, v);
  }

  Future<void> toggleTrackerBlock(bool v) async {
    trackerBlockEnabled = v;
    await _saveBool(AppConstants.prefsTrackerBlockEnabled, v);
  }

  Future<void> toggleJavascript(bool v) async {
    javascriptEnabled = v;
    await _saveBool(AppConstants.prefsJsEnabled, v);
  }

  Future<void> toggleDesktopMode(bool v) async {
    desktopMode = v;
    await _saveBool(AppConstants.prefsDesktopMode, v);
  }

  Future<void> toggleIncognito(bool v) async {
    incognitoMode = v;
    await _saveBool(AppConstants.prefsIncognito, v);
  }

  Future<void> toggleBiometricLock(bool v) async {
    biometricLock = v;
    await _saveBool(AppConstants.prefsBiometric, v);
  }

  Future<void> toggleForceHttps(bool v) async {
    forceHttps = v;
    await _saveBool(AppConstants.prefsForceHttps, v);
  }

  Future<void> toggleForceDarkPages(bool v) async {
    forceDarkPages = v;
    await _saveBool(AppConstants.prefsForceDark, v);
  }

  Future<void> toggleBlockPopups(bool v) async {
    blockPopups = v;
    await _saveBool(AppConstants.prefsBlockPopups, v);
  }

  Future<void> toggleMediaGesture(bool v) async {
    mediaRequiresGesture = v;
    await _saveBool(AppConstants.prefsMediaGesture, v);
  }

  Future<void> toggleLoadImages(bool v) async {
    loadImages = v;
    await _saveBool(AppConstants.prefsLoadImages, v);
  }

  Future<void> toggleCloakSearch(bool v) async {
    cloakSearchBranding = v;
    await _saveBool(AppConstants.prefsCloakSearch, v);
  }

  Future<void> toggleSaveHistory(bool v) async {
    saveHistory = v;
    await _saveBool(AppConstants.prefsSaveHistory, v);
  }

  Future<void> toggleClearOnExit(bool v) async {
    clearDataOnExit = v;
    await _saveBool(AppConstants.prefsClearOnExit, v);
  }

  /// 0 system · 1 light · 2 dark
  Future<void> setThemeModeIndex(int index) async {
    themeModeIndex = index.clamp(0, 2);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.prefsThemeMode, themeModeIndex);
    notifyListeners();
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    notifyListeners();
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
  }
}
