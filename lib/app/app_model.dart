import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile.dart';

/// App state: saved profiles, the one shown in Chart / Dasha and the chart
/// style. Kept in `shared_preferences`; nothing leaves the phone.
class AppModel extends ChangeNotifier {
  AppModel._(this._prefs, this._profiles, this._selectedId, this._south);

  final SharedPreferences _prefs;
  final List<Profile> _profiles;
  String? _selectedId;
  bool _south;

  static Future<AppModel> load([SharedPreferences? prefs]) async {
    final p = prefs ?? await SharedPreferences.getInstance();
    final list = <Profile>[];
    final raw = p.getString('profiles');
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final j in decoded) {
            final pr = Profile.fromJson(j);
            if (pr != null) list.add(pr);
          }
        }
      } on Object {
        // A damaged list is dropped rather than crashing the app.
      }
    }
    var sel = p.getString('selected');
    if (list.isNotEmpty && !list.any((e) => e.id == sel)) sel = list.first.id;
    return AppModel._(p, list, sel, p.getBool('south') ?? false);
  }

  List<Profile> get profiles => List.unmodifiable(_profiles);

  Profile? get selected {
    for (final p in _profiles) {
      if (p.id == _selectedId) return p;
    }
    return null;
  }

  bool get south => _south;

  set south(bool v) {
    if (v == _south) return;
    _south = v;
    _prefs.setBool('south', v);
    notifyListeners();
  }

  void select(Profile p) {
    _selectedId = p.id;
    _prefs.setString('selected', p.id);
    notifyListeners();
  }

  String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  /// Adds a profile or replaces the one with the same id.
  void save(Profile p, {bool select = true}) {
    final i = _profiles.indexWhere((e) => e.id == p.id);
    if (i < 0) {
      _profiles.add(p);
    } else {
      _profiles[i] = p;
    }
    if (select || _selectedId == null) {
      _selectedId = p.id;
      _prefs.setString('selected', p.id);
    }
    _persist();
    notifyListeners();
  }

  void remove(Profile p) {
    _profiles.removeWhere((e) => e.id == p.id);
    if (_selectedId == p.id) {
      _selectedId = _profiles.isEmpty ? null : _profiles.first.id;
      if (_selectedId == null) {
        _prefs.remove('selected');
      } else {
        _prefs.setString('selected', _selectedId!);
      }
    }
    _persist();
    notifyListeners();
  }

  void _persist() => _prefs.setString('profiles', jsonEncode([for (final p in _profiles) p.toJson()]));
}

class AppScope extends InheritedNotifier<AppModel> {
  const AppScope({super.key, required AppModel model, required super.child}) : super(notifier: model);

  static AppModel of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
