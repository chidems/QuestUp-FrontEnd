# Backend gaps: community post photos and author names (Quest-Up / FastAPI)

Two issues found testing the weekly-quest photo share flow end-to-end
(complete the weekly quest with a photo → share to community → check the
Weekly tab). Both are backend contract gaps, not frontend bugs — confirmed by
reading `app/api/routes/community.py`, `app/api/routes/photos.py`, and
`app/schemas/community.py`, and by exercising the real endpoints:

```
POST /photos/upload-url            -> {"upload_url": "local://uploads/<user_id>/photo.jpg", "method": "mock"}
POST /community/weekly/{id}/submit -> 200, post created
GET  /community/weekly/{id}/posts  -> [{"id": ..., "user_id": "231c292b-...", "weekly_quest_id": ..., "user_quest_id": ...,
                                        "photo_url": "local://uploads/231c292b-.../photo.jpg", "caption": null, "likes_count": 0}]
```

The post itself submits and lists correctly — this isn't a "the share
silently failed" bug. The two problems are in what the post *contains*.

## 1. Photos never actually upload — `photo_url` is a non-fetchable placeholder

`POST /photos/upload-url` (`app/api/routes/photos.py:9-11`) doesn't accept or
store a file at all; it just returns a synthetic `local://uploads/<user_id>/photo.jpg`
string, and there is no route that ever accepts binary photo data. That
`local://` URL is then saved as-is on the `CommunityPost.photo_url` column and
returned unchanged by `GET /community/weekly/{id}/posts`. No client can ever
render it — it isn't `http(s)`, and there is nothing hosted behind it —
so every shared photo is permanently a dead link, not just this one.

**Frontend workaround already shipped:** the Weekly screen now detects any
`photo_url` that isn't `http(s)` and shows an honest "Photo pending upload
support" placeholder instead of attempting to fetch it (which used to render
as a generic broken-image icon — indistinguishable from an actual bug). This
does not make photos visible; it only stops misrepresenting the failure as
one.

### Suggested fix

Add real object storage (S3-compatible bucket, or even local disk + a static
file route for local/dev) behind `/photos/upload-url`, so it either:
- returns a pre-signed upload URL the client can `PUT` the file to directly, or
- accepts multipart file data on a new endpoint and returns the resulting
  public/authenticated fetch URL,

then stores *that* URL on `CommunityPost.photo_url` (and `QuestCompletion`'s
own photo field, which has the same problem for quest-completion photos).

## 2. `CommunityPostOut` has no author name — only a raw `user_id`

`CommunityPostOut` (`app/schemas/community.py`) exposes `user_id: str` and
nothing else identifying the poster:

```python
class CommunityPostOut(BaseModel):
    id: str
    user_id: str
    weekly_quest_id: str | None
    user_quest_id: str | None
    photo_url: str | None
    caption: str | None
    likes_count: int
```

There's no join to `users` for a display name anywhere in `posts()`
(`app/api/routes/community.py:44-47` — a plain `select(CommunityPost)`, no
join). The frontend has no way to resolve an arbitrary `user_id` to a name —
there's no "get user by id" endpoint either.

**Frontend workaround already shipped:** the app never displays the raw
`user_id` (it read like a meaningless "generated number" to players). It
shows "You" for the current user's own post (their name is already known
client-side from `/auth/me`) and a generic "A Fellow Adventurer" for every
other post. Every other user's post is effectively anonymous until this
ships.

### Suggested fix

Join `User.display_name` in `posts()` and add it to `CommunityPostOut`, e.g.:

```python
class CommunityPostOut(BaseModel):
    ...
    user_display_name: str
```

```python
stmt = (
    select(CommunityPost, User.display_name)
    .join(User, User.id == CommunityPost.user_id)
    .where(CommunityPost.weekly_quest_id == weekly_quest_id)
    .order_by(CommunityPost.created_at.desc())
)
```

The frontend already reads `user_display_name` when present
(`WeeklyPhotoPost.fromJson`) — no frontend change needed once this ships.

## Verification

- Share a photo to the weekly community feed from two different accounts.
- `GET /community/weekly/{id}/posts` should return a real, fetchable
  `photo_url` for each post (not `local://...`), and a `user_display_name`
  distinct per account.
- The Weekly screen's community photos section should show each poster's
  real name and the actual uploaded image once both ship.
