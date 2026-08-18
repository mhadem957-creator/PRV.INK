import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// In-memory representation of a single browser tab. Each tab owns its own
/// live [InAppWebViewController], so switching tabs preserves scroll
/// position and back/forward history.
class BrowserTab {
  BrowserTab({
    required this.id,
    required this.url,
    this.title = 'New Tab',
  });

  final String id;
  String url;
  String title;
  InAppWebViewController? controller;
}
