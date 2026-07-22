# Claude Opus Build Prompt — Quest Up Frontend Mobile App

You are helping me build the **frontend mobile app** for my capstone project, **Quest Up**.

Quest Up is a location-aware gamification mobile app that turns everyday life into real-world side quests. Users receive randomized quests based on their location, nearby places, weather, time of day, and preferences. They complete quests in real life, take photos, earn XP and coins, level up life stats, encounter random NPCs, participate in weekly community quests, and customize a 2D pixel-art avatar.

This file is the implementation brief for Claude Opus. Build the Flutter frontend in a clean, scalable way, but keep the first version realistic for a 10-week college capstone MVP.

---

## 1. Project Identity

### Product Name
**Quest Up**

### Tagline
**Life is Full of Side Quests. Start Completing Them.**

### Main Idea
Quest Up motivates users to go outside, explore, socialize, and try new activities by giving them real-life quests. The app should feel like a lightweight RPG: users earn XP, coins, streak bonuses, stat progress, achievements, avatar customization items, and occasional NPC quest offers.

### Main Quest Types
The current version uses **3 quest types**:

1. **Location**
   - Visit a park you have never been to.
   - Find a hidden mural downtown.
   - Explore a new neighborhood cafe.
   - Walk a trail within 2 km.

2. **Social**
   - Compliment 3 strangers today.
   - Have coffee with someone new.
   - Join a local community event.
   - Teach someone a skill you have.

3. **Action**
   - Do 20 push-ups in a park.
   - Sketch the view from a rooftop.
   - Cook a recipe from a new culture.
   - Write a poem about your friends.

---

## 2. Frontend MVP Scope

Build the mobile frontend for these core flows:

- Authentication screens: register, login, logout, token persistence.
- Onboarding/profile setup: display name, quest preferences, location permission explanation, avatar creation basics.
- Main home/quest feed.
- Automatic app-open behavior: when the user opens the app, send the current location to the backend and request quest feed/top-up. The backend will create new normal quests if the user has fewer than 2 active normal quests. Weekly quests do **not** count toward that limit.
- Quest detail page.
- Quest completion flow with photo capture/upload.
- Weekly community quest page with optional photo sharing after completion.
- Walking mode/location tracking state for random NPC encounter checks.
- NPC encounter popup/modal where the user can accept or decline an extra quest.
- Profile/stat page with XP, level, coins, streak, and life stats.
- Achievements page.
- Avatar customization page.
- Shop page for buying avatar items with coins.
- Inventory/equipped items handling.
- Quest history page.
- Settings page for preferences, radius, and privacy/location controls.

Do **not** overbuild these for the first MVP:

- No full friends system.
- No complex global leaderboard except weekly community quest photo sharing/weekly participation view.
- No advanced AR.
- No complex offline sync beyond simple local caching for logged-in user data and recent quests.
- No production-level photo verification UI. The app should capture/upload photos and show verification/status messages from the backend.

---

## 3. Recommended Frontend Tech Stack

Use this stack unless there is a strong reason not to:

- **Flutter 3.x**
- **Dart**
- **Riverpod** for state management
- **GoRouter** for navigation
- **Dio** for HTTP requests
- **Flutter Secure Storage** for JWT tokens
- **SharedPreferences or Hive** for lightweight local cache/preferences
- **google_maps_flutter** for map display
- **geolocator** for GPS/location permissions and walking tracking
- **permission_handler** for permission flow
- **image_picker** or **camera** for quest completion photos
- **cached_network_image** for avatar item images and uploaded photos
- **flutter_svg** if SVG icons are used
- **lottie** or **rive** optional for celebration animations
- **fl_chart** optional for stat/progress visualization

The app should be easy to run locally with:

```bash
flutter pub get
flutter run
```

Use environment/config support for API base URL, for example:

```dart
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
```

For Android emulator, remember backend localhost may need `10.0.2.2`.

---

## 4. Visual Direction

