# Backend change required for store item catalog (Quest-Up / FastAPI)

The Store screen against the real backend only shows **7 items** (Basic
Shirt, Adventurer Jacket, Explorer Hat, Star Accessory, Wooden Sword, Trophy
Badge, Weekly Cape) instead of the full **84-item** catalog the frontend
shipped with (and that mock mode has always shown). This is a seed-data gap,
not a frontend bug — confirmed by reading `Quest-Up/app/seed.py`.

## Root cause

`seed_avatar_items()` in `app/seed.py` only inserts 7 `AvatarItem` rows —
those are genuinely all the items that exist in the `avatar_items` table.
`/store/items` (`app/api/routes/avatar.py:29`) faithfully returns every
active row, so the frontend is displaying exactly what's in the database.

The other 77 items only exist client-side, in
`lib/features/avatar/data/asset_catalog.g.dart`'s `kItems` list (used by mock
mode's `StoreApi.getItems()`), with real pixel art already bundled at
`sprites/items/item_001.png` … `item_084.png` and prices derived from a
rarity table (`tool/gen_catalog.dart`: common 40 / uncommon 90 / rare 180 /
epic 320 / legendary 600).

## Fix — seed the full catalog in `app/seed.py`

Extend `seed_avatar_items()`'s `rows` list with the 84 entries below. Each
`pixel_asset_key` is set to the existing frontend catalog id (`item_001` …
`item_084`) — the frontend can resolve those directly against its own
`AssetCatalog.itemById` map, so no new sprites or frontend asset registry are
needed, only a lookup change (see "Frontend follow-up" below).

