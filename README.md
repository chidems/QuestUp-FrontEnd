# Quest Up — Frontend

**Life is Full of Side Quests. Start Completing Them.**

Flutter mobile app for Quest Up, a location-aware RPG gamification platform that turns everyday life into real-world side quests.

---

## Flutter Version

Built with Flutter 3.x / Dart 3.x (`sdk: ^3.11.5`).

---

## Setup

```bash
flutter pub get
flutter run
```

For Android emulator the backend defaults to `http://10.0.2.2:8000`. For a physical device, pass a custom URL (see Environment Variables below).

---

## Run Modes

### With real backend
```bash
flutter run
```

### Mock mode (no backend needed)
```bash
flutter run --dart-define=USE_MOCK_API=true
```

Mock mode returns hardcoded data so the frontend can be developed in parallel with the backend.

### Custom backend URL
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
```

---

## Environment Variables (dart-define)

| Variable | Default | Description |
|---|---|---|
| `API_BASE_URL` | `http://10.0.2.2:8000` | Backend base URL |
| `USE_MOCK_API` | `false` | Use mock data instead of real API |

---

## Required Permissions

| Permission | When used |
|---|---|
| Location (fine) | Quest feed generation, walking mode |
| Camera | Quest completion photo |
| Photo library | Quest completion photo (gallery pick) |

Permissions are requested at the point of use with explanations. The app is usable without location (limited features).

---

## Folder Structure

```
lib/
  main.dart               — Entry point, ProviderScope
  app.dart                — MaterialApp.router wired to GoRouter
  core/
    config/app_config.dart        — API URL and feature flags
    constants/                    — AppColors, AppAssets, QuestConstants
    network/                      — Dio client, AuthInterceptor, ApiException
    routing/                      — AppRouter (GoRouter), RouteNames
    storage/                      — TokenStorage (secure), LocalCache (prefs)
    theme/app_theme.dart          — Dark RPG theme
    utils/result.dart             — Result<T> sealed class
  features/
    auth/                  — Login, Register, AuthProvider, AuthRepository
    onboarding/            — (Phase 2) Onboarding flow
    quests/                — (Phase 2) Quest feed, detail, completion
    weekly/                — (Phase 4) Weekly community quest
    npc/                   — (Phase 6) NPC encounter + walking mode
    profile/               — (Phase 2) Profile, stats
    achievements/          — (Phase 7) Achievements
    avatar/                — (Phase 5) Avatar customisation
    store/                 — (Phase 5) Coin shop
    history/               — (Phase 7) Quest history
    settings/              — (Phase 7) Settings
  shared/
    widgets/               — AppScaffold, PixelButton, LoadingView, ErrorView
```

---

## Screens Implemented

All MVP phases are complete.

- **Auth** — Login, Register, session restore on launch.
- **Quests** — Quest feed (HUD, weekly highlight, active quests, location states), quest detail, completion flow (photo capture/upload + reward summary).
- **Weekly** — Weekly community quest, community photo feed, optional share-after-completion.
- **Avatar & Store** — Avatar preview + inventory with equip, shop with type/rarity filters and buy/equip/owned states.
- **NPC & Walking** — Walking-mode banner, location tracking with 3-minute timer, NPC encounter modal (accept/decline).
- **Profile** — Avatar preview, level/XP/coins/streak, life-stat bars, recent achievements.
- **Achievements** — Grid with locked/unlocked + progress.
- **Quest History** — Completed quests with date and rewards.
- **Settings** — Search radius, quest category prefs (persisted), walking toggle, location access, privacy note, logout.

Navigation: bottom tabs (Quests / Weekly / Avatar / Profile); Store, Achievements, History, and Settings are pushed from Avatar/Profile.

---

## Architecture

```
Widget → Provider (Riverpod) → Repository → API client (Dio) → Backend
```

- State: `flutter_riverpod` (`AsyncNotifierProvider`)
- Navigation: `go_router` with auth guard redirect
- HTTP: `dio` with `AuthInterceptor` (injects Bearer token, clears on 401)
- Token storage: `flutter_secure_storage` (EncryptedSharedPreferences on Android)
- Local cache: `shared_preferences`

---

## Known Limitations (MVP)

- No background location tracking (foreground only; walking mode stops when the app is backgrounded).
- No token refresh — on 401 the user is redirected to login.
- No offline queue for completed quests.
- Avatar/NPC images use icon placeholders until real pixel-art assets are wired in (set non-null `image_url`s and the existing widgets render/layer them).
- Settings preferences (radius, categories) are stored locally only; not yet synced to the backend (`PUT /profile`).
- Equip only (no unequip-to-empty); the backend owns NPC encounter chance and item/coin state.
