import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/history_entry.dart';

/// Persists browsing history (URL, title, time).
/// Skips about:/ink home and empty URLs. Dedupes consecutive same URL.
class HistoryService extends ChangeNotifier {
  HistoryService._();
  static final HistoryService instance = HistoryService._();

  static const _prefsKey = 'pref_browse_history_v1';
  static const _maxEntries = 300;

  final List<HistoryEntry> _entries = [];
  bool _loaded = false;

  List<HistoryEntry> get entries => List.unmodifiable(_entries);

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _entries
          ..clear()
          ..addAll(
            list
                .whereType<Map>()
                .map((e) => HistoryEntry.fromJson(Map<String, dynamic>.from(e))),
          );
      } catch (e) {
        debugPrint('History load error: $e');
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _entries.map((e) => e.toJson()).toList();
    await prefs.setString(_prefsKey, jsonEncode(data));
  }

  bool _shouldSkip(String url) {
    final u = url.trim().toLowerCase();
    if (u.isEmpty) return true;
    if (u.startsWith('about:')) return true;
    if (u.startsWith('https://ink.local')) return true;
    if (u == 'about:blank') return true;
    return false;
  }

  /// Record a visit. [incognito] skips saving entirely.
  Future<void> add({
    required String url,
    required String title,
    bool incognito = false,
  }) async {
    if (incognito || _shouldSkip(url)) return;
    await load();

    // Skip if same as most recent URL (refresh / progress updates)
    if (_entries.isNotEmpty && _entries.first.url == url) {
      // Update title if we got a better one
      if (title.isNotEmpty && title != _entries.first.title) {
        _entries[0] = HistoryEntry(
          url: url,
          title: title,
          visitedAt: DateTime.now(),
        );
        await _save();
        notifyListeners();
      }
      return;
    }

    _entries.insert(
      0,
      HistoryEntry(
        url: url,
        title: title.isEmpty ? url : title,
        visitedAt: DateTime.now(),
      ),
    );

    if (_entries.length > _maxEntries) {
      _entries.removeRange(_maxEntries, _entries.length);
    }
    await _save();
    notifyListeners();
  }

  Future<void> removeAt(int index) async {
    if (index < 0 || index >= _entries.length) return;
    _entries.removeAt(index);
    await _save();
    notifyListeners();
  }

  Future<void> removeUrl(String url) async {
    _entries.removeWhere((e) => e.url == url);
    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _entries.clear();
    await _save();
    notifyListeners();
  }

  List<HistoryEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return entries;
    return _entries
        .where(
          (e) =>
              e.title.toLowerCase().contains(q) ||
              e.url.toLowerCase().contains(q),
        )
        .toList();
  }
}
