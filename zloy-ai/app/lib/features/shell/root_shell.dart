import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../home/home_screen.dart';
import '../practice/practice_hub_screen.dart';
import '../progress/progress_screen.dart';
import '../settings/settings_hub_screen.dart';
import '../tutor/tutor_screen.dart';

/// Bottom-navigation shell. Keeps each tab's state alive with an IndexedStack.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  static const _tabs = [
    _TabSpec('Home', Icons.home_rounded, Icons.home_outlined),
    _TabSpec('Tutor', Icons.forum_rounded, Icons.forum_outlined),
    _TabSpec('Practice', Icons.school_rounded, Icons.school_outlined),
    _TabSpec('Progress', Icons.insights_rounded, Icons.insights_outlined),
    _TabSpec('Settings', Icons.settings_rounded, Icons.settings_outlined),
  ];

  void _select(int index) {
    if (index == _index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(0);
      },
      child: Scaffold(
        backgroundColor: ZloyColors.background,
        body: IndexedStack(
          index: _index,
          children: [
            HomeScreen(onSelectTab: _select),
            const TutorScreen(),
            const PracticeHubScreen(),
            const ProgressScreen(),
            const SettingsHubScreen(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            for (final tab in _tabs)
              NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.selectedIcon),
                label: tab.label,
                tooltip: tab.label,
              ),
          ],
        ),
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.selectedIcon, this.icon);

  final String label;
  final IconData selectedIcon;
  final IconData icon;
}
