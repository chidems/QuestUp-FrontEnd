import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_palette.dart';
import 'pixel_glyph.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AppScaffold({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: _PixelNavBar(
        currentIndex: shell.currentIndex,
        onTap: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
      ),
    );
  }
}

/// Hand-drawn 12x12 pixel glyphs for the nav tabs ('X' = filled cell).
const _swordGlyph = [
  '........XX..',
  '.......XXXX.',
  '......XXXX..',
  '.....XXXX...',
  '.X..XXXX....',
  '.XX.XXX.....',
  '..XXXX......',
  '..XXX.......',
  '.XX.XX......',
  'XX...X......',
  '............',
  '............',
];

const _bannerGlyph = [
  '............',
  '.XXXXXXXXXX.',
  '.XXXXXXXXXX.',
  '.XXXXXXXXXX.',
  '.XXXXXXXXXX.',
  '.XXXXXXXXXX.',
  '.XXXX..XXXX.',
  '.XXX....XXX.',
  '.XX......XX.',
  '............',
  '............',
  '............',
];

const _helmetGlyph = [
  '............',
  '...XXXXXX...',
  '..XXXXXXXX..',
  '.XXXXXXXXXX.',
  '.XXXXXXXXXX.',
  '.XX......XX.',
  '.XXXXXXXXXX.',
  '.XXXXXXXXXX.',
  '..XX.XX.XX..',
  '............',
  '............',
  '............',
];

const _shieldGlyph = [
  '............',
  '.XXXXXXXXXX.',
  '.XXXXXXXXXX.',
  '.XX......XX.',
  '.XX.XXXX.XX.',
  '.XX.XXXX.XX.',
  '.XX......XX.',
  '..XX....XX..',
  '...XX..XX...',
  '....XXXX....',
  '.....XX.....',
  '............',
];

/// Pixel-styled bottom navigation: chunky top border, hand-drawn pixel
/// glyphs, an animated plate + pop on the active tab, pixel-font labels.
class _PixelNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PixelNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    (_swordGlyph, 'Quests'),
    (_bannerGlyph, 'Events'),
    (_helmetGlyph, 'Hero'),
    (_shieldGlyph, 'Stats'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.borderDeep, width: 3)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: _NavItem(
                  glyph: _items[i].$1,
                  label: _items[i].$2,
                  selected: i == currentIndex,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final List<String> glyph;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.glyph,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final color = selected ? p.primaryLight : p.textMuted;
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              // Plate slides in behind the active glyph; glyph pops slightly.
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: selected ? p.surfaceDeep : Colors.transparent,
                  border: Border.all(
                    color: selected ? p.border : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: AnimatedScale(
                  scale: selected ? 1.15 : 1.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.elasticOut,
                  child: PixelGlyph(glyph, color: color, size: 22),
                ),
              ),
              const SizedBox(height: 4),
              // Tight metrics + scale-down so labels never crop on narrow tabs.
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 7,
                    height: 1.0,
                    letterSpacing: 0,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 7),
            ],
          ),
        ),
      ),
    );
  }
}

