import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

import '../models/browser_settings.dart';
import '../models/browser_tab.dart';
import '../services/adblock_service.dart';
import '../services/download_service.dart';
import '../services/history_service.dart';
import '../services/search_service.dart';
import '../services/storage_service.dart';
import '../theme/manga_theme.dart';
import '../widgets/manga_bottom_bar.dart';
import '../widgets/ink_home_page.dart';
import '../widgets/manga_url_bar.dart';
import 'downloads_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'tabs_screen.dart';

const String _searxCloakJs = r"""
(function(){
  try {
    var h = location.hostname || '';
    if (h.indexOf('searx') === -1 && location.href.indexOf('/search') === -1) return;
    var css = 'body,html{background:#F6F5F0!important;color:#121212!important}'
      + '.title,.navbar-brand,#main-logo,.logo,footer,#footer,.footer,.powered-by,'
      + 'img[alt*="SearX"],img[src*="searx"],header .title,.instance-name'
      + '{display:none!important;height:0!important;overflow:hidden!important}'
      + 'nav.navbar,.searx-navbar,header{background:#F6F5F0!important;border-bottom:3px solid #121212!important;box-shadow:none!important}'
      + 'input[type=text],input[type=search],#q{border:3px solid #121212!important;border-radius:0!important;background:#fff!important;box-shadow:3px 3px 0 #121212!important}'
      + 'button,.btn,input[type=submit]{background:#E60012!important;color:#F6F5F0!important;border:3px solid #121212!important;border-radius:0!important;font-weight:800!important}'
      + '#urls article,.result{border:2px solid #121212!important;background:#fff!important;box-shadow:3px 3px 0 #121212!important;margin-bottom:10px!important;padding:10px!important}'
      + 'a{color:#E60012!important}h3,h4{color:#121212!important;font-weight:900!important}';
    var s=document.createElement('style'); s.textContent=css;
    (document.documentElement||document.head).appendChild(s);
  } catch(e) {}
})();
""";

const String _desktopUserAgent =
    'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

/// Main browser screen combining InAppWebView, AdBlock, DownloadService,
/// MangaUrlBar and MangaBottomBar.
class BrowserScreen extends StatefulWidget {
  const BrowserScreen({super.key});

  @override
  State<BrowserScreen> createState() => _BrowserScreenState();
}

class _BrowserScreenState extends State<BrowserScreen> {
  final List<BrowserTab> _tabs = [];
  int _currentIndex = 0;
  final TextEditingController _urlController = TextEditingController();
  final FocusNode _urlFocusNode = FocusNode();
  bool _isLoading = false;
  double _progress = 0;

  /// Address bar + progress chrome visibility (hide on scroll down).
  bool _chromeVisible = true;
  int _lastScrollY = 0;
  static const double _scrollHideThreshold = 10;

  BrowserTab get _currentTab => _tabs[_currentIndex];

