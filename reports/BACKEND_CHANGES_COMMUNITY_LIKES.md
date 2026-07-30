# Backend gap: liking a community post isn't wired up (Quest-Up / FastAPI)

The Weekly screen's community photo cards used to show a heart + a like
count next to each post. It's been removed from the UI for now (frontend
commit) because there is nothing behind it to make it work — confirmed by
reading `app/models/community.py`, `app/api/routes/community.py`, and
`app/schemas/community.py`.

## Current state

`CommunityPost.likes_count` (`app/models/community.py:39`) is a plain
integer column, `default=0`, with only a `>= 0` check constraint. Nothing in
the codebase ever increments it:

```python
likes_count: Mapped[int] = mapped_column(Integer, default=0)
```

It's read in exactly two places — `CommunityPostOut` (serialization) and the
leaderboard query's `ORDER BY` (`app/api/routes/community.py:57`) — both
read-only. There is no `POST`/`DELETE` route anywhere under
`/community/...` for liking a post, and no table recording *which* user
liked *which* post. Without that second part, there's no way to:

- stop the same user from liking a post twice (or a hundred times) to
  inflate the count,
- support unliking (toggling), or
- tell a given viewer whether *they've* already liked a post, so the
  frontend can render the heart filled vs. outlined.

## Suggested fix

Not a large change — comparable in scope to the earlier weekly-rollover fix,
not a redesign:

1. **New join table**, e.g.:

   ```python
   class CommunityPostLike(UUIDPrimaryKeyMixin, Base):
       __tablename__ = "community_post_likes"
       __table_args__ = (UniqueConstraint("user_id", "post_id", name="uq_post_likes_user_post"),)

       user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
       post_id: Mapped[str] = mapped_column(ForeignKey("community_posts.id", ondelete="CASCADE"), index=True)
       created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
   ```

   The unique constraint on `(user_id, post_id)` is what makes "like" safely
   idempotent — a duplicate `POST` just no-ops instead of double-counting.

2. **Two routes** under `/community/weekly/{weekly_quest_id}/posts/{post_id}`:
   - `POST .../like` — insert into `community_post_likes` (ignore if the
     unique constraint rejects a duplicate), increment `likes_count`.
   - `DELETE .../like` — delete the row if present, decrement `likes_count`.

   Either do both writes in one transaction, or — simpler and always
   consistent — drop the `likes_count` column entirely and compute the count
   with `SELECT count(*) FROM community_post_likes WHERE post_id = ...` at
   read time (fine at this data scale, and removes any chance of the counter
   drifting from reality).

3. **Add `is_liked_by_me: bool` to `CommunityPostOut`**, resolved per-request
   from `current_user.id` against `community_post_likes`. Without this the
   frontend can show a count but never a correct filled/outlined heart state
   for the viewer.

## Frontend follow-up (once this ships)

- Reintroduce the heart in `_PhotoCard` (`lib/features/weekly/presentation/weekly_quest_screen.dart`),
  wired to `POST`/`DELETE` the like endpoint and toggling on
  `post.isLikedByMe`.
- `WeeklyPhotoPost` (`lib/features/weekly/models/weekly_models.dart`) already
  parses `likes_count`; add `is_liked_by_me` alongside it.
- Optimistic update on tap (flip the heart + count immediately, roll back on
  a failed request) rather than waiting on a round trip, consistent with how
  `AcceptedQuestIdsNotifier` already does optimistic accept/abandon.

## Verification

- Like the same post twice from the same account — `likes_count` must only
  go up by 1, and the second `POST` should succeed (no-op) rather than error.
- Unlike, then re-like — count should return to 1, not stack.
- Fetch the same post's list as two different accounts — each should see
  `is_liked_by_me` reflect *their own* like state independently.