```python
rows = [
    # ... existing 7 rows (basic_shirt, adventurer_jacket, explorer_hat,
    # star_accessory, wooden_sword, trophy_badge, weekly_cape) stay as-is ...
    AvatarItem(name="Squire's Sword", item_type=AvatarItemType.accessory, pixel_asset_key="item_001", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Knight's Blade", item_type=AvatarItemType.accessory, pixel_asset_key="item_002", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Chef's Knife", item_type=AvatarItemType.accessory, pixel_asset_key="item_003", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Shadow Dagger", item_type=AvatarItemType.accessory, pixel_asset_key="item_004", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Frost Blade", item_type=AvatarItemType.accessory, pixel_asset_key="item_005", price_coins=600, rarity=Rarity.legendary),
    AvatarItem(name="Oak Staff", item_type=AvatarItemType.accessory, pixel_asset_key="item_006", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Red Rose", item_type=AvatarItemType.accessory, pixel_asset_key="item_007", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Carrot", item_type=AvatarItemType.accessory, pixel_asset_key="item_008", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Star Wand", item_type=AvatarItemType.accessory, pixel_asset_key="item_009", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Sapphire Scepter", item_type=AvatarItemType.accessory, pixel_asset_key="item_010", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Amethyst Scepter", item_type=AvatarItemType.accessory, pixel_asset_key="item_011", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Moonvine Staff", item_type=AvatarItemType.accessory, pixel_asset_key="item_012", price_coins=600, rarity=Rarity.legendary),
    AvatarItem(name="Bubble Tea", item_type=AvatarItemType.accessory, pixel_asset_key="item_013", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Swirl Lollipop", item_type=AvatarItemType.accessory, pixel_asset_key="item_014", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Hunter's Bow", item_type=AvatarItemType.accessory, pixel_asset_key="item_015", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Vine Bow", item_type=AvatarItemType.accessory, pixel_asset_key="item_016", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Ribbon Bow", item_type=AvatarItemType.accessory, pixel_asset_key="item_017", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Crossbow", item_type=AvatarItemType.accessory, pixel_asset_key="item_018", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Slingshot", item_type=AvatarItemType.accessory, pixel_asset_key="item_019", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Fishing Rod", item_type=AvatarItemType.accessory, pixel_asset_key="item_020", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Butterfly Net", item_type=AvatarItemType.accessory, pixel_asset_key="item_021", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Black Umbrella", item_type=AvatarItemType.accessory, pixel_asset_key="item_022", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Lace Parasol", item_type=AvatarItemType.accessory, pixel_asset_key="item_023", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Iron Lantern", item_type=AvatarItemType.accessory, pixel_asset_key="item_024", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Torch", item_type=AvatarItemType.accessory, pixel_asset_key="item_025", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Paper Kite", item_type=AvatarItemType.accessory, pixel_asset_key="item_026", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Balloon Puppy", item_type=AvatarItemType.accessory, pixel_asset_key="item_027", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Skateboard", item_type=AvatarItemType.accessory, pixel_asset_key="item_028", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Old Tome", item_type=AvatarItemType.accessory, pixel_asset_key="item_029", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Moon Tome", item_type=AvatarItemType.accessory, pixel_asset_key="item_030", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Leaf Tome", item_type=AvatarItemType.accessory, pixel_asset_key="item_031", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Gem Tome", item_type=AvatarItemType.accessory, pixel_asset_key="item_032", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Heart Tome", item_type=AvatarItemType.accessory, pixel_asset_key="item_033", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Retro Console", item_type=AvatarItemType.accessory, pixel_asset_key="item_034", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Flip Phone", item_type=AvatarItemType.accessory, pixel_asset_key="item_035", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Teddy Bear", item_type=AvatarItemType.accessory, pixel_asset_key="item_036", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Bunny Plush", item_type=AvatarItemType.accessory, pixel_asset_key="item_037", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Cat Plush", item_type=AvatarItemType.accessory, pixel_asset_key="item_038", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Shiba Plush", item_type=AvatarItemType.accessory, pixel_asset_key="item_039", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Rubber Duck", item_type=AvatarItemType.accessory, pixel_asset_key="item_040", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Snow Globe", item_type=AvatarItemType.accessory, pixel_asset_key="item_041", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Music Box", item_type=AvatarItemType.accessory, pixel_asset_key="item_042", price_coins=600, rarity=Rarity.legendary),
    AvatarItem(name="Heart Wand", item_type=AvatarItemType.accessory, pixel_asset_key="item_043", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Charm Wand", item_type=AvatarItemType.accessory, pixel_asset_key="item_044", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Candy Cane", item_type=AvatarItemType.accessory, pixel_asset_key="item_045", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Pinwheel", item_type=AvatarItemType.accessory, pixel_asset_key="item_046", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Sunflower", item_type=AvatarItemType.accessory, pixel_asset_key="item_047", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Cotton Candy", item_type=AvatarItemType.accessory, pixel_asset_key="item_048", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Sparkler", item_type=AvatarItemType.accessory, pixel_asset_key="item_049", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Glow Stick", item_type=AvatarItemType.accessory, pixel_asset_key="item_050", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Pink Balloon", item_type=AvatarItemType.accessory, pixel_asset_key="item_051", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Star Balloon", item_type=AvatarItemType.accessory, pixel_asset_key="item_052", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Paw Wand", item_type=AvatarItemType.accessory, pixel_asset_key="item_053", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Disco Ball", item_type=AvatarItemType.accessory, pixel_asset_key="item_054", price_coins=600, rarity=Rarity.legendary),
    AvatarItem(name="Retro Camera", item_type=AvatarItemType.accessory, pixel_asset_key="item_055", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Boombox", item_type=AvatarItemType.accessory, pixel_asset_key="item_056", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Pickaxe", item_type=AvatarItemType.accessory, pixel_asset_key="item_057", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Woodcutter Axe", item_type=AvatarItemType.accessory, pixel_asset_key="item_058", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Shovel", item_type=AvatarItemType.accessory, pixel_asset_key="item_059", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Sickle", item_type=AvatarItemType.accessory, pixel_asset_key="item_060", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Sledgehammer", item_type=AvatarItemType.accessory, pixel_asset_key="item_061", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Shuriken", item_type=AvatarItemType.accessory, pixel_asset_key="item_062", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Nunchucks", item_type=AvatarItemType.accessory, pixel_asset_key="item_063", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Spiked Flail", item_type=AvatarItemType.accessory, pixel_asset_key="item_064", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Wrench", item_type=AvatarItemType.accessory, pixel_asset_key="item_065", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Quest Scroll Kit", item_type=AvatarItemType.accessory, pixel_asset_key="item_066", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Green Elixir", item_type=AvatarItemType.accessory, pixel_asset_key="item_067", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Spray Can", item_type=AvatarItemType.accessory, pixel_asset_key="item_068", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Megaphone", item_type=AvatarItemType.accessory, pixel_asset_key="item_069", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Microphone", item_type=AvatarItemType.accessory, pixel_asset_key="item_070", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Bubble Blower", item_type=AvatarItemType.accessory, pixel_asset_key="item_071", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Potted Cactus", item_type=AvatarItemType.accessory, pixel_asset_key="item_072", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Aloe Plant", item_type=AvatarItemType.accessory, pixel_asset_key="item_073", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Coffee To-Go", item_type=AvatarItemType.accessory, pixel_asset_key="item_074", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Sprout Pouch", item_type=AvatarItemType.accessory, pixel_asset_key="item_075", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Watering Can", item_type=AvatarItemType.accessory, pixel_asset_key="item_076", price_coins=40, rarity=Rarity.common),
    AvatarItem(name="Soft Serve", item_type=AvatarItemType.accessory, pixel_asset_key="item_077", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Taiyaki", item_type=AvatarItemType.accessory, pixel_asset_key="item_078", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Jar & Ukulele", item_type=AvatarItemType.accessory, pixel_asset_key="item_079", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Pink Guitar", item_type=AvatarItemType.accessory, pixel_asset_key="item_080", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Violin", item_type=AvatarItemType.accessory, pixel_asset_key="item_081", price_coins=320, rarity=Rarity.epic),
    AvatarItem(name="Tambourine", item_type=AvatarItemType.accessory, pixel_asset_key="item_082", price_coins=90, rarity=Rarity.uncommon),
    AvatarItem(name="Pan Flute", item_type=AvatarItemType.accessory, pixel_asset_key="item_083", price_coins=180, rarity=Rarity.rare),
    AvatarItem(name="Sparrow", item_type=AvatarItemType.accessory, pixel_asset_key="item_084", price_coins=600, rarity=Rarity.legendary),
]
```

