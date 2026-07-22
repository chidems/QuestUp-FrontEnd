# Backend gap: weekly community quest never rolls over (Quest-Up / FastAPI)

The Weekly Quest screen goes empty ("No weekly quest right now") against the
real backend once the seeded quest's week ends — confirmed against the local
DB, not a guess:

```
title                            status  starts_at                   ends_at
Neighborhood Snapshot Challenge  active  2026-07-09 19:09:35         2026-07-16 19:09:35
```

The row is still marked `status = active`, but its `ends_at` passed days ago.
`GET /community/weekly/current` (`app/api/routes/community.py:18-28`) filters
on `ends_at > utcnow()`, correctly excludes the lapsed row, and returns `200
null` — which is the right response for "no active quest right now," but
nothing ever creates the *next* week's quest, so the app is stuck in that
state indefinitely.

## Root cause

The only code that ever inserts a `WeeklyCommunityQuest` is `seed_weekly()`
in `app/seed.py:173-193` — a one-off dev seed function, not a recurring job:

```python
async def seed_weekly(db, items):
    if await db.scalar(
        select(WeeklyCommunityQuest).where(
            WeeklyCommunityQuest.status == WeeklyQuestStatus.active,
            WeeklyCommunityQuest.starts_at <= utcnow(),
            WeeklyCommunityQuest.ends_at > utcnow(),
        )
    ):
        return
    db.add(WeeklyCommunityQuest(
        title="Neighborhood Snapshot Challenge",
        ...
        starts_at=utcnow(),
        ends_at=utcnow() + timedelta(days=7),
        status=WeeklyQuestStatus.active,
    ))
```

It's only invoked from `seed()`, which is run manually (`python -m
app.seed`) — typically once, when a dev/environment is first set up. There is
no cron/APScheduler/Celery-beat task (or any other mechanism) in the backend
that re-runs this check on a schedule. So the very first weekly quest works
for exactly 7 days, then every environment (local, staging, prod alike) sees
`/community/weekly/current` return null forever, until someone notices and
reruns the seed script by hand.

## Suggested fix

Turn `seed_weekly`'s "create one if none is currently active" logic into a
recurring job instead of a manual one-time script step, e.g.:

- Add a scheduled task (APScheduler job, Celery beat task, or a simple
  cron-triggered management command — whatever this backend's existing
  scheduling story is, since none of the reviewed code shows one yet) that
  runs at least once a day and calls the same "insert a new
  `WeeklyCommunityQuest` if none is active-and-in-window" logic already in
  `seed_weekly()`.
- Consider also chaining `ends_at` off the *previous* quest's `ends_at`
  instead of `utcnow()` when one just expired, so weeks stay contiguous
  (back-to-back) rather than having a gap sized by however long it takes the
  job to notice.
- Longer term, the quest content itself (title/description/rewards) is
  hardcoded to "Neighborhood Snapshot Challenge" — worth deciding whether
  future weeks should rotate through a small template pool (mirroring how
  normal quests use `QuestTemplate`) rather than repeating the same one
  forever, but that's a separate product decision from the rollover bug
  itself.

## Frontend note

The frontend has already been updated to treat `null` from
`/community/weekly/current` as a normal "no quest this week" state (empty
view with a "Check back soon!" message) rather than an error screen, so no
frontend changes are needed once this ships — the screen will simply start
showing the new quest as soon as one exists.

## Verification

- Let a seeded weekly quest's `ends_at` pass (or manually update the row) and
  confirm the rollover job creates a new active quest without manual
  intervention.
- `GET /community/weekly/current` should return a non-null quest
  continuously over time, with no multi-day gaps between one quest's
  `ends_at` and the next quest's `starts_at`.
