import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Runs in a background isolate — must stay top-level so downloads
/// continue when the UI process is paused or closed.
@pragma('vm:entry-point')
void inkDownloaderCallback(String id, int status, int progress) {
  final SendPort? send =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

/// Background downloads via [flutter_downloader].
class DownloadService extends ChangeNotifier {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  final List<DownloadItem> _items = [];
  bool _initialized = false;
  final ReceivePort _port = ReceivePort();
  Timer? _pollTimer;

  List<DownloadItem> get items => List.unmodifiable(_items);
  List<DownloadItem> get active => _items
      .where((e) =>
          e.status == DownloadTaskStatus.running ||
          e.status == DownloadTaskStatus.enqueued ||
          e.status == DownloadTaskStatus.paused)
      .toList();
  List<DownloadItem> get completed =>
      _items.where((e) => e.status == DownloadTaskStatus.complete).toList();

  static const Set<String> downloadableExtensions = {
    'apk',
    'mp3',
    'mp4',
    'm4a',
    'ogg',
    'wav',
    'flac',
    'webm',
    'mkv',
    'avi',
    'zip',
    'rar',
    '7z',
    'tar',
    'gz',
    'pdf',
    'epub',
    'mobi',
    'doc',
    'docx',
    'xls',
    'xlsx',
    'ppt',
    'pptx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'svg',
    'txt',
    'csv',
    'json',
  };

  /// Call once after [FlutterDownloader.initialize] in main().
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      // Do NOT call FlutterDownloader.initialize here — it is done in main.dart.
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      final registered = IsolateNameServer.registerPortWithName(
        _port.sendPort,
        'downloader_send_port',
      );
      if (!registered) {
        debugPrint('DownloadService: failed to register isolate port');
      }

      _port.listen((dynamic data) {
        try {
          final String id = data[0] as String;
          final int statusCode = data[1] as int;
          final int progress = data[2] as int;
          final status = _statusFromInt(statusCode);

          final index = _items.indexWhere((e) => e.taskId == id);
          if (index != -1) {
            _items[index].status = status;
            _items[index].progress = progress;
            notifyListeners();
          } else {
            refresh();
          }
        } catch (e) {
          debugPrint('Download port listener error: $e');
        }
      });

      // Callback also registered in main(); re-register is safe and ensures link.
      FlutterDownloader.registerCallback(inkDownloaderCallback);
      await _loadExistingTasks();
      _ensurePolling();
    } catch (e, st) {
      debugPrint('DownloadService init error: $e\n$st');
    }
    _initialized = true;
  }

  static DownloadTaskStatus _statusFromInt(int code) {
    // flutter_downloader status codes:
    // 0 undefined, 1 enqueued, 2 running, 3 complete, 4 failed, 5 canceled, 6 paused
    switch (code) {
      case 1:
        return DownloadTaskStatus.enqueued;
      case 2:
        return DownloadTaskStatus.running;
      case 3:
        return DownloadTaskStatus.complete;
      case 4:
        return DownloadTaskStatus.failed;
      case 5:
        return DownloadTaskStatus.canceled;
      case 6:
        return DownloadTaskStatus.paused;
      default:
        return DownloadTaskStatus.undefined;
    }
  }

  @pragma('vm:entry-point')
  static void downloadCallback(String id, int status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  Future<void> _loadExistingTasks() async {
    try {
      final tasks = await FlutterDownloader.loadTasks();
      if (tasks == null) return;
      _items
        ..clear()
        ..addAll(tasks.map(DownloadItem.fromTask));
      notifyListeners();
    } catch (e) {
      debugPrint('loadTasks error: $e');
    }
  }


  /// Re-bind the isolate port after the app returns from background.
  Future<void> rebind() async {
    try {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      IsolateNameServer.registerPortWithName(
        _port.sendPort,
        'downloader_send_port',
      );
      FlutterDownloader.registerCallback(inkDownloaderCallback);
      await refresh();
      _ensurePolling();
    } catch (e) {
      debugPrint('DownloadService.rebind error: $e');
    }
  }

  void _ensurePolling() {
    final hasActive = _items.any((e) =>
        e.status == DownloadTaskStatus.running ||
        e.status == DownloadTaskStatus.enqueued);
    if (hasActive) {
      _pollTimer ??= Timer.periodic(const Duration(seconds: 2), (_) {
        refresh().then((_) {
          final still = _items.any((e) =>
              e.status == DownloadTaskStatus.running ||
              e.status == DownloadTaskStatus.enqueued);
          if (!still) {
            _pollTimer?.cancel();
            _pollTimer = null;
          }
        });
      });
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  bool isDownloadableUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      final lastSegment = path.split('/').lastWhere(
            (s) => s.isNotEmpty,
            orElse: () => '',
          );
      final ext = lastSegment.contains('.')
          ? lastSegment.split('.').last.split('?').first
          : '';
      if (downloadableExtensions.contains(ext)) return true;

      final q = uri.query.toLowerCase();
      if (q.contains('apk') ||
          q.contains('download') ||
          path.contains('/apk/') ||
          path.endsWith('.apk')) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static String categoryFor(String filename) {
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    if (const {'mp3', 'm4a', 'ogg', 'wav', 'flac'}.contains(ext)) {
      return 'Music';
    }
    if (const {'mp4', 'webm', 'mkv', 'avi'}.contains(ext)) return 'Videos';
    if (ext == 'apk') return 'Apps';
    if (const {'pdf', 'epub', 'mobi', 'doc', 'docx', 'txt'}.contains(ext)) {
      return 'Documents';
    }
    return 'Other';
  }

  Future<void> _ensurePermissions({bool forApk = false}) async {
    if (!Platform.isAndroid) return;

    try {
      final notif = await Permission.notification.status;
      if (!notif.isGranted) await Permission.notification.request();
    } catch (_) {}

    try {
      if (await Permission.storage.isDenied) {
        await Permission.storage.request();
      }
    } catch (_) {}

    // Android 13+ media (best-effort, never block downloads)
    try {
      if (await Permission.audio.isDenied) await Permission.audio.request();
      if (await Permission.videos.isDenied) await Permission.videos.request();
      if (await Permission.photos.isDenied) await Permission.photos.request();
    } catch (_) {}

    if (forApk) {
      try {
        final install = await Permission.requestInstallPackages.status;
        if (!install.isGranted) {
          await Permission.requestInstallPackages.request();
        }
      } catch (_) {}
    }
  }

  /// Always return a directory that exists and is writable by the app.
  /// Prefer app-external storage (reliable). Public Downloads is handled by
  /// [saveInPublicStorage] in enqueue().
  Future<String> _downloadDir() async {
    try {
      final ext = await getExternalStorageDirectory();
      if (ext != null) {
        final dir = Directory('${ext.path}/Downloads');
        if (!await dir.exists()) await dir.create(recursive: true);
        return dir.path;
      }
    } catch (e) {
      debugPrint('external storage dir failed: $e');
    }

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/Downloads');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  String _safeFileName(String raw) {
    var name = raw.split('?').first.split('#').first;
    name = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (name.isEmpty || name == '.' || name == '..') {
      name = 'download_${DateTime.now().millisecondsSinceEpoch}';
    }
    if (name.length > 120) {
      final ext = name.contains('.') ? '.${name.split('.').last}' : '';
      name = '${name.substring(0, 120 - ext.length)}$ext';
    }
    return name;
  }

  Future<String?> enqueue({
    required String url,
    String? fileName,
    bool showNotification = true,
  }) async {
    await initialize();

    var name = _safeFileName(
      fileName ??
          Uri.parse(url).pathSegments.lastWhere(
                (s) => s.isNotEmpty,
                orElse: () =>
                    'download_${DateTime.now().millisecondsSinceEpoch}',
              ),
    );

    final lowerUrl = url.toLowerCase();
    final looksApk = lowerUrl.contains('.apk') ||
        lowerUrl.contains('application/vnd.android') ||
        name.toLowerCase().endsWith('.apk');
    if (looksApk && !name.toLowerCase().endsWith('.apk')) {
      name = name.contains('.') ? name : '$name.apk';
    }
    final isApk = name.toLowerCase().endsWith('.apk');

    await _ensurePermissions(forApk: isApk);
    final savedDir = await _downloadDir();

    debugPrint('Enqueue download: $url -> $savedDir/$name (apk=$isApk)');

    // Try public storage first (visible in Files app), then app-private.
    String? taskId;
    try {
      taskId = await FlutterDownloader.enqueue(
        url: url,
        savedDir: savedDir,
        fileName: name,
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: true,
        allowCellular: true,
        requiresStorageNotLow: false,
      );
    } catch (e) {
      debugPrint('enqueue public failed: $e');
    }

    // Fallback: app storage without public flag (more reliable on locked-down OEMs)
    if (taskId == null) {
      try {
        taskId = await FlutterDownloader.enqueue(
          url: url,
          savedDir: savedDir,
          fileName: name,
          showNotification: true,
          openFileFromNotification: true,
          saveInPublicStorage: false,
          allowCellular: true,
          requiresStorageNotLow: false,
        );
      } catch (e, st) {
        debugPrint('enqueue private failed: $e\n$st');
        return null;
      }
    }

    if (taskId != null) {
      _items.insert(
        0,
        DownloadItem(
          taskId: taskId,
          url: url,
          fileName: name,
          savedDir: savedDir,
          progress: 0,
          status: DownloadTaskStatus.enqueued,
        ),
      );
      notifyListeners();
      Future.delayed(const Duration(seconds: 1), refresh);
      Future.delayed(const Duration(seconds: 3), refresh);
      Future.delayed(const Duration(seconds: 8), refresh);
      _ensurePolling();
    } else {
      debugPrint('FlutterDownloader.enqueue returned null for $url');
    }
    return taskId;
  }

  Future<void> pause(String taskId) async {
    await FlutterDownloader.pause(taskId: taskId);
    await refresh();
  }

  Future<void> resume(String taskId) async {
    await FlutterDownloader.resume(taskId: taskId);
    await refresh();
  }

  Future<void> cancel(String taskId) async {
    await FlutterDownloader.cancel(taskId: taskId);
    await refresh();
  }

  Future<void> remove(String taskId, {bool deleteFile = false}) async {
    await FlutterDownloader.remove(
      taskId: taskId,
      shouldDeleteContent: deleteFile,
    );
    _items.removeWhere((e) => e.taskId == taskId);
    notifyListeners();
  }

  Future<void> refresh() async {
    await _loadExistingTasks();
    _ensurePolling();
  }

  Future<OpenResult> openFile(DownloadItem item) async {
    final path = item.filePath;
    if (path == null || !File(path).existsSync()) {
      return OpenResult(type: ResultType.error, message: 'File not found');
    }
    if (item.fileName.toLowerCase().endsWith('.apk') && Platform.isAndroid) {
      final status = await Permission.requestInstallPackages.request();
      if (!status.isGranted) {
        return OpenResult(
          type: ResultType.permissionDenied,
          message: 'Install packages permission denied',
        );
      }
    }
    return OpenFilex.open(path);
  }
}

class DownloadItem {
  DownloadItem({
    required this.taskId,
    required this.url,
    required this.fileName,
    required this.savedDir,
    required this.progress,
    required this.status,
  });

  final String taskId;
  final String url;
  final String fileName;
  final String savedDir;
  int progress;
  DownloadTaskStatus status;

  String? get filePath =>
      savedDir.isNotEmpty ? '$savedDir/$fileName' : null;

  String get category => DownloadService.categoryFor(fileName);

  factory DownloadItem.fromTask(DownloadTask t) {
    return DownloadItem(
      taskId: t.taskId,
      url: t.url,
      fileName: t.filename ?? 'unknown',
      savedDir: t.savedDir,
      progress: t.progress,
      status: t.status,
    );
  }
}