`price_coins` and `rarity` above mirror the exact tier table the frontend
catalog was generated with (`tool/gen_catalog.dart`):
common 40 / uncommon 90 / rare 180 / epic 320 / legendary 600.

**One design call the backend owner needs to make:** `AvatarItemType` has no
generic "held prop" category (it's `hair | head | body | outfit | accessory |
weapon | background | badge`), but these 84 items span swords, plushies,
instruments, tools, food, etc. — the frontend renders all of them identically
(one held item in the avatar's hand, no per-type behavior). The rows above
default everything to `AvatarItemType.accessory` as a placeholder so they at
least insert cleanly; swap in a more accurate type per item, or add a new enum
member (e.g. `prop`) if the category should be meaningful later.

Since `seed_avatar_items()` guards on `pixel_asset_key == "basic_shirt"`
already existing, re-running `python -m app.seed` after this change is safe
for a fresh DB, but **won't retroactively add rows to a database that already
has the 7-item seed** (the early-return skips the whole function). Either add
the 77 new rows as a follow-up `if not exists` block, or ship them via a
proper Alembic migration/data-seed script instead of relying on `seed.py`'s
run-once guard.

## Frontend follow-up once this ships

`AvatarItem.fromJson` (`lib/features/avatar/models/avatar_models.dart`)
currently only resolves `asset` against the small `kBackendItemAssets` map
(7 entries, for the original seed items — see `BACKEND_CHANGES_MAP_QUESTS.md`-style
change made when store icons were first wired up). It needs to also check the
existing 84-item catalog:

```dart
asset: kBackendItemAssets[json['pixel_asset_key'] as String?] ??
    AssetCatalog.itemById[json['pixel_asset_key'] as String?]?.asset,
```

No new sprites needed for this part — `sprites/items/item_001.png` … `item_084.png`
are already bundled and registered in `pubspec.yaml`.

## Verification

- `GET /store/items` returns 91 rows (7 original + 84 restored) with real,
  non-null `pixel_asset_key` values.
- Store screen shows real art (not the placeholder glyph) for all of them,
  at the prices in the table above.
- Purchase flow (`POST /store/items/{id}/purchase`) works against the new
  rows the same as the original 7 — no route changes needed there.
