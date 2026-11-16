import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    return UiScaffold(
      appBar: const UiAppBar(title: 'Settings'),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiSection(
            title: 'Chart style',
            child: UiSegmentedControl<bool>(
              const [UiSegment(false, label: 'North Indian'), UiSegment(true, label: 'South Indian')],
              value: m.south,
              expand: true,
              onChanged: (v) => m.south = v,
            ),
          ),
          const UiGap(UiSpace.xs),
          Text(
            'Positions use the Lahiri (Chitrapaksha) ayanamsa, whole-sign houses and the mean lunar node for Rahu.',
            style: context.text.bodySmall,
          ),
          const UiGap(UiSpace.lg),
          const UiAppearanceSection(),
          const UiGap(UiSpace.lg),
          const UiUpdateSection(storeId: 'kundli'),
          const UiGap(UiSpace.lg),
          const UiDeveloperSection(),
        ],
      ),
    );
  }
}
