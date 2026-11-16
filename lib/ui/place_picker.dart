import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../data/places.dart';
import '../engine/engine.dart';

/// Search the offline city list; pops with the chosen [Place].
class PlacePicker extends StatefulWidget {
  const PlacePicker({super.key});

  @override
  State<PlacePicker> createState() => _PlacePickerState();
}

class _PlacePickerState extends State<PlacePicker> {
  late final Future<Places> _places = Places.load();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return UiScaffold(
      appBar: const UiAppBar(title: 'Birth place'),
      body: FutureBuilder<Places>(
        future: _places,
        builder: (context, snap) {
          final places = snap.data;
          if (places == null) return const Center(child: UiSpinner());
          final results = places.search(_query);
          return Column(
            children: [
              UiSearchField(hint: 'Search city', onChanged: (v) => setState(() => _query = v)),
              const UiGap(UiSpace.md),
              Expanded(
                child: results.isEmpty
                    ? const UiEmptyState(
                        title: 'No city found',
                        message: 'Try another spelling, or the nearest big city.',
                        icon: Icons.search_off_rounded,
                      )
                    : ListView(
                        children: [
                          UiListGroup(
                            children: [
                              for (final Place p in results)
                                UiListTile(
                                  p.name,
                                  subtitle: p.region,
                                  icon: Icons.location_city_rounded,
                                  onTap: () => Navigator.of(context).pop(p),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
