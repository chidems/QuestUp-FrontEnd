# Quest Up Mobile Frontend Integration Guide

Base URL for local Docker:

```text
http://localhost:8000
```

For a physical mobile device, replace `localhost` with your computer's LAN IP address.

Protected routes require:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

Quest types currently used by the backend:

```text
location | social | action
```

Quest statuses:

```text
active | accepted | completed | skipped | expired | failed
```

## Auth

### Register

`POST /auth/register`

Creates a user and returns tokens. The backend also creates the user's profile, stats, and avatar record.

Request:

```json
{
  "email": "player@example.com",
  "password": "password123",
  "display_name": "Player One"
}
```

Response:

```json
{
  "access_token": "jwt-access-token",
  "refresh_token": "jwt-refresh-token",
  "token_type": "bearer"
}
```

### Login

`POST /auth/login`

Request:

```json
{
  "email": "player@example.com",
  "password": "password123"
}
```

Response:

```json
{
  "access_token": "jwt-access-token",
  "refresh_token": "jwt-refresh-token",
  "token_type": "bearer"
}
```

### Refresh Tokens

`POST /auth/refresh`

Use the refresh token to get a new access/refresh pair.

Request:

```json
{
  "refresh_token": "jwt-refresh-token"
}
```

Response:

```json
{
  "access_token": "new-jwt-access-token",
  "refresh_token": "new-jwt-refresh-token",
  "token_type": "bearer"
}
```

### Current User

`GET /auth/me`

Auth required.

Response:

```json
{
  "id": "user-id",
  "email": "player@example.com",
  "display_name": "Player One",
  "total_xp": 319,
  "level": 3,
  "coins": 151,
  "current_streak": 1,
  "longest_streak": 1
}
```

## Profile

### Get Profile

`GET /profile`

Auth required.

Response:

```json
{
  "preferred_radius_km": 5.0,
  "preferred_difficulty": 2,
  "preferred_quest_types": ["location"],
  "timezone": "America/Vancouver",
  "home_lat": 49.2827,
  "home_lng": -123.1207,
  "location_sharing_enabled": true,
  "community_sharing_enabled": true
}
```

### Update Profile

`PUT /profile`

Auth required. All fields are optional. Send only what changed.

Request:

```json
{
  "preferred_radius_km": 8,
  "preferred_difficulty": 2,
  "preferred_quest_types": ["location", "social"],
  "timezone": "America/Vancouver",
  "home_lat": 49.2827,
  "home_lng": -123.1207,
  "location_sharing_enabled": true,
  "community_sharing_enabled": true
}
```

Response: same shape as `GET /profile`.

### Get Stats

`GET /profile/stats`

Auth required.

Response:

```json
{
  "social_xp": 243,
  "creativity_xp": 0,
  "exploration_xp": 51,
  "knowledge_xp": 0,
  "fitness_xp": 0
}
```

### Get Progression

`GET /profile/progression`

Auth required.

Response:

```json
{
  "total_xp": 319,
  "level": 3,
  "coins": 151,
  "current_streak": 1
}
```

## Quest Flow

### Open App Session

`POST /quests/session/open`

Auth required. This is the best first call after login. It tops up normal quests, creates/returns the user's weekly quest, returns any current NPC offer, and includes progression.

Request:

```json
{
  "lat": 49.2827,
  "lng": -123.1207,
  "timezone": "America/Vancouver"
}
```

`lat` and `lng` are optional, but if one is sent the other must also be sent.

Response:

```json
{
  "normal": [
    {
      "id": "quest-id-1",
      "source": "normal",
      "generated_title": "Visit a New Park: English Bay Beach",
      "generated_description": "Walk to English Bay Beach, take in the space, and capture one photo that shows what made it worth the trip.",
      "quest_type": "location",
      "stat_category": "exploration",
      "difficulty": 2,
      "xp_reward": 45,
      "coin_reward": 12,
      "status": "active",
      "target_place_name": "English Bay Beach",
      "target_place_type": "park"
    }
  ],
  "weekly": {
    "id": "weekly-user-quest-id",
    "source": "weekly",
    "generated_title": "Neighborhood Snapshot Challenge",
    "generated_description": "Take a photo that captures a hidden gem in your neighborhood and share it with the weekly community feed.",
    "quest_type": "location",
    "stat_category": "exploration",
    "difficulty": 3,
    "xp_reward": 120,
    "coin_reward": 50,
    "status": "active",
    "target_place_name": null,
    "target_place_type": null
  },
  "weekly_community": {
    "id": "weekly-community-quest-id",
    "title": "Neighborhood Snapshot Challenge",
    "description": "Take a photo that captures a hidden gem in your neighborhood and share it with the weekly community feed.",
    "quest_type": "location",
    "stat_category": "exploration",
    "xp_reward": 120,
    "coin_reward": 50,
    "reward_item_id": "avatar-item-id",
    "status": "active"
  },
  "npc_offer": null,
  "progression": {
    "level": 1,
    "xp": 0,
    "coins": 0
  }
}
```

