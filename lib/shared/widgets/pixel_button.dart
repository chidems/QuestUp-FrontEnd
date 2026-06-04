import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

enum PixelButtonVariant { primary, navigation, neutral, destructive }

/// Pixel-art button with a chunky 3D border and a press-down animation.
/// Keeps the original API (label / onPressed / isLoading / color) and adds
/// [variant], [icon] and [fullWidth].
class PixelButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final PixelButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  /// Optional explicit fill color; overrides [variant].
  final Color? color;

  const PixelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = PixelButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
    this.color,
  });

  @override
  State<PixelButton> createState() => _PixelButtonState();
}

class _PixelButtonState extends State<PixelButton> {
  bool _pressed = false;

  Color _base(AppPalette p) {
    if (widget.color != null) return widget.color!;
    switch (widget.variant) {
      case PixelButtonVariant.primary:
        return p.primary;
      case PixelButtonVariant.navigation:
        return p.accentTeal;
      case PixelButtonVariant.neutral:
        return p.accentPurple;
      case PixelButtonVariant.destructive:
        return p.error;
    }
  }

  Color _darken(Color c, double amount) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final disabled = widget.onPressed == null || widget.isLoading;
    final fill = _base(palette);
    final border = _darken(fill, 0.14);
    final shadow1 = _darken(fill, 0.26);
    final shadow2 = _darken(fill, 0.38);

    final shadows = _pressed
        ? [
            for (final o in const [
              Offset(0, -4), Offset(0, 4), Offset(-4, 0), Offset(4, 0),
              Offset(4, 4), Offset(4, -4), Offset(-4, 4), Offset(-4, -4),
            ])
              BoxShadow(color: border, offset: o, blurRadius: 0),
          ]
        : [
            BoxShadow(color: border, offset: const Offset(0, -4)),
            BoxShadow(color: border, offset: const Offset(-4, 0)),
            BoxShadow(color: border, offset: const Offset(4, 0)),
            BoxShadow(color: border, offset: const Offset(4, -4)),
            BoxShadow(color: border, offset: const Offset(-4, -4)),
            BoxShadow(color: shadow1, offset: const Offset(0, 4)),
            BoxShadow(color: shadow1, offset: const Offset(-4, 4)),
            BoxShadow(color: shadow2, offset: const Offset(4, 4)),
          ];

    Widget content = widget.isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: palette.buttonText,
            ),
          )
        : Row(
            mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: palette.buttonText),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.buttonText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          );

    final btn = GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 60),
        transform: _pressed
            ? Matrix4.translationValues(2, 2, 0)
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: disabled ? _darken(fill, 0.08) : (_pressed ? shadow1 : fill),
          boxShadow: disabled ? null : shadows,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: content,
      ),
    );

    return widget.fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
