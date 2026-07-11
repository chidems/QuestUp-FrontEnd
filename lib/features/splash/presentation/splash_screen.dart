import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_palette.dart';
import '../../../shared/widgets/pixel_glyph.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';

const _kWordmark = 'assets/branding/questup_wordmark_splash_transparent.png';

/// Minimum time the splash stays up so the intro animation always lands,
/// even when the session restore resolves instantly.
const _kMinDisplay = Duration(milliseconds: 2100);

// Chunky pixel plus, matching the sparkles in the app icon art.
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

/// Branded boot screen: shows the wordmark with ambient pixel effects while
/// the stored session is restored, then fades out and hands off to the
/// router (which maps to home or login).
///
/// Always renders with the dark palette — the wordmark asset is designed for
/// a dark backdrop, and a dark boot reads correctly in both app themes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  static const _palette = AppPalette.dark;

  /// One-shot entrance: wordmark fade/rise, then sparkles and loading dots.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  /// Long repeating loop driving embers, glow, sparkles and dots. Everything
  /// derived from it uses whole cycles per loop so the wrap is seamless.
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  );

  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );

  late final List<_EmberSpec> _embers = _EmberSpec.scatter(math.Random(7));

  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Decode the wordmark before the fade-in reveals it.
    if (!_precached) {
      _precached = true;
      precacheImage(const AssetImage(_kWordmark), context);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    _exit.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    // On a cold start Dart runs well before the first frame reaches the
    // screen; anchor the intro and the minimum display time to the moment
    // pixels are actually visible, or the animation plays out unseen behind
    // the OS launch screen.
    await WidgetsBinding.instance.waitUntilFirstFrameRasterized;
    if (!mounted) return;
    _intro.forward();
    _ambient.repeat();
    await Future.wait<void>([
      Future<void>.delayed(_kMinDisplay),
      // Session restore never throws (AuthRepository catches), but guard so
      // a failure can never strand the user on the splash.
      ref.read(authStateProvider.future).then<void>((_) {}).catchError((_) {}),
    ]);
    if (!mounted) return;
    // "App opened" is the trigger for the daily streak reminder (see
    // SettingsNotifier.syncStreakReminderForAppOpen); only meaningful once
    // there's a signed-in streak to protect.
    if (ref.read(authStateProvider).value != null) {
      await ref.read(settingsProvider.future);
      await ref.read(settingsProvider.notifier).syncStreakReminderForAppOpen();
    }
    await _exit.forward();
    if (!mounted) return;
    // Always aim for home; the router redirect bounces to login when the
    // session didn't restore.
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoW = math.min(size.width * 0.78, 420.0);
    final logoH = logoW * (438 / 1395);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _palette.surfaceDeep,
        body: FadeTransition(
          opacity: Tween(begin: 1.0, end: 0.0).animate(
            CurvedAnimation(parent: _exit, curve: Curves.easeOut),
          ),
          child: AnimatedBuilder(
            animation: Listenable.merge([_intro, _ambient]),
            builder: (context, _) {
              final t = _ambient.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
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
                  ),
                  CustomPaint(painter: _EmberPainter(_embers, t)),
                  // Vignette pulls focus to the center.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.1,
                        colors: [Colors.transparent, Color(0x590C0E1E)],
                        stops: [0.6, 1.0],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _wordmark(logoW, logoH, t),
                        SizedBox(height: logoH * 0.55),
                        _loadingDots(t),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Wordmark with a breathing glow behind it and pixel sparkles around it.
  Widget _wordmark(double w, double h, double t) {
    final entrance = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    );
    // 4s breathing cycle (5 whole cycles per 20s loop keeps the wrap smooth).
    final breathe = math.sin(2 * math.pi * 5 * t);

    return FadeTransition(
      opacity: entrance,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(entrance),
        child: ScaleTransition(
          scale: Tween(begin: 0.94, end: 1.0).animate(entrance),
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: -w * 0.25,
                  top: -h * 0.6,
                  child: IgnorePointer(
                    child: Container(
                      width: w * 1.5,
                      height: w * 1.5 * 0.55,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            _palette.accent
                                .withValues(alpha: 0.09 + 0.03 * breathe),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Image.asset(
                  _kWordmark,
                  width: w,
                  // Downscaling a high-res asset: linear sampling avoids the
                  // shimmer nearest-neighbor would add.
                  filterQuality: FilterQuality.medium,
                ),
                _sparkle(_plusGlyph, _palette.accent,
                    left: -w * 0.055, top: -h * 0.14, size: w * 0.058,
                    cycles: 11, phase: 0.0, t: t),
                _sparkle(_diamondGlyph, _palette.rarityUncommon,
                    left: w * 1.005, top: h * 0.34, size: w * 0.040,
                    cycles: 13, phase: 0.35, t: t),
                _sparkle(_plusGlyph, _palette.primaryLight,
                    left: w * 0.30, top: -h * 0.34, size: w * 0.044,
                    cycles: 9, phase: 0.6, t: t),
                _sparkle(_diamondGlyph, _palette.accent,
                    left: -w * 0.10, top: h * 0.72, size: w * 0.034,
                    cycles: 15, phase: 0.82, t: t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sparkle(
    List<String> glyph,
    Color color, {
    required double left,
    required double top,
    required double size,
    required int cycles,
    required double phase,
    required double t,
  }) {
    // Sparkles hold back until the wordmark has landed.
    final gate = const Interval(0.55, 1.0, curve: Curves.easeOut)
        .transform(_intro.value);
    final wave = 0.5 + 0.5 * math.sin(2 * math.pi * (cycles * t + phase));
    final twinkle = wave * wave;
    return Positioned(
      left: left,
      top: top,
      child: Opacity(
        opacity: gate * (0.15 + 0.75 * twinkle),
        child: Transform.scale(
          scale: 0.75 + 0.35 * twinkle,
          child: PixelGlyph(glyph, color: color, size: size),
        ),
      ),
    );
  }

  /// Retro loading indicator: three squares stepping in discrete beats
  /// (3 steps/sec; the fourth beat rests with all dim).
  Widget _loadingDots(double t) {
    final gate = const Interval(0.7, 1.0, curve: Curves.easeOut)
        .transform(_intro.value);
    final step = (t * 60).floor() % 4;
    return Opacity(
      opacity: gate,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Container(
              width: 9,
              height: 9,
              color: step == i
                  ? _palette.accent
                  : _palette.surfaceVariant.withValues(alpha: 0.8),
            ),
          ],
        ],
      ),
    );
  }
}

/// A drifting background pixel: mostly dim slate squares with the occasional
/// gold or teal one, rising slowly like the embers in the app icon art.
class _EmberSpec {
  final double xFrac;
  final double sizePx;
  final int cycles; // whole climbs per ambient loop, so the wrap is seamless
  final double phase;
  final Color color;

  const _EmberSpec(this.xFrac, this.sizePx, this.cycles, this.phase, this.color);

  static List<_EmberSpec> scatter(math.Random rng) {
    const slate = Color(0xFF454B7E);
    const gold = Color(0xFFF0A830);
    const teal = Color(0xFF20D4BE);
    return List.generate(18, (i) {
      final accentRoll = rng.nextDouble();
      final color = accentRoll < 0.12
          ? gold.withValues(alpha: 0.20)
          : accentRoll < 0.2
              ? teal.withValues(alpha: 0.16)
              : slate.withValues(alpha: 0.14 + rng.nextDouble() * 0.18);
      return _EmberSpec(
        rng.nextDouble(),
        2.5 + rng.nextDouble() * 3.0,
        1 + rng.nextInt(3),
        rng.nextDouble(),
        color,
      );
    });
  }
}

class _EmberPainter extends CustomPainter {
  final List<_EmberSpec> embers;
  final double t;

  _EmberPainter(this.embers, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var i = 0; i < embers.length; i++) {
      final e = embers[i];
      final progress = (e.phase + t * e.cycles) % 1.0;
      final y = size.height * (1.0 - progress);
      // Gentle horizontal sway; fade in near the bottom, out near the top.
      final x = size.width * e.xFrac +
          math.sin(2 * math.pi * (2 * t) + i * 1.7) * 6;
      final fade = math.sin(math.pi * progress);
      paint.color = e.color.withValues(alpha: e.color.a * fade);
      canvas.drawRect(Rect.fromLTWH(x, y, e.sizePx, e.sizePx), paint);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter oldDelegate) => oldDelegate.t != t;
}
