# Quest Up — UI/UX Design Review & Roadmap

> Expert design critique of the Flutter frontend, grounded in code review (2026-06-11).
> Lens: Material 3 principles + pixel-art RPG visual identity per project spec.

## What's genuinely good

1. **Real design system, not ad-hoc styling.** `AppPalette` as a `ThemeExtension` with
   `context.colors`, semantic tokens (rarity tiers, quest categories, XP/coin colors),
   and proper `lerp` for theme transitions.
2. **Distinctive visual identity.** Chunky offset-shadow `pixelBorder()` technique,
   `BorderRadius.zero` everywhere, press-down `PixelButton` animation — sells the RPG
   feel without image assets.
3. **Thoughtful M3 fundamentals.** `useMaterial3: true`, complete `ColorScheme`, themed
   inputs/snackbars/cards, light/dark parity, 48px min button height.
4. **Good UX details:** actionable location-error states ("Open settings" vs "Retry"),
   pull-to-refresh, persistent HUD with XP/coins/streak.

## Critical issues

### 1. Design system only half-adopted
- `ElevatedButton` (generic M3) used in 7 files — login, register, NPC modal, feed
  errors, store item card, error view, and the reward modal's "Awesome!" button —
  while `PixelButton` appears in only 2 screens.
- Feed loading uses bare `CircularProgressIndicator`; `_EmptyQuests` duplicates
  `empty_state.dart`.
