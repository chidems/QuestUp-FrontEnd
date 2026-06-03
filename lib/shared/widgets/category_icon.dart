import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/quest_constants.dart';

/// Round badge showing a quest category's icon and accent color.
class CategoryIcon extends StatelessWidget {
  final String questType;
  final double size;

  const CategoryIcon({super.key, required this.questType, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: _color, width: 1.5),
      ),
      child: Icon(_icon, color: _color, size: size * 0.5),
    );
  }

  Color get _color {
    switch (questType) {
      case QuestType.location:
        return AppColors.locationQuest;
      case QuestType.social:
        return AppColors.socialQuest;
      case QuestType.action:
        return AppColors.actionQuest;
      default:
        return AppColors.primaryLight;
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
