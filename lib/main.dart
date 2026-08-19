import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:provider/provider.dart';

import 'models/browser_settings.dart';
import 'screens/browser_screen.dart';
import 'services/download_service.dart';
import 'theme/manga_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FlutterDownloader.initialize(
      debug: kDebugMode,
      ignoreSsl: true,
    );
  } catch (e) {
    debugPrint('FlutterDownloader optional init: $e');
  }
  await DownloadService.instance.initialize();

  runApp(const InkApp());
}

class InkApp extends StatefulWidget {
  const InkApp({super.key});

  @override
  State<InkApp> createState() => _InkAppState();
}

class _InkAppState extends State<InkApp> with WidgetsBindingObserver {
  final BrowserSettings _settings = BrowserSettings();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _settings.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      DownloadService.instance.rebind();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: MangaTheme.light,
        darkTheme: MangaTheme.dark,
        themeMode: ThemeMode.system,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: MangaTheme.crimson),
          ),
        ),
      );
    }

    return ChangeNotifierProvider<BrowserSettings>.value(
      value: _settings,
      child: Consumer<BrowserSettings>(
        builder: (context, settings, _) {
          ThemeMode mode;
          switch (settings.themeModeIndex) {
            case 1:
              mode = ThemeMode.light;
              break;
            case 2:
              mode = ThemeMode.dark;
              break;
            default:
              mode = ThemeMode.system;
          }
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: MangaTheme.light,
            darkTheme: MangaTheme.dark,
            themeMode: mode,
            home: const BrowserScreen(),
          );
        },
      ),
    );
  }
}
