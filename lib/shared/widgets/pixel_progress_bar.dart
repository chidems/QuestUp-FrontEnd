import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// Pixel-art progress bar with an inset track and a highlighted fill.
/// Optionally shows a label row above (label + value text).
class PixelProgressBar extends StatelessWidget {
  final double value; // 0.0 – 1.0
  final Color? fillColor;
  final double height;

  /// Optional label row drawn above the bar.
  final String? label;
  final String? valueLabel;

  const PixelProgressBar({
    super.key,
    required this.value,
    this.fillColor,
    this.height = 14,
    this.label,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final fill = fillColor ?? p.xpColor;

    final bar = Container(
      height: height,
      decoration: BoxDecoration(
        color: p.surfaceDeep,
        boxShadow: [
          BoxShadow(color: p.border, offset: const Offset(0, -2)),
          BoxShadow(color: p.borderDeep, offset: const Offset(0, 2)),
          BoxShadow(color: p.border, offset: const Offset(-2, 0)),
          BoxShadow(color: p.border, offset: const Offset(2, 0)),
        ],
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        // Fill animates in on first build and eases to any new value.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: value.clamp(0.0, 1.0)),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, animatedValue, child) => FractionallySizedBox(
            widthFactor: animatedValue,
            child: child,
          ),
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: fill)),
              Positioned(
                top: 3,
                left: 4,
                right: 4,
                child: Container(
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (label == null && valueLabel == null) return bar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (label != null)
              Text(label!,
                  style: TextStyle(fontSize: 12, color: p.textBody)),
            if (valueLabel != null)
              Text(valueLabel!,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.accent)),
          ],
        ),
        const SizedBox(height: 4),
        bar,
      ],
    );
  }
}
