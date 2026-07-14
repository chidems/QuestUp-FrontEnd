import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/category_icon.dart';
import '../../quests/models/quest_models.dart';

/// Exclamation mark for NPC quest pins — the classic RPG quest-giver marker.
const _bangGlyph = [
  '....XXXX....',
  '....XXXX....',
  '....XXXX....',
  '....XXXX....',
  '.....XX.....',
  '.....XX.....',
  '.....XX.....',
  '............',
  '....XXXX....',
  '....XXXX....',
  '............',
  '............',
];

const _kOutline = Color(0xFF140E08);
const _kCream = Color(0xFFF2F0D8);

/// The pin-set key for a quest: its category, or the special weekly/npc pins.
String questPinKey(Quest q) {
  if (q.source == 'npc') return 'npc';
  if (q.isWeekly) return 'weekly';
  const categories = {'location', 'social', 'action'};
  return categories.contains(q.questType) ? q.questType : 'action';
}

/// Renders the map's pixel-art marker set: chunky outlined pins carrying the
/// same category glyphs as [CategoryIcon], plus a teal flag pin for the
/// weekly quest and a purple "!" pin for NPC quests.
Future<Map<String, BitmapDescriptor>> renderQuestPins(
  AppPalette palette,
  double devicePixelRatio,
) async {
  final specs = <String, (Color, List<String>)>{
    'location': (palette.locationQuest, categoryGlyph('location')),
    'social': (palette.socialQuest, categoryGlyph('social')),
    'action': (palette.actionQuest, categoryGlyph('action')),
    'weekly': (palette.accentTeal, categoryGlyph('weekly')),
    'npc': (palette.primary, _bangGlyph),
  };
  return {
    for (final entry in specs.entries)
      entry.key: await _renderPin(
        fill: entry.value.$1,
        glyph: entry.value.$2,
        devicePixelRatio: devicePixelRatio,
      ),
  };
}

/// Draws one pin on a cell grid (18x20 cells, 2 logical px per cell → a
/// 36x40 logical marker): outlined square head with a top highlight and
/// bottom shade, the glyph in cream, and a tapering tip. Hard edges only —
/// no anti-aliasing — to match the app's pixel art.
Future<BitmapDescriptor> _renderPin({
  required Color fill,
  required List<String> glyph,
  required double devicePixelRatio,
}) async {
  final cell = 2.0 * devicePixelRatio;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..isAntiAlias = false;

  void cells(int x, int y, int w, int h, Color c) {
    paint.color = c;
    canvas.drawRect(
      Rect.fromLTWH(x * cell, y * cell, w * cell + 0.5, h * cell + 0.5),
      paint,
    );
  }

  final highlight = Color.lerp(fill, Colors.white, 0.45)!;
  final shade = Color.lerp(fill, Colors.black, 0.30)!;

  // Head: outline, fill, painterly top highlight + bottom shade.
  cells(0, 0, 18, 16, _kOutline);
  cells(1, 1, 16, 14, fill);
  cells(1, 1, 16, 1, highlight);
  cells(1, 14, 16, 1, shade);
  // Glyph, centered in the head.
  for (var gy = 0; gy < glyph.length; gy++) {
    for (var gx = 0; gx < glyph[gy].length; gx++) {
      if (glyph[gy][gx] == 'X') cells(3 + gx, 2 + gy, 1, 1, _kCream);
    }
  }
  // Tapering tip pointing at the quest location.
  cells(5, 16, 8, 1, _kOutline);
  cells(6, 16, 6, 1, shade);
  cells(6, 17, 6, 1, _kOutline);
  cells(7, 17, 4, 1, shade);
  cells(7, 18, 4, 1, _kOutline);
  cells(8, 19, 2, 1, _kOutline);

  final image = await recorder
      .endRecording()
      .toImage((18 * cell).ceil(), (20 * cell).ceil());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return BitmapDescriptor.bytes(
    bytes!.buffer.asUint8List(),
    imagePixelRatio: devicePixelRatio,
  );
}