- HUD XP bar is a rounded `LinearProgressIndicator` (breaks the "hard rectangular
  edges" rule) instead of `PixelProgressBar`.

### 2. Zero motion design
No `AnimationController` / `TweenAnimationBuilder` / `AnimatedSwitcher` / `Hero`
anywhere except PixelButton's 60ms press. Rewards pop in statically, XP bars jump,
level-ups don't celebrate, screens cut instead of transition.

### 3. Typography undermines the pixel identity
Default Roboto everywhere; text theme only recolors. A pixel/fantasy display font
(Press Start 2P / VT323) for headings + HUD numerals — never for body text — would do
more for the RPG feel per hour than anything else.

### 4. Accessibility nearly absent
- Two `Semantics`/`tooltip` references in the whole app.
- HUD chips are icon+number with no labels.
- `PixelButton` is a raw `GestureDetector` — invisible to screen readers, no focus
  state, no min tap-target enforcement.
- `textMuted` (#9090B8) on surface (#353868) ≈ 3.2:1 — below WCAG AA for small text.

## Moderate issues

5. **M2 nav bar.** `BottomNavigationBar` instead of M3 `NavigationBar` (or better: a
   custom pixel-styled nav to match the chrome).
6. **Store buried in app-bar overflow.** Earn-coins → spend-coins is the core retention
   loop; the store deserves nav-bar presence or HUD coin-chip entry.
7. **`PixelBox` tap feedback is dead.** Quest cards give zero touch feedback;
   PixelButton already solved this pattern.
8. **Reward modal is a list, not a moment.** Static rows where a staggered reveal
   (XP count-up → coins → items punch in) should be.
9. **Dialogs bypass the pixel border.** Reward + NPC modals use flat 2px `BorderSide`
   instead of `pixelBorder()`.

## Minor

10. `_HudChip` / `_MetaChip` / `_RewardStat` are near-identical — one shared `StatChip`.
11. `textSecondary == textBody` in both palettes — dead distinction.
12. HUD XP uses hardcoded `% 100` placeholder (misleading at high levels in demos).

---

# Roadmap (ordered by impact ÷ effort)

## Phase A — Consistency sweep (~1 day) · highest ROI
1. Replace all 7 `ElevatedButton` sites with `PixelButton` (reward modal first).
2. Swap HUD `LinearProgressIndicator` → `PixelProgressBar`.
3. Use `EmptyState` / `LoadingView` / `ErrorView` shared widgets in the feed.
4. Apply `pixelBorder()` to both dialogs.
5. Add pressed-state feedback to `PixelBox.onTap`.

**Verify:** `grep -r "ElevatedButton(" lib/features lib/shared` returns nothing;
visual pass in mock mode; `flutter analyze` clean.

## Phase B — Typography & identity (~1 day)
6. Add `google_fonts`; pixel display font for headings/app bar/HUD numerals/buttons;
   readable font for body.
7. Explicit `TextTheme` scale (sizes, weights, letter-spacing); remove inline styles.

**Verify:** screenshots of all 12 screens, light + dark.

## Phase C — Motion & juice (2–3 days) · biggest felt improvement
8. Reward modal: staggered reveal + XP count-up + scale-in trophy; haptics on
   reward (medium) and level-up (heavy).
9. Animate `PixelProgressBar` fills.
10. Staggered feed-card entrance; GoRouter fade-through transitions.
11. Level-up celebratory overlay (pixel squares as particles).

## Phase D — Navigation & IA (1–2 days)
12. Custom pixel-styled bottom nav (or restyled M3 `NavigationBar`); Store as 5th tab.
13. HUD coin chip tap → Store.

## Phase E — Accessibility (~1 day)
14. `Semantics(button: true)` on PixelButton/PixelBox; 48dp min targets.
15. Label HUD chips; lift `textMuted` contrast to ≥4.5:1.

**Verify:** TalkBack pass on the core loop.

## Phase F — Asset integration (when real pixel art lands)
16. Replace `CategoryIcon` / `ItemThumbnail` placeholders; consider 9-slice panel
    frames over BoxShadow borders for richer chrome.

**Suggested order: A → C → B → D → E → F.**

## Status
- [x] Phase A — done 2026-06-11 (all generic buttons → PixelButton incl. avatar
      Equip; HUD bar → PixelProgressBar; feed uses LoadingView/EmptyState; both
      dialogs use pixelBorder(); PixelBox press feedback; PixelButton gained
      optional textColor)
- [x] Phase B — done 2026-06-11 (google_fonts + Press Start 2P for
      display/headline/titleLarge/labelLarge, app-bar titles, nav labels,
      PixelButton labels, HUD numerals, login wordmark; explicit TextTheme
      scale; body text stays system font for readability. Note: google_fonts
      fetches at first run then caches — bundle the TTF in Phase F for fully
      offline demos.)
- [x] Phase C — done 2026-06-11 (reward modal staggered reveal + XP/coin count-up
      + haptics + PixelConfetti on level-up; animated PixelProgressBar fills;
      fade-through transitions on pushed routes; staggered feed-card entrance.
      Level-up celebration implemented as confetti within the reward modal
      rather than a global overlay.)
- [x] Phase D — done 2026-06-11 (custom _PixelNavBar in app_scaffold.dart:
      chunky top border, pixel labels, indicator notch, selection haptics;
      Store promoted to 5th shell branch between Avatar and Profile; avatar
      shop icon now go() instead of push(); HUD coin chip taps through to
      Store.)
- [x] Phase E — done 2026-06-11 (PixelButton/PixelBox wrapped in Semantics
      button nodes; both now fire callbacks from onTap so GestureDetector
      exposes a semantic tap action — they fired from onTapUp before, which
      made them un-activatable by TalkBack. PixelButton enforces a 48dp min
      target via inner ConstrainedBox; HUD coin chip got a 48dp target. HUD
      chips read as "N coins. Opens shop." / "N day streak" with the raw
      icon+number excluded; HUD XP bar labeled with a percent value; nav
      items are merged button nodes with selected state. textMuted lifted
      for ≥4.5:1 on surface AND surfaceVariant: dark #9CA0C4→#ACB0D2,
      light #8A7A5A→#665B43. Stale ItemCard test (still expected
      ElevatedButton from pre-Phase-A) updated to PixelButton. Remaining
      manual check: TalkBack pass on a device/emulator.)
- [x] Phase F — done 2026-06-12 (Press Start 2P TTF bundled in assets/fonts
      + declared in pubspec; google_fonts dependency removed, so demos work
      fully offline. Nav-bar pixel painter extracted to shared
      PixelGlyph widget; CategoryIcon's Material icons replaced with
      hand-drawn 12x12 sprites (map pin / two figures / bolt / flag);
      ItemThumbnail placeholders replaced with per-type sprites (hat,
      tunic, pants, boot, sword, gem, framed scene, chest fallback) —
      still swapped out automatically when a real imageUrl is present.
      9-slice panel frames deferred until real art assets exist.)
- [x] Real art integration — done 2026-06-12 (705 sprites in sprites/ bundled:
      16 skins, 24 eye colors, 112 hairstyles, 465 clothes, 84 shop items.
      Catalog generated by tool/gen_catalog.dart into asset_catalog.g.dart;
      AvatarPreview composites layers with empirically tuned anchors
      (tool/composite_test.ps1); Hero screen is now a full appearance editor;
      shop sells the 84 props with a persisted mock wallet.)

## Feedback round 1 (2026-06-11, after emulator review)
User-reported issues and the fixes applied:
- **Color scheme** → refined dark palette: deeper bg `#1E2138`, clearer surface
  steps, brighter primary `#9B7BD8`, near-white `textPrimary #ECE6F2`; gold now
  reserved for currency/rewards. Light palette untouched.
- **Tab organization** → 4 tabs: Quests · Events · Hero · Stats (user picked
  4-tab option; Shop demoted back to pushed route, reachable via Hero app-bar
  icon + HUD coin chip; screen titles renamed Hero/Stats).
- **Nav label cropping** → tight label metrics (7px, height 1.0) + FittedBox
  scale-down; roomier 4-tab layout.
- **Nav icons** → hand-drawn 12x12 pixel glyphs (sword/banner/helmet/shield)
  via CustomPainter in app_scaffold.dart; active tab gets animated plate +
  elastic pop + color shift.
- **Store chips too big** → custom compact pixel chips (hard rect, 1px border),
  row 48→38px.
- **Shop cards** → sprite-slot backdrop plate, tighter text, Spacer pins action
  to bottom (kills stranded whitespace), grid aspect 0.72→0.80.
- **Card borders** → default pixelBorder thinned 2px→1.5px app-wide (buttons
  keep their chunkier bevel).