### Get Active Quests

`GET /quests/active`

Auth required.

Response:

```json
{
  "normal": [],
  "npc": [],
  "weekly": []
}
```

Each array contains `QuestOut` objects with the same shape shown above.

### Generate One Normal Quest

`POST /quests/generate?lat=49.2827&lng=-123.1207&timezone=America/Vancouver`

Auth required. Usually the app should use `/quests/session/open` instead. This route manually generates one normal quest. It may return `409` if the normal active quest limit is reached.

Optional query params:

```text
lat
lng
timezone
force
```

Response:

```json
{
  "id": "quest-id",
  "source": "normal",
  "generated_title": "Cafe Vibe Check: Side Quest Cafe",
  "generated_description": "Find Side Quest Cafe, order something small, and note one detail that gives the place character.",
  "quest_type": "location",
  "stat_category": "knowledge",
  "difficulty": 2,
  "xp_reward": 30,
  "coin_reward": 8,
  "status": "active",
  "target_place_name": "Side Quest Cafe",
  "target_place_type": "cafe"
}
```

### Accept Quest

`POST /quests/{quest_id}/accept`

Auth required.

Response:

```json
{
  "id": "quest-id",
  "source": "normal",
  "generated_title": "Compliment Three People",
  "generated_description": "Give three genuine compliments today and write down how the conversations felt.",
  "quest_type": "social",
  "stat_category": "social",
  "difficulty": 3,
  "xp_reward": 60,
  "coin_reward": 18,
  "status": "accepted",
  "target_place_name": null,
  "target_place_type": null
}
```

### Skip Quest

`POST /quests/{quest_id}/skip`

Auth required.

Response: same shape as `QuestOut`, with `status: "skipped"`.

### Complete Quest

`POST /quests/{quest_id}/complete`

Auth required. Photos are optional for all quests.

Request with no photo:

```json
{
  "rating": 5,
  "notes": "Finished this quest.",
  "shared_to_community": false
}
```

Request with optional photo/community sharing:

```json
{
  "photo_url": "local://uploads/user-id/photo.jpg",
  "caption": "A hidden spot I found today.",
  "completion_lat": 49.2827,
  "completion_lng": -123.1207,
  "notes": "Completed near downtown.",
  "rating": 5,
  "shared_to_community": true
}
```

`completion_lat` and `completion_lng` are optional, but if one is sent the other must also be sent.

Response:

```json
{
  "id": "completion-id",
  "xp_awarded": 81,
  "coins_awarded": 18,
  "level_up_coins": 35,
  "item_awarded_id": null,
  "duplicate_item_id": null,
  "duplicate_compensation_coins": 0,
  "achievement_xp_bonus": 25,
  "achievement_coin_bonus": 10,
  "unlocked_achievements": [
    {
      "achievement_id": "achievement-id",
      "name": "First Quest Complete",
      "xp_bonus": 25,
      "coin_bonus": 10,
      "item_awarded_id": null,
      "duplicate_item_id": null,
      "duplicate_compensation_coins": 0
    }
  ],
  "shared_to_community": false,
  "previous_level": 1,
  "level": 2,
  "leveled_up": true,
  "total_xp": 157,
  "total_coins": 75,
  "current_streak": 1,
  "longest_streak": 1
}
```

### Quest Detail

`GET /quests/{quest_id}`

Auth required.

Response: `QuestOut`.

### Quest History

`GET /quests/history`

Auth required.

Response:

```json
[
  {
    "id": "quest-id",
    "source": "normal",
    "generated_title": "Compliment Three People",
    "generated_description": "Give three genuine compliments today and write down how the conversations felt.",
    "quest_type": "social",
    "stat_category": "social",
    "difficulty": 3,
    "xp_reward": 60,
    "coin_reward": 18,
    "status": "completed"
  }
]
```

## Store And Avatar

### List Store Items

`GET /store/items`

No auth required currently.

Response:

```json
[
  {
    "id": "avatar-item-id",
    "name": "Adventurer Jacket",
    "item_type": "outfit",
    "pixel_asset_key": "adventurer_jacket",
    "price_coins": 120,
    "unlock_level": 1,
    "rarity": "rare",
    "is_purchasable": true,
    "is_reward_only": false
  }
]
```

Current note for mobile: image URLs are not exposed yet in this response. For now, map `pixel_asset_key` to local frontend assets, or wait for the store asset catalog task to add `asset_url`.

### Purchase Item

`POST /store/items/{item_id}/purchase`

Auth required.

Response:

