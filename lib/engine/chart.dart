import 'astro.dart';
import 'place.dart';
import 'planets.dart';

/// The nine grahas used in a kundli.
enum Graha {
  sun('Sun', 'Surya', 'Su'),
  moon('Moon', 'Chandra', 'Mo'),
  mars('Mars', 'Mangala', 'Ma'),
  mercury('Mercury', 'Budha', 'Me'),
  jupiter('Jupiter', 'Guru', 'Ju'),
  venus('Venus', 'Shukra', 'Ve'),
  saturn('Saturn', 'Shani', 'Sa'),
  rahu('Rahu', 'Rahu', 'Ra'),
  ketu('Ketu', 'Ketu', 'Ke');

  const Graha(this.english, this.sanskrit, this.abbr);
  final String english;
  final String sanskrit;
  final String abbr;
}

const rashiNames = [
  'Mesha', 'Vrishabha', 'Mithuna', 'Karka', 'Simha', 'Kanya', //
  'Tula', 'Vrishchika', 'Dhanu', 'Makara', 'Kumbha', 'Meena',
];

const rashiEnglish = [
  'Aries', 'Taurus', 'Gemini', 'Cancer', 'Leo', 'Virgo', //
  'Libra', 'Scorpio', 'Sagittarius', 'Capricorn', 'Aquarius', 'Pisces',
];

const nakshatraNames = [
  'Ashwini', 'Bharani', 'Krittika', 'Rohini', 'Mrigashira', 'Ardra', 'Punarvasu', 'Pushya', 'Ashlesha', //
  'Magha', 'Purva Phalguni', 'Uttara Phalguni', 'Hasta', 'Chitra', 'Swati', 'Vishakha', 'Anuradha', 'Jyeshtha',
  'Mula', 'Purva Ashadha', 'Uttara Ashadha', 'Shravana', 'Dhanishta', 'Shatabhisha', 'Purva Bhadrapada',
  'Uttara Bhadrapada', 'Revati',
];

/// Lord of each rashi (index 0 = Mesha).
const rashiLords = [
  Graha.mars, Graha.venus, Graha.mercury, Graha.moon, Graha.sun, Graha.mercury, //
  Graha.venus, Graha.mars, Graha.jupiter, Graha.saturn, Graha.saturn, Graha.jupiter,
];

/// Vimshottari order and years.
const dashaOrder = [
  Graha.ketu, Graha.venus, Graha.sun, Graha.moon, Graha.mars, Graha.rahu, Graha.jupiter, Graha.saturn, Graha.mercury,
];
const dashaYears = {
  Graha.ketu: 7,
  Graha.venus: 20,
  Graha.sun: 6,
  Graha.moon: 10,
  Graha.mars: 7,
  Graha.rahu: 18,
  Graha.jupiter: 16,
  Graha.saturn: 19,
  Graha.mercury: 17,
};

const double nakshatraSpan = 360 / 27;
const double padaSpan = nakshatraSpan / 4;

/// A graha (or the Lagna) placed in the sidereal zodiac.
class Placement {
  Placement(this.graha, this.longitude, this.house, {this.retro = false});

  /// Null for the ascendant.
  final Graha? graha;

  /// Sidereal longitude, degrees 0..360.
  final double longitude;

  /// Whole-sign house from the Lagna, 1..12.
  final int house;
  final bool retro;

  int get rashi => (longitude ~/ 30) % 12;
  double get degreeInRashi => longitude - rashi * 30;
  int get nakshatra => (longitude / nakshatraSpan).floor() % 27;
  int get pada => ((longitude % nakshatraSpan) / padaSpan).floor() + 1;

  /// Navamsa rashi (D9).
  int get navamsa => (longitude / (30 / 9)).floor() % 12;
}

/// One Vimshottari period.
class DashaPeriod {
  const DashaPeriod(this.lord, this.start, this.end, [this.sub = const []]);

  final Graha lord;
  final DateTime start;
  final DateTime end;

  /// Antardashas (empty for an antardasha itself).
  final List<DashaPeriod> sub;

  bool contains(DateTime t) => !t.isBefore(start) && t.isBefore(end);
}

/// A complete birth chart: sidereal Lahiri positions, whole-sign houses and
/// the Vimshottari dasha timeline.
class BirthChart {
  BirthChart._(this.birthUtc, this.place, this.ayanamsa, this.lagna, this.grahas);

  final DateTime birthUtc;
  final Place place;
  final double ayanamsa;
  final Placement lagna;

  /// The nine grahas in [Graha.values] order.
  final List<Placement> grahas;

