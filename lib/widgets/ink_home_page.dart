import 'package:flutter/material.dart';

import '../theme/manga_theme.dart';

/// Native Flutter start page for INK (replaces the old HTML home).
class InkHomePage extends StatefulWidget {
  const InkHomePage({
    super.key,
    required this.onSearch,
    required this.onOpenUrl,
  });

  final ValueChanged<String> onSearch;
  final ValueChanged<String> onOpenUrl;

  @override
  State<InkHomePage> createState() => _InkHomePageState();
}

class _InkHomePageState extends State<InkHomePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  static const _shortcuts = [
    _Shortcut(Icons.menu_book_rounded, 'WIKI', 'https://en.wikipedia.org', Color(0xFFE60012)),
    _Shortcut(Icons.code_rounded, 'GITHUB', 'https://github.com', Color(0xFF6C63FF)),
    _Shortcut(Icons.whatshot_rounded, 'NEWS', 'https://news.ycombinator.com', Color(0xFFFF6B00)),
    _Shortcut(Icons.forum_rounded, 'REDDIT', 'https://reddit.com', Color(0xFFFF4500)),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _controller.text.trim();
    if (q.isEmpty) return;
    widget.onSearch(q);
  }

  @override
  Widget build(BuildContext context) {
    final ink = MangaTheme.inkOf(context);
    final paper = MangaTheme.paperOf(context);
    final muted = MangaTheme.inkOf(context).withOpacity(0.55);

    return ColoredBox(
      color: paper,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                decoration: BoxDecoration(
                  color: paper,
                  border: Border.all(color: ink, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: ink,
                      offset: const Offset(8, 8),
                      blurRadius: 0,
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand logo
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        border: Border.all(color: ink, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: ink,
                            offset: const Offset(5, 5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Image.asset(
                        'assets/branding/home_logo.png',
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'INK',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 8,
                        color: ink,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PRIVATE · FAST · YOURS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.5,
                        color: MangaTheme.crimson,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Search box
                    Container(
                      decoration: BoxDecoration(
                        color: paper,
                        border: Border.all(color: ink, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: ink,
                            offset: const Offset(5, 5),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focus,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _submit(),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: ink,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search privately…',
                                hintStyle: TextStyle(
                                  color: ink.withOpacity(0.35),
                                  fontWeight: FontWeight.w700,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 14,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          Material(
                            color: MangaTheme.crimson,
                            child: InkWell(
                              onTap: _submit,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: ink, width: 3.5),
                                  ),
                                ),
                                child: Text(
                                  'GO',
                                  style: TextStyle(
                                    color: paper,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Shortcuts grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.55,
                      children: [
                        for (final s in _shortcuts)
                          _ShortcutTile(
                            icon: s.icon,
                            label: s.label,
                            accent: s.accent,
                            onTap: () => widget.onOpenUrl(s.url),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Feature pills
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 6,
                      children: const [
                        _Feat('NO TRACKERS'),
                        _Feat('NO ADS'),
                        _Feat('SEARXNG'),
                        _Feat('DOH READY'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'INK BROWSER · YOU OWN THE PAGE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        color: muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut(this.icon, this.label, this.url, this.accent);
  final IconData icon;
  final String label;
  final String url;
  final Color accent;
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.icon,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Fixed high-contrast palette so tiles always pop on dark or light home.
    const bg = Color(0xFF1A1A1A);
    const fg = Color(0xFFF0EDE6);
    const border = Color(0xFFF0EDE6);

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        splashColor: accent.withOpacity(0.25),
        highlightColor: accent.withOpacity(0.12),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Color(0xFFF0EDE6),
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Accent stripe
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 5, color: accent),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.18),
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: Icon(icon, size: 20, color: accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.4,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feat extends StatelessWidget {
  const _Feat(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final muted = MangaTheme.inkOf(context).withOpacity(0.55);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '●',
          style: TextStyle(color: MangaTheme.crimson, fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: muted,
          ),
        ),
      ],
    );
  }
}