  @override
  void initState() {
    super.initState();
    // Initialize download service early.
    DownloadService.instance.initialize();
    HistoryService.instance.load();
    _urlFocusNode.addListener(_onUrlFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = context.read<BrowserSettings>();
      final home = settings.homePage.trim().isEmpty
          ? 'about:ink'
          : settings.homePage;
      _openNewTab(url: home);
    });
  }

  void _onUrlFocusChange() {
    if (_urlFocusNode.hasFocus && !_chromeVisible) {
      setState(() => _chromeVisible = true);
    }
  }

  void _handleWebScroll(int index, int x, int y) {
    // Chrome stays fixed — hide-on-scroll caused jank with WebView.
    // Keep the hook so we can re-enable later with a smoother strategy.
    _lastScrollY = y;
  }

  @override
  void dispose() {
    // Clear on exit if enabled. Avoid context.read after unmount —
    // use a best-effort try and ignore if the element is already defunct.
    try {
      if (mounted) {
        final settings = context.read<BrowserSettings>();
        if (settings.clearDataOnExit) {
          StorageService.clearAllBrowsingData();
        }
      }
    } catch (_) {}
    _urlFocusNode.removeListener(_onUrlFocusChange);
    _urlController.dispose();
    _urlFocusNode.dispose();
    super.dispose();
  }

  void _openNewTab({String? url}) {
    final settings = context.read<BrowserSettings>();
    final tab = BrowserTab(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      url: url ?? settings.homePage,
    );
    setState(() {
      _tabs.add(tab);
      _currentIndex = _tabs.length - 1;
      _urlController.text = tab.url;
      _chromeVisible = true;
      _lastScrollY = 0;
    });
  }

  Future<void> _closeTab(int index) async {
    final settings = context.read<BrowserSettings>();
    if (_tabs.length == 1) {
      setState(() {
        _tabs[0] = BrowserTab(
          id: _tabs[0].id,
          url: 'about:ink',
          title: 'Ink',
        );
        _currentIndex = 0;
        _urlController.text = '';
        _chromeVisible = true;
      });
      return;
    }
    setState(() {
      _tabs.removeAt(index);
      if (_currentIndex >= _tabs.length) {
        _currentIndex = _tabs.length - 1;
      }
      _urlController.text = _currentTab.url;
    });
  }

  void _switchTab(int index) {
    setState(() {
      _currentIndex = index;
      _urlController.text = _tabs[index].url;
      _isLoading = false;
      _progress = 0;
      _chromeVisible = true;
      _lastScrollY = 0;
    });
  }

  bool _isHomeUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final s = url.trim().toLowerCase();
    return s == 'about:ink' ||
        s == 'about:home' ||
        s == 'ink://home' ||
        s.startsWith('https://ink.local') ||
        s.startsWith('http://ink.local');
  }

  Future<void> _handleSubmitted(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty ||
        trimmed == 'about:ink' ||
        trimmed == 'about:home' ||
        trimmed == 'ink://home') {
      setState(() {
        _currentTab.url = 'about:ink';
        _currentTab.title = 'Ink';
        _currentTab.controller = null; // drop WebView; native home is shown
        _urlController.text = '';
        _isLoading = false;
        _chromeVisible = true;
      });
      _urlFocusNode.unfocus();
      return;
    }

    final settings = context.read<BrowserSettings>();
    final searchService = SearchService(settings.searxngUrl, safeSearch: settings.safeSearch);
    var resolved = searchService.resolveInput(trimmed);
    if (resolved.isEmpty) return;
    if (settings.forceHttps && resolved.startsWith('http://')) {
      resolved = 'https://${resolved.substring(7)}';
    }

    _urlFocusNode.unfocus();
    final controller = _currentTab.controller;
    if (controller != null) {
      await controller.loadUrl(urlRequest: URLRequest(url: WebUri(resolved)));
    } else {
      setState(() => _currentTab.url = resolved);
    }
  }


  bool _isSearxUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final u = url.toLowerCase();
    return u.contains('searx') || (u.contains('/search?') && u.contains('q='));
  }

  /// Hide SearXNG branding and restyle results.
  Future<void> _cloakSearx(InAppWebViewController controller) async {
    const js = r"""
(function() {
  if (window.__inkCloak) return;
  window.__inkCloak = true;
  var css = `
    body, html { background: #F6F5F0 !important; color: #121212 !important; }
    .title, a.navbar-brand, .navbar-brand, #main-logo, .logo,
    footer, #footer, .footer, .powered-by,
    img[alt*="SearX"], img[src*="searx"],
    header .title, .instance-name {
      display: none !important;
      visibility: hidden !important;
      height: 0 !important;
      overflow: hidden !important;
    }
    nav.navbar, .searx-navbar, header {
      background: #F6F5F0 !important;
      border-bottom: 3px solid #121212 !important;
      box-shadow: none !important;
    }
    input[type="text"], input[type="search"], #q {
      border: 3px solid #121212 !important;
      border-radius: 0 !important;
      background: #fff !important;
      box-shadow: 3px 3px 0 #121212 !important;
      color: #121212 !important;
      font-weight: 600 !important;
    }
    button, .btn, input[type="submit"] {
      background: #E60012 !important;
      color: #F6F5F0 !important;
      border: 3px solid #121212 !important;
      border-radius: 0 !important;
      box-shadow: 3px 3px 0 #121212 !important;
      font-weight: 800 !important;
    }
    #urls article, .result, #urls .result {
      border: 2px solid #121212 !important;
      border-radius: 0 !important;
      background: #fff !important;
      box-shadow: 3px 3px 0 #121212 !important;
      margin-bottom: 12px !important;
      padding: 12px !important;
    }
    a { color: #E60012 !important; }
    h3, h4 { color: #121212 !important; font-weight: 900 !important; }
  `;
  var s = document.createElement('style');
  s.id = 'ink-cloak';
  s.textContent = css;
  (document.head || document.documentElement).appendChild(s);
  try {
    document.title = (document.title || '').replace(/SearXNG/gi, 'Ink').replace(/SearxNG/gi, 'Ink').replace(/Searx/gi, 'Ink');
  } catch (e) {}
})();
""";
    try {
      await controller.evaluateJavascript(source: js);
    } catch (_) {}
  }

  String _displayUrl(String url) {
    if (url == 'about:ink' ||
        url == 'about:home' ||
        url.startsWith('https://ink.local')) {
      return '';
    }
    if (_isSearxUrl(url)) {
      try {
        final q = Uri.parse(url).queryParameters['q'];
        if (q != null && q.isNotEmpty) return q;
      } catch (_) {}
      return 'Search';
    }
    return url;
  }


  Future<void> _injectForceDark(InAppWebViewController controller) async {
    const js = r"""
(function(){
  if (window.__inkDark) return; window.__inkDark = true;
  var s=document.createElement('style');
  s.textContent='html,body{background:#121212!important;color:#E8E6DF!important}a{color:#E60012!important}img,video{opacity:.92}';
  (document.head||document.documentElement).appendChild(s);
})();
""";
    try { await controller.evaluateJavascript(source: js); } catch (_) {}
  }

  Future<void> _applyContentBlockers(InAppWebViewController controller) async {
    final settings = context.read<BrowserSettings>();
    final blockers = await AdBlockService.instance.buildContentBlockers(
      blockAds: settings.adBlockEnabled,
      blockTrackers: settings.trackerBlockEnabled,
    );
    await controller.setSettings(
      settings: InAppWebViewSettings(contentBlockers: blockers),
    );
  }

  /// Intercept navigation / resource loads that look like direct file downloads.
  Future<NavigationActionPolicy?> _shouldOverrideUrlLoading(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final url = action.request.url?.toString() ?? '';
    if (url.isEmpty) return NavigationActionPolicy.ALLOW;

    final downloadService = DownloadService.instance;
    if (downloadService.isDownloadableUrl(url)) {
      // Ask user before starting the download.
      final confirmed = await _showDownloadConfirmDialog(url);
      if (confirmed == true) {
        final taskId = await downloadService.enqueue(url: url);
        if (mounted && taskId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download started: ${Uri.parse(url).pathSegments.last}'),
              action: SnackBarAction(
                label: 'VIEW',
                textColor: MangaTheme.crimson,
                onPressed: _showDownloadsScreen,
              ),
            ),
          );
        }
      }
      return NavigationActionPolicy.CANCEL;
    }
    return NavigationActionPolicy.ALLOW;
  }

  Future<bool?> _showDownloadConfirmDialog(String url) {
    final name = Uri.parse(url).pathSegments.isNotEmpty
        ? Uri.parse(url).pathSegments.last
        : url;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MangaTheme.paperOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: MangaTheme.inkOf(context), width: 4),
        ),
        title: const Text(
          'DOWNLOAD?',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        content: Text(
          name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('DOWNLOAD'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return Scaffold(
        backgroundColor: MangaTheme.paperOf(context),
        body: const Center(
          child: CircularProgressIndicator(color: MangaTheme.crimson),
        ),
      );
    }

    final bottomChromeH = _isLoading ? 7.0 : 3.0;
    // Toolbar (~56) + optional progress strip
    final appBarH = kToolbarHeight + bottomChromeH;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _onSystemBack();
      },
      child: Scaffold(
        backgroundColor: MangaTheme.paperOf(context),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(appBarH),
          child: AppBar(
            titleSpacing: 8,
            toolbarHeight: kToolbarHeight,
            centerTitle: false,
            title: MangaUrlBar(
              controller: _urlController,
              focusNode: _urlFocusNode,
              isSecure: _currentTab.url.startsWith('https://'),
              onSubmitted: _handleSubmitted,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                tooltip: 'New tab',
                onPressed: () => _openNewTab(),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: _showSettingsScreen,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(bottomChromeH),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    LinearProgressIndicator(
                      value: _progress <= 0 ? null : _progress,
                      minHeight: 4,
                      backgroundColor: MangaTheme.paperMutedOf(context),
                      color: MangaTheme.crimson,
                    ),
                  Container(
                    height: 3,
                    color: MangaTheme.inkOf(context),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: [
            for (int i = 0; i < _tabs.length; i++) _buildTab(i),
          ],
        ),
        // Collapses fully when hidden so the WebView can use the space.
        bottomNavigationBar: MangaBottomBar(
          onBack: _goBack,
          onForward: _goForward,
          onReload: _reloadOrStop,
          onHome: _goHome,
          isLoading: _isLoading,
          tabCount: _tabs.length,
          onTabsPressed: _showTabsScreen,
          onHistoryPressed: _showHistoryScreen,
          onDownloadsPressed: _showDownloadsScreen,
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    final tab = _tabs[index];
    if (_isHomeUrl(tab.url)) {
      return KeyedSubtree(
        key: ValueKey('home-${tab.id}'),
        child: InkHomePage(
          onSearch: (q) {
            if (index == _currentIndex) _handleSubmitted(q);
          },
          onOpenUrl: (url) {
            if (index == _currentIndex) _handleSubmitted(url);
          },
        ),
      );
    }
    return _buildWebViewForTab(index);
  }

  Widget _buildWebViewForTab(int index) {
    final tab = _tabs[index];
    final settings = context.read<BrowserSettings>();

    return KeyedSubtree(
      key: ValueKey(tab.id),
      child: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(
            tab.url.isEmpty || _isHomeUrl(tab.url)
                ? 'about:blank'
                : tab.url,
          ),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: settings.javascriptEnabled,
          cacheEnabled: true,
          supportZoom: true,
          transparentBackground: true,
          mediaPlaybackRequiresUserGesture: settings.mediaRequiresGesture,
          userAgent: settings.desktopMode ? _desktopUserAgent : null,
          useShouldOverrideUrlLoading: true,
          useOnDownloadStart: true,
          supportMultipleWindows: !settings.blockPopups,
          mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
          // Speed
          useOnLoadResource: false,
          verticalScrollBarEnabled: true,
          preferredContentMode: UserPreferredContentMode.MOBILE,
          allowsInlineMediaPlayback: true,
          allowsBackForwardNavigationGestures: true,
        ),
        onWebViewCreated: (controller) async {
          tab.controller = controller;
          try {
            await controller.addUserScript(
              userScript: UserScript(
                source: _searxCloakJs,
                injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
              ),
            );
          } catch (_) {}
          await _applyContentBlockers(controller);
        },
        shouldOverrideUrlLoading: _shouldOverrideUrlLoading,
        onLoadStart: (controller, url) {
          final u = url?.toString() ?? '';
          // Never replace the synthetic home URL with about:blank / data:
          if (u == 'about:blank' || u.startsWith('data:')) {
            if (index == _currentIndex) {
              setState(() => _isLoading = true);
            }
            return;
          }
          if (_isHomeUrl(u) ||
              tab.url == 'about:ink' ||
              tab.url == 'about:home') {
            if (_isHomeUrl(u) || u.startsWith('https://ink.local')) {
              tab.url = 'about:ink';
              tab.title = 'Ink';
            }
            if (index == _currentIndex) {
              setState(() {
                _isLoading = true;
                _urlController.text = '';
              });
            }
            return;
          }
          tab.url = u;
          if (index != _currentIndex) return;
          setState(() {
            _isLoading = true;
            _urlController.text = _displayUrl(tab.url);
          });
        },
        onLoadStop: (controller, url) async {
          final u = url?.toString() ?? '';
          if (u == 'about:blank' ||
              u.startsWith('data:') ||
              _isHomeUrl(u) ||
              tab.url == 'about:ink' ||
              tab.url == 'about:home') {
            if (_isHomeUrl(u) ||
                u.startsWith('https://ink.local') ||
                tab.url == 'about:ink' ||
                tab.url == 'about:home') {
              tab.url = 'about:ink';
              tab.title = 'Ink';
            }
            if (!mounted || index != _currentIndex) return;
            setState(() {
              _isLoading = false;
              _urlController.text = '';
            });
            return;
          }
          tab.url = u.isNotEmpty ? u : tab.url;
          tab.title = await controller.getTitle() ?? tab.url;
          final settings = context.read<BrowserSettings>();
          if (_isSearxUrl(tab.url) && settings.cloakSearchBranding) {
            await _cloakSearx(controller);
            tab.title = 'Ink Search';
          }
          if (settings.forceDarkPages) {
            await _injectForceDark(controller);
          }
          if (!settings.loadImages) {
            try {
              await controller.evaluateJavascript(source: r"""
                (function(){var s=document.createElement('style');s.textContent='img,picture,video{display:none!important}';(document.head||document.documentElement).appendChild(s);})();
              """);
            } catch (_) {}
          }
          // Record history (skipped when incognito / disabled)
          await HistoryService.instance.add(
            url: tab.url,
            title: tab.title,
            incognito: settings.incognitoMode || !settings.saveHistory,
          );
          if (!mounted || index != _currentIndex) return;
          setState(() {
            _isLoading = false;
            _urlController.text = _displayUrl(tab.url);
          });
        },
        onProgressChanged: (controller, progress) {
          if (index != _currentIndex) return;
          setState(() => _progress = progress / 100);
        },
        onScrollChanged: (controller, x, y) {
          _handleWebScroll(index, x, y);
        },
        onReceivedError: (controller, request, error) {
          if (index != _currentIndex) return;
          setState(() => _isLoading = false);
        },
        onTitleChanged: (controller, title) {
          if (title != null) tab.title = title;
        },
        // Capture any server-driven download (APK, PDF, zip, Content-Disposition, etc.).
        onDownloadStartRequest: (controller, request) async {
          final url = request.url.toString();
          final suggested = request.suggestedFilename;
          final displayName = (suggested != null && suggested.isNotEmpty)
              ? suggested
              : (Uri.tryParse(url)?.pathSegments.isNotEmpty == true
                  ? Uri.parse(url).pathSegments.last
                  : 'file');
          final confirmed = await _showDownloadConfirmDialog(displayName);
          if (confirmed == true) {
            final taskId = await DownloadService.instance.enqueue(
              url: url,
              fileName: suggested,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    taskId != null
                        ? 'Download started: $displayName'
                        : 'Download failed to start',
                  ),
                  action: SnackBarAction(
                    label: 'VIEW',
                    textColor: MangaTheme.crimson,
                    onPressed: _showDownloadsScreen,
                  ),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Future<void> _goBack() async {
    final controller = _currentTab.controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
    }
  }

  /// Phone system back button / gesture:
  /// 1) WebView history back if possible
  /// 2) Otherwise leave the app
  Future<void> _onSystemBack() async {
    final controller = _currentTab.controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return;
    }
    // No more pages in this tab → exit app
    SystemNavigator.pop();
  }

  Future<void> _goForward() async {
    final controller = _currentTab.controller;
    if (controller != null && await controller.canGoForward()) {
      await controller.goForward();
    }
  }

  Future<void> _reloadOrStop() async {
    final controller = _currentTab.controller;
    if (controller == null) return;
    if (_isLoading) {
      await controller.stopLoading();
    } else {
      await controller.reload();
    }
  }

  Future<void> _goHome() async {
    final settings = context.read<BrowserSettings>();
    await _handleSubmitted(settings.homePage);
  }

  void _showTabsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TabsScreen(
          tabs: _tabs,
          currentIndex: _currentIndex,
          onSelect: (i) {
            Navigator.pop(context);
            _switchTab(i);
          },
          onClose: _closeTab,
          onNewTab: () {
            Navigator.pop(context);
            _openNewTab();
          },
        ),
      ),
    );
  }

  void _showSettingsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _showHistoryScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          onOpenUrl: (url) {
            _handleSubmitted(url);
          },
        ),
      ),
    );
  }

  void _showDownloadsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DownloadsScreen()),
    );
  }
}
