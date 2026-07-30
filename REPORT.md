# Quest Up — Frontend Technical Report

**Period covered:** 2026-07-14 → 2026-07-27 (last 2 weeks)
**Repo:** QuestUp-FrontEnd (Flutter/Dart) · single contributor (`cigdemsa`) · no open PRs/issues on GitHub — all work lands as direct commits to `main`.

---

## 1. Executive Summary

Over the past two weeks the app moved from "quests just appear as active" to a real **accept → active → complete/abandon** quest lifecycle, and the shop/avatar system started talking to the real backend catalog and inventory instead of running entirely on local mock data. Alongside that, a first-run **onboarding wizard** (quiz → difficulty/radius → avatar customization → reveal) shipped, the map got hand-drawn pixel-art pins with a tappable quest info card, and the avatar/clothing sprite set was reworked and roughly doubled in size (112 → 144 hair styles, 465 → 489 clothing pieces). Two backend-caused bugs were also diagnosed and written up for the backend team (all quests showing "Hard", and the weekly quest going permanently empty after 7 days), with a client-side workaround already shipped for the weekly-quest case. Test coverage grew from effectively nothing to 45 passing automated tests, and network requests now fail fast (≤1.4s) instead of retrying silently for up to 38 seconds.

---

## 2. What Shipped, By Category

### Feature: Quest accept/abandon lifecycle
**Commit:** `2ef4f3c` — `lib/features/quests/providers/accepted_quests_provider.dart`, `quest_detail_screen.dart`, `quest_feed_screen.dart`