```json
{
  "id": "inventory-row-id",
  "user_id": "user-id",
  "avatar_item_id": "avatar-item-id",
  "acquired_from": "purchase",
  "acquired_at": "2026-06-23T06:05:28.411557Z"
}
```

Possible errors:

```json
{"detail": "User already owns this item"}
```

```json
{"detail": "Not enough coins"}
```

### Get Inventory

`GET /inventory`

Auth required.

Response:

```json
[
  {
    "id": "inventory-row-id",
    "user_id": "user-id",
    "avatar_item_id": "avatar-item-id",
    "acquired_from": "quest_reward",
    "acquired_at": "2026-06-23T06:05:28.411557Z"
  }
]
```

### Get Avatar

`GET /avatar`

Auth required.

Response:

```json
{
  "id": "avatar-id",
  "user_id": "user-id",
  "equipped_items": {
    "outfit": "avatar-item-id",
    "head": "avatar-item-id"
  },
  "base_style": "default",
  "updated_at": "2026-06-23T06:05:28.411557Z"
}
```

### Equip Avatar Items

`PUT /avatar/equip`

Auth required. All item IDs must already be owned by the user.

Request:

```json
{
  "equipped_items": {
    "outfit": "avatar-item-id",
    "head": "avatar-item-id"
  },
  "base_style": "default"
}
```

Response: same shape as `GET /avatar`.

## Community

### Current Weekly Challenge

`GET /community/weekly/current`

Response:

```json
{
  "id": "weekly-community-quest-id",
  "title": "Neighborhood Snapshot Challenge",
  "description": "Take a photo that captures a hidden gem in your neighborhood and share it with the weekly community feed.",
  "quest_type": "location",
  "stat_category": "exploration",
  "xp_reward": 120,
  "coin_reward": 50,
  "reward_item_id": "avatar-item-id",
  "status": "active"
}
```

### Submit Weekly Post

`POST /community/weekly/{weekly_quest_id}/submit`

Auth required. Photo is optional. If `user_quest_id` is provided, it must be a completed weekly quest owned by the user.

Request:

```json
{
  "user_quest_id": "completed-weekly-user-quest-id",
  "photo_url": null,
  "caption": "Finished this challenge without a photo."
}
```

Response:

```json
{
  "id": "community-post-id",
  "user_id": "user-id",
  "weekly_quest_id": "weekly-community-quest-id",
  "user_quest_id": "completed-weekly-user-quest-id",
  "photo_url": null,
  "caption": "Finished this challenge without a photo.",
  "likes_count": 0
}
```

### Weekly Posts

`GET /community/weekly/{weekly_quest_id}/posts`

Response:

```json
[
  {
    "id": "community-post-id",
    "user_id": "user-id",
    "weekly_quest_id": "weekly-community-quest-id",
    "user_quest_id": "completed-weekly-user-quest-id",
    "photo_url": null,
    "caption": "Finished this challenge without a photo.",
    "likes_count": 0
  }
]
```

### Weekly Leaderboard

`GET /community/weekly/{weekly_quest_id}/leaderboard`

Response:

```json
[
  {
    "rank": 1,
    "user_id": "user-id",
    "likes_count": 5,
    "post_id": "community-post-id"
  }
]
```

## Photos

Photo support is currently a mock/local flow. Photos are optional for quest completion.

### Get Upload URL

`POST /photos/upload-url`

Auth required.

Response:

```json
{
  "upload_url": "local://uploads/user-id/photo.jpg",
  "method": "mock"
}
```

### Save Photo Metadata

`POST /photos/metadata`

Auth required. The backend echoes/stores no permanent photo metadata yet; this is a placeholder endpoint.

Request:

```json
{
  "photo_url": "local://uploads/user-id/photo.jpg",
  "width": 1200,
  "height": 900
}
```

Response:

```json
{
  "user_id": "user-id",
  "metadata": {
    "photo_url": "local://uploads/user-id/photo.jpg",
    "width": 1200,
    "height": 900
  }
}
```

## Achievements

### List Achievements

`GET /achievements`

Response:

```json
[
  {
    "id": "achievement-id",
    "name": "First Quest Complete",
    "description": "Complete your first side quest.",
    "icon_key": "first_quest",
    "category": "milestone",
    "condition_type": "completed_quests",
    "condition_value": {"count": 1},
    "xp_bonus": 25,
    "coin_bonus": 10,
    "item_reward_id": null,
    "is_active": true
  }
]
```

### User Achievement Progress

`GET /achievements/progress`

Auth required.

Response:

```json
[
  {
    "id": "user-achievement-id",
    "user_id": "user-id",
    "achievement_id": "achievement-id",
    "unlocked_at": "2026-06-23T06:05:28.411557Z",
    "progress": 1.0
  }
]
```

## Walking And NPC

### Start Walking Session

`POST /walking/session/start`

Auth required.

Request:

```json
{
  "lat": 49.2827,
  "lng": -123.1207
}
```

