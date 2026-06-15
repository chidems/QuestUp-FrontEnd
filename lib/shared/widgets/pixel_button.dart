import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';

enum PixelButtonVariant { primary, navigation, neutral, destructive }

/// Rounded button with a subtle raised edge and a press-down animation.
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

  /// Optional explicit label/icon color; defaults to the palette button text.
  final Color? textColor;

  const PixelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = PixelButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
    this.color,
    this.textColor,
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
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final disabled = widget.onPressed == null || widget.isLoading;
    final fill = _base(palette);
    final border = _darken(fill, 0.16);
    final shadow1 = _darken(fill, 0.26);
    final shadow2 = _darken(fill, 0.40);

    // A single hard bottom offset reads as a rounded, raised edge; it shrinks
    // on press so the button appears to push down.
    final shadows = [
      BoxShadow(
        color: shadow2,
        offset: Offset(0, _pressed ? 1 : 4),
        blurRadius: 0,
      ),
    ];

    final textColor = widget.textColor ?? palette.buttonText;

    Widget content = widget.isLoading
        ? SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: textColor),
          )
        : Row(
            mainAxisSize: widget.fullWidth
                ? MainAxisSize.max
                : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 16, color: textColor),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: textColor),
              ),
            ],
          );

    // onPressed fires from onTap (not onTapUp) so GestureDetector exposes a
    // semantic tap action to screen readers.
    final btn = Semantics(
      container: true,
      button: true,
      enabled: !disabled,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
        onTapUp: disabled ? null : (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: disabled ? null : () => widget.onPressed?.call(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          transform: _pressed
              ? Matrix4.translationValues(0, 3, 0)
              : Matrix4.identity(),
          decoration: BoxDecoration(
            color: disabled ? _darken(fill, 0.08) : (_pressed ? shadow1 : fill),
            borderRadius: AppRadius.rButton,
            border: Border.all(color: border, width: 1.5),
            boxShadow: disabled ? null : shadows,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          // 24 content + 24 padding = 48dp minimum tap target.
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 24, minWidth: 24),
            child: Center(widthFactor: 1, child: content),
          ),
        ),
      ),
    );

    return widget.fullWidth
        ? SizedBox(width: double.infinity, child: btn)
        : btn;
  }
}
