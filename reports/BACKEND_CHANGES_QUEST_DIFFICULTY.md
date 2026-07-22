# Backend bug: every quest shows as "Hard" (Quest-Up / FastAPI)

## Status: still open (re-verified)

A backend change landed recently (commit `9a0001a`, "Fix of the weekly
quests"), but it only touched `app/api/routes/community.py`,
`app/core/config.py`, `app/main.py`, `app/seed.py`, and
`app/services/weekly_quest_service.py` — the weekly-quest rollover issue, a
separate bug. `app/services/quest_generation_service.py` and
`app/services/difficulty_service.py` have no commits and no uncommitted
changes touching them; the exact lines flagged below (lines 99-101) are
unchanged. **The fix described in this doc has not been applied yet.**

Every quest a user is assigned shows the same difficulty label in the app —
currently "Hard" for every account tested — regardless of what kind of quest
it is. Confirmed with a live DB query, not a guess:

```
 difficulty |             generated_title              |     template_title      | template_base_difficulty
------------+------------------------------------------+-------------------------+--------------------------
          3 | Outdoor Fitness Burst: Harbor Green Park | Outdoor Fitness Burst   |                        3
          3 | Visit a New Park: Harbor Green Park      | Visit a New Park        |                        2
          3 | Sketch the View: Hidden Mural Alley      | Sketch the View         |                        2
          3 | Cafe Vibe Check: Side Quest Cafe         | Cafe Vibe Check         |                        1
          3 | Compliment Three People                  | Compliment Three People |                        3
```

Every row is `difficulty = 3` ("Hard" in the frontend's
`Quest.difficultyLabel`, `lib/features/quests/models/quest_models.dart`) even
though the underlying templates range from 1 ("Cafe Vibe Check") to 3
("Compliment Three People"). This is a backend generation bug, not a frontend
labeling bug — the frontend's 1→Easy / 2→Medium / 3→Hard mapping is correct;
the API is sending `3` for everything.

## Root cause

`QuestGenerationService.generate` (`app/services/quest_generation_service.py:99-101`):

```python
preferred_difficulty = profile.preferred_difficulty if profile else None
base_difficulty = preferred_difficulty or chosen.base_difficulty
difficulty = self.difficulty.adapt(base_difficulty)
```

`preferred_difficulty` is the value set once during onboarding
(`lib/features/onboarding/presentation/adventure_level_screen.dart` on the
frontend; defaults to `3`, "Adventurer," if the user doesn't change it — see
`OnboardingFlowState.difficulty` in `onboarding_flow_provider.dart`). Because
it's a per-*user* value, not a per-*quest* value, and it unconditionally wins
over `chosen.base_difficulty` (the per-*template*'s own intended difficulty)
whenever it's set, every quest generated for that user gets exactly the same
difficulty — the user's one onboarding number — no matter which of the five
templates (spanning base difficulty 1–3) was actually picked.

`DifficultyService.adapt` (`app/services/difficulty_service.py`) doesn't
rescue this either: it's called as `self.difficulty.adapt(base_difficulty)`
with no `completion_rate` argument, so it always takes the
`completion_rate is None` branch and just clamps the input to `[1, 5]` — no
per-quest variation happens there.

Net effect: `preferred_difficulty` was clearly meant to be a *starting
point/nudge* — the onboarding copy says "how much of a challenge do you want
your quests to be?" — but the current logic makes it a hard, permanent
override that erases each template's own difficulty entirely.

## Suggested fix

Blend the two instead of letting one replace the other, e.g. average and
round, or bias toward the template's own difficulty and use
`preferred_difficulty` only as a bounded adjustment:

```python
preferred_difficulty = profile.preferred_difficulty if profile else None
if preferred_difficulty is None:
    base_difficulty = chosen.base_difficulty
else:
    # Nudge the template's own difficulty toward the user's preference
    # instead of replacing it outright, so quest-to-quest variety survives.
    base_difficulty = round((chosen.base_difficulty + preferred_difficulty) / 2)
difficulty = self.difficulty.adapt(base_difficulty)
```

(Exact blend formula is a design call for whoever owns this service — the
important part is that `chosen.base_difficulty` must still influence the
result per-quest, not just the user's one onboarding value every time.)

## Verification

- Generate several quests from different templates (spanning base difficulty
  1–3) for the same user with a fixed `preferred_difficulty` — resulting
  `difficulty` values should vary across quests, not all collapse to one
  number.
- The Quests screen should show a mix of Easy / Medium / Hard across a
  user's active quests, not one label for everything.