The app should have a **2D pixel-art RPG style** with modern mobile usability.

### Style Goals

- Pixel-art inspired, but readable and clean.
- Purple/navy fantasy-game background tones.
- Bright accent colors for XP, coins, hearts, rarity, and quest categories.
- Large quest cards that feel like RPG mission cards.
- Icons for Location, Social, and Action quests.
- Avatar customization should feel like equipping RPG items.
- Achievements and level-ups should feel rewarding.

### Suggested UI Elements

- Quest cards with category icon, title, distance, difficulty, XP reward, coin reward, and status.
- Pixel-style buttons: **Accept**, **Complete**, **Share**, **Buy**, **Equip**.
- Top user HUD: avatar, level, XP bar, coins, streak.
- Stat bars for Social, Creativity, Exploration, Knowledge, and Fitness if backend exposes all 5. If the product UI only shows 4 initially, keep Fitness available in model but hidden or optional.
- Rarity badges for avatar items: common, uncommon, rare, epic, legendary.

---

## 5. Recommended Flutter Project Structure

Use a feature-first architecture:

```text
lib/
  main.dart
  app.dart
  core/
    config/
      app_config.dart
    constants/
      app_colors.dart
      app_assets.dart
      quest_constants.dart
    network/
      dio_client.dart
      api_exception.dart
      auth_interceptor.dart
    routing/
      app_router.dart
      route_names.dart
    storage/
      token_storage.dart
      local_cache.dart
    theme/
      app_theme.dart
    utils/
      result.dart
      formatters.dart
      validators.dart
  features/
    auth/
      data/
        auth_api.dart
        auth_repository.dart
      models/
        auth_models.dart
      providers/
        auth_provider.dart
      presentation/
        login_screen.dart
        register_screen.dart
    onboarding/
      presentation/
        onboarding_screen.dart
        avatar_setup_screen.dart
        permission_explainer_screen.dart
    quests/
      data/
        quest_api.dart
        quest_repository.dart
      models/
        quest_models.dart
      providers/
        quest_feed_provider.dart
        quest_detail_provider.dart
      presentation/
        quest_feed_screen.dart
        quest_detail_screen.dart
        quest_card.dart
        quest_completion_screen.dart
    weekly/
      data/
        weekly_api.dart
      models/
        weekly_models.dart
      providers/
        weekly_provider.dart
      presentation/
        weekly_quest_screen.dart
        weekly_photo_feed_screen.dart
    npc/
      data/
        npc_api.dart
      models/
        npc_models.dart
      providers/
        walking_session_provider.dart
        npc_encounter_provider.dart
      presentation/
        npc_encounter_modal.dart
        walking_status_banner.dart
    profile/
      data/
        profile_api.dart
      models/
        profile_models.dart
      providers/
        profile_provider.dart
      presentation/
        profile_screen.dart
        stat_bar.dart
    achievements/
      data/
        achievements_api.dart
      models/
        achievement_models.dart
      providers/
        achievements_provider.dart
      presentation/
        achievements_screen.dart
    avatar/
      data/
        avatar_api.dart
      models/
        avatar_models.dart
      providers/
        avatar_provider.dart
      presentation/
        avatar_screen.dart
        inventory_screen.dart
        avatar_preview.dart
    store/
      data/
        store_api.dart
      models/
        store_models.dart
      providers/
        store_provider.dart
      presentation/
        store_screen.dart
        item_card.dart
    history/
      data/
        history_api.dart
      providers/
        history_provider.dart
      presentation/
        quest_history_screen.dart
    settings/
      presentation/
        settings_screen.dart
  shared/
    widgets/
      app_scaffold.dart
      pixel_button.dart
      loading_view.dart
      error_view.dart
      empty_state.dart
      xp_bar.dart
      coin_chip.dart
      rarity_badge.dart
      category_icon.dart
```

Keep screens simple and delegate API/state logic to repositories/providers.

---

## 6. Important Product Rules for the Frontend

