# Onboarding: Quest Preferences — Implementation Plan

Handoff spec for building a first-time-user preferences flow. Grounded in the actual QuestUp-FrontEnd (Flutter) and Quest-Up (FastAPI) codebases — every field, endpoint, widget, and file path below is real, not illustrative.

## 1. Goal & trigger

Right after a user registers (not on every login), show a short, game-flavored wizard that sets three real backend preferences before they land on the quest feed:

- `preferred_quest_types` — which of the 3 quest types (`location`, `social`, `action`) they want
- `preferred_difficulty` — 1–5, how hard quests should start
- `preferred_radius_km` — how far they're willing to roam

These are not cosmetic — `recommendation_service.py` filters by `preferred_quest_types`, `quest_generation_service.py` uses `preferred_difficulty` as `base_difficulty`, and both use `preferred_radius_km`. So the onboarding answers directly shape the first quests the user sees. That's worth telling Fable explicitly, because it means the copy can honestly say "this decides what quests you get" — not empty flavor text.

**Assumption flagged:** the backend has no `onboarding_completed` flag today, so there's no way to know "has this user seen onboarding" if they reinstall or log in on a new device. Section 5 proposes adding one column — it's the one required backend change. Without it, the fallback is a local-only flag keyed by user id (works for the common case, silently re-prompts on a new device). I recommend the backend column; it's a two-line model change plus a migration, and it's the honest fix.

## 2. Recommended flow — 3 screens, not 4

The three real preferences naturally group into two questions (quest types is its own decision; difficulty and radius are both "how big an adventure" and fit on one screen together) plus a payoff screen. That keeps it to what you asked for — "a couple of screens" — while still hitting all three fields.

```
Register success
      │
      ▼
┌─────────────────┐   ┌─────────────────────┐   ┌──────────────────────┐
│ 1. Quest Style   │──▶│ 2. Adventure Level   │──▶│ 3. Adventurer Profile │──▶ /home
│ (multi-select)   │   │ (difficulty + radius)│   │ (reveal + confirm)   │
└─────────────────┘   └─────────────────────┘   └──────────────────────┘
   "Skip for now" on 1 & 2 → jumps straight to step 3's submit with defaults, no reveal ceremony.
```

Total interaction: 2 taps to pick quest types (or accept the pre-checked defaults), 2 taps to set difficulty + drag one slider, 1 tap to confirm. Roughly 15–20 seconds for someone who just accepts defaults, longer if they want to fine-tune.

If you'd rather have one control per screen for more pacing/delight (4 screens instead of 3), that's a fine variant — split step 2 into "Challenge" and "Roaming Range" separately. I'd default to the 3-screen version since "not too long" was explicit.

### Screen 1 — "Choose Your Quest Style"

