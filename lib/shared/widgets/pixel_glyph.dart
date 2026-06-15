import 'package:flutter/material.dart';

/// Renders a hand-drawn pixel sprite from a 12x12 string grid
/// ('X' = filled cell), e.g.:
///
/// ```dart
/// const heart = [
///   '............',
///   '..XX....XX..',
///   ...
/// ];
/// PixelGlyph(heart, color: Colors.red, size: 24)
/// ```
///
/// Used for nav-bar tabs, quest category icons and item placeholders.
class PixelGlyph extends StatelessWidget {
  final List<String> glyph;
  final Color color;
  final double size;

  const PixelGlyph(this.glyph, {super.key, required this.color, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _PixelGlyphPainter(glyph, color),
    );
  }
}

class _PixelGlyphPainter extends CustomPainter {
  final List<String> glyph;
  final Color color;

  _PixelGlyphPainter(this.glyph, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 12;
    final paint = Paint()..color = color;
    for (var y = 0; y < glyph.length; y++) {
      final row = glyph[y];
      for (var x = 0; x < row.length; x++) {
        if (row[x] == 'X') {
          // Slight overdraw avoids hairline seams between cells.
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell + 0.5, cell + 0.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PixelGlyphPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glyph != glyph;
}
