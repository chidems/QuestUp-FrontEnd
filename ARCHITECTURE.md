# Quest Up — Frontend Architecture Report

Flutter pixel-art RPG gamification app. Dart SDK `^3.11.5`, ~80 Dart files. Backend contract: `MOBILE_FRONTEND_INTEGRATION.md` (the data layer has been realigned to it).

## 1. Folder Structure

Strict **feature-first** layout. Each feature is a vertical slice with the same four sub-layers; cross-cutting concerns live in `core/`, reusable UI in `shared/`.

```
lib/
├── main.dart                 # ProviderScope + runApp
├── app.dart                  # MaterialApp.router, theme wiring
├── core/
│   ├── config/               # AppConfig (env flags: USE_MOCK_API, API_BASE_URL)
│   ├── constants/            # QuestType/Source/Status/Rarity, AppAssets
│   ├── location/             # LocationService + LatLng + LocationException
│   ├── network/              # dio_client, auth_interceptor, api_exception
│   ├── routing/              # app_router (GoRouter), route_names
│   ├── storage/              # token_storage (secure), local_cache (prefs), mock_economy
│   ├── theme/                # app_theme, app_palette (ThemeExtension), app_radius
│   └── utils/                # result.dart (sealed Result<T> — unused)
├── features/
│   ├── auth/ achievements/ avatar/ history/ npc/ profile/
│   ├── quests/ settings/ store/ weekly/
│   │   ├── data/             # *_api.dart (Dio) + *_repository.dart
│   │   ├── models/           # plain Dart models + fromJson
│   │   ├── providers/        # Riverpod providers/notifiers
│   │   └── presentation/     # screens + feature widgets
└── shared/widgets/           # 16 reusable widgets (pixel_*, app_scaffold, etc.)
```

