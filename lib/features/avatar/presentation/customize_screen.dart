import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/routing/route_names.dart';
import '../../../shared/widgets/error_view.dart';
import '../../../shared/widgets/loading_view.dart';
import '../../../shared/widgets/pixel_button.dart';
import '../../../shared/widgets/pixel_chip.dart';
import '../../../shared/widgets/rarity_badge.dart';
import '../../store/providers/store_provider.dart';
import '../data/asset_catalog.dart';
import '../models/avatar_models.dart';
import '../providers/avatar_provider.dart';
import 'avatar_preview.dart';

/// Appearance editor: skin, eyes, hair and clothes are free to pick; the
/// Items tab equips a shop purchase into the avatar's hand.
class CustomizeScreen extends ConsumerStatefulWidget {
  const CustomizeScreen({super.key});

  @override
  ConsumerState<CustomizeScreen> createState() => _CustomizeScreenState();
}

enum _Slot { skin, eyes, hair, top, bottom, items }

/// Swatches for the hair color chips, roughly matching each group's sprites.
const _hairSwatches = {
  'black': Color(0xFF33312F),
  'brown': Color(0xFF8A5A2E),
  'blonde': Color(0xFFD9A85A),
  'red': Color(0xFFA03020),
  'orange': Color(0xFFC06018),
  'silver': Color(0xFFAAB0BC),
  'purple': Color(0xFF7A55A8),
  'blue': Color(0xFF3568A8),
  'green': Color(0xFF3E7A5E),
  'pink': Color(0xFFD4798A),
};

class _CustomizeScreenState extends ConsumerState<CustomizeScreen> {
  _Slot _slot = _Slot.skin;
  String? _hairColor; // null until first visit; defaults to equipped color
  String _fit = 'feminine';
  String _theme = 'modern';

  /// Folder style-set key for the current fit + theme selection.
  String get _styleKey => switch ((_fit, _theme)) {
        ('feminine', 'modern') => 'modern_feminine',
        ('masculine', 'modern') => 'modern_masculine',
        ('feminine', 'fantasy') => 'rpg_feminine',
        _ => 'rpg_neutral',
      };

  Future<void> _apply(AvatarAppearance next) =>
      ref.read(appearanceProvider.notifier).apply(next);

  @override
  Widget build(BuildContext context) {
    final appearance = ref.watch(appearanceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Customize')),
      body: appearance.when(
        loading: () => const LoadingView(),
        error: (_, __) => ErrorView(
          message: 'Could not load your avatar.',
          onRetry: () => ref.invalidate(appearanceProvider),
        ),
        data: (a) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SizedBox(
                height: 200,
                child: Center(child: AvatarPreview(appearance: a)),
              ),
            ),
            _SlotTabs(
              slot: _slot,
              onSelect: (s) => setState(() => _slot = s),
            ),
            if (_slot == _Slot.hair)
              _HairColorChips(
                color: _hairColor ?? _equippedHairColor(a),
                onSelect: (c) => setState(() => _hairColor = c),
              ),
            if (_slot == _Slot.top || _slot == _Slot.bottom)
              _FitStyleChips(
                fit: _fit,
                theme: _theme,
                onFit: (f) => setState(() => _fit = f),
                onTheme: (t) => setState(() => _theme = t),
              ),
            Expanded(child: _optionGrid(a)),
          ],
        ),
      ),
    );
  }

  String _equippedHairColor(AvatarAppearance a) =>
      AssetCatalog.hairById[a.hairId]?.color ?? 'black';

  Widget _optionGrid(AvatarAppearance a) {
    switch (_slot) {
      case _Slot.skin:
        return _SpriteGrid(
          options: kSkinTones,
          selectedId: a.skinId,
          columns: 4,
          aspect: 0.62,
          onPick: (id) => _apply(a.copyWith(skinId: id)),
        );
      case _Slot.eyes:
        return _SpriteGrid(
          options: kEyeColors,
          selectedId: a.eyesId,
          columns: 3,
          aspect: 1.5,
          onPick: (id) => _apply(a.copyWith(eyesId: id)),
        );
      case _Slot.hair:
        final color = _hairColor ?? _equippedHairColor(a);
        return _SpriteGrid(
          options: kHairStyles.where((h) => h.color == color).toList(),
          selectedId: a.hairId,
          columns: 4,
          aspect: 0.95,
          onPick: (id) => _apply(a.copyWith(hairId: id)),
        );
      case _Slot.top:
      case _Slot.bottom:
        final slot = _slot == _Slot.top ? ItemType.top : ItemType.bottom;
        final options = kClothes
            .where((c) => c.slot == slot && c.style == _styleKey)
            .toList();
        final selectedId = _slot == _Slot.top ? a.topId : a.bottomId;
        return _SpriteGrid(
          options: options,
          selectedId: selectedId,
          columns: 4,
          aspect: 0.95,
          allowNone: true,
          onPick: (id) => _apply(_slot == _Slot.top
              ? a.copyWith(topId: id)
              : a.copyWith(bottomId: id)),
        );
      case _Slot.items:
        return _ItemsGrid(
          appearance: a,
          onPick: (id) => _apply(a.copyWith(itemId: id)),
        );
    }
  }
}

class _SlotTabs extends StatelessWidget {
  final _Slot slot;
  final ValueChanged<_Slot> onSelect;

  const _SlotTabs({required this.slot, required this.onSelect});

