import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme/app_palette.dart';

/// One-shot celebratory burst of pixel squares (level-ups etc.).
/// Plays once when mounted; squares launch upward then fall and fade.
class PixelConfetti extends StatefulWidget {
  final int count;

  const PixelConfetti({super.key, this.count = 24});

  @override
  State<PixelConfetti> createState() => _PixelConfettiState();
}

class _PixelConfettiState extends State<PixelConfetti>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) => CustomPaint(
          painter: _ConfettiPainter(
            t: _controller.value,
            colors: [
              p.accent,
              p.xpColor,
              p.primaryLight,
              p.socialQuest,
              p.locationQuest,
            ],
            count: widget.count,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  final List<Color> colors;
  final int count;

  _ConfettiPainter({required this.t, required this.colors, required this.count});

  @override
  void paint(Canvas canvas, Size size) {
    // Fixed seed: every frame re-derives the same particle trajectories.
    final rng = Random(7);
    final paint = Paint();

    for (var i = 0; i < count; i++) {
      final angle = rng.nextDouble() * pi - pi; // upward hemisphere
      final speed = 0.5 + rng.nextDouble() * 0.5;
      final side = 4.0 + rng.nextInt(3) * 2;

      final x = size.width / 2 + cos(angle) * speed * size.width * 0.6 * t;
      final y = size.height / 3 +
          sin(angle) * speed * size.height * 0.5 * t +
          0.6 * size.height * t * t; // gravity

      paint.color =
          colors[i % colors.length].withValues(alpha: (1 - t).clamp(0.0, 1.0));
      // Snap to a 2px grid to keep the pixel feel.
      canvas.drawRect(
        Rect.fromLTWH(
          (x / 2).roundToDouble() * 2,
          (y / 2).roundToDouble() * 2,
          side,
          side,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => oldDelegate.t != t;
}
