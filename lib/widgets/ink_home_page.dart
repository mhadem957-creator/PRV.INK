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
    _Shortcut('📖', 'WIKI', 'https://en.wikipedia.org'),
    _Shortcut('⚡', 'GITHUB', 'https://github.com'),
    _Shortcut('🔥', 'NEWS', 'https://news.ycombinator.com'),
    _Shortcut('💬', 'REDDIT', 'https://reddit.com'),
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
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.6,
                      children: [
                        for (final s in _shortcuts)
                          _ShortcutTile(
                            emoji: s.emoji,
                            label: s.label,
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
  const _Shortcut(this.emoji, this.label, this.url);
  final String emoji;
  final String label;
  final String url;
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = MangaTheme.inkOf(context);
    final paper = MangaTheme.paperOf(context);
    return Material(
      color: paper,
      child: InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: ink, width: 3),
            boxShadow: [
              BoxShadow(
                color: ink,
                offset: const Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 1,
                  color: ink,
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
