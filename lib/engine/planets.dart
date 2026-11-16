import 'dart:math' as math;

import 'astro.dart';

const double _rad = math.pi / 180;

/// Mean orbital elements and their rates per Julian century (J2000 ecliptic
/// and equinox), from E. M. Standish, "Keplerian Elements for Approximate
/// Positions of the Major Planets" (JPL), valid 1800-2050. Jupiter and Saturn
/// carry the extra b, c, s, f terms of that table.
class _Elements {
  const _Elements(this.a, this.da, this.e, this.de, this.i, this.di, this.l, this.dl, this.w, this.dw, this.o,
      this.dO,
      [this.b = 0, this.c = 0, this.s = 0, this.f = 0]);

  final double a, da, e, de, i, di, l, dl, w, dw, o, dO, b, c, s, f;
}

const _mercury = _Elements(0.38709927, 0.00000037, 0.20563593, 0.00001906, 7.00497902, -0.00594749, 252.25032350,
    149472.67411175, 77.45779628, 0.16047689, 48.33076593, -0.12534081);
const _venus = _Elements(0.72333566, 0.00000390, 0.00677672, -0.00004107, 3.39467605, -0.00078890, 181.97909950,
    58517.81538729, 131.60246718, 0.00268329, 76.67984255, -0.27769418);
const _earthMoon = _Elements(1.00000261, 0.00000562, 0.01671123, -0.00004392, -0.00001531, -0.01294668, 100.46457166,
    35999.37244981, 102.93768193, 0.32327364, 0.0, 0.0);
const _mars = _Elements(1.52371034, 0.00001847, 0.09339410, 0.00007882, 1.84969142, -0.00813131, -4.55343205,
    19140.30268499, -23.94362959, 0.44441088, 49.55953891, -0.29257343);
const _jupiter = _Elements(5.20288700, -0.00011607, 0.04838624, -0.00013253, 1.30439695, -0.00183714, 34.39644051,
    3034.74612775, 14.72847983, 0.21252668, 100.47390909, 0.20469106, -0.00012452, 0.06064060, -0.35635438, 38.35125);
const _saturn = _Elements(9.53667594, -0.00125060, 0.05386179, -0.00050991, 2.48599187, 0.00193609, 49.95424423,
    1222.49362201, 92.59887831, -0.41897216, 113.66242448, -0.28867794, 0.00025899, -0.13434469, 0.87320147,
    38.35125);

/// Heliocentric rectangular ecliptic coordinates (J2000), AU.
({double x, double y, double z}) _helio(_Elements k, double t) {
  final a = k.a + k.da * t;
  final e = k.e + k.de * t;
  final inc = (k.i + k.di * t) * _rad;
  final l = k.l + k.dl * t;
  final w = k.w + k.dw * t; // longitude of perihelion
  final node = k.o + k.dO * t;
  final omega = (w - node) * _rad; // argument of perihelion
  var m = l - w + k.b * t * t + k.c * math.cos(k.f * t * _rad) + k.s * math.sin(k.f * t * _rad);
  m = (norm360(m + 180) - 180) * _rad;
  var ea = m + e * math.sin(m);
  for (var n = 0; n < 12; n++) {
    final d = (ea - e * math.sin(ea) - m) / (1 - e * math.cos(ea));
    ea -= d;
    if (d.abs() < 1e-12) break;
  }
  final xp = a * (math.cos(ea) - e);
  final yp = a * math.sqrt(1 - e * e) * math.sin(ea);
  final cw = math.cos(omega), sw = math.sin(omega);
  final co = math.cos(node * _rad), so = math.sin(node * _rad);
  final ci = math.cos(inc), si = math.sin(inc);
  return (
    x: (cw * co - sw * so * ci) * xp + (-sw * co - cw * so * ci) * yp,
    y: (cw * so + sw * co * ci) * xp + (-sw * so + cw * co * ci) * yp,
    z: (sw * si) * xp + (cw * si) * yp,
  );
}

/// The five visible planets and the lunar node, in pure Dart.
///
/// Planets use the JPL Keplerian approximation (about 1 to 4 arc-minutes
/// over 1800-2050, light time and aberration left out), which is far
/// inside the 1 degree that a rashi, nakshatra pada or navamsa needs.
/// Longitudes are tropical, mean equinox of date (precession from J2000 is
/// added, nutation left out; see [Astro]).
abstract final class Planets {
  /// Precession in longitude from J2000 to the date, degrees.
  static double precession(double jde) {
    final t = (jde - Astro.j2000) / 36525.0;
    return (5028.796195 * t + 1.1054348 * t * t) / 3600;
  }

  /// Geocentric tropical longitude (degrees, mean equinox of date) of
  /// 'mercury', 'venus', 'mars', 'jupiter' or 'saturn'.
  static double longitude(String planet, double jde) {
    final t = (jde - Astro.j2000) / 36525.0;
    final k = switch (planet) {
      'mercury' => _mercury,
      'venus' => _venus,
      'mars' => _mars,
      'jupiter' => _jupiter,
      'saturn' => _saturn,
      _ => throw ArgumentError('unknown planet $planet'),
    };
    final p = _helio(k, t);
    final e = _helio(_earthMoon, t);
    final lon = math.atan2(p.y - e.y, p.x - e.x) / _rad;
    return norm360(lon + precession(jde));
  }

  /// Geocentric ecliptic latitude, degrees.
  static double latitude(String planet, double jde) {
    final t = (jde - Astro.j2000) / 36525.0;
    final k = switch (planet) {
      'mercury' => _mercury,
      'venus' => _venus,
      'mars' => _mars,
      'jupiter' => _jupiter,
      _ => _saturn,
    };
    final p = _helio(k, t);
    final e = _helio(_earthMoon, t);
    final dx = p.x - e.x, dy = p.y - e.y, dz = p.z - e.z;
    return math.atan2(dz, math.sqrt(dx * dx + dy * dy)) / _rad;
  }

  /// Mean ascending node of the Moon (Rahu), tropical longitude of date
  /// (Meeus ch. 47).
  static double meanNode(double jde) {
    final t = (jde - Astro.j2000) / 36525.0;
    return norm360(125.0445479 - 1934.1362891 * t + 0.0020754 * t * t + t * t * t / 467441);
  }

  /// Ascendant (Lagna): tropical longitude of the ecliptic point rising in
  /// the east, degrees. [jdUt] is UT, longitude is east-positive.
  static double ascendant(double jdUt, double latitude, double longitude) {
    final jde = Astro.jde(jdUt);
    final theta = norm360(Astro.gmst(jdUt) + longitude) * _rad; // local sidereal time
    final eps = Astro.obliquity(jde) * _rad;
    final phi = latitude * _rad;
    final asc = math.atan2(math.cos(theta), -(math.sin(theta) * math.cos(eps) + math.tan(phi) * math.sin(eps)));
    return norm360(asc / _rad);
  }
}
