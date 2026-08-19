import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Background isolate callback for [flutter_downloader] (secondary engine).
@pragma('vm:entry-point')
void inkDownloaderCallback(String id, int status, int progress) {
  final SendPort? send =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

/// Downloads that keep running while the app is open (any screen).
///
/// Primary engine: Dart [HttpClient] stream-to-file (reliable in-process).
/// Secondary engine: [flutter_downloader] for OS-level background when possible.
class DownloadService extends ChangeNotifier {
  DownloadService._();
  static final DownloadService instance = DownloadService._();

  final List<DownloadItem> _items = [];
  bool _initialized = false;
  final ReceivePort _port = ReceivePort();
  final Map<String, HttpClient> _activeClients = {};
  final Map<String, bool> _cancelFlags = {};

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
    'apk', 'mp3', 'mp4', 'm4a', 'ogg', 'wav', 'flac', 'webm', 'mkv', 'avi',
    'zip', 'rar', '7z', 'tar', 'gz', 'pdf', 'epub', 'mobi', 'doc', 'docx',
    'xls', 'xlsx', 'ppt', 'pptx', 'jpg', 'jpeg', 'png', 'gif', 'webp', 'svg',
    'txt', 'csv', 'json',
  };

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      IsolateNameServer.registerPortWithName(
        _port.sendPort,
        'downloader_send_port',
      );
      _port.listen((dynamic data) {
        try {
          final String id = data[0] as String;
          final int statusCode = data[1] as int;
          final int progress = data[2] as int;
          final status = _statusFromInt(statusCode);
          final index = _items.indexWhere((e) => e.taskId == id);
          if (index != -1) {
            // Don't overwrite primary-engine items with secondary status noise
            if (!_items[index].isPrimary) {
              _items[index].status = status;
              _items[index].progress = progress;
              notifyListeners();
            }
          }
        } catch (e) {
          debugPrint('Download port listener error: $e');
        }
      });
      try {
        FlutterDownloader.registerCallback(inkDownloaderCallback);
        await _loadExistingTasks();
      } catch (e) {
        debugPrint('flutter_downloader bind: $e');
      }
    } catch (e, st) {
      debugPrint('DownloadService init error: $e\n$st');
    }
    _initialized = true;
  }

  Future<void> rebind() async {
    try {
      IsolateNameServer.removePortNameMapping('downloader_send_port');
      IsolateNameServer.registerPortWithName(
        _port.sendPort,
        'downloader_send_port',
      );
      FlutterDownloader.registerCallback(inkDownloaderCallback);
      await refresh();
    } catch (e) {
      debugPrint('DownloadService.rebind error: $e');
    }
  }

  static DownloadTaskStatus _statusFromInt(int code) {
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

  Future<void> _loadExistingTasks() async {
    try {
      final tasks = await FlutterDownloader.loadTasks();
      if (tasks == null) return;
      // Merge secondary tasks without wiping primary in-flight ones.
      final primaryIds =
          _items.where((e) => e.isPrimary).map((e) => e.taskId).toSet();
      final secondary = tasks
          .where((t) => !primaryIds.contains(t.taskId))
          .map(DownloadItem.fromTask)
          .toList();
      _items
        ..removeWhere((e) => !e.isPrimary)
        ..addAll(secondary);
      notifyListeners();
    } catch (e) {
      debugPrint('loadTasks error: $e');
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

  /// Starts a download that continues while the app is open (any screen).
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
    final taskId = 'ink_${DateTime.now().millisecondsSinceEpoch}';
    final item = DownloadItem(
      taskId: taskId,
      url: url,
      fileName: name,
      savedDir: savedDir,
      progress: 0,
      status: DownloadTaskStatus.enqueued,
      isPrimary: true,
    );
    _items.insert(0, item);
    notifyListeners();

    // Fire-and-forget: runs until complete even if user leaves Downloads screen.
    unawaited(_runPrimaryDownload(item));

    // Also try OS downloader for true device-background (best-effort).
    if (showNotification) {
      unawaited(_trySecondaryEnqueue(url, name, savedDir));
    }

    return taskId;
  }

  Future<void> _trySecondaryEnqueue(
    String url,
    String name,
    String savedDir,
  ) async {
    try {
      await FlutterDownloader.enqueue(
        url: url,
        savedDir: savedDir,
        fileName: 'bg_$name',
        showNotification: true,
        openFileFromNotification: true,
        saveInPublicStorage: false,
        allowCellular: true,
        requiresStorageNotLow: false,
      );
    } catch (e) {
      debugPrint('secondary enqueue: $e');
    }
  }

  Future<void> _runPrimaryDownload(DownloadItem item) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 30);
    client.idleTimeout = const Duration(seconds: 60);
    // Follow redirects, accept self-signed if needed for edge hosts.
    client.badCertificateCallback = (cert, host, port) => true;
    _activeClients[item.taskId] = client;
    _cancelFlags[item.taskId] = false;

    final filePath = '${item.savedDir}/${item.fileName}';
    final tmpPath = '$filePath.part';

    try {
      item.status = DownloadTaskStatus.running;
      item.progress = 0;
      notifyListeners();

      final request = await client.getUrl(Uri.parse(item.url));
      request.headers.set(HttpHeaders.userAgentHeader, 'INK-Browser/2.0');
      request.followRedirects = true;
      request.maxRedirects = 8;

      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException('HTTP ${response.statusCode}');
      }

      final total = response.contentLength;
      final sink = File(tmpPath).openWrite();
      var received = 0;
      var lastNotify = 0;

      await for (final chunk in response) {
        if (_cancelFlags[item.taskId] == true) {
          await sink.close();
          try {
            await File(tmpPath).delete();
          } catch (_) {}
          item.status = DownloadTaskStatus.canceled;
          item.progress = 0;
          notifyListeners();
          return;
        }
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          final p = ((received / total) * 100).floor().clamp(0, 100);
          // Throttle UI updates to ~4/sec
          if (p != item.progress &&
              (p - lastNotify >= 1 || p == 100 || received < 64 * 1024)) {
            item.progress = p;
            lastNotify = p;
            notifyListeners();
          }
        } else {
          // Unknown size — pulse progress slowly
          final p = (item.progress + 1).clamp(0, 95);
          if (p != item.progress) {
            item.progress = p;
            notifyListeners();
          }
        }
      }
      await sink.flush();
      await sink.close();

      final out = File(filePath);
      if (await out.exists()) await out.delete();
      await File(tmpPath).rename(filePath);

      item.progress = 100;
      item.status = DownloadTaskStatus.complete;
      notifyListeners();
      debugPrint('Download complete: $filePath');
    } catch (e, st) {
      debugPrint('Primary download error: $e\n$st');
      item.status = DownloadTaskStatus.failed;
      notifyListeners();
      try {
        await File(tmpPath).delete();
      } catch (_) {}
    } finally {
      client.close(force: true);
      _activeClients.remove(item.taskId);
      _cancelFlags.remove(item.taskId);
    }
  }

  Future<void> pause(String taskId) async {
    // Primary engine: cancel (no true pause for HttpClient stream).
    final item = _items.cast<DownloadItem?>().firstWhere(
          (e) => e?.taskId == taskId,
          orElse: () => null,
        );
    if (item != null && item.isPrimary) {
      await cancel(taskId);
      return;
    }
    try {
      await FlutterDownloader.pause(taskId: taskId);
      await refresh();
    } catch (_) {}
  }

  Future<void> resume(String taskId) async {
    try {
      await FlutterDownloader.resume(taskId: taskId);
      await refresh();
    } catch (_) {}
  }

  Future<void> cancel(String taskId) async {
    _cancelFlags[taskId] = true;
    _activeClients[taskId]?.close(force: true);
    final item = _items.cast<DownloadItem?>().firstWhere(
          (e) => e?.taskId == taskId,
          orElse: () => null,
        );
    if (item != null && item.isPrimary) {
      item.status = DownloadTaskStatus.canceled;
      notifyListeners();
      return;
    }
    try {
      await FlutterDownloader.cancel(taskId: taskId);
      await refresh();
    } catch (_) {}
  }

  Future<void> remove(String taskId, {bool deleteFile = false}) async {
    _cancelFlags[taskId] = true;
    _activeClients[taskId]?.close(force: true);
    final idx = _items.indexWhere((e) => e.taskId == taskId);
    if (idx != -1) {
      final item = _items[idx];
      if (deleteFile && item.filePath != null) {
        try {
          final f = File(item.filePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      _items.removeAt(idx);
      notifyListeners();
    }
    try {
      await FlutterDownloader.remove(
        taskId: taskId,
        shouldDeleteContent: deleteFile,
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    await _loadExistingTasks();
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
    this.isPrimary = false,
  });

  final String taskId;
  final String url;
  final String fileName;
  final String savedDir;
  int progress;
  DownloadTaskStatus status;

  /// True = Dart HttpClient engine (survives leaving Downloads screen).
  final bool isPrimary;

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
      isPrimary: false,
    );
  }
}
