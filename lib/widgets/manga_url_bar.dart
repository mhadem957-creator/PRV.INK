import 'package:flutter/material.dart';

import '../theme/manga_theme.dart';

/// Speech-bubble styled URL / search bar with sharp edges and thick ink lines.
class MangaUrlBar extends StatelessWidget {
  const MangaUrlBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isSecure,
    required this.onSubmitted,
    this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSecure;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final ink = MangaTheme.inkOf(context);
    final paper = MangaTheme.paperOf(context);

    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: paper,
        border: Border.all(color: ink, width: 2.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: ink, width: 2.5),
              ),
            ),
            child: Icon(
              isSecure ? Icons.lock : Icons.info_outline,
              size: 18,
              color: isSecure ? MangaTheme.crimson : ink,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Search or enter address…',
                  hintStyle: TextStyle(
                    color: ink.withOpacity(0.4),
                    fontWeight: FontWeight.w500,
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.go,
                onSubmitted: onSubmitted,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: ink),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            onPressed: () {
              controller.clear();
              focusNode.requestFocus();
              onClear?.call();
            },
          ),
        ],
      ),
    );
  }
}
