import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class AppScaffold extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AppScaffold({super.key, required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: shell.currentIndex,
        onTap: (index) => shell.goBranch(
          index,
          initialLocation: index == shell.currentIndex,
        ),
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Quests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: 'Weekly',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_pin_outlined),
            activeIcon: Icon(Icons.person_pin),
            label: 'Avatar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