  static const _labels = {
    _Slot.skin: 'Skin',
    _Slot.eyes: 'Eyes',
    _Slot.hair: 'Hair',
    _Slot.top: 'Tops',
    _Slot.bottom: 'Bottoms',
    _Slot.items: 'Items',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final s in _Slot.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Center(
                child: PixelChip(
                  label: _labels[s]!,
                  selected: s == slot,
                  onTap: () => onSelect(s),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hair color comes first; the style grid below only shows that color.
class _HairColorChips extends StatelessWidget {
  final String color;
  final ValueChanged<String> onSelect;

  const _HairColorChips({required this.color, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final entry in kHairColorLabels.entries)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Center(
                child: PixelChip(
                  label: entry.value,
                  swatch: _hairSwatches[entry.key],
                  selected: color == entry.key,
                  onTap: () => onSelect(entry.key),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Two-step clothes filter: fit (feminine/masculine), then style
/// (modern/fantasy).
class _FitStyleChips extends StatelessWidget {
  final String fit;
  final String theme;
  final ValueChanged<String> onFit;
  final ValueChanged<String> onTheme;

  const _FitStyleChips({
    required this.fit,
    required this.theme,
    required this.onFit,
    required this.onTheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final f in const [('feminine', 'Feminine'), ('masculine', 'Masculine')])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Center(
                child: PixelChip(
                  label: f.$2,
                  selected: fit == f.$1,
                  onTap: () => onFit(f.$1),
                ),
              ),
            ),
          Center(
            child: Container(
              width: 1.5,
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: context.colors.border,
            ),
          ),
          for (final t in const [('modern', 'Modern'), ('fantasy', 'Fantasy')])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Center(
                child: PixelChip(
                  label: t.$2,
                  selected: theme == t.$1,
                  onTap: () => onTheme(t.$1),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grid of pickable sprites. With [allowNone], the first cell clears the slot.
class _SpriteGrid extends StatelessWidget {
  final List<SpriteAsset> options;
  final String? selectedId;
  final int columns;
  final double aspect;
  final bool allowNone;
  final ValueChanged<String?> onPick;

  const _SpriteGrid({
    required this.options,
    required this.selectedId,
    required this.columns,
    required this.aspect,
    required this.onPick,
    this.allowNone = false,
  });

  @override
  Widget build(BuildContext context) {
    final extra = allowNone ? 1 : 0;
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: aspect,
      ),
      itemCount: options.length + extra,
      itemBuilder: (_, i) {
        if (allowNone && i == 0) {
          return _OptionCell(
            label: 'None',
            selected: selectedId == null,
            onTap: () => onPick(null),
            child: Icon(Icons.block, color: context.colors.textMuted),
          );
        }
        final option = options[i - extra];
        final rarity = option is ClothingAsset ? option.rarity : null;
        return _OptionCell(
          label: option.name,
          selected: option.id == selectedId,
          rarity: rarity,
          onTap: () => onPick(option.id),
          child: Image.asset(
            option.asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
          ),
        );
      },
    );
  }
}

/// Items tab: equips an owned shop item into the avatar's hand.
class _ItemsGrid extends ConsumerWidget {
  final AvatarAppearance appearance;
  final ValueChanged<String?> onPick;

  const _ItemsGrid({
    required this.appearance,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(storeProvider);
    final selectedId = appearance.itemId;

    return store.when(
      loading: () => const LoadingView(),
      error: (_, __) => ErrorView(
        message: 'Could not load your items.',
        onRetry: () => ref.read(storeProvider.notifier).refresh(),
      ),
      data: (items) {
        final owned = items.where((i) => i.isOwned).toList();
        if (owned.isEmpty) return const _NoItemsYet();
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.95,
          ),
          itemCount: owned.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return _OptionCell(
                label: 'None',
                selected: selectedId == null,
                onTap: () => onPick(null),
                child: Icon(Icons.block, color: context.colors.textMuted),
              );
            }
            final item = owned[i - 1];
            return _OptionCell(
              label: item.name,
              selected: item.id == selectedId,
              rarity: item.rarity,
              onTap: () => onPick(item.id),
              child: item.asset == null
                  ? const SizedBox.shrink()
                  : Image.asset(
                      item.asset!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                    ),
            );
          },
        );
      },
    );
  }
}

class _NoItemsYet extends StatelessWidget {
  const _NoItemsYet();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 40, color: context.colors.textMuted),
          const SizedBox(height: 12),
          Text(
            'No items yet.\nVisit the shop to gear up!',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          PixelButton(
            label: 'Open Shop',
            icon: Icons.storefront,
            variant: PixelButtonVariant.navigation,
            onPressed: () => context.push(RouteNames.store),
          ),
        ],
      ),
    );
  }
}

/// One selectable sprite cell; selected cells get a bright border, clothes
/// and items show a rarity-colored strip along the bottom edge.
class _OptionCell extends StatelessWidget {
  final String label;
  final bool selected;
  final String? rarity;
  final VoidCallback onTap;
  final Widget child;

  const _OptionCell({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.child,
    this.rarity,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? p.surfaceDeep : p.surfaceVariant,
            borderRadius: AppRadius.rSmall,
            border: Border.all(
              color: selected ? p.primaryLight : p.border,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(5),
          child: Column(
            children: [
              Expanded(child: ExcludeSemantics(child: child)),
              if (rarity != null) ...[
                const SizedBox(height: 4),
                Container(
                  height: 3,
                  width: double.infinity,
                  color: rarityColor(p, rarity!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