  /// [birthUtc] is the birth instant in UTC. [latitude] and [longitude] come
  /// from [place] unless given.
  factory BirthChart.compute(DateTime birthUtc, Place place) {
    final jdUt = Astro.julianDay(birthUtc.toUtc());
    final jde = Astro.jde(jdUt);
    final ay = Astro.ayanamsa(jde);
    double sid(double tropical) => norm360(tropical - ay);

    final asc = sid(Planets.ascendant(jdUt, place.latitude, place.longitude));
    final lagnaRashi = (asc ~/ 30) % 12;
    int houseOf(double lon) => (((lon ~/ 30) % 12) - lagnaRashi + 12) % 12 + 1;

    final trop = <Graha, double>{
      Graha.sun: Astro.sun(jde).lon,
      Graha.moon: Astro.moon(jde, withLatitude: false).lon,
      Graha.mars: Planets.longitude('mars', jde),
      Graha.mercury: Planets.longitude('mercury', jde),
      Graha.jupiter: Planets.longitude('jupiter', jde),
      Graha.venus: Planets.longitude('venus', jde),
      Graha.saturn: Planets.longitude('saturn', jde),
      Graha.rahu: Planets.meanNode(jde),
      Graha.ketu: norm360(Planets.meanNode(jde) + 180),
    };

    // A planet is retrograde when its longitude falls over a short interval.
    bool retro(Graha g) {
      const name = {
        Graha.mars: 'mars',
        Graha.mercury: 'mercury',
        Graha.jupiter: 'jupiter',
        Graha.venus: 'venus',
        Graha.saturn: 'saturn',
      };
      final n = name[g];
      if (n == null) return g == Graha.rahu || g == Graha.ketu; // mean nodes always move backwards
      return angleDiff(Planets.longitude(n, jde + 1), Planets.longitude(n, jde - 1)) < 0;
    }

    return BirthChart._(
      birthUtc,
      place,
      ay,
      Placement(null, asc, 1),
      [
        for (final g in Graha.values)
          Placement(g, sid(trop[g]!), houseOf(sid(trop[g]!)), retro: retro(g)),
      ],
    );
  }

  Placement of(Graha g) => grahas[g.index];
  Placement get moon => of(Graha.moon);
  Placement get mars => of(Graha.mars);

  /// Graha lords of the moon nakshatra: dasha lord at birth.
  Graha get birthDashaLord => dashaOrder[moon.nakshatra % 9];

  /// Fraction of the Moon's nakshatra already travelled, 0..1.
  double get nakshatraElapsed => (moon.longitude % nakshatraSpan) / nakshatraSpan;

  /// Balance of the first mahadasha at birth, in years.
  double get dashaBalanceYears => (1 - nakshatraElapsed) * dashaYears[birthDashaLord]!;

  static const _yearMs = 365.25 * 86400000;

  /// Vimshottari mahadashas from birth for [years] years, each with its
  /// antardashas. The first one is cut at birth (the balance).
  List<DashaPeriod> dashas({int years = 120}) {
    final result = <DashaPeriod>[];
    final startIdx = moon.nakshatra % 9;
    var cursor = birthUtc.toUtc().millisecondsSinceEpoch - (nakshatraElapsed * dashaYears[birthDashaLord]! * _yearMs);
    final limit = birthUtc.toUtc().millisecondsSinceEpoch + years * _yearMs;
    var i = 0;
    while (cursor < limit) {
      final lord = dashaOrder[(startIdx + i) % 9];
      final len = dashaYears[lord]! * _yearMs;
      final subs = <DashaPeriod>[];
      var sc = cursor;
      for (var j = 0; j < 9; j++) {
        final sl = dashaOrder[((startIdx + i) + j) % 9];
        final sLen = len * dashaYears[sl]! / 120;
        subs.add(DashaPeriod(sl, _ms(sc), _ms(sc + sLen)));
        sc += sLen;
      }
      result.add(DashaPeriod(lord, _ms(cursor), _ms(cursor + len), subs));
      cursor += len;
      i++;
    }
    return result;
  }

  static DateTime _ms(double ms) => DateTime.fromMillisecondsSinceEpoch(ms.round(), isUtc: true);

  /// Mangal dosha from the Lagna and from the Moon: Mars in the 1st, 2nd,
  /// 4th, 7th, 8th or 12th house.
  ({bool fromLagna, bool fromMoon}) get manglik {
    const bad = {1, 2, 4, 7, 8, 12};
    final fromMoon = ((mars.rashi - moon.rashi + 12) % 12) + 1;
    return (fromLagna: bad.contains(mars.house), fromMoon: bad.contains(fromMoon));
  }
}