Multi-select cards, **all three pre-checked** (matches the backend's own default of `["location","social","action"]`, so skipping or backing out never produces an empty selection). At least one must stay checked.

| Card | Glyph / color (existing) | Title | Subtext |
|---|---|---|---|
| Location | `categoryGlyph(QuestType.location)` / `p.locationQuest` | Explorer | Discover spots near you |
| Social | `categoryGlyph(QuestType.social)` / `p.socialQuest` | Socialite | Quests with other people |
| Action | `categoryGlyph(QuestType.action)` / `p.actionQuest` | Go-Getter | Get up and get moving |

Headline: **"CHOOSE YOUR QUEST STYLE"** (pixel font, matches `RegisterScreen`'s `CREATE ACCOUNT` styling)
Subtext: "Pick the adventures that sound fun. You can change this anytime in Settings."
Primary CTA: `PixelButton` "Next"
Secondary: small "Skip for now" text link, top-right.

### Screen 2 — "Set Your Adventure Level"

Two compact controls on one screen:

**(a) Challenge** — 5-tier segmented picker, one tap. Reuse the palette's existing 5-step rarity ramp (`rarityCommon → rarityLegendary`) so the tiers read as a familiar progression instead of new colors:

| Tier | Difficulty value | Color |
|---|---|---|
| Novice | 1 | `rarityCommon` |
| Apprentice | 2 | `rarityUncommon` |
| Adventurer | 3 | `rarityRare` |
| Hero | 4 | `rarityEpic` |
| Legend | 5 | `rarityLegendary` |

Default selection: **Adventurer (3)** — a sane middle default rather than leaving it null.
Subtext: "How much of a challenge do you want your quests to be?"

**(b) Roaming Range** — slider, 0.5–10 km, default 2 km. Deliberately reuses the exact range, step count, and default already in `SettingsScreen`'s radius slider (`min: 0.5, max: 10, divisions: 19`) so onboarding and Settings feel like the same control, not two different sliders that happen to do the same thing. (Backend allows up to 50 km — leave the wider range as a Settings-only "advanced" option, not part of onboarding.)
Subtext: "How far are you willing to roam for a quest?"

Headline: **"SET YOUR ADVENTURE LEVEL"**

### Screen 3 — "Your Adventurer Profile" (reveal, no skip)

The payoff screen — this is where "interesting" comes from, and it's built entirely from components that already exist:

- `PixelConfetti` burst on entrance (same widget used for level-ups)
- A `PixelBox` summary card containing:
  - A row of `CategoryIcon` chips, one per selected quest type
  - A tier chip in the style of `RarityBadge`, showing the chosen difficulty tier name/color
  - A line of text: "X km roam radius"
  - Optionally, the user's default hero via the existing `AvatarPreview` widget (`lib/features/avatar/presentation/avatar_preview.dart`) alongside the card, so the reveal feels personal, not just a settings recap
- A one-line personalized headline composed from the picks, e.g. "You're an Explorer & Go-Getter, ready for Hero-tier quests." (plain string template — no new copy system needed)
- `PixelButton` "Start Questing" (full width, primary) — fires the single `PUT /profile` call (see §4) with everything collected, plus `onboarding_completed: true`, then navigates to `/home`.

"Skip for now" from screens 1–2 bypasses this screen entirely: it submits immediately with whatever was chosen so far plus remaining defaults, sets `onboarding_completed: true`, and goes straight to `/home`. Skippers don't owe you a ceremony they opted out of.

## 3. Visual design — reuse, don't invent

Everything above maps to widgets that already exist in `lib/shared/widgets/`:

| Need | Existing widget | New code needed |
|---|---|---|
| Card backgrounds, tap feedback | `PixelBox` | none |
| Buttons | `PixelButton` | none |
| Quest-type icons + colors | `CategoryIcon`, `categoryGlyph()`, `categoryColor()` in `category_icon.dart` | none — reuse directly |
| Difficulty tier colors | `rarityColor()` / `RarityBadge` pattern in `rarity_badge.dart` | none — reuse the color ramp; tier *names* (Novice…Legend) are new but it's just a `Map<int,String>` constant |
| Confetti | `PixelConfetti` | none |
| Screen chrome (dark gradient backdrop, centered scroll column) | `AuthShell`'s pattern in `auth_shell.dart` | new `OnboardingShell` widget, same backdrop/centering approach but with a step progress indicator (e.g. 3 dots) and skip link instead of the wordmark/back-arrow header |

Typography and color: use `context.colors` and the existing text theme exactly as every other screen does — pixel font (`PressStart2P`) for headlines via the theme's existing style, system font for body copy. Don't introduce new colors; everything above already exists in `AppPalette`.

## 4. Data mapping (question → backend field)

| Screen | User input | Backend field | Endpoint |
|---|---|---|---|
| 1 | Selected quest types | `preferred_quest_types: string[]` | `PUT /profile` |
| 2a | Selected tier | `preferred_difficulty: int (1-5)` | `PUT /profile` |
| 2b | Slider value | `preferred_radius_km: float` | `PUT /profile` |
| 3 (submit) | — | `onboarding_completed: true` | `PUT /profile` |

One batched `PUT /profile` call on the final "Start Questing" tap (or on skip) — not one call per screen. `ProfileUpdate` on the backend already treats every field as optional and only applies what's sent (`model_dump(exclude_unset=True)`), so this is a clean fit with no backend logic changes beyond the new field.

## 5. Backend changes required

Exactly one addition: an `onboarding_completed` flag on `user_profiles`, defaulting to `false`. Nothing else about `/profile` needs to change — `preferred_quest_types`, `preferred_difficulty`, and `preferred_radius_km` are already fully wired end-to-end (model, schema, route, and consumed by `recommendation_service.py` / `quest_generation_service.py`).

**`app/models/user.py`** — add to `UserProfile`:
```python
onboarding_completed: Mapped[bool] = mapped_column(Boolean, default=False)
```
No change needed to `auth_service.py`'s `UserProfile(user_id=user.id)` — it already relies on column defaults for everything else, so the new column just falls in line.

**`app/schemas/profile.py`**:
```python
class ProfileOut(BaseModel):
    ...
    onboarding_completed: bool

class ProfileUpdate(BaseModel):
    ...
    onboarding_completed: bool | None = None
```

**Migration** — new file in `alembic/versions/`, following the existing naming convention (`YYYYMMDD_NNNN_description.py`, e.g. `20260714_0004_onboarding_completed.py`):
```python
op.add_column("user_profiles", sa.Column("onboarding_completed", sa.Boolean(), nullable=False, server_default="false"))
```

No route changes to `app/api/routes/profile.py` — the existing `GET`/`PUT /profile` handlers already loop over whatever fields are set.

## 6. Frontend architecture changes

Follows the existing feature-first layering (`Widget → Provider → Repository → Api → Dio`) and extends the **existing** `profile` feature rather than duplicating it — quest preferences are profile data, so they belong there, not in a separate "onboarding" data layer.

**`lib/features/profile/models/profile_models.dart`** — add a `UserProfile` model (the feature currently only has `LifeStats`):
```dart
class UserProfile {
  final double preferredRadiusKm;
  final int? preferredDifficulty;
  final List<String> preferredQuestTypes;
  final bool onboardingCompleted;
  // fromJson (snake_case backend keys), toUpdateJson({only changed fields})
}
```

**`lib/features/profile/data/profile_api.dart`** — add, mirroring the existing `getStats()` pattern (including its `USE_MOCK_API` branch):
```dart
Future<UserProfile> getProfile();
Future<UserProfile> updateProfile(UserProfile updates); // PUT /profile
```

**`lib/features/profile/data/profile_repository.dart`** — add pass-through methods `getProfile()` / `updateProfile()`.

**`lib/features/profile/providers/profile_provider.dart`** — add:
```dart
final userProfileProvider = FutureProvider<UserProfile>(
  (ref) => ref.read(profileRepositoryProvider).getProfile(),
);
```
This also becomes the thing the router redirect reads to decide whether to send a freshly-authenticated user to `/onboarding` vs `/home` — see §7.

**New feature folder `lib/features/onboarding/`** (screens only — no new data/model layer, since it writes through the `profile` feature above):
```
lib/features/onboarding/
  providers/onboarding_flow_provider.dart   # local wizard state: step index, selected quest types, difficulty, radius
  presentation/
    onboarding_shell.dart                   # backdrop + progress dots + skip link
    quest_style_screen.dart                 # screen 1
    adventure_level_screen.dart             # screen 2
    adventurer_reveal_screen.dart           # screen 3
    onboarding_screen.dart                  # hosts the 3 screens in a PageView/step switch, single route
```
`onboarding_flow_provider.dart` is a plain `Notifier` (in-memory, no persistence needed mid-flow — if the app is killed mid-onboarding, restarting just re-shows the wizard, which is correct behavior since `onboarding_completed` is still `false`).

## 7. Routing

`RouteNames.onboarding = '/onboarding'` already exists in `route_names.dart` but is unregistered and unused — this is the first thing that actually wires it up.

**`app_router.dart`** changes:
1. Register the route: `GoRoute(path: RouteNames.onboarding, builder: (_, __) => const OnboardingScreen())`.
2. Update the `redirect` callback. Today it does: authenticated + on an auth screen → `/home`. Change to: authenticated + on an auth screen or splash-exit → check `userProfileProvider`; if still loading, don't redirect yet (same pattern already used for `authValue.isLoading`); once loaded, `onboardingCompleted == false` → `/onboarding`, else → `/home`. Also add: authenticated + `onboardingCompleted == false` + NOT already on `/onboarding` → redirect to `/onboarding` (covers a killed-app resume mid-flow).
3. `userProfileProvider` should be invalidated (or the redirect notifier pinged) on the final onboarding submit so the redirect re-evaluates and naturally falls through to `/home` once `onboarding_completed` flips to `true` — no manual `context.go('/home')` needed if the redirect logic is doing its job, though an explicit `context.go(RouteNames.home)` after a successful submit is simpler and fine too.

This is the one place where I'd double check with you before Fable builds it: reading `userProfileProvider` synchronously inside `redirect` needs the same "don't redirect while loading" guard the auth check already uses, and it's worth Fable writing a quick test (or at least a manual run-through) of: fresh register → onboarding shows → submit → home; existing user login → straight to home; kill app mid-onboarding → resume → onboarding shows again.

## 8. Image/asset requirements

**Required new assets: none.** Every screen above is built from widgets and hand-drawn `PixelGlyph` string-art that already exist — this matches how the rest of the app works today (quest categories, NPC modal, bottom nav glyphs, sparkles are all code-drawn; the only real PNG assets in the whole app are the wordmark, app icon, and 4 tiny bottom-nav icons). Difficulty tiers use the existing rarity color ramp; quest-type icons reuse `categoryGlyph()`. New code (not art): a `Map<int, String>` of tier names, and a small set of progress-dot/skip-link widgets for `OnboardingShell`.

**Optional polish** (skip for MVP, revisit if the reveal screen feels flat once built):
- A single small pixel-art hero illustration for the reveal screen background (same style/artist as `questup_wordmark_splash_transparent.png` and the `assets/branding/nav/` icons — transparent PNG, similar file size class as the nav icons, ~2–3 KB). Would live at `assets/branding/questup_onboarding_hero.png`.
- Custom 12×12 `PixelGlyph` patterns for the difficulty tiers (a small sword/shield motif per tier) instead of plain color chips, if you want the challenge picker to feel as illustrated as the quest-type cards.

Neither is required to ship this; both are cheap to add later without touching the data/routing work.

## 9. Suggested build order (for Fable, each step independently verifiable)

1. **Backend**: add `onboarding_completed` column + migration + schema fields → verify: `alembic upgrade head` runs clean, `GET /profile` for a fresh user returns `onboarding_completed: false`, `PUT /profile {"onboarding_completed": true}` persists it.
2. **Frontend data layer**: `UserProfile` model, `ProfileApi.getProfile()/updateProfile()`, repository + `userProfileProvider` → verify: manual call against a running backend (or mock mode) returns the right shape.
3. **Onboarding UI**: build the 3 screens + shell against local wizard state only (no network yet) → verify: can navigate forward/back/skip through all 3 screens, selections persist across steps.
4. **Wire submission**: final screen's CTA and skip both call `updateProfile()` → verify: after submit, `GET /profile` reflects the choices.
5. **Routing**: register `/onboarding`, update redirect logic → verify the three scenarios listed in §7.
6. **Regression check**: existing users (already `onboarding_completed: true` after step 1's migration should probably backfill existing rows to `true` so current users aren't unexpectedly dropped into onboarding — flag this explicitly in the migration) log in and land on `/home` as before.

Note for step 6: the migration in §5 defaults new rows to `false`, but existing rows also get `false` via `server_default`. Decide explicitly whether existing users should see onboarding retroactively (probably not) — if not, the migration needs a one-time backfill: `UPDATE user_profiles SET onboarding_completed = true` for rows that existed before the migration ran, then leave the column default `false` for genuinely new rows going forward.