Previously every quest in the feed was implicitly "active." Now the feed is split into **Active Quests** and **Available Quests** sections, and a quest must be explicitly accepted (`POST` via `QuestRepository.acceptQuest`) before it counts as active. The quest detail screen grew a bottom action bar that adapts to state: **Accept** for a fresh quest, **Abandon / Complete** once accepted, and **Complete only** for the weekly quest (which is assigned, not picked up, so it can't be dropped). Abandoning shows a confirmation dialog and calls the backend's `skip` endpoint, since the backend has no `accepted → active` reverse transition — this is enforced in code (`accepted_quests_provider.dart:632-641`) and covered by a dedicated test (`abandon skips the quest on the backend`).

*Why it matters:* the previous "everything is active" model didn't match the backend's actual state machine (`active / accepted / completed / skipped / expired / failed`), so a restart or refresh could silently re-show quests the user thought they'd committed to. The new `isQuestAccepted()` helper treats the backend's own `status == 'accepted'` as the source of truth and layers a session-local `Set<String>` on top only to cover the gap before the feed refetches — so state survives app restarts correctly (tested explicitly in `accepted_quests_provider_test.dart`).

### Feature: First-run onboarding wizard
**Commits:** `63cc3f0`, `264a583`

A 4-step wizard shown once after registration: a welcome step, a 4-question quiz that infers preferred quest types (`QuestType.location/social/action`), a difficulty (Novice→Legend, Roman-numeral tiers) + roaming-radius picker, an avatar customization prompt, and a personalized "adventurer reveal" screen. Routing is handled by `GoRouter` redirects keyed on a new `onboardingPendingProvider` (`app_router.dart`) — a fresh registration is redirected into `/onboarding` and can't navigate around it until it submits or explicitly skips.

The follow-up fix (`264a583`) addressed a real navigation bug: the avatar-customize screen, when reached *from inside* the wizard, used `context.push` (GoRouter), which the router's "onboarding still pending" redirect would immediately bounce back to the wizard. Fixed by switching to a plain `Navigator.push` for that one entry point, with an explicit code comment explaining why the two navigation APIs can't be interchanged there.

*Why it matters:* new users previously landed straight in the quest feed with no context-setting step; the wizard is what lets the app tailor difficulty/radius per user rather than everyone starting from the same defaults. It's also the underlying cause of a backend bug found this period (see §5).

### Feature: Pixel-art map pins + quest info card
**Commit:** `3914203` — `lib/features/map/presentation/map_pins.dart` (new, 112 lines), `map_screen.dart`

Replaced Google Maps' default colored-hue markers with hand-rendered pixel-art pins (`renderQuestPins`), color-coded by quest category, with a dedicated teal flag for the weekly quest and a purple "!" for NPC quests — drawn cell-by-cell onto a `Canvas` with anti-aliasing explicitly disabled to keep hard pixel edges. Tapping a pin now opens an in-map info card (title, place name, XP/coin/distance chips, weekly/NPC badges, "View Quest" button) instead of the default Maps info window.

*Why it matters:* this closes out a `TODO(map)` that was previously left in the code as a known placeholder ("replace the placeholder hue with pixel-art marker sprites... tracked as a separate follow-up") — the map now matches the rest of the app's pixel-art design system instead of looking like stock Google Maps.

### Feature: Real backend integration for the shop/avatar
**Commit:** `2ef4f3c` — `store_api.dart`, `store_repository.dart`, `avatar_models.dart`, `customize_screen.dart`, `hero_screen.dart`

The store previously only knew what the mock economy told it. Now `StoreRepository.getItems()` makes two calls — the item catalog and a new `GET /inventory` — and stitches ownership onto each item, since the backend keeps those in separate resources. A new `AvatarItem.assetKey` field and `isHoldable` getter fix a real data-modeling mismatch: the backend's `id` is a database UUID that can't be used to look up bundled sprite art, so equip/hold logic now keys off the stable `pixel_asset_key` instead. `isHoldable` also filters out backend-only items (hats, capes, badges) that have no avatar slot to render into, so they can't get stuck in the "equip" picker with nothing to show. The hero screen's shop button is also no longer hidden once a player owns at least one item — previously owning something made the "Open Shop" button disappear entirely.

*Why it matters:* this is the first real integration between the shop and the live backend inventory rather than a local `MockEconomy` stand-in — a prerequisite noted as outstanding in `ARCHITECTURE.md`'s technical-debt section ("Store & avatar are local-only").

### Fix: Weekly quest going empty forever
**Commit:** `bfac057` — `weekly_api.dart`, `weekly_repository.dart`, `weekly_models.dart`, `weekly_quest_screen.dart`, `weekly_provider.dart`

`GET /community/weekly/current` legitimately returns `null` (HTTP 200) when no weekly quest is currently active, but the client previously force-cast that into `WeeklyQuestStatus.fromJson(null)`, which would crash or dead-end. `WeeklyRepository.getWeeklyQuest()` and `WeeklyData.status` are now nullable end-to-end, and the screen shows a "No weekly quest right now. Check back soon!" empty state instead of erroring. This was diagnosed as a genuine backend bug (see §5) and the frontend fix ships ahead of the backend rollover fix, so the app degrades gracefully in the meantime.

### Fix: Location fetch could hang indefinitely
**Commit:** `2ef4f3c` — `lib/core/location/location_service.dart`

`Geolocator.getCurrentPosition()` had no timeout, so both the quest feed and the map would show an endless spinner if a GPS fix never arrived (e.g., indoors). Now capped at 10s with `LocationAccuracy.medium`, falling back to `getLastKnownPosition()` on timeout, and only surfacing a `LocationException` if even that fails.

### Fix: Network retries burned up to 38 seconds before showing an error
**Commit:** `2ef4f3c` — `lib/core/network/provider_retry.dart` (new)

Riverpod's default provider retry policy is 10 attempts with exponential backoff up to 6.4s delays — roughly 38 seconds of spinner before a failed request ever reaches the UI. A custom `appProviderRetry` policy now short-circuits: any 4xx (the server's final answer — retrying can't change a 404 or 400) and any `LocationException` (only the user can fix permissions) fail immediately; everything else gets 3 quick retries (200ms/400ms/800ms, ~1.4s total) before giving up and showing the existing "Retry" button. Installed globally via `ProviderScope(retry: appProviderRetry, ...)` in `main.dart`. Covered by 4 unit tests in `test/core/provider_retry_test.dart`.

### Fix: Location-quest completion had no location proof
**Commit:** `2ef4f3c` — `quest_completion_provider.dart`

Quest completion now attempts to attach the player's current lat/lng so the backend can verify they were actually at a location quest's target. Deliberately best-effort: a `getCurrentLocation()` failure is swallowed and the quest completes without coordinates rather than blocking a legitimate completion on a bad GPS fix.

### Fix: Android cleartext HTTP blocked by target SDK 36
**Commit:** `2ef4f3c` — `android/app/src/debug/AndroidManifest.xml`

Android's default (as of target SDK 36) blocks plaintext HTTP, which would silently kill every request to the local dev backend at `http://10.0.2.2:8000`. Added `android:usesCleartextTraffic="true"` scoped to the **debug** manifest only, so release builds keep the secure default.

### Refactor: Avatar/clothing sprite catalog rework
**Commit:** `bfac057` — 809 files changed (mostly binary sprite regen), `tool/gen_catalog.dart`

Regenerated the sprite catalog with revised anchor points (hair scale 1.42→1.55, adjusted top-y offsets) and added a computed **garment fit-width scale** per clothing item: `tool/gen_catalog.dart` now inspects each garment's opaque pixel bounding box against the base body silhouette and computes how much a garment needs to stretch so the body doesn't poke out past sleeves/pant legs, replacing what was previously a fixed 1.30 scale for everything. Catalog size grew from 112 hair styles / 465 clothing pieces to 144 / 489 (test-verified in `test/avatar_catalog_test.dart`).

*Why it matters:* this replaces guesswork ("does this garment look right on every body type") with a repeatable, code-computed value, so future sprite additions don't require manual per-item tuning.

### Infra/tooling: Avatar concept exploration pipeline (added then removed)
**Commits:** `a62f83e` (added), `bfac057` (removed)

Four generations of a Python/PIL-based avatar concept generator (`design_concepts/gen_avatar_concept_v1..v4.py`, ~1,800 lines total) were added to prototype avatar art directions, then deleted two commits later once `bfac057`'s sprite rework superseded them. This is normal design-exploration churn, not wasted work — worth knowing if `design_concepts/` is referenced in future history and appears to have "vanished."

### Docs: Backend gap reports
**Commits:** `63cc3f0`, `a62f83e`, `bfac057`

Four `reports/BACKEND_CHANGES_*.md` write-ups were added, each documenting a frontend/backend contract gap found while integrating: onboarding preference sync, map quest coordinates, store item catalog (backend only seeds 7 of the 84 items the frontend ships art for), and the weekly-quest rollover bug. These aren't code changes but are the paper trail for cross-team coordination — see §5.

---

## 3. Key Metrics

| Metric | Before (2026-07-14) | Now (2026-07-27) | Source |
|---|---|---|---|
| Automated tests | ~0 (per `ARCHITECTURE.md`: "No tests... no `test/` files") | **45 passing, 1 skipped** (mock-mode-only test) | `flutter test`, run live |
| Analyzer issues | 38 baseline infos (per `ARCHITECTURE.md`) | **39 infos, 0 warnings/errors** | `flutter analyze`, run live |
| Hair styles in catalog | 112 | **144** | `test/avatar_catalog_test.dart`, verified against `bfac057` diff |
| Clothing pieces in catalog | 465 | **489** | same |
| Lines changed (code, excl. binary sprites/design_concepts/generated reports) | — | **+3,602 / −802** across 62 files | `git diff --shortstat` |
| Lines changed (everything incl. binary regen) | — | **+11,178 / −6,666** | `git log --numstat` |
| Total commits in window | — | **6** (`3914203`, `63cc3f0`, `a62f83e`, `bfac057`, `264a583`, `2ef4f3c`) | `git log` |
| Retry latency before error surfaces | up to **~38s** (Riverpod default: 10 attempts, exponential backoff to 6.4s) | **≤1.4s** for retryable errors, **immediate** for 4xx/location errors | `provider_retry.dart` + its test |
| Location fetch timeout | none (could hang indefinitely) | **10s**, then falls back to last-known position | `location_service.dart` |

No CI pipeline or CHANGELOG exists in this repo — all figures above were measured directly from `flutter test`/`flutter analyze` runs and `git` history rather than pulled from any dashboard.

---

## 4. Notable Technical Decisions & Trade-offs

- **Session-local overlay over backend truth for quest acceptance.** `AcceptedQuestIdsNotifier` keeps an in-memory `Set<String>` so a just-accepted quest moves to "Active" instantly, without waiting for a feed refetch — but `isQuestAccepted()` always trusts the backend's own `status == 'accepted'` first, so this overlay can never cause a quest to look active after a restart if the backend disagrees. Deliberate optimistic-UI pattern, explicitly commented as such.
- **Abandon = skip, not delete.** The backend has no route back from `accepted` to `active`, so "abandon" calls the same skip endpoint as declining a quest outright, and the UI's confirmation dialog is worded accordingly ("It won't come back, but a new quest will take its place."). This was a constraint discovered while building the feature, not an initial design goal.
- **`assetKey` vs `id` split on `AvatarItem`.** Rather than changing what `id` means (which is used elsewhere as the stable database key), a separate `assetKey` field was added purely for sprite-catalog lookups, with `isHoldable` falling back to `id` when `assetKey` is absent — this keeps mock mode (where `id` already *is* the catalog key) working unchanged while fixing real-backend equip logic. Covered by 3 explicit tests distinguishing the two code paths.
- **Best-effort location on quest completion.** Chose to swallow location-fetch failures rather than block completion, on the reasoning (stated in-code) that "a player who genuinely did the quest must not be blocked by a bad GPS fix."
- **Debug-only cleartext HTTP exception.** Scoped narrowly to `android/app/src/debug/AndroidManifest.xml` rather than the main manifest, so the fix for local dev doesn't weaken the release build's security posture.
- **Frontend shipped ahead of a backend fix.** The weekly-quest null-handling fix (`bfac057`) was shipped as a defensive frontend change *before* the actual backend rollover job exists, so the app already degrades gracefully today and needs no further frontend change once the backend fix lands (explicitly noted in `reports/BACKEND_CHANGES_WEEKLY_QUEST_ROLLOVER.md`).

---

## 5. Known Issues / Open Work / Risks

**Confirmed backend bugs, documented but not yet fixed server-side** (frontend has already worked around what it can):
- **Every quest shows difficulty "Hard."** Root-caused to `QuestGenerationService.generate` letting the user's one onboarding `preferred_difficulty` value unconditionally override each quest template's own `base_difficulty`, so every quest a user sees collapses to the same label regardless of which template was picked. (`reports/BACKEND_CHANGES_QUEST_DIFFICULTY.md`) — **still open**, re-verified as of this report against the latest backend commit.
- **Weekly community quest never rolls over.** `seed_weekly()` is a one-off dev script, not a scheduled job — the first weekly quest works for exactly 7 days and then `/community/weekly/current` returns `null` forever until someone manually reruns the seed. Frontend already handles the `null` gracefully (`bfac057`); backend fix (a recurring job) is still outstanding.
- **Store catalog gap.** The real backend only seeds 7 of the 84 avatar items the frontend has bundled art and pricing for (`reports/BACKEND_CHANGES_STORE_ITEMS.md`) — a fix is drafted (specific `seed.py` rows) but not confirmed merged.

**Stale documentation:** `ARCHITECTURE.md`'s "Technical Debt" section still lists "No tests," "`RouteNames.onboarding` declared but unused," and other items that this period's work has since resolved (45 tests now exist; onboarding is now wired into the router). The doc's line-level content wasn't touched by this period's commits except one provider list; it should be refreshed to reflect the current state before it's used as a debt-tracking source of truth.

**Existing debt not addressed this period** (carried over from `ARCHITECTURE.md`, still applicable):
- No single-flight protection on JWT refresh — concurrent 401s can trigger multiple parallel `/auth/refresh` calls.
- `restoreSession()` logs the user out on *any* `/auth/me` failure, including transient 5xx/timeouts.
- `dioErrorToApiException` mishandles FastAPI's list-shaped 422 validation `detail`, producing a stringified array in the UI.
- Photos aren't really uploaded (`uploadPhoto` ignores the file and returns a `local://…` URL the backend can't host), so weekly community photos can't render for real.
- `mock`-mode branches remain in nearly every API method, doubling maintenance surface and risking mock/real data drift (this is exactly what caused the store catalog and NPC-encounter shape mismatches found this period).

