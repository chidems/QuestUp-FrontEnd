import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/theme/app_radius.dart';
import '../data/asset_catalog.dart';
import '../models/avatar_models.dart';

const double _bodyW = 141.0;
const double _bodyH = 286.0;

Widget _sprite(SpriteAsset sprite, double w, double h) => Image.asset(
      sprite.asset,
      width: w,
      height: h,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
    );

/// Body-only sprite layers (skin, eyes, bottom, top, hair) positioned on the
/// 141x286 canvas, centred horizontally and offset by [dx]. Shared by the full
/// preview and the circular head crop so the empirical anchors live in one
/// place. Eyes and hair are anchored empirically (eyes scale 0.62 top y=58;
/// hair scale 1.55 top y=-7 so it wraps the oversized chibi head). Clothes
/// are anchored by their opaque content box (see [ClothingAsset]): all
/// garment sheets share one drawing scale, and 1.30 maps garment pixels to
/// body pixels, so each garment keeps its drawn silhouette — tops hang from
/// the collar line, bottoms from the waistband.
List<Widget> _bodyLayers(AvatarAppearance appearance, {double dx = 0}) {
  final skin = AssetCatalog.skinById[appearance.skinId] ?? kSkinTones.first;
  final eyes = AssetCatalog.eyesById[appearance.eyesId] ?? kEyeColors.first;
  final hair = AssetCatalog.hairById[appearance.hairId] ?? kHairStyles.first;
  final top = AssetCatalog.clothingById[appearance.topId ?? ''];
  final bottom = AssetCatalog.clothingById[appearance.bottomId ?? ''];

  Widget layer(SpriteAsset sprite, {required double top, double scale = 1.0}) {
    final w = sprite.w * scale;
    final h = sprite.h * scale;
    return Positioned(
      left: dx + (_bodyW - w) / 2,
      top: top,
      child: _sprite(sprite, w, h),
    );
  }

  // The garment's content box is centred on the body and hung from the slot's
  // anchor line. Width uses the shared 1.30 scale times the garment's
  // precomputed fitWidthScale (so sleeves/pant legs cover the body's flared
  // arms/legs); height alone is compressed when a long garment would
  // otherwise bury the feet, so pants stay full-width at the hip but end
  // above the toes.
  Widget clothingLayer(
    ClothingAsset sprite, {
    required double anchorY,
    required double hemMaxY,
  }) {
    const scale = 1.30;
    final wScale = scale * sprite.fitWidthScale;
    final hScale = math.min(scale, (hemMaxY - anchorY) / sprite.contentH);
    final w = sprite.w * wScale;
    final h = sprite.h * hScale;
    return Positioned(
      left: dx +
          _bodyW / 2 -
          (sprite.contentL + sprite.contentW / 2) * wScale,
      top: anchorY - sprite.contentT * hScale,
      child: _sprite(sprite, w, h),
    );
  }

  return [
    layer(skin, top: 0),
    layer(eyes, top: 58, scale: 0.62),
    // Waistband line y=182; hems capped above the toes.
    if (bottom != null)
      clothingLayer(bottom, anchorY: 182, hemMaxY: 272),
    // Collar line y=124 — high enough that the collar covers the body's
    // shoulder slope, which starts at y~128.
    if (top != null) clothingLayer(top, anchorY: 124, hemMaxY: 262),
    layer(hair, top: -7, scale: 1.55),
  ];
}

/// Renders the full-body avatar with the equipped held item in one hand.
class AvatarPreview extends StatelessWidget {
  final AvatarAppearance appearance;

  const AvatarPreview({super.key, required this.appearance});

  /// Side margin so an item that overhangs the hand isn't clipped at the edge.
  static const _itemMargin = 40.0;
  static const _canvasW = _bodyW + 2 * _itemMargin;

  /// Centre of the right hand on the body canvas (offset by [_itemMargin]).
  static const _handX = _itemMargin + 124.0;
  static const _handY = 198.0;

  @override
  Widget build(BuildContext context) {
    final item = AssetCatalog.itemById[appearance.itemId ?? ''];

    return Semantics(
      image: true,
      label: 'Your avatar',
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: AppRadius.rCard,
            border: Border.all(color: context.colors.border, width: 1.5),
            boxShadow: context.colors.softShadow(),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(12),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _canvasW,
              height: _bodyH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ..._bodyLayers(appearance, dx: _itemMargin),
                  // Drawn last so it sits in front of the body — looks held.
                  if (item != null) _itemLayer(item),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The held item is centred on the right hand and scaled down so it reads as
  /// hand-held rather than dominating the figure.
  Widget _itemLayer(ItemAsset item) {
    final scale = [
      64 / item.w,
      90 / item.h,
      1.0,
    ].reduce((a, b) => a < b ? a : b);
    final w = item.w * scale;
    final h = item.h * scale;
    return Positioned(
      left: _handX - w / 2,
      top: _handY - h / 2,
      child: _sprite(item, w, h),
    );
  }
}

/// A circular head-and-shoulders crop of the composed avatar, for HUD/profile
/// chips. Shows the top ~140px of the body canvas (hair + face + shoulders).
class AvatarHeadCircle extends StatelessWidget {
  final AvatarAppearance appearance;
  final double size;

  const AvatarHeadCircle({
    super.key,
    required this.appearance,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.surfaceVariant,
        shape: BoxShape.circle,
        border: Border.all(color: p.primaryLight, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: OverflowBox(
        alignment: Alignment.topCenter,
        maxHeight: double.infinity,
        // Body scaled so its width fills the circle; aligned to the top so the
        // legs overflow below the clip and only the head/shoulders show.
        child: SizedBox(
          width: size,
          height: size * _bodyH / _bodyW,
          child: FittedBox(
            fit: BoxFit.fill,
            child: SizedBox(
              width: _bodyW,
              height: _bodyH,
              child: Stack(
                clipBehavior: Clip.none,
                children: _bodyLayers(appearance),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
