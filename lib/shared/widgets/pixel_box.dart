import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';

/// A rounded surface panel with a thin border and a soft drop shadow.
/// Replaces the old `Container` + 1px `Border.all` pattern app-wide.
/// Tappable boxes get the same press-down feedback as [PixelButton].
class PixelBox extends StatefulWidget {
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
  State<PixelBox> createState() => _PixelBoxState();
}

class _PixelBoxState extends State<PixelBox> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final box = AnimatedContainer(
      duration: const Duration(milliseconds: 60),
      transform: _pressed
          ? Matrix4.translationValues(2, 2, 0)
          : Matrix4.identity(),
      margin: widget.margin,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.color ?? palette.surface,
        borderRadius: AppRadius.rCard,
        border: Border.all(
          color: widget.highlightColor ?? palette.border,
          width: widget.highlightColor != null ? 2 : 1.5,
        ),
        boxShadow: palette.softShadow(),
      ),
      child: widget.child,
    );
    if (widget.onTap == null) return box;
    // onTap (not onTapUp) fires the callback so GestureDetector exposes a
    // semantic tap action to screen readers.
    return Semantics(
      container: true,
      button: true,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: box,
      ),
    );
  }
}
