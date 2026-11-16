import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import '../app/profile.dart';
import '../engine/engine.dart';
import 'chart_page.dart';

/// Guna Milan: Ashtakoota matching of two saved profiles.
class MatchPage extends StatefulWidget {
  const MatchPage({super.key, required this.onAddProfile});

  final VoidCallback onAddProfile;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> {
  String? _boyId, _girlId;

  Profile? _find(List<Profile> l, String? id) {
    for (final p in l) {
      if (p.id == id) return p;
    }
    return null;
  }

  String _score(double v) => v == v.roundToDouble() ? '${v.round()}' : '$v';

  @override
  Widget build(BuildContext context) {
    final m = AppScope.of(context);
    final list = m.profiles;
    if (list.length < 2) return NeedProfile(onAdd: widget.onAddProfile, count: 2);
    final boy = _find(list, _boyId) ?? list[0];
    final girl = _find(list, _girlId) ?? (list[1].id == boy.id ? list[0] : list[1]);
    final options = [for (final p in list) UiOption<String>(p.id, p.name.isEmpty ? 'Unnamed' : p.name)];
    final same = boy.id == girl.id;

    Widget body;
    if (same) {
      body = const UiAlert('Choose two different profiles.', status: UiStatus.warning);
    } else {
      final g = GunaMilan.compute(boy.chart.moon, girl.chart.moon);
      final bm = boy.chart.manglik, gm = girl.chart.manglik;
      final boyM = bm.fromLagna || bm.fromMoon, girlM = gm.fromLagna || gm.fromMoon;
      final manglikText = !boyM && !girlM
          ? 'Neither chart has Manglik dosha.'
          : boyM && girlM
              ? 'Both charts are Manglik. Traditionally the two cancel each other.'
              : '${boyM ? boy.name : girl.name} is Manglik and the partner is not. Tradition advises a closer look or remedies.';
      final nadiZero = g.koota('Nadi').score == 0;
      final bhakootZero = g.koota('Bhakoot').score == 0;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiCard(
            child: Column(
              children: [
                Text('${_score(g.total)} / ${g.max}', style: context.text.displaySmall),
                const UiGap(UiSpace.xs),
                Text(g.verdict, style: context.text.titleMedium),
                const UiGap(UiSpace.sm),
                UiProgressBar(g.total / g.max, status: g.total >= 18 ? UiStatus.success : UiStatus.warning, height: 8),
                const UiGap(UiSpace.xs),
                Text('18 or more is the traditional minimum.', style: context.text.bodySmall),
              ],
            ),
          ),
          const UiGap(UiSpace.lg),
          UiListGroup(
            header: 'Ashtakoota',
            children: [
              for (final k in g.kootas)
                UiListTile(
                  k.name,
                  subtitle: '${k.meaning}\n${k.detail}',
                  maxSubtitleLines: 3,
                  icon: k.score == k.max ? Icons.check_circle_rounded : (k.score == 0 ? Icons.cancel_rounded : Icons.adjust_rounded),
                  iconStatus: k.score == k.max ? UiStatus.success : (k.score == 0 ? UiStatus.danger : UiStatus.warning),
                  trailing: Text('${_score(k.score)} / ${k.max}', style: context.text.titleSmall),
                ),
            ],
          ),
          const UiGap(UiSpace.lg),
          UiAlert(manglikText, title: 'Manglik check', status: boyM != girlM ? UiStatus.warning : UiStatus.success),
          if (nadiZero || bhakootZero) ...[
            const UiGap(UiSpace.md),
            UiAlert(
              [
                if (nadiZero) 'Nadi dosha: same nadi.',
                if (bhakootZero) 'Bhakoot dosha: the Moon signs are in an unfavourable pairing.',
              ].join(' '),
              title: 'Doshas',
              status: UiStatus.warning,
            ),
          ],
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(UiSpace.lg),
      children: [
        UiSelect<String>(
          label: 'Groom (boy)',
          value: boy.id,
          options: options,
          sheetTitle: 'Groom',
          onChanged: (v) => setState(() => _boyId = v),
        ),
        const UiGap(UiSpace.md),
        UiSelect<String>(
          label: 'Bride (girl)',
          value: girl.id,
          options: options,
          sheetTitle: 'Bride',
          onChanged: (v) => setState(() => _girlId = v),
        ),
        const UiGap(UiSpace.lg),
        body,
        const UiGap(UiSpace.lg),
        Text(
          'Matching is based on the Moon sign and nakshatra of each person. Traditional guidance, not certainty.',
          style: context.text.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
