import 'package:flutter/material.dart';
import '../../core/constants/quest_constants.dart';
import '../../core/theme/app_palette.dart';
import '../../core/theme/app_radius.dart';
import 'pixel_glyph.dart';

/// Hand-drawn 12x12 pixel sprites per quest category ('X' = filled cell).
const _pinGlyph = [
  '...XXXXXX...',
  '..XXXXXXXX..',
  '.XXXXXXXXXX.',
  '.XXX....XXX.',
  '.XXX....XXX.',
  '.XXXXXXXXXX.',
  '..XXXXXXXX..',
  '...XXXXXX...',
  '....XXXX....',
  '.....XX.....',
  '.....XX.....',
  '............',
];

const _socialGlyph = [
  '............',
  '..XX....XX..',
  '.XXXX..XXXX.',
  '.XXXX..XXXX.',
  '..XX....XX..',
  '............',
  '.XXXX..XXXX.',
  '.XXXX..XXXX.',
  '.XXXX..XXXX.',
  '.XXXX..XXXX.',
  '............',
  '............',
];

const _boltGlyph = [
  '......XXXX..',
  '.....XXXX...',
  '....XXXX....',
  '...XXXXXXX..',
  '..XXXXXXX...',
  '.....XXX....',
  '....XXX.....',
  '...XXX......',
  '..XX........',
  '.XX.........',
  '............',
  '............',
];

const _flagGlyph = [
  '............',
  '..X.........',
  '..XXXXXXXXX.',
  '..XXXXXXXXX.',
  '..XXXXXXX...',
  '..X.........',
  '..X.........',
  '..X.........',
  '..X.........',
  '..X.........',
  '............',
  '............',
];

/// The 12x12 sprite for a quest category (shared with the map's pin
/// renderer, which paints the same glyphs onto marker bitmaps).
List<String> categoryGlyph(String questType) {
  switch (questType) {
    case QuestType.location:
      return _pinGlyph;
    case QuestType.social:
      return _socialGlyph;
    case QuestType.action:
      return _boltGlyph;
    default:
      return _flagGlyph;
  }
}

/// The accent color for a quest category.
Color categoryColor(AppPalette p, String questType) {
  switch (questType) {
    case QuestType.location:
      return p.locationQuest;
    case QuestType.social:
      return p.socialQuest;
    case QuestType.action:
      return p.actionQuest;
    default:
      return p.primaryLight;
  }
}

/// Square pixel badge showing a quest category's sprite and accent color.
class CategoryIcon extends StatelessWidget {
  final String questType;
  final double size;

  const CategoryIcon({super.key, required this.questType, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final color = categoryColor(palette, questType);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: AppRadius.rSmall,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: PixelGlyph(
          categoryGlyph(questType),
          color: color,
          size: size * 0.55,
        ),
      ),
    );
  }
}