Response example:

```json
{
  "id": "walking-session-id",
  "user_id": "user-id",
  "started_at": "2026-06-23T06:05:28.411557Z",
  "ended_at": null,
  "start_lat": 49.2827,
  "start_lng": -123.1207,
  "last_lat": 49.2827,
  "last_lng": -123.1207,
  "total_distance_m": 0,
  "is_active": true
}
```

### Update Walking Session

`POST /walking/session/update`

Auth required.

Request:

```json
{
  "session_id": "walking-session-id",
  "lat": 49.283,
  "lng": -123.121,
  "speed_mps": 1.4
}
```

Response: updated walking session object.

### End Walking Session

`POST /walking/session/end?session_id=walking-session-id`

Auth required.

Response:

```json
{
  "ended": true
}
```

### Check NPC Spawn

`POST /npc/spawn/check`

Auth required.

Response:

```json
{
  "npc_spawned": true,
  "offer": {
    "id": "offer-id",
    "user_id": "user-id",
    "npc_id": "npc-id",
    "generated_title": "A Tiny Errand From Pixel Wanderer",
    "generated_description": "Complete this small challenge before the offer expires.",
    "xp_reward": 40,
    "coin_reward": 12,
    "status": "offered"
  }
}
```

### Current NPC Offer

`GET /npc/offers/current`

Auth required.

Response is an NPC offer object or `null`.

### Accept NPC Offer

`POST /npc/offers/{offer_id}/accept`

Auth required.

Response: accepted NPC offer or generated NPC quest, depending on service result.

### Decline NPC Offer

`POST /npc/offers/{offer_id}/decline`

Auth required.

Response: declined NPC offer.

## ML And Recommendations

These are fallback rule-based endpoints right now, not OpenAI-powered quest writing.

### Recommend

`POST /ml/recommend`

Auth required.

Request:

```json
{
  "lat": 49.2827,
  "lng": -123.1207,
  "timezone": "America/Vancouver",
  "limit": 5
}
```

Response example:

```json
[
  {
    "title": "Visit a New Park",
    "quest_type": "location",
    "score": 0.82
  }
]
```

The exact response shape comes from the fallback recommender and may be refined later.

### Adapt Difficulty

`POST /ml/adapt-difficulty`

Auth required.

Request:

```json
{
  "quest_type": "social",
  "base_difficulty": 3
}
```

Response:

```json
{
  "quest_type": "social",
  "difficulty": 3
}
```

### Record ML Event

`POST /ml/events`

Auth required.

Request:

```json
{
  "user_quest_id": "quest-id",
  "event_type": "completed",
  "quest_type": "social",
  "difficulty": 3,
  "rating": 5,
  "context": {
    "screen": "quest_complete"
  }
}
```

Response:

```json
{
  "id": "ml-interaction-id"
}
```

### ML Health

`GET /ml/health`

Response:

```json
{
  "status": "ok",
  "mode": "fallback-rule-based"
}
```

## External API Smoke Tests

These are useful during development to test weather and places integrations.

### Weather

`GET /external/weather?lat=49.2827&lng=-123.1207`

Response example:

```json
{
  "temperature_c": 17.2,
  "condition": "clear",
  "wind_speed_kmh": 8.4,
  "source": "open-meteo"
}
```

### Places

`GET /external/places?lat=49.2827&lng=-123.1207&radius_km=5`

Response example:

```json
[
  {
    "name": "Harbor Green Park",
    "place_type": "park",
    "lat": 49.2857,
    "lng": -123.1207,
    "distance_m": 420
  }
]
```

## Health

### Liveness

`GET /health`

Response:

```json
{
  "status": "ok",
  "app": "Quest Up API"
}
```

### Readiness

`GET /health/ready`

Response:

```json
{
  "status": "ready",
  "checks": {
    "database": true,
    "redis": true
  }
}
```

## Recommended Mobile Startup Flow

1. Register or login.
2. Store `access_token` and `refresh_token` securely.
3. Call `GET /auth/me`.
4. Call `GET /profile`.
5. Call `POST /quests/session/open` with location/timezone if available.
6. Render normal quests, weekly quest, progression, and current NPC offer.
7. Use `POST /quests/{quest_id}/accept`, `skip`, and `complete` for quest actions.
8. After completion, refresh `GET /auth/me`, `GET /profile/stats`, `GET /inventory`, and `GET /achievements/progress`.
9. For store screens, call `GET /store/items` and `GET /inventory`.

## Common Error Shapes

Validation error:

```json
{
  "detail": [
    {
      "type": "value_error",
      "loc": ["body", "rating"],
      "msg": "Input should be less than or equal to 5"
    }
  ]
}
```

Application error:

```json
{
  "detail": "Quest is not completable"
}
```

Auth error:

```json
{
  "detail": "Invalid email or password"
}
```