**Test gap introduced this period:** the new quest-mechanics tests (`accepted_quests_provider_test.dart`, `store_repository_test.dart`, `provider_retry_test.dart`) are solid unit coverage of the new logic, but there's no widget/integration test exercising the new Accept/Abandon buttons or the onboarding wizard's navigation end-to-end — only `onboarding_flow_test.dart`'s state-machine logic is covered, not the screens themselves.

---

## 6. What's Next

Based on the open backend-gap reports and `ARCHITECTURE.md`'s remaining debt list (no open branches or TODO-tagged code beyond what's cited above):

1. **Backend fixes to land** (frontend has already adapted or is blocked waiting): quest difficulty variety, weekly-quest rollover job, and seeding the full 84-item store catalog.
2. **Settings → backend sync.** `radiusKm` and `categories` are still local-only and never sent to `/quests/session/open`; `/profile` GET/PUT is unimplemented.
3. **Real photo hosting**, so weekly community photos and quest-completion photos actually render instead of resolving to unrenderable `local://` URLs.
4. **Widget/integration test coverage** for the new Accept/Abandon flow and the onboarding wizard screens, to close the gap noted in §5.
5. Per `CLAUDE.md`'s stated project status, remaining polish items: real pixel-art assets beyond what's already landed, optional backend prefs sync, JWT refresh hardening (single-flight), and general demo polish.

---

*All figures in this report were derived directly from `git log`/`git show` on commits `3914203`..`2ef4f3c`, a live `flutter test` run (45 passed, 1 skipped), a live `flutter analyze` run (39 infos, 0 errors), and the four `reports/BACKEND_CHANGES_*.md` documents already checked into the repo. No figures were estimated.*
