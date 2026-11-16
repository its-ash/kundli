import '../engine/engine.dart';

/// A saved person: name, birth moment and birth place.
class Profile {
  Profile({
    required this.id,
    required this.name,
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.place,
    required this.tzMinutes,
  });

  final String id;
  final String name;
  final int year, month, day, hour, minute;
  final Place place;

  /// UTC offset of the birth clock time in minutes (summer time included).
  final int tzMinutes;

  /// The birth moment in UTC.
  DateTime get birthUtc => DateTime.utc(year, month, day, hour, minute).subtract(Duration(minutes: tzMinutes));

  late final BirthChart chart = BirthChart.compute(birthUtc, place);

  /// Offset the place's rule gives for a wall-clock time (minutes).
  static int autoOffset(Place place, int y, int mo, int d, int h, int mi) {
    final naive = DateTime.utc(y, mo, d, h, mi);
    final guess = naive.subtract(Duration(minutes: place.standardOffsetMinutes));
    return place.offsetAt(guess).inMinutes;
  }

  Profile copyWith({String? name, int? year, int? month, int? day, int? hour, int? minute, Place? place, int? tzMinutes}) =>
      Profile(
        id: id,
        name: name ?? this.name,
        year: year ?? this.year,
        month: month ?? this.month,
        day: day ?? this.day,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        place: place ?? this.place,
        tzMinutes: tzMinutes ?? this.tzMinutes,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'y': year,
        'mo': month,
        'd': day,
        'h': hour,
        'mi': minute,
        'place': place.toJson(),
        'tz': tzMinutes,
      };

  static Profile? fromJson(Object? j) {
    if (j is! Map) return null;
    final place = Place.fromJson(j['place']);
    if (place == null) return null;
    try {
      return Profile(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        year: j['y'] as int,
        month: j['mo'] as int,
        day: j['d'] as int,
        hour: j['h'] as int,
        minute: j['mi'] as int,
        place: place,
        tzMinutes: j['tz'] as int,
      );
    } catch (_) {
      return null;
    }
  }
}
