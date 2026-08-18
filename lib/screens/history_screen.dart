import 'package:flutter/material.dart';

import '../models/history_entry.dart';
import '../services/history_service.dart';
import '../theme/manga_theme.dart';
import '../widgets/manga_container.dart';

/// Manga-styled browsing history list.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.onOpenUrl,
  });

  final ValueChanged<String> onOpenUrl;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _history = HistoryService.instance;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _history.load().then((_) {
      if (mounted) setState(() {});
    });
    _history.addListener(_onChange);
  }

  @override
  void dispose() {
    _history.removeListener(_onChange);
    _search.dispose();
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  List<HistoryEntry> get _filtered => _history.search(_query);

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'JUST NOW';
    if (diff.inHours < 1) return '${diff.inMinutes}M AGO';
    if (diff.inDays < 1) return '${diff.inHours}H AGO';
    if (diff.inDays < 7) return '${diff.inDays}D AGO';
    return '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: MangaTheme.paperOf(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: MangaTheme.inkOf(context), width: 4),
        ),
        title: const Text(
          'CLEAR HISTORY?',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
    if (ok == true) await _history.clear();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;

    return Scaffold(
      backgroundColor: MangaTheme.paperOf(context),
      appBar: AppBar(
        title: Text(
          'HISTORY',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: MangaTheme.inkOf(context),
          ),
        ),
        actions: [
          if (_history.entries.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: MangaTheme.inkOf(context)),
              tooltip: 'Clear all',
              onPressed: _confirmClear,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: MangaTheme.paperOf(context),
                    border: Border.all(color: MangaTheme.inkOf(context), width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: MangaTheme.inkOf(context),
                        offset: const Offset(3, 3),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _query = v),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: MangaTheme.inkOf(context),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search history…',
                      hintStyle: TextStyle(
                        color: MangaTheme.inkOf(context).withOpacity(0.4),
                      ),
                      prefixIcon: Icon(Icons.search, color: MangaTheme.inkOf(context)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              Container(height: 3, color: MangaTheme.inkOf(context)),
            ],
          ),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: MangaContainer(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 48,
                      color: MangaTheme.inkOf(context).withOpacity(0.45),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'NO HISTORY',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        letterSpacing: 1,
                        color: MangaTheme.inkOf(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Sites you visit will show up here.',
                      style: TextStyle(
                        color: MangaTheme.inkOf(context).withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final e = items[index];
                return MangaContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  onTap: () {
                    Navigator.pop(context);
                    widget.onOpenUrl(e.url);
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: MangaTheme.paperMutedOf(context),
                          border: Border.all(color: MangaTheme.inkOf(context), width: 2),
                        ),
                        child: Icon(Icons.public, size: 18, color: MangaTheme.inkOf(context)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: MangaTheme.inkOf(context),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              e.url,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: MangaTheme.inkOf(context).withOpacity(0.55),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTime(e.visitedAt),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: MangaTheme.crimson,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, size: 18, color: MangaTheme.inkOf(context)),
                        tooltip: 'Remove',
                        onPressed: () {
                          final realIndex = _history.entries.indexOf(e);
                          if (realIndex >= 0) {
                            _history.removeAt(realIndex);
                          } else {
                            _history.removeUrl(e.url);
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
