import 'package:flutter/material.dart';
import '../../core/constants/quest_constants.dart';
import '../../core/theme/app_palette.dart';

/// Square pixel badge showing a quest category's icon and accent color.
class CategoryIcon extends StatelessWidget {
  final String questType;
  final double size;

  const CategoryIcon({super.key, required this.questType, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final palette = context.colors;
    final color = _color(palette);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Icon(_icon, color: color, size: size * 0.5),
    );
  }

  Color _color(AppPalette p) {
    switch (questType) {
      case QuestType.location:
        return p.locationQuest;
      case QuestType.social:
        return p.socialQuest;
      case QuestType.action:
        return p.actionQuest;
      default:
        return p.primaryLight;
    }
  }

  IconData get _icon {
    switch (questType) {
      case QuestType.location:
        return Icons.place;
      case QuestType.social:
        return Icons.groups;
      case QuestType.action:
        return Icons.bolt;
      default:
        return Icons.flag;
    }
  }
}
