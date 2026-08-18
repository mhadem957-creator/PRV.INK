import 'package:flutter/material.dart';

import '../theme/manga_theme.dart';

/// Reusable container with thick borders and hard offset shadows
/// (Neubrutalism / manga ink style). Adapts to light/dark theme.
class MangaContainer extends StatelessWidget {
  const MangaContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.borderWidth,
    this.shadowOffset,
    this.onTap,
    this.width,
    this.height,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? borderWidth;
  final Offset? shadowOffset;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final bw = borderWidth ?? MangaTheme.borderWidth;
    final offset = shadowOffset ?? MangaTheme.shadowOffset;
    final ink = MangaTheme.inkOf(context);
    final paper = MangaTheme.paperOf(context);

    final container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color ?? paper,
        border: Border.all(color: ink, width: bw),
        boxShadow: [
          BoxShadow(
            color: ink,
            offset: offset,
            blurRadius: 0,
            spreadRadius: 0,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: container,
      );
    }
    return container;
  }
}

/// Compact variant often used for buttons / chips.
class MangaChip extends StatelessWidget {
  const MangaChip({
    super.key,
    required this.label,
    this.onTap,
    this.selected = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final bool selected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ink = MangaTheme.inkOf(context);
    final paper = MangaTheme.paperOf(context);
    return MangaContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(right: 8),
      color: selected ? MangaTheme.crimson : paper,
      borderWidth: 2.5,
      shadowOffset: const Offset(3, 3),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: selected ? paper : ink,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: selected ? paper : ink,
            ),
          ),
        ],
      ),
    );
  }
}
