import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_palette.dart';

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

/// Pixel-styled bottom navigation: chunky top border, painterly pixel-art
/// icons (assets/branding/nav), an animated plate + pop on the active tab,
/// pixel-font labels. The full-color art can't be state-tinted like the old
/// monochrome glyphs, so inactive tabs desaturate + dim instead.
class _PixelNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _PixelNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    ('assets/branding/nav/nav_quests.png', 'Quests'),
    ('assets/branding/nav/nav_map.png', 'Map'),
    ('assets/branding/nav/nav_events.png', 'Events'),
    ('assets/branding/nav/nav_hero.png', 'Hero'),
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
                  asset: _items[i].$1,
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

/// Rec. 709 luma weights — turns the gold art grey for inactive tabs.
const _desaturate = ColorFilter.matrix([
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
]);

class _NavItem extends StatelessWidget {
  final String asset;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.asset,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    final color = selected ? p.primaryLight : p.textMuted;

    Widget icon = Image.asset(
      asset,
      width: 30,
      height: 30,
      // Pixel art: hard edges, no smoothing.
      filterQuality: FilterQuality.none,
    );
    if (!selected) {
      icon = Opacity(
        opacity: 0.55,
        child: ColorFiltered(colorFilter: _desaturate, child: icon),
      );
    }
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
                  child: icon,
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

