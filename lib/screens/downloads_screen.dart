import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:open_filex/open_filex.dart';

import '../services/download_service.dart';
import '../theme/manga_theme.dart';
import '../widgets/manga_container.dart';

/// File manager UI for active and completed downloads, styled in Manga aesthetic.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadService _service = DownloadService.instance;
  String _filter = 'All';

  static const _categories = ['All', 'Music', 'Apps', 'Documents', 'Videos', 'Other'];

  @override
  void initState() {
    super.initState();
    _service.initialize().then((_) => _service.refresh());
    _service.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _service.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  List<DownloadItem> get _filtered {
    final list = _service.items;
    if (_filter == 'All') return list;
    return list.where((e) => e.category == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MangaTheme.paperOf(context),
      appBar: AppBar(
        title: Text(
          'DOWNLOADS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: MangaTheme.inkOf(context),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: MangaTheme.inkOf(context)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: MangaTheme.inkOf(context)),
            tooltip: 'Refresh',
            onPressed: () => _service.refresh(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: Container(height: 3, color: MangaTheme.inkOf(context)),
        ),
      ),
      body: Column(
        children: [
          // Category chips
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              children: _categories
                  .map(
                    (c) => MangaChip(
                      label: c,
                      selected: _filter == c,
                      onTap: () => setState(() => _filter = c),
                    ),
                  )
                  .toList(),
            ),
          ),
          Container(height: 2.5, color: MangaTheme.inkOf(context)),
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmpty(context)
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      return _DownloadTile(
                        item: item,
                        onPause: () => _service.pause(item.taskId),
                        onResume: () => _service.resume(item.taskId),
                        onCancel: () => _service.cancel(item.taskId),
                        onRemove: () =>
                            _service.remove(item.taskId, deleteFile: true),
                        onOpen: () async {
                          final result = await _service.openFile(item);
                          if (context.mounted &&
                              result.type != ResultType.done) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result.message)),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: MangaContainer(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_outlined,
              size: 48,
              color: MangaTheme.inkOf(context).withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'NO DOWNLOADS YET',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Detected media files will appear here.',
              style: TextStyle(
                color: MangaTheme.inkOf(context).withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  const _DownloadTile({
    required this.item,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRemove,
    required this.onOpen,
  });

  final DownloadItem item;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final isRunning = item.status == DownloadTaskStatus.running ||
        item.status == DownloadTaskStatus.enqueued;
    final isPaused = item.status == DownloadTaskStatus.paused;
    final isComplete = item.status == DownloadTaskStatus.complete;
    final isFailed = item.status == DownloadTaskStatus.failed ||
        item.status == DownloadTaskStatus.canceled;

    final ink = MangaTheme.inkOf(context);

    return MangaContainer(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _categoryIcon(context, item.category),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                item.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: MangaTheme.crimson,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar (manga style – thick, hard)
          if (!isComplete && !isFailed)
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: LinearProgressIndicator(
                    value: item.progress / 100,
                    minHeight: 8,
                    backgroundColor: MangaTheme.paperMutedOf(context),
                    color: MangaTheme.crimson,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${item.progress}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          if (isComplete)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPLETED',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: MangaTheme.crimson,
                    letterSpacing: 1,
                  ),
                ),
                if (item.filePath != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.filePath!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: ink.withOpacity(0.55),
                    ),
                  ),
                ],
              ],
            ),
          if (isFailed)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.status == DownloadTaskStatus.canceled
                      ? 'CANCELED'
                      : 'FAILED',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: ink,
                    letterSpacing: 0.5,
                  ),
                ),
                if (item.error != null && item.error!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.error!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      color: ink.withOpacity(0.55),
                    ),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 10),
          // Action row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isRunning)
                _actionBtn(context, Icons.pause, 'Pause', onPause),
              if (isPaused)
                _actionBtn(context, Icons.play_arrow, 'Resume', onResume),
              if (isRunning || isPaused)
                _actionBtn(context, Icons.close, 'Cancel', onCancel),
              if (isComplete) ...[
                _actionBtn(context, Icons.open_in_new, 'Open', onOpen),
                _actionBtn(context, Icons.delete_outline, 'Delete', onRemove),
              ],
              if (isFailed) ...[
                _actionBtn(context, Icons.refresh, 'Retry', onResume),
                _actionBtn(context, Icons.delete_outline, 'Remove', onRemove),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _categoryIcon(BuildContext context, String cat) {
    IconData icon;
    switch (cat) {
      case 'Music':
        icon = Icons.music_note;
        break;
      case 'Videos':
        icon = Icons.videocam;
        break;
      case 'Apps':
        icon = Icons.android;
        break;
      case 'Documents':
        icon = Icons.description;
        break;
      default:
        icon = Icons.insert_drive_file;
    }
    final ink = MangaTheme.inkOf(context);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: MangaTheme.paperMutedOf(context),
        border: Border.all(color: ink, width: 2),
      ),
      child: Icon(icon, size: 20, color: ink),
    );
  }

  Widget _actionBtn(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onTap,
  ) {
    // High-contrast: always dark ink on light paper so labels never vanish.
    const fg = Color(0xFF121212);
    const bg = Color(0xFFF6F5F0);
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Material(
        color: bg,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: bg,
              border: Border.all(color: fg, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: fg,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 4),
                Text(
                  tooltip.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