### Normal Quest Feed Rule

Normal quests are randomized and context-aware. The frontend should not generate quests locally. Instead:

1. On app open or quest feed refresh, get current GPS location.
2. Call backend quest feed/top-up endpoint with latitude/longitude.
3. Backend returns active normal quests and weekly quest separately.
4. Show normal active quests in the quest feed.
5. Show weekly quest in a separate card/section so it does not look like it counts toward the normal 2-quest limit.

Frontend should display clear states:

- Loading location.
- Location permission denied.
- No nearby quest context available.
- Quest generation failed.
- Active quests loaded.

### Weekly Quest Rule

Weekly quest is shared by all users. It is separate from normal quests. After completing a weekly quest and taking a photo, the user can choose whether to share the photo to the weekly community page.

Frontend flow:

1. User opens Weekly Quest page.
2. User sees current weekly quest and community photo feed.
3. User completes weekly quest.
4. User takes/uploads photo.
5. App asks: **Share this photo to the weekly community page?**
6. If yes, call share endpoint.
7. If no, keep completion private.

### NPC Encounter Rule

NPCs appear randomly when the user is walking with the app open.

Product behavior:

- If user walks with the app open for more than 3 minutes, there is a 70% chance of an NPC appearing.
- When an NPC appears, show a modal/card with NPC name, pixel-art image, message, and quest offer.
- User can accept or decline the NPC quest.
- After the user accepts an NPC quest, NPC appearance chance drops to 20% for that user.
- The chance restores after 3 hours.

Frontend implementation recommendation:

- Use `geolocator` to track position while the app is open and user has allowed location.
- Detect walking in a simple MVP way:
  - Use location updates and speed if available.
  - Treat speed around 0.5 m/s to 2.5 m/s as walking.
  - Track continuous walking duration in app state.
- After 3 minutes of continuous walking, call the backend NPC encounter check endpoint.
- Do **not** decide the random chance on the frontend. Let the backend decide. Frontend only reports walking session/location context.
- Avoid draining battery: use reasonable update intervals and stop tracking when user disables walking mode or leaves the app.

### Coins and Shop Rule

Users earn coins from:

- Completing quests.
- Leveling up.
- Possibly weekly quests, high-difficulty quests, NPC quests, achievements, and item rewards.

Users spend coins in the avatar item shop.

Frontend must enforce/display:

- User cannot buy an item they already own.
- Owned items show **Owned** or **Equip** instead of **Buy**.
- Equipped items show **Equipped**.
- Not enough coins should show disabled Buy button and helpful message.
- Item cards should show item image, name, category, rarity, and price.

Backend remains source of truth for coins, inventory, purchases, and equipped items.

### Item Reward Rule

Users can receive item rewards from:

- Completing weekly quests.
- Completing higher-difficulty quests.
- Completing NPC quests.
- Leveling up.
- Unlocking achievements.

Frontend should support reward results returned from quest completion, level-up, or achievement endpoints.

Show reward summary after completion:

- XP gained.
- Coins gained.
- Stat increased.
- Streak update.
- Level-up if any.
- Achievement unlocks if any.
- Item rewards if any.

---

## 7. Expected Backend API Contract

The backend is being built separately in FastAPI. Use these endpoint assumptions and create the frontend API layer so names can be changed easily later.

### Auth

```text
POST /auth/register
POST /auth/login
POST /auth/refresh
GET  /users/me
```

### Quest Feed and Quest Detail

```text
POST /quests/feed
GET  /quests/{quest_id}
POST /quests/{quest_id}/complete
GET  /quests/history
```

`POST /quests/feed` should send:

```json
{
  "latitude": 49.2827,
  "longitude": -123.1207,
  "timezone": "America/Vancouver"
}
```

Expected response shape:

```json
{
  "normal_quests": [],
  "weekly_quest": {},
  "generated_new_quests": true,
  "message": "Quest feed loaded"
}
```

### Photo Upload

