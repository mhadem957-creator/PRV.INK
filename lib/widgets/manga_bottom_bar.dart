import 'package:flutter/material.dart';

import '../theme/manga_theme.dart';

/// Manga-styled bottom toolbar with thick borders and hard shadows.
class MangaBottomBar extends StatelessWidget {
  const MangaBottomBar({
    super.key,
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.onHome,
    required this.isLoading,
    required this.tabCount,
    required this.onTabsPressed,
    this.onDownloadsPressed,
    this.onHistoryPressed,
  });

  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onReload;
  final VoidCallback onHome;
  final bool isLoading;
  final int tabCount;
  final VoidCallback onTabsPressed;
  final VoidCallback? onDownloadsPressed;
  final VoidCallback? onHistoryPressed;

  @override
  Widget build(BuildContext context) {
    final paper = MangaTheme.paperOf(context);
    final ink = MangaTheme.inkOf(context);

    return Container(
      decoration: BoxDecoration(
        color: paper,
        border: Border(
          top: BorderSide(color: ink, width: 3),
        ),
        boxShadow: [
          BoxShadow(
            color: ink,
            offset: const Offset(0, -3),
            blurRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _barBtn(context, Icons.arrow_back, 'Back', onBack),
            _barBtn(context, Icons.arrow_forward, 'Forward', onForward),
            _barBtn(context, Icons.home_outlined, 'Home', onHome),
            _barBtn(
              context,
              isLoading ? Icons.close : Icons.refresh,
              isLoading ? 'Stop' : 'Reload',
              onReload,
            ),
            if (onHistoryPressed != null)
              _barBtn(context, Icons.history, 'History', onHistoryPressed!),
            if (onDownloadsPressed != null)
              _barBtn(
                context,
                Icons.download_outlined,
                'Downloads',
                onDownloadsPressed!,
              ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                _barBtn(context, Icons.filter_none, 'Tabs', onTabsPressed),
                if (tabCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: MangaTheme.crimson,
                        border: Border.all(color: ink, width: 1.5),
                      ),
                      child: Text(
                        '$tabCount',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: paper,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _barBtn(
    BuildContext context,
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    final ink = MangaTheme.inkOf(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            width: 44,
            height: 48,
            alignment: Alignment.center,
            child: Icon(icon, color: ink, size: 24),
          ),
        ),
      ),
    );
  }
}
