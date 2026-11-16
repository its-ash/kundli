import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import '../engine/engine.dart';
import 'chart_page.dart';
import 'format.dart';

/// Vimshottari dasha timeline with antardashas.
class DashaPage extends StatefulWidget {
  const DashaPage({super.key, required this.onAddProfile});

  final VoidCallback onAddProfile;

  @override
  State<DashaPage> createState() => _DashaPageState();
}

class _DashaPageState extends State<DashaPage> {
  int? _open;
  String? _openFor;

  String _range(DashaPeriod d) => '${fmtDate(d.start)} - ${fmtDate(d.end)}';

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final p = m.selected;
    if (p == null) return NeedProfile(onAdd: widget.onAddProfile);
    final c = p.chart;
    final now = DateTime.now().toUtc();
    final list = c.dashas();
    final cur = list.indexWhere((d) => d.contains(now));
    if (_openFor != p.id) {
      _openFor = p.id;
      _open = cur < 0 ? null : cur;
    }
    final moon = c.moon;
    final curSub = cur < 0 ? null : list[cur].sub.where((s) => s.contains(now)).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(UiSpace.lg),
      children: [
        Text(p.name, style: context.text.titleLarge),
        Text('Vimshottari dasha', style: context.text.bodySmall),
        const UiGap(UiSpace.md),
        UiCard(
          child: Column(
            children: [
              UiKeyValue('Moon nakshatra', '${nakshatraNames[moon.nakshatra]}, pada ${moon.pada}'),
              UiKeyValue('Dasha at birth', c.birthDashaLord.sanskrit),
              UiKeyValue('Balance at birth', fmtYears(c.dashaBalanceYears)),
              if (cur >= 0)
                UiKeyValue('Running now',
                    '${list[cur].lord.sanskrit}${curSub == null ? '' : ' / ${curSub.lord.sanskrit}'}'),
            ],
          ),
        ),
        const UiGap(UiSpace.lg),
        UiListGroup(
          header: 'Mahadasha',
          footer: 'Tap a period to see its antardashas. The first period is the balance left at birth.',
          children: [
            for (var i = 0; i < list.length; i++) ...[
              UiListTile(
                '${list[i].lord.sanskrit} Mahadasha',
                subtitle: _range(list[i]),
                icon: Icons.timelapse_rounded,
                selected: i == cur,
                trailing: i == cur
                    ? const UiStatusPill('Now', status: UiStatus.accent)
                    : Icon(_open == i ? Icons.expand_less_rounded : Icons.expand_more_rounded),
                onTap: () => setState(() => _open = _open == i ? null : i),
              ),
              if (_open == i)
                for (final s in list[i].sub)
                  UiListTile(
                    '${list[i].lord.sanskrit} - ${s.lord.sanskrit}',
                    subtitle: _range(s),
                    dense: true,
                    selected: s.contains(now),
                    trailing: s.contains(now) ? const UiStatusPill('Now', status: UiStatus.accent) : null,
                  ),
            ],
          ],
        ),
        const UiGap(UiSpace.lg),
        Text(
          'Traditional guidance, not certainty. Periods use a 365.25-day year from the Moon\'s nakshatra.',
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