```text
POST /photos/upload
```

Use multipart upload from Flutter.

### Weekly Community Quest

```text
GET  /community/weekly-quest
GET  /community/weekly-quest/photos
POST /community/weekly-quest/share-photo
```

### NPC and Walking

```text
POST /walking/session-tick
POST /npc/check-encounter
POST /npc/{npc_encounter_id}/accept
POST /npc/{npc_encounter_id}/decline
```

### Profile, Stats, Achievements

```text
GET /profile
PUT /profile
GET /profile/stats
GET /achievements
GET /achievements/progress
```

### Avatar, Inventory, Store

```text
GET  /avatar
PUT  /avatar/equip
GET  /avatar/inventory
GET  /store/items
POST /store/items/{item_id}/buy
```

---

## 8. Core Data Models Needed in Flutter

Create Dart models for these objects. Use `fromJson`/`toJson`. Keep fields nullable where backend may evolve.

### User

Fields:

- id
- email
- displayName
- level
- totalXp
- coins
- currentStreak
- longestStreak
- avatarUrl or avatar config

### Quest

Fields:

- id
- title
- description
- questType: location/social/action
- source: normal/weekly/npc
- difficulty
- xpReward
- coinReward
- status: active/completed/skipped/expired/failed
- targetLatitude
- targetLongitude
- targetPlaceName
- distanceMeters
- expiresAt
- requiresPhoto
- isWeekly
- npcId nullable

### QuestCompletionResult

Fields:

- questId
- xpGained
- coinsGained
- levelBefore
- levelAfter
- didLevelUp
- streakCount
- statChanges
- unlockedAchievements
- itemRewards
- message

### WeeklyPhotoPost

Fields:

- id
- userDisplayName
- photoUrl
- questTitle
- caption
- likesCount optional
- createdAt

### NPCEncounter

Fields:

- id
- npcName
- npcImageUrl
- message
- questOffer
- expiresAt
- encounterChanceUsed

### AvatarItem

Fields:

- id
- name
- description
- itemType: hat/top/bottom/shoes/weapon/accessory/background
- rarity: common/uncommon/rare/epic/legendary
- priceCoins
- imageUrl
- isOwned
- isEquipped

### Achievement

Fields:

- id
- name
- description
- iconUrl
- category
- progress
- isUnlocked
- unlockedAt

---

## 9. Main Screens to Build

### 9.1 Login Screen

- Email/password fields.
- Login button.
- Link to register.
- Loading state.
- Error messages from API.

### 9.2 Register Screen

- Email, display name, password, confirm password.
- Basic validation.
- On success, store token and navigate to onboarding/home.

### 9.3 Onboarding Screen

Explain:

- Quest Up uses location to generate real-world quests.
- Photos are used to save completion moments.
- Weekly quest photo sharing is optional.
- User can customize avatar with coins/items.

Ask for:

- Quest preferences.
- Preferred radius.
- Location permission.

### 9.4 Home / Quest Feed Screen

This is the main screen.

UI sections:

- Top HUD: avatar, level, XP bar, coins, streak.
- Weekly Quest card at top or highlighted section.
- Active Normal Quests section, max 2 active normal quests shown.
- Walking/NPC status banner if walking tracking is active.
- Refresh button or pull-to-refresh.

On screen load:

1. Check auth token.
2. Request location permission if needed.
3. Get current location.
4. Call `/quests/feed`.
5. Render quests.

### 9.5 Quest Detail Screen

Show:

- Quest title and description.
- Quest type/category.
- Difficulty.
- XP/coins.
- Target place and distance if location quest.
- Map preview if coordinates exist.
- Expiration/time remaining.
- Complete button.

### 9.6 Quest Completion Screen

Flow:

1. User taps Complete.
2. If quest requires photo, open camera/image picker.
3. Upload photo.
4. Call completion endpoint with photo metadata.
5. Show reward summary screen/modal.
6. If weekly quest, ask whether to share photo.

