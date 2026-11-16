import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import '../app/profile.dart';
import '../engine/engine.dart';
import 'format.dart';
import 'profile_form.dart';

/// Saved profiles. Tapping one opens its chart.
class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key, required this.onOpenChart});

  final VoidCallback onOpenChart;

  Future<void> _edit(BuildContext context, [Profile? p]) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ProfileForm(profile: p)));

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final list = m.profiles;
    return ListView(
      padding: const EdgeInsets.all(UiSpace.lg),
      children: [
        if (list.isEmpty)
          UiEmptyState(
            title: 'No profiles yet',
            message: 'Add a name, birth date, time and place to see the kundli. Everything is worked out on this phone.',
            icon: Icons.person_add_alt_1_rounded,
            action: UiButton('Add profile', icon: Icons.add_rounded, onPressed: () => _edit(context)),
          )
        else ...[
          UiListGroup(
            children: [
              for (final p in list)
                UiListTile(
                  p.name.isEmpty ? 'Unnamed' : p.name,
                  subtitle: '${birthLine(p)}\n${rashiNames[p.chart.moon.rashi]} Moon, ${nakshatraNames[p.chart.moon.nakshatra]}',
                  icon: Icons.person_rounded,
                  selected: p.id == m.selected?.id,
                  maxSubtitleLines: 3,
                  onTap: () {
                    m.select(p);
                    onOpenChart();
                  },
                  trailing: UiMenuButton<String>(
                    items: const [
                      UiMenuItem('edit', 'Edit', icon: Icons.edit_rounded),
                      UiMenuItem('delete', 'Delete', icon: Icons.delete_outline_rounded, destructive: true),
                    ],
                    onSelected: (v) async {
                      if (v == 'edit') {
                        _edit(context, p);
                      } else {
                        final ok = await UiDialog.confirm(
                          context,
                          title: 'Delete ${p.name.isEmpty ? 'this profile' : p.name}?',
                          confirmLabel: 'Delete',
                          destructive: true,
                        );
                        if (ok) m.remove(p);
                      }
                    },
                  ),
                ),
            ],
          ),
          const UiGap(UiSpace.lg),
          UiButton('Add profile', icon: Icons.add_rounded, expand: true, onPressed: () => _edit(context)),
        ],
        const UiGap(UiSpace.lg),
        Text(
          'Kundli follows traditional Vedic methods. It is guidance from tradition, not certainty.',
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
