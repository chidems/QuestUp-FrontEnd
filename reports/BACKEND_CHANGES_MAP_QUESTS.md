# Backend change required for map quest pins (Quest-Up / FastAPI)

The Map screen shows "0 quests nearby" and no pins against the real backend,
even though the same quests appear correctly in the Quests list. This is a
backend serialization gap, not a frontend bug — confirmed by reading the
actual source in `Quest-Up/app/models/quest.py` and
`Quest-Up/app/schemas/quest.py`.

## Root cause

`UserQuest` (`app/models/quest.py`) already stores per-quest coordinates:

```python
target_lat: Mapped[float | None] = mapped_column(Numeric(10, 6))
target_lng: Mapped[float | None] = mapped_column(Numeric(10, 6))
```

But `QuestOut` (`app/schemas/quest.py`), the Pydantic response schema used by
`/quests/session/open`, `/quests/active`, `/quests/generate`,
`/quests/{id}/accept` and `/quests/{id}/skip`, never declares those two
fields:

```python
class QuestOut(BaseModel):
    id: str
    source: str
    generated_title: str
    generated_description: str
    quest_type: str
    stat_category: str
    difficulty: int
    xp_reward: int
    coin_reward: int
    status: str
    target_place_name: str | None = None
    target_place_type: str | None = None

    model_config = {"from_attributes": True}
```

Every route builds the response with `QuestOut.model_validate(q)` off the ORM
object — since `target_lat`/`target_lng` aren't declared on the schema,
Pydantic silently drops them, regardless of what's in the database row. The
frontend's `Quest.fromJson` (`lib/features/quests/models/quest_models.dart`)
gets `null` for both on every quest, and `mapQuestsProvider`
(`lib/features/map/providers/map_providers.dart`) filters out any quest
without coordinates before it can become a pin — hence zero pins and "0
quests nearby", while the same quests render fine in the Quests list (which
doesn't need coordinates).

Mock mode never surfaced this: the mock fixtures in
`lib/features/quests/data/quest_api.dart` hardcode `targetLatitude`/
`targetLongitude` directly in the fake JSON, bypassing the real schema
entirely.

## Fix — `app/schemas/quest.py`

Add the two fields to `QuestOut`, matching the ORM attribute names exactly
(the convention this schema already uses everywhere else — `xp_reward`,
`coin_reward`, `quest_type`, etc. are all exact snake_case matches to the ORM,
no aliasing):

```python
class QuestOut(BaseModel):
    id: str
    source: str
    generated_title: str
    generated_description: str
    quest_type: str
    stat_category: str
    difficulty: int
    xp_reward: int
    coin_reward: int
    status: str
    target_lat: float | None = None
    target_lng: float | None = None
    target_place_name: str | None = None
    target_place_type: str | None = None

    model_config = {"from_attributes": True}
```

No route changes needed — every route already does `QuestOut.model_validate(q)`
off the `UserQuest` ORM object, so the new fields populate automatically once
declared.

## Frontend follow-up once this ships

One field-name change in QuestUp-FrontEnd, `lib/features/quests/models/quest_models.dart`
(`Quest.fromJson`), to match the backend's naming:

```dart
targetLatitude: (json['target_lat'] as num?)?.toDouble(),
targetLongitude: (json['target_lng'] as num?)?.toDouble(),
```

(currently reads `target_latitude` / `target_longitude`, which the backend
never sends under any name).

## Optional, separate gap: `distance_meters`

While reading the schema, note `QuestOut` also never returns `distance_meters`
(used for the "X m / X km" chip on the quest card and map info card) —
`/quests/session/open` already has the user's `lat`/`lng` in
`SessionOpenRequest`, so a haversine calc against each quest's `target_lat`/
`target_lng` would be straightforward to add there if wanted. Not required to
fix the pins/nearby-count issue — the frontend already treats
`distanceMeters` as optional and simply hides the chip when it's null.

## Verification

- `GET`/equivalent quest-list responses include non-null `target_lat`/
  `target_lng` for quests that have a location (location-type quests;
  social/action quests may legitimately have neither).
- Map screen: pins appear for those quests, and the "N quests nearby" badge
  reflects the count.
