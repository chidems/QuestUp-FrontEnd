# Backend changes required for onboarding (Quest-Up / FastAPI)

The onboarding preferences wizard is fully implemented on the frontend and
already persists `preferred_quest_types`, `preferred_difficulty`, and
`preferred_radius_km` through the existing `PUT /profile` — those fields need
**no backend changes**.

One field is missing server-side: a persistent **`onboarding_completed`**
flag. Until it exists, the frontend tracks completion with a local per-user
flag (`pref_onboarding_pending_<userId>` in SharedPreferences, see
`lib/features/onboarding/providers/onboarding_status_provider.dart`). That
covers the common case but is device-local: a user who reinstalls or logs in
on a new device won't be re-prompted (login never triggers onboarding), but
their completion state isn't portable either. The backend flag is the honest
fix.

## 1. Model — `app/models/user.py`

Add to `UserProfile`:

```python
onboarding_completed: Mapped[bool] = mapped_column(Boolean, default=False)
```

No change needed to `auth_service.py` — `UserProfile(user_id=user.id)`
already relies on column defaults.

## 2. Schemas — `app/schemas/profile.py`

```python
class ProfileOut(BaseModel):
    ...
    onboarding_completed: bool

class ProfileUpdate(BaseModel):
    ...
    onboarding_completed: bool | None = None
```

No route changes — `PUT /profile` already applies whatever fields are set
via `model_dump(exclude_unset=True)`.

## 3. Migration — new file in `alembic/versions/`

Follow the existing naming convention (e.g.
`20260714_0004_onboarding_completed.py`):

```python
op.add_column(
    "user_profiles",
    sa.Column("onboarding_completed", sa.Boolean(), nullable=False,
              server_default="false"),
)
# Existing users must not be dropped into onboarding retroactively:
op.execute("UPDATE user_profiles SET onboarding_completed = true")
```

The backfill runs after the column add, so rows that existed before the
migration end up `true`; genuinely new rows created afterwards default to
`false` via the model/column default.

## 4. Frontend follow-up once this ships

Two small changes in QuestUp-FrontEnd:

1. `UserProfile.toUpdateJson()` / `fromJson()`
   (`lib/features/profile/models/profile_models.dart`): add the
   `onboarding_completed` field, and have the wizard's submit send
   `onboarding_completed: true`.
2. `OnboardingStatusNotifier.build()`
   (`lib/features/onboarding/providers/onboarding_status_provider.dart`):
   replace the LocalCache read with the field from
   `userProfileProvider` (`GET /profile`), keeping the same
   `markCompleted()` API. The register-time `expectNewUser()` sentinel can
   then be deleted too — a fresh `GET /profile` returning
   `onboarding_completed: false` is the trigger.

## Verification (from the plan)

- `alembic upgrade head` runs clean.
- `GET /profile` for a freshly registered user returns
  `onboarding_completed: false`; for pre-migration users, `true`.
- `PUT /profile {"onboarding_completed": true}` persists.
