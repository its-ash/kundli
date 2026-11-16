import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import 'chart_page.dart';
import 'dasha_page.dart';
import 'match_page.dart';
import 'profiles_page.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return UiShell(
      appBar: UiAppBar(
        title: 'Kundli',
        actions: [
          UiIconButton(
            Icons.settings_rounded,
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      items: const [
        UiNavItem(Icons.people_outline_rounded, 'Profiles', selectedIcon: Icons.people_rounded),
        UiNavItem(Icons.grid_view_outlined, 'Chart', selectedIcon: Icons.grid_view_rounded),
        UiNavItem(Icons.timeline_outlined, 'Dasha', selectedIcon: Icons.timeline_rounded),
        UiNavItem(Icons.favorite_border_rounded, 'Match', selectedIcon: Icons.favorite_rounded),
      ],
      index: _tab,
      onChanged: (i) => setState(() => _tab = i),
      pages: [
        ProfilesPage(onOpenChart: () => setState(() => _tab = 1)),
        ChartPage(onAddProfile: () => setState(() => _tab = 0)),
        DashaPage(onAddProfile: () => setState(() => _tab = 0)),
        MatchPage(onAddProfile: () => setState(() => _tab = 0)),
      ],
    );
  }
}