Layering is consistent: **Widget → Provider → Repository → Api → Dio**. The only deviations are `settings` and `store` (no `models/` folder — settings holds its state class inline; store reuses `avatar`'s models).

## 2. State Management

**Riverpod 3.3** (`flutter_riverpod`), no codegen. Patterns in use:

- `Provider` for DI of singletons (`dioClientProvider`, `tokenStorageProvider`, every `*ApiProvider` / `*RepositoryProvider`).
- `AsyncNotifierProvider` for screen state that loads + mutates: `authStateProvider`, `questFeedProvider`, `storeProvider`, `weeklyProvider`, `settingsProvider`, `appearanceProvider`.
- `AsyncNotifierProvider.autoDispose.family` for the per-quest completion flow (`questCompletionProvider(questId)`).
- `FutureProvider` for read-only fetches: `statsProvider`, `achievementsProvider`, `questDetailProvider` (family).
- `NotifierProvider` for synchronous in-memory state: `walkingSessionProvider`, `npcEncounterProvider`, `acceptedNpcQuestsProvider`.

Cross-provider coordination is done via `ref.invalidate(...)` and notifier method calls (e.g. completing a quest invalidates `questFeedProvider` and calls `authStateProvider.notifier.refreshUser()`). `ref.listen` bridges auth changes into the router.

## 3. Navigation

**GoRouter 17** via `appRouterProvider` (a `Provider<GoRouter>`).

- **Auth-gated redirect**: reads `authStateProvider`; loading → no redirect, unauthenticated → `/login`, authenticated-on-auth-screen → `/home`. A lightweight `_AuthChangeNotifier` (fed by `ref.listen`) is the `refreshListenable`, so redirects re-run on auth change without rebuilding the router.
- **Shell navigation**: `StatefulShellRoute.indexedStack` with 4 branches (Quests `/home`, Events `/weekly`, Hero `/avatar`, Stats `/profile`), rendered through `AppScaffold`'s custom pixel bottom nav (preserves per-tab state).
- **Stacked routes** (detail, complete, customize, store, achievements, history, settings) use a shared `_fadeThrough` `CustomTransitionPage` (fade + slight slide). Path params for `/quests/:id` and `/quests/:id/complete`.
- `RouteNames` centralizes paths (`onboarding` is declared but unused).

## 4. Theme Organization

Tokenized, theme-aware, light + dark, driven by a `ThemeExtension`.

- **`AppPalette`** (`ThemeExtension<AppPalette>`) holds ~28 semantic colors (surfaces, pixel borders, brand/accent, text ramp, quest-category colors, 5 rarity tiers) with full `lerp`. Two const instances: `dark` (slate) and `light` (parchment), both annotated for WCAG AA contrast. Accessed in widgets via `context.colors` (extension `PaletteX`).
- **`AppTheme`** builds `ThemeData` (Material 3) from a palette: registers the extension, maps `ColorScheme`, and themes AppBar/inputs/buttons/cards/bottom-nav/snackbar. Typography mixes the bundled **Press Start 2P** pixel font (titles/HUD/labels via `_px()`) with the system font for body text (readability).
- **`AppRadius`** centralizes corner radii (card/button/input/chip/small).
- Theme mode is selected in `app.dart` from `settingsProvider.darkMode` (dark default).

## 5. Networking Layer

- **`dioClientProvider`** builds the main `Dio` (baseUrl from `AppConfig.apiBaseUrl`, default `http://10.0.2.2:8000` for the Android emulator; 10s connect / 30s receive timeouts) plus a **bare `refreshDio`** (no interceptor) shared with the auth interceptor.
- **`AuthInterceptor`**: injects `Authorization: Bearer <access>` on every request; on `401` (for non-auth paths) it calls `/auth/refresh` with the stored refresh token, saves the new pair, and **replays the original request once** via `refreshDio`; on refresh failure it clears tokens (router then redirects to login).
- **`ApiException`** + `dioErrorToApiException` map `DioException` → friendly messages, reading the backend's `detail` field and distinguishing timeouts from generic network errors.
- Per-call convention: each Api method wraps Dio in `try/catch (DioException)` and rethrows `ApiException`. A `USE_MOCK_API` branch at the top of nearly every method returns canned data so the app runs with no backend.

## 6. Authentication Flow

1. `LoginScreen`/`RegisterScreen` → `authStateProvider.notifier.login/register`.
2. `AuthRepository` calls `AuthApi` (`POST /auth/login|register`) → receives **tokens only** → saves to `TokenStorage` → then `GET /auth/me` to load the `User`.
3. `TokenStorage` persists `access_token` + `refresh_token` in **`flutter_secure_storage`** only (JWT never in prefs).
4. Cold start: `AuthNotifier.build()` → `restoreSession()` reads the stored token and calls `/auth/me`; any failure clears tokens and returns `null`.
5. The router's redirect reacts to `authStateProvider`; `refreshUser()` re-pulls `/auth/me` after reward-bearing actions; `logout()` clears tokens and resets state.

## 7. Models

Plain immutable Dart classes with `factory fromJson` (no `json_serializable`/freezed). Defensive parsing throughout (`as num?`, `?? defaults`, `.toString()` for ids). Key models:

- **auth**: `User`, `LoginRequest`, `RegisterRequest`, `AuthResponse` (token pair).
- **quests**: `Quest` (+`difficultyLabel`), `QuestFeed`, `QuestCompletionResult`, `RewardAchievement`, `RewardItem`, `PhotoUploadResult`.
- **profile**: `LifeStats` (map-based, ordered keys, strips `*_xp`).
- **avatar/store**: `AvatarItem` (+`copyWith`), `AvatarAppearance` (encode/decode JSON, layered slots), `ItemType`.
- **weekly**: `WeeklyQuestStatus`, `WeeklyPhotoPost`, `WeeklyData`.
- **npc**: `NPCEncounter` (builds a `Quest` from an offer).
- **achievements**: `Achievement` (+`copyWith`), `AchievementProgress`.
- **history**: `QuestHistoryItem`.

Property names are intentionally stable across the backend rename (`Quest.title` ← `generated_title`) so the UI didn't churn.

## 8. Services

- **`LocationService`** (`core/location`): wraps `geolocator` — service-enabled + permission checks, throws typed `LocationException` (with `canOpenSettings`) for friendly UI handling; `getCurrentLocation()` / `openSettings()`. Exposed as `locationServiceProvider`.
- **`TokenStorage`** — secure JWT persistence.
- **`LocalCache`** — thin `shared_preferences` wrapper (settings + avatar appearance).
- **`MockEconomy`** — persisted mock wallet/inventory (`baseCoins = 350`, coins-spent, owned-item ids) so the offline shop is realistic.
- **`AssetCatalog`** — id-keyed lookups over the generated `asset_catalog.g.dart` (705 sprites: skins/eyes/hair/clothes/items).

## 9. Repositories

Thin orchestration over Api(s); no Dio knowledge. One per feature: `AuthRepository` (login→getMe, session restore, logout), `QuestRepository`, `ProfileRepository`, `StoreRepository`, `WeeklyRepository`, `AchievementsRepository` (**merges** `/achievements` definitions with `/achievements/progress`), `HistoryRepository`, `AvatarRepository` (local-only appearance via `LocalCache`). NPC/walking has no repository — providers call `NpcApi` directly (a minor inconsistency).

## 10. Existing UI Components (`shared/widgets/`, 16)

Reusable pixel design system:

- **Primitives**: `PixelButton`, `PixelBox`, `PixelBadge`, `PixelChip`, `PixelProgressBar`, `PixelGlyph` (12×12 string-art renderer), `PixelConfetti`.
- **Scaffolding/state**: `AppScaffold` (custom pixel bottom nav with hand-drawn glyphs, haptics, animated active plate), `LoadingView`, `ErrorView`, `EmptyState`.
- **Domain**: `RewardSummaryModal` (animated XP/coin/level-up reveal), `WeeklyQuestCard`, `RarityBadge`, `CategoryIcon`, `ItemThumbnail`.

Feature-local widgets (in each `presentation/`) include `QuestCard`, `StatBar`, `AchievementCard`, `AvatarPreview`, `NpcEncounterModal`, `WalkingStatusBanner`. All consume `context.colors` and the shared text theme — consistent design language.

## 11. Technical Debt

### Backend divergence (highest impact)

- **Store & avatar are local-only.** The shop runs on `MockEconomy`; appearance persists to `shared_preferences`. The real `/store/items` + `/inventory` + `/avatar` are not wired (and `/store/items` exposes no asset URLs), so purchases/looks don't sync across devices. `AvatarItem.fromJson` still reads `is_owned`/`is_equipped`/`image_url` the backend never returns. *(Deliberate per product decision — flagged for future.)*
- **Settings don't reach the backend.** `radiusKm` and `categories` are stored locally but **never sent** to `/quests/session/open` (feed always uses raw device location + `DateTime.now().timeZoneName`). `/profile` GET/PUT is unimplemented — no preference sync.
- **Photos are not really uploaded.** `uploadPhoto(File)` ignores the file and just fetches a `local://…` URL (`/photos/upload-url`); the backend has no image host. `cached_network_image` in the weekly feed cannot render `local://` URLs, so community photos won't show real images.

### Model / data gaps

- `Quest` carries fields the backend never sends (`targetLatitude/Longitude`, `distanceMeters`, `requiresPhoto`, `expiresAt`) — the "distance / map coords" UI silently never renders. Conversely backend `stat_category` and `target_place_type` are **not surfaced**.
- `QuestCompletionResult` drops several real fields (`level_up_coins`, `total_xp/coins`, `duplicate_*`, `achievement_*_bonus`) and always yields empty `itemRewards`/`statChanges` and null `message`, so the reward modal can't show item art or stat deltas.
- `NPCEncounter.npcName` is always the default ("Mysterious Stranger") and NPC quests default to `action`/difficulty 1 (offer lacks those fields). Weekly posts show `user_id` as the author (no display name) and never show a timestamp; likes are read-only and `/community/.../leaderboard` is unused.
- Dead code: `QuestFeed.generatedNewQuests` & `message` (set only by mocks, read nowhere), `core/utils/result.dart` (`Result<T>` unused), `AppAssets` icon constants (point at assets not in `pubspec`), `RouteNames.onboarding`.

### Robustness

- **No single-flight on token refresh** — concurrent 401s can fire multiple parallel `/auth/refresh` calls.
- `restoreSession()` clears tokens on *any* `/auth/me` failure, so a transient 5xx/timeout on cold start logs the user out.
- `dioErrorToApiException` does `data['detail'].toString()` — for 422 validation errors `detail` is a **list**, producing an ugly stringified array in the UI.
- Deprecated `encryptedSharedPreferences: true` in `TokenStorage` (flagged by analyzer; removed in `flutter_secure_storage` v11).

### Process / tooling

- **No tests** (`flutter_test` present, no `test/` files) — contradicts CLAUDE.md §4's "write a failing test, then make it pass"; the recent contract drift would have been caught by model-parsing tests.
- **Mock mode is pervasive** — an `if (AppConfig.useMockApi)` branch in nearly every Api method doubles the maintenance surface and lets mock data drift from real shapes (which is exactly what happened before the integration pass).
- 38 baseline analyzer infos (mostly `unnecessary_underscores`, plus the deprecation above).
- No Dio logging/observability interceptor, which makes diagnosing real-backend issues harder.

---

*Reflects the project after the backend-integration refactor (auth/quests/profile/weekly/npc/achievements/history match the guide; store/avatar intentionally local).*
