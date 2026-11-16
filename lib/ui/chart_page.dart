import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import '../app/profile.dart';
import '../engine/engine.dart';
import 'chart_painter.dart';
import 'format.dart';

/// Shown by the Chart, Dasha and Match tabs when nothing is saved yet.
class NeedProfile extends StatelessWidget {
  const NeedProfile({super.key, required this.onAdd, this.count = 1});

  final VoidCallback onAdd;
  final int count;

  @override
  Widget build(BuildContext context) => UiEmptyState(
        title: count == 1 ? 'No profile yet' : 'Two profiles needed',
        message: count == 1
            ? 'Add a profile to see the birth chart.'
            : 'Add at least two profiles to match them.',
        icon: Icons.person_add_alt_1_rounded,
        action: UiButton('Go to Profiles', onPressed: onAdd),
      );
}

class ChartPage extends StatelessWidget {
  const ChartPage({super.key, required this.onAddProfile});

  final VoidCallback onAddProfile;

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final Profile? p = m.selected;
    if (p == null) return NeedProfile(onAdd: onAddProfile);
    final c = p.chart;
    final colors = context.colors;
    final moon = c.moon;

    return ListView(
      padding: const EdgeInsets.all(UiSpace.lg),
      children: [
        Text(p.name, style: context.text.titleLarge),
        Text(birthLine(p), style: context.text.bodySmall),
        const UiGap(UiSpace.md),
        UiSegmentedControl<bool>(
          const [UiSegment(false, label: 'North Indian'), UiSegment(true, label: 'South Indian')],
          value: m.south,
          expand: true,
          onChanged: (v) => m.south = v,
        ),
        const UiGap(UiSpace.md),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(
                painter: ChartPainter(
                  chart: c,
                  south: m.south,
                  line: colors.borderStrong,
                  sign: colors.textMuted,
                  planet: colors.text,
                  accent: colors.accent,
                  fill: colors.surface,
                ),
              ),
            ),
          ),
        ),
        const UiGap(UiSpace.xs),
        Text(
          'Small numbers are signs (1 Mesha ... 12 Meena). * marks a retrograde planet.',
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
        const UiGap(UiSpace.lg),
        UiCard(
          child: Column(
            children: [
              UiKeyValue('Lagna (ascendant)',
                  '${rashiNames[c.lagna.rashi]} ${fmtDeg(c.lagna.degreeInRashi)}'),
              UiKeyValue('Moon sign (Rashi)', '${rashiNames[moon.rashi]} (${rashiEnglish[moon.rashi]})'),
              UiKeyValue('Nakshatra', '${nakshatraNames[moon.nakshatra]}, pada ${moon.pada}'),
              UiKeyValue('Nakshatra lord', c.birthDashaLord.sanskrit),
              UiKeyValue('Ayanamsa (Lahiri)', fmtDeg(c.ayanamsa)),
            ],
          ),
        ),
        const UiGap(UiSpace.lg),
        UiSection(
          title: 'Planets',
          child: UiTable<Placement>(
            dense: true,
            rows: [c.lagna, ...c.grahas],
            columns: [
              UiTableColumn('Graha', text: (r) => r.graha == null ? 'Lagna' : '${r.graha!.sanskrit}${r.retro && r.graha!.index < 7 ? ' (R)' : ''}'),
              UiTableColumn('Sign', text: (r) => rashiNames[r.rashi]),
              UiTableColumn('Degree', text: (r) => fmtDeg(r.degreeInRashi)),
              UiTableColumn('Nakshatra', text: (r) => '${nakshatraNames[r.nakshatra]} ${r.pada}'),
              UiTableColumn('House', text: (r) => '${r.house}', numeric: true),
            ],
          ),
        ),
        const UiGap(UiSpace.lg),
        _Manglik(chart: c),
        const UiGap(UiSpace.lg),
        Text(
          'Traditional guidance, not certainty. Positions are calculated on your phone with the Lahiri ayanamsa and whole-sign houses.',
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Manglik extends StatelessWidget {
  const _Manglik({required this.chart});

  final BirthChart chart;

  @override
  Widget build(BuildContext context) {
    final m = chart.manglik;
    final any = m.fromLagna || m.fromMoon;
    return UiAlert(
      'Mars is in house ${chart.mars.house} from the Lagna'
      '${m.fromLagna ? ' (a Manglik house)' : ''}, and ${((chart.mars.rashi - chart.moon.rashi + 12) % 12) + 1} from the Moon'
      '${m.fromMoon ? ' (a Manglik house)' : ''}. Mars in the 1st, 2nd, 4th, 7th, 8th or 12th house counts.',
      title: any ? 'Manglik dosha present' : 'No Manglik dosha',
      status: any ? UiStatus.warning : UiStatus.success,
    );
  }
}
