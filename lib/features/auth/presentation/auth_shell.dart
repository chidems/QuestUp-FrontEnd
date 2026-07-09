import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/pixel_glyph.dart';

const _kWordmark = 'assets/branding/questup_wordmark_splash_transparent.png';

// Chunky pixel sparkles, matching the splash screen and app icon art.
const _plusGlyph = [
  '............',
  '............',
  '.....XX.....',
  '.....XX.....',
  '.....XX.....',
  '..XXXXXXXX..',
  '..XXXXXXXX..',
  '.....XX.....',
  '.....XX.....',
  '.....XX.....',
  '............',
  '............',
];

const _diamondGlyph = [
  '............',
  '............',
  '............',
  '.....XX.....',
  '....XXXX....',
  '...XXXXXX...',
  '...XXXXXX...',
  '....XXXX....',
  '.....XX.....',
  '............',
  '............',
  '............',
];

/// Shared scaffold for the auth screens: the splash's dark gradient backdrop,
/// the wordmark header, and a keyboard-safe scroll column that centers its
/// content on tall screens.
///
/// Always renders with the dark theme — the wordmark art is designed for a
/// dark backdrop, and it keeps the splash → auth handoff seamless in both
/// app themes.
class AuthShell extends StatefulWidget {
  final List<Widget> children;
  final double logoWidth;
  final String? tagline;

  /// Top-bar title (pixel font); the bar appears when this or [onBack] is set.
  final String? title;
  final VoidCallback? onBack;
  final bool sparkles;

  const AuthShell({
    super.key,
    required this.children,
    this.logoWidth = 300,
    this.tagline,
    this.title,
    this.onBack,
    this.sparkles = false,
  });

  @override
  State<AuthShell> createState() => _AuthShellState();
}

class _AuthShellState extends State<AuthShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _twinkle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    if (widget.sparkles) _twinkle.repeat();
  }

  @override
  void dispose() {
    _twinkle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.dark(),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Builder(builder: (context) {
          final palette = context.colors;
          return Scaffold(
            backgroundColor: palette.surfaceDeep,
            body: Container(
              decoration: const BoxDecoration(
                // Same backdrop as the splash screen, for a seamless handoff.
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF16182C),
                    Color(0xFF1E2138),
                    Color(0xFF0C0E1E),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    if (widget.title != null || widget.onBack != null)
                      _topBar(context),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 28),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: constraints.maxHeight,
                              ),
                              // Centers on tall screens; scrolls when the
                              // keyboard shrinks the viewport.
                              child: Center(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 420),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 24),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _header(context),
                                        const SizedBox(height: 36),
                                        ...widget.children,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    final palette = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            if (widget.onBack case final onBack?)
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                color: palette.textPrimary,
                tooltip: 'Back',
                onPressed: onBack,
              )
            else
              const SizedBox(width: 48),
            Expanded(
              child: Text(
                widget.title ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            // Balances the leading button so the title stays centered.
            const SizedBox(width: 48),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final w = widget.logoWidth;
    final h = w * (438 / 1395);
    return Column(
      children: [
        Center(
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Image.asset(
                  _kWordmark,
                  width: w,
                  // High-res asset scaled down: linear sampling avoids the
                  // shimmer nearest-neighbor would add.
                  filterQuality: FilterQuality.medium,
                ),
                if (widget.sparkles) ...[
                  _sparkle(_plusGlyph, const Color(0xFFF0A830),
                      left: -0.075 * w, top: -0.08 * h, size: 0.062 * w,
                      phase: 0.0),
                  _sparkle(_diamondGlyph, const Color(0xFF20D4BE),
                      left: 1.02 * w, top: 0.42 * h, size: 0.044 * w,
                      phase: 0.4),
                  _sparkle(_plusGlyph, const Color(0xFFC8A8F0),
                      left: 0.24 * w, top: -0.36 * h, size: 0.05 * w,
                      phase: 0.7),
                ],
              ],
            ),
          ),
        ),
        if (widget.tagline case final tagline?) ...[
          const SizedBox(height: 12),
          Text(
            tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Widget _sparkle(
    List<String> glyph,
    Color color, {
    required double left,
    required double top,
    required double size,
    required double phase,
  }) {
    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: _twinkle,
        builder: (_, _) {
          final wave =
              0.5 + 0.5 * math.sin(2 * math.pi * (_twinkle.value + phase));
          final pulse = wave * wave;
          return Opacity(
            opacity: 0.25 + 0.65 * pulse,
            child: Transform.scale(
              scale: 0.8 + 0.3 * pulse,
              child: PixelGlyph(glyph, color: color, size: size),
            ),
          );
        },
      ),
    );
  }
}

/// Thin divider with a small pixel-font label, e.g. `NEW ADVENTURER?`.
class AuthDivider extends StatelessWidget {
  final String label;

  const AuthDivider(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    return Row(
      children: [
        Expanded(child: Divider(color: palette.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(fontSize: 8, color: palette.textMuted),
          ),
        ),
        Expanded(child: Divider(color: palette.border, thickness: 1)),
      ],
    );
  }
}