### 9.7 Weekly Quest Screen

Show:

- Current weekly quest.
- User completion status.
- Community photo feed.
- Optional share photo action after completion.

### 9.8 NPC Encounter Modal

Triggered when backend returns an NPC encounter.

Show:

- NPC image.
- NPC name.
- Message.
- Offered quest title/description.
- XP/coin reward.
- Accept button.
- Decline button.

After accepting:

- Add NPC quest to active quest list or show success.
- NPC chance cooldown is handled by backend.

### 9.9 Profile / Stats Screen

Show:

- Avatar preview.
- Level.
- XP bar.
- Coins.
- Current streak and longest streak.
- Life stat bars.
- Recent achievements.

### 9.10 Avatar Customization Screen

Show:

- Avatar preview.
- Equipped items.
- Inventory grouped by item type.
- Equip/Unequip controls.

### 9.11 Store Screen

Show:

- Available items.
- Filters by item type and rarity.
- Coin balance.
- Buy button.
- Owned/Equipped state.
- Prevent duplicate purchases in UI, but backend is still source of truth.

### 9.12 Achievements Screen

Show:

- Achievement grid.
- Locked/unlocked state.
- Progress bars.
- Reward info if available.

### 9.13 Quest History Screen

Show completed quests with:

- Quest title.
- Date.
- XP/coins earned.
- Photo thumbnail if available.
- Quest type.

### 9.14 Settings Screen

Show:

- Preferred radius.
- Quest category preferences.
- Location permission status.
- Walking/NPC tracking toggle.
- Privacy note for weekly photo sharing.
- Logout button.

---

## 10. State Management Requirements

Use Riverpod providers for:

- Auth state.
- Current user/profile state.
- Quest feed state.
- Weekly quest state.
- NPC/walking state.
- Avatar/inventory state.
- Store state.
- Achievements state.
- Settings/preferences state.

Use clear loading/error/data states. A simple sealed class or `AsyncValue` is fine.

Do not put API calls directly inside widgets unless it is a tiny prototype. Prefer:

```text
Widget -> Provider -> Repository -> Api Client -> Dio
```

---

## 11. Location and Walking Tracking

Implement location carefully.

### MVP Location Flow

- Ask permission only after explaining why.
- Handle denied and permanently denied states.
- Let user use limited app features without location if possible.
- Use current location for quest generation.

### Walking/NPC Flow

- Add a toggle or banner: **Walking Mode**.
- When enabled, listen to location updates.
- Track whether user is likely walking.
- After 3 minutes of continuous walking, call backend NPC check.
- If encounter returned, show NPC modal.
- Reset local walking timer after check or after NPC appears.
- Stop tracking when app is closed/backgrounded for MVP unless backend later supports background location.

Do not implement aggressive background tracking in MVP. It creates privacy, battery, and app store complexity.

---

## 12. Photo Handling

Use image picker or camera package.

For MVP:

- Let user take a photo or choose from gallery if easier during testing.
- Compress image before upload if package is available.
- Send multipart request to backend.
- Show upload progress if simple to implement.
- Show uploaded photo preview.
- For weekly quest, after completion, ask user if they want to share.

Photo sharing should always be optional.

---

## 13. Error Handling and UX States

Every network screen should handle:

- Loading.
- Empty state.
- API error.
- No internet.
- Unauthorized token expired.
- Location denied.
- Backend unavailable.

For errors, show friendly messages, not raw stack traces.

Examples:

- “We could not generate a quest from your current location. Try refreshing or moving to another area.”
- “Location permission is needed to create nearby quests.”
- “You need more coins to buy this item.”
- “You already own this item.”

---

## 14. Mock Mode for Parallel Development

Because backend and frontend may be built at the same time, create a simple mock mode.

Requirements:

- Repository interfaces should make it easy to swap real API with mock data.
- Add mock quest feed data.
- Add mock weekly quest/photo posts.
- Add mock avatar items/shop inventory.
- Add mock profile/stats.
- Add mock NPC encounter.

