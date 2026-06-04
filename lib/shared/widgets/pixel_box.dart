import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// A surface panel with the pixel-art chunky border (hard offset shadows).
/// Replaces the old `Container` + 1px `Border.all` pattern app-wide.
class PixelBox extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? highlightColor;
  final VoidCallback? onTap;

  const PixelBox({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.highlightColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final box = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? palette.surface,
        boxShadow: palette.pixelBorder(highlightColor: highlightColor),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return GestureDetector(onTap: onTap, child: box);
  }
}
