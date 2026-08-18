import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:provider/provider.dart';

import 'models/browser_settings.dart';
import 'screens/browser_screen.dart';
import 'theme/manga_theme.dart';
import 'utils/constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must init before runApp so background isolates can attach.
  try {
    await FlutterDownloader.initialize(
      debug: kDebugMode,
      ignoreSsl: true,
    );
  } catch (e) {
    debugPrint('FlutterDownloader.initialize failed: $e');
  }

  runApp(const InkApp());
}

class InkApp extends StatefulWidget {
  const InkApp({super.key});

  @override
  State<InkApp> createState() => _InkAppState();
}

class _InkAppState extends State<InkApp> {
  final BrowserSettings _settings = BrowserSettings();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _settings.load().then((_) {
      if (mounted) setState(() => _ready = true);
    });
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