This lets frontend development continue even if backend endpoints are not finished.

Suggested config:

```dart
const bool useMockApi = bool.fromEnvironment('USE_MOCK_API', defaultValue: false);
```

Run mock mode:

```bash
flutter run --dart-define=USE_MOCK_API=true
```

---

## 15. Navigation Structure

Use bottom navigation for main app sections:

1. **Quests**
2. **Weekly**
3. **Avatar/Shop**
4. **Profile**

Settings can be accessed from Profile.

Suggested routes:

```text
/login
/register
/onboarding
/home
/quests/:id
/quests/:id/complete
/weekly
/avatar
/store
/profile
/achievements
/history
/settings
```

Use route guards:

- Unauthenticated users go to login/register.
- Authenticated users go to home.

---

## 16. Minimum UI Components to Create

Create reusable widgets:

- `PixelButton`
- `QuestCard`
- `WeeklyQuestCard`
- `CategoryIcon`
- `DifficultyBadge`
- `XpBar`
- `CoinChip`
- `StreakChip`
- `RarityBadge`
- `AvatarPreview`
- `ItemCard`
- `AchievementCard`
- `RewardSummaryModal`
- `NpcEncounterModal`
- `LoadingView`
- `ErrorView`
- `EmptyState`

---

## 17. Suggested Implementation Order

Build in this order:

### Phase 1 — Foundation

- Flutter project setup.
- Theme/colors/text styles.
- Routing with GoRouter.
- Dio client with auth interceptor.
- Token storage.
- Basic auth screens.
- Mock mode setup.

### Phase 2 — Quest Feed MVP

- Quest models.
- Quest repository/API.
- Quest feed screen.
- Location permission/current location.
- App-open quest feed request.
- Quest detail screen.

### Phase 3 — Completion + Rewards

- Photo picker/camera.
- Photo upload flow.
- Quest completion endpoint call.
- Reward summary modal.
- Profile refresh after completion.

### Phase 4 — Weekly Quest

- Weekly quest page.
- Community photo feed.
- Optional share photo flow.

### Phase 5 — Avatar + Store

- Avatar item models.
- Inventory screen.
- Store screen.
- Buy/equip logic.
- Owned/equipped UI states.

### Phase 6 — NPC + Walking

- Walking mode banner/toggle.
- Location stream.
- 3-minute walking timer logic.
- Backend NPC check.
- NPC encounter modal.
- Accept/decline NPC quest.

### Phase 7 — Polish

- Achievements screen.
- Quest history.
- Settings.
- Animations.
- Better empty/error states.
- Demo data and demo flow polish.

---

## 18. Code Quality Rules

- Keep code readable and beginner-friendly enough for a college capstone.
- Avoid overengineering.
- Use feature folders.
- Keep widgets small.
- Keep API models separate from UI widgets.
- Avoid hardcoding API URLs in multiple files.
- Add comments only where logic is not obvious.
- Make UI work in mock mode before relying on backend.
- Do not store JWT in plain SharedPreferences; use secure storage.
- Do not make location tracking run in the background for MVP.

---

## 19. README Requirements

Create/update a frontend README with:

- Project overview.
- Flutter version.
- Setup instructions.
- How to run with backend.
- How to run mock mode.
- Required permissions.
- Environment variables / dart defines.
- Main folder structure.
- Screens implemented.
- Known limitations.

---

## 20. First Task for Claude Opus

Start by creating the Flutter project foundation:

1. Set up the folder structure.
2. Add dependencies in `pubspec.yaml`.
3. Create app theme and constants.
4. Set up GoRouter routes.
5. Set up Dio API client with token interceptor.
6. Set up secure token storage.
7. Create auth models, auth repository, and auth provider.
8. Create login/register screens.
9. Create mock home screen shell with bottom navigation.
10. Add README instructions.

After that, continue with the Quest Feed MVP using mock data first, then wire it to the backend API.

