import 'package:flutter/material.dart';
import 'package:theme/theme.dart';

import '../app/app_model.dart';
import '../app/profile.dart';
import '../engine/engine.dart';
import 'format.dart';
import 'place_picker.dart';

/// Add or edit a profile: name, date, time, place and time zone.
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key, this.profile});

  final Profile? profile;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late final TextEditingController _name = TextEditingController(text: widget.profile?.name ?? '');
  DateTime? _date;
  TimeOfDay? _time;
  Place _place = Place.newDelhi;

  /// Null means "automatic" (the place's own rule).
  int? _tzOverride;
  bool _tried = false;

  static const _offsets = [
    -720, -660, -600, -540, -480, -420, -360, -300, -240, -180, -120, -60, 0, 60, 120, 180, 210, 240, 270, 300, 330, //
    345, 360, 390, 420, 480, 525, 540, 570, 600, 660, 720, 765, 780,
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    if (p != null) {
      _date = DateTime(p.year, p.month, p.day);
      _time = TimeOfDay(hour: p.hour, minute: p.minute);
      _place = p.place;
      final auto = Profile.autoOffset(p.place, p.year, p.month, p.day, p.hour, p.minute);
      _tzOverride = p.tzMinutes == auto ? null : p.tzMinutes;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int get _autoTz {
    final d = _date, t = _time;
    if (d == null || t == null) return _place.standardOffsetMinutes;
    return Profile.autoOffset(_place, d.year, d.month, d.day, t.hour, t.minute);
  }

  int get _tz => _tzOverride ?? _autoTz;

  Future<void> _pickPlace() async {
    final p = await Navigator.of(context).push<Place>(MaterialPageRoute(builder: (_) => const PlacePicker()));
    if (p != null && mounted) setState(() => _place = p);
  }

  void _save() {
    setState(() => _tried = true);
    final d = _date, t = _time;
    if (_name.text.trim().isEmpty || d == null || t == null) return;
    final m = AppScope.of(context);
    final old = widget.profile;
    final p = Profile(
      id: old?.id ?? m.newId(),
      name: _name.text.trim(),
      year: d.year,
      month: d.month,
      day: d.day,
      hour: t.hour,
      minute: t.minute,
      place: _place,
      tzMinutes: _tz,
    );
    m.save(p);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final offsets = {..._offsets, _tz}.toList()..sort();
    return UiScaffold(
      appBar: UiAppBar(title: widget.profile == null ? 'New profile' : 'Edit profile'),
      scrollable: true,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          UiTextField(
            label: 'Name',
            controller: _name,
            textCapitalization: TextCapitalization.words,
            error: _tried && _name.text.trim().isEmpty ? 'Enter a name' : null,
          ),
          const UiGap(UiSpace.md),
          UiDateField(
            label: 'Date of birth',
            value: _date,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            clearable: false,
            error: _tried && _date == null ? 'Pick the date' : null,
            onChanged: (v) => setState(() => _date = v),
          ),
          const UiGap(UiSpace.md),
          UiTimeField(
            label: 'Time of birth',
            value: _time,
            clearable: false,
            error: _tried && _time == null ? 'Pick the time' : null,
            helper: 'The ascendant changes about every two hours, so be as exact as you can.',
            onChanged: (v) => setState(() => _time = v),
          ),
          const UiGap(UiSpace.md),
          UiListGroup(
            header: 'Birth place',
            children: [
              UiListTile(
                _place.name,
                subtitle: _place.region,
                icon: Icons.place_rounded,
                chevron: true,
                onTap: _pickPlace,
              ),
            ],
          ),
          const UiGap(UiSpace.md),
          UiSelect<int>(
            label: 'Time zone of the birth clock',
            value: _tz,
            sheetTitle: 'Time zone',
            options: [
              for (final o in offsets)
                UiOption<int>(o, fmtOffset(o), subtitle: o == _autoTz ? 'Automatic for ${_place.name}' : null),
            ],
            helper: _tzOverride == null
                ? 'Set from the place. Change it if the birth clock used another zone (for example summer time).'
                : 'Set by hand.',
            onChanged: (v) => setState(() => _tzOverride = v == _autoTz ? null : v),
          ),
          const UiGap(UiSpace.xl),
          UiButton('Save', icon: Icons.check_rounded, expand: true, onPressed: _save),
        ],
      ),
    );
  }
}
