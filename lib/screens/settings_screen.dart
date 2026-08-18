import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/browser_settings.dart';
import '../services/history_service.dart';
import '../services/storage_service.dart';
import '../services/system_settings_service.dart';
import '../theme/manga_theme.dart';
import '../utils/constants.dart';
import '../widgets/manga_container.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _searxController;
  late final TextEditingController _homeController;
  late final BrowserSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = context.read<BrowserSettings>();
    _searxController = TextEditingController(text: _settings.searxngUrl);
    _homeController = TextEditingController(text: _settings.homePage);
  }

  @override
  void dispose() {
    final searx = _searxController.text.trim();
    final home = _homeController.text.trim();
    if (searx.isNotEmpty && searx != _settings.searxngUrl) {
      _settings.updateSearxngUrl(searx);
    }
    if (home.isNotEmpty && home != _settings.homePage) {
      _settings.updateHomePage(home);
    }
    _searxController.dispose();
    _homeController.dispose();
    super.dispose();
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  Future<void> _saveToggle(
    Future<void> Function(bool) fn,
    bool value,
    String label,
  ) async {
    await fn(value);
    _snack('Saved · $label');
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<BrowserSettings>();
    final ink = MangaTheme.inkOf(context);
    final paper = MangaTheme.paperOf(context);
    final muted = MangaTheme.paperMutedOf(context);
    final dim = MangaTheme.inkDimOf(context);

    return Scaffold(
      backgroundColor: paper,
      appBar: AppBar(
        title: const Text(
          'SETTINGS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 48),
        children: [
          // ── Privacy score ──────────────────────────────────────────
          MangaContainer(
            padding: const EdgeInsets.all(16),
            color: muted,
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: MangaTheme.crimson,
                    border: Border.all(color: ink, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: ink,
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: Text(
                    _privacyScore(s).toString(),
                    style: TextStyle(
                      color: paper,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PRIVACY SCORE',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 13,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _privacyLabel(s),
                        style: TextStyle(
                          color: dim,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Appearance ─────────────────────────────────────────────
          const _SectionHeader('APPEARANCE'),
          MangaContainer(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'THEME',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    fontSize: 12,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ThemeModeButton(
                        label: 'SYSTEM',
                        icon: Icons.brightness_auto,
                        selected: s.themeModeIndex == 0,
                        onTap: () async {
                          await s.setThemeModeIndex(0);
                          _snack('Theme · System');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeModeButton(
                        label: 'LIGHT',
                        icon: Icons.light_mode_outlined,
                        selected: s.themeModeIndex == 1,
                        onTap: () async {
                          await s.setThemeModeIndex(1);
                          _snack('Theme · Light');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeModeButton(
                        label: 'DARK',
                        icon: Icons.dark_mode_outlined,
                        selected: s.themeModeIndex == 2,
                        onTap: () async {
                          await s.setThemeModeIndex(2);
                          _snack('Theme · Dark');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Bars auto-hide while you scroll down and return when you scroll up.',
                  style: TextStyle(fontSize: 12, color: dim, height: 1.35),
                ),
                const Divider(height: 20),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Force dark on websites'),
                  subtitle: Text(
                    'Inject dark CSS into pages (separate from app theme)',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.forceDarkPages,
                  onChanged: (v) =>
                      _saveToggle(s.toggleForceDarkPages, v, 'Force dark pages'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Search & Home ──────────────────────────────────────────
          const _SectionHeader('SEARCH & HOME'),
          MangaContainer(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _FieldLabel('Search engine'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _presetValue(s.searxngUrl),
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    for (final p in AppConstants.searchPresets)
                      if (p['url']!.isNotEmpty)
                        DropdownMenuItem(
                          value: p['url'],
                          child: Text(p['name']!),
                        ),
                    const DropdownMenuItem(
                      value: '__custom__',
                      child: Text('Custom URL…'),
                    ),
                  ],
                  onChanged: (v) async {
                    if (v == null || v == '__custom__') return;
                    _searxController.text = v;
                    await s.updateSearxngUrl(v);
                    _snack('Search engine updated');
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searxController,
                  decoration: const InputDecoration(
                    labelText: 'Search endpoint',
                    helperText: 'Must end with q=  e.g. …/search?q=',
                  ),
                  onSubmitted: (v) async {
                    await s.updateSearxngUrl(v);
                    _snack('Saved · Search URL');
                  },
                  onEditingComplete: () async {
                    await s.updateSearxngUrl(_searxController.text);
                    _snack('Saved · Search URL');
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _homeController,
                  decoration: const InputDecoration(
                    labelText: 'Home page',
                    helperText: 'about:ink = built-in manga start page',
                  ),
                  onSubmitted: (v) async {
                    await s.updateHomePage(v);
                    _snack('Saved · Home page');
                  },
                  onEditingComplete: () async {
                    await s.updateHomePage(_homeController.text);
                    _snack('Saved · Home page');
                  },
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _miniChip('INK HOME', () {
                      _homeController.text = 'about:ink';
                      s.updateHomePage('about:ink');
                      _snack('Home · Ink page');
                    }),
                    _miniChip('SEARX', () {
                      final u = s.searxngUrl.contains('?')
                          ? s.searxngUrl.split('?').first
                          : s.searxngUrl;
                      _homeController.text = u;
                      s.updateHomePage(u);
                      _snack('Home · Search');
                    }),
                  ],
                ),
                const SizedBox(height: 14),
                const _FieldLabel('SafeSearch'),
                const SizedBox(height: 6),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('OFF')),
                    ButtonSegment(value: 1, label: Text('MOD')),
                    ButtonSegment(value: 2, label: Text('STRICT')),
                  ],
                  selected: {s.safeSearch},
                  onSelectionChanged: (set) async {
                    await s.updateSafeSearch(set.first);
                    _snack('Saved · SafeSearch');
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hide search branding'),
                  subtitle: Text(
                    'Restyle SearXNG results as Ink',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.cloakSearchBranding,
                  onChanged: (v) =>
                      _saveToggle(s.toggleCloakSearch, v, 'Cloak search'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Privacy ────────────────────────────────────────────────
          const _SectionHeader('PRIVACY'),
          MangaContainer(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Block ads'),
                  subtitle: Text(
                    'Local domain list',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.adBlockEnabled,
                  onChanged: (v) =>
                      _saveToggle(s.toggleAdBlock, v, 'Ad block'),
                ),
                SwitchListTile(
                  title: const Text('Block trackers'),
                  subtitle: Text(
                    'Local tracker list',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.trackerBlockEnabled,
                  onChanged: (v) =>
                      _saveToggle(s.toggleTrackerBlock, v, 'Tracker block'),
                ),
                SwitchListTile(
                  title: const Text('Force HTTPS'),
                  subtitle: Text(
                    'Upgrade http:// links when possible',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.forceHttps,
                  onChanged: (v) =>
                      _saveToggle(s.toggleForceHttps, v, 'Force HTTPS'),
                ),
                SwitchListTile(
                  title: const Text('Incognito mode'),
                  subtitle: Text(
                    'Skip history for this session',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.incognitoMode,
                  onChanged: (v) =>
                      _saveToggle(s.toggleIncognito, v, 'Incognito'),
                ),
                SwitchListTile(
                  title: const Text('Save history'),
                  value: s.saveHistory,
                  onChanged: (v) =>
                      _saveToggle(s.toggleSaveHistory, v, 'Save history'),
                ),
                SwitchListTile(
                  title: const Text('Clear data on exit'),
                  subtitle: Text(
                    'Cookies & cache when the app closes',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.clearDataOnExit,
                  onChanged: (v) =>
                      _saveToggle(s.toggleClearOnExit, v, 'Clear on exit'),
                ),
                SwitchListTile(
                  title: const Text('Biometric lock'),
                  subtitle: Text(
                    'Require unlock when opening the app',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.biometricLock,
                  onChanged: (v) =>
                      _saveToggle(s.toggleBiometricLock, v, 'Biometric'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Secure DNS ─────────────────────────────────────────────
          const _SectionHeader('SECURE DNS'),
          MangaContainer(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('DNS-over-HTTPS lookups'),
                  subtitle: Text(
                    'For address-bar host checks',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.dohEnabled,
                  onChanged: (v) => _saveToggle(s.toggleDoh, v, 'DoH'),
                ),
                DropdownButtonFormField<String>(
                  value: AppConstants.dohProviders.any((p) => p['url'] == s.dohProviderUrl)
                      ? s.dohProviderUrl
                      : AppConstants.dohProviders.first['url'],
                  decoration: const InputDecoration(labelText: 'DoH provider'),
                  items: AppConstants.dohProviders
                      .map(
                        (p) => DropdownMenuItem(
                          value: p['url'],
                          child: Text(p['name']!),
                        ),
                      )
                      .toList(),
                  onChanged: (v) async {
                    if (v != null) {
                      await s.updateDohProvider(v);
                      _snack('Saved · DNS provider');
                    }
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.dns_outlined),
                    label: const Text('Open system Private DNS'),
                    onPressed: SystemSettingsService.openPrivateDnsSettings,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'WebView uses the system network stack. Enable Android '
                  'Private DNS for full-device protection.',
                  style: TextStyle(fontSize: 12, color: dim, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Site controls ──────────────────────────────────────────
          const _SectionHeader('BROWSING'),
          MangaContainer(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('JavaScript'),
                  subtitle: Text(
                    'Off = maximum lockdown',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.javascriptEnabled,
                  onChanged: (v) =>
                      _saveToggle(s.toggleJavascript, v, 'JavaScript'),
                ),
                SwitchListTile(
                  title: const Text('Desktop site'),
                  subtitle: Text(
                    'Request desktop user-agent',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.desktopMode,
                  onChanged: (v) =>
                      _saveToggle(s.toggleDesktopMode, v, 'Desktop site'),
                ),
                SwitchListTile(
                  title: const Text('Block pop-ups'),
                  value: s.blockPopups,
                  onChanged: (v) =>
                      _saveToggle(s.toggleBlockPopups, v, 'Block pop-ups'),
                ),
                SwitchListTile(
                  title: const Text('Tap to play media'),
                  value: s.mediaRequiresGesture,
                  onChanged: (v) =>
                      _saveToggle(s.toggleMediaGesture, v, 'Media gesture'),
                ),
                SwitchListTile(
                  title: const Text('Load images'),
                  subtitle: Text(
                    'Off saves data',
                    style: TextStyle(fontSize: 12, color: dim),
                  ),
                  value: s.loadImages,
                  onChanged: (v) =>
                      _saveToggle(s.toggleLoadImages, v, 'Load images'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Data ───────────────────────────────────────────────────
          const _SectionHeader('DATA'),
          MangaContainer(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.cookie_outlined),
                  label: const Text('Clear cookies, cache & site data'),
                  onPressed: () async {
                    await StorageService.clearAllBrowsingData();
                    _snack('Browsing data cleared');
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.history),
                  label: const Text('Clear browsing history'),
                  onPressed: () async {
                    await HistoryService.instance.clear();
                    _snack('History cleared');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── About ──────────────────────────────────────────────────
          const _SectionHeader('ABOUT'),
          MangaContainer(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'INK BROWSER',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 16,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Privacy-first mobile browser with manga UI.\n'
                  '• SearXNG search · local ad/tracker lists\n'
                  '• Downloads · multi-tabs · auto-hiding chrome\n'
                  '• Light / Dark / System themes · DoH helpers',
                  style: TextStyle(color: dim, height: 1.45, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  'v2.0 · Built for people, not advertisers.',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _presetValue(String url) {
    for (final p in AppConstants.searchPresets) {
      if (p['url'] == url) return url;
    }
    return '__custom__';
  }

  int _privacyScore(BrowserSettings s) {
    var score = 40;
    if (s.adBlockEnabled) score += 12;
    if (s.trackerBlockEnabled) score += 12;
    if (s.forceHttps) score += 8;
    if (s.incognitoMode) score += 6;
    if (!s.saveHistory || s.incognitoMode) score += 4;
    if (s.blockPopups) score += 4;
    if (s.dohEnabled) score += 4;
    if (!s.javascriptEnabled) score += 6;
    if (s.clearDataOnExit) score += 4;
    return score.clamp(0, 100);
  }

  String _privacyLabel(BrowserSettings s) {
    final n = _privacyScore(s);
    if (n >= 90) return 'Maximum shield — excellent';
    if (n >= 75) return 'Strong — better than mainstream';
    if (n >= 60) return 'Good — tighten a few toggles';
    return 'Basic — enable ad & tracker block';
  }

  Widget _miniChip(String label, VoidCallback onTap) {
    final ink = MangaTheme.inkOf(context);
    final paper = MangaTheme.paperOf(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: ink, width: 2),
          boxShadow: [
            BoxShadow(color: ink, offset: const Offset(2, 2), blurRadius: 0),
          ],
          color: paper,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 11,
            color: ink,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 1.6,
          color: MangaTheme.crimson,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 13,
        color: MangaTheme.inkOf(context),
      ),
    );
  }
}

class _ThemeModeButton extends StatelessWidget {
  const _ThemeModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = MangaTheme.inkOf(context);
    final paper = MangaTheme.paperOf(context);
    return Material(
      color: selected ? MangaTheme.crimson : paper,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: ink, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: ink,
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, size: 22, color: selected ? paper : ink),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: selected ? paper : ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
