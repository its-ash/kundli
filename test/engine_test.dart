import 'package:flutter_test/flutter_test.dart';
import 'package:kundli/engine/engine.dart';

/// Reference values: astropy 8 (ERFA "builtin" ephemeris) geocentric mean
/// ecliptic longitudes of date, and an independent numeric solution of the
/// rising ecliptic point (horizon crossing of the ecliptic with mean
/// sidereal time). Order: Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn.
class _Ref {
  const _Ref(this.name, this.utc, this.lat, this.lon, this.trop, this.asc);

  final String name;
  final String utc;
  final double lat, lon;
  final List<double> trop;
  final double asc;
}

const _refs = [
  _Ref('J2000 Delhi', '2000-01-01T12:00:00Z', 28.6139, 77.2090,
      [280.3728, 223.3277, 327.9681, 271.8932, 25.2497, 241.5697, 40.4095], 100.196),
  _Ref('Independence of India', '1947-08-14T18:30:00Z', 28.6139, 77.2090,
      [141.1145, 117.11, 90.58, 126.7998, 229.0005, 135.6867, 133.5953], 60.86),
  _Ref('Mumbai 1990', '1990-05-20T01:00:00Z', 19.08, 72.88,
      [58.7686, 356.7419, 351.7001, 38.2475, 100.4053, 18.0119, 295.1536], 64.933),
  _Ref('New York 1985', '1985-12-25T13:15:00Z', 40.71, -74.01,
      [273.6997, 74.1465, 216.6239, 253.8969, 316.9028, 267.694, 244.4715], 286.553),
  _Ref('Chennai 1975', '1975-03-10T17:15:00Z', 13.08, 80.27,
      [349.5039, 324.7779, 305.6379, 322.6791, 358.0614, 18.8039, 101.9538], 234.572),
  _Ref('London 2026', '2026-02-15T18:00:00Z', 51.51, -0.13,
      [327.0586, 306.1738, 318.3054, 344.3355, 105.9657, 336.6601, 0.1899], 155.819),
];

double _err(double a, double b) => angleDiff(a, b).abs();

void main() {
  group('positions against astropy', () {
    for (final r in _refs) {
      test(r.name, () {
        final utc = DateTime.parse(r.utc);
        final jdUt = Astro.julianDay(utc);
        final jde = Astro.jde(jdUt);
        final got = [
          Astro.sun(jde).lon,
          Astro.moon(jde).lon,
          Planets.longitude('mars', jde),
          Planets.longitude('mercury', jde),
          Planets.longitude('jupiter', jde),
          Planets.longitude('venus', jde),
          Planets.longitude('saturn', jde),
        ];
        // Jupiter and Saturn: the JPL table 1 elements are good to about
        // 0.2 and 0.45 deg (measured on these dates).
        const tol = [0.03, 0.03, 0.1, 0.1, 0.3, 0.1, 0.5];
        for (var i = 0; i < 7; i++) {
          expect(_err(got[i], r.trop[i]), lessThan(tol[i]), reason: 'planet $i: ${got[i]} vs ${r.trop[i]}');
        }
        final asc = Planets.ascendant(jdUt, r.lat, r.lon);
        expect(_err(asc, r.asc), lessThan(0.05), reason: 'ascendant $asc vs ${r.asc}');
      });
    }
  });

  test('Meeus example 33.a: Venus 1992-12-20 0h TD', () {
    // RA 21h04m41.5s, Dec -18d53'17" (apparent). Our value is geometric of date.
    final jde = Astro.julianDay(DateTime.utc(1992, 12, 20));
    final lon = Planets.longitude('venus', jde);
    final lat = Planets.latitude('venus', jde);
    final eq = Astro.toEquatorial(lon, lat, jde);
    expect(_err(eq.ra, (21 + 4 / 60 + 41.454 / 3600) * 15), lessThan(0.05));
    expect((eq.dec - (-(18 + 53 / 60 + 16.84 / 3600))).abs(), lessThan(0.05));
  });

  test('mean node and ayanamsa', () {
    // Meeus 47.a: 1992-04-12 0h TD, mean node 274.4 deg (approx).
    final jde = Astro.julianDay(DateTime.utc(1992, 4, 12));
    expect(Planets.meanNode(jde), closeTo(274.40, 0.05));
    // Drik Panchang Lahiri ayanamsa on 2026-02-15 is 24 deg 13' 44" (24.2288).
    final a = Astro.ayanamsa(Astro.jde(Astro.julianDay(DateTime.utc(2026, 2, 15))));
    expect(a, closeTo(24.2288, 0.01));
  });

  group('sidereal chart', () {
    test('Independence of India (15 Aug 1947, 00:00 IST, Delhi)', () {
      final c = BirthChart.compute(DateTime.utc(1947, 8, 14, 18, 30), Place.newDelhi);
      // Widely published Lahiri chart: Taurus lagna, Sun, Moon and Mercury in
      // Cancer, Saturn in Cancer, Mars in Gemini, Rahu in Taurus, Ketu in Scorpio.
      expect(rashiNames[c.lagna.rashi], 'Vrishabha');
      expect(rashiNames[c.of(Graha.sun).rashi], 'Karka');
      expect(rashiNames[c.moon.rashi], 'Karka');
      expect(rashiNames[c.of(Graha.rahu).rashi], 'Vrishabha');
      expect(rashiNames[c.of(Graha.ketu).rashi], 'Vrishchika');
      // Whole-sign houses count from the lagna sign.
      expect(c.of(Graha.sun).house, 3);
      expect(c.lagna.house, 1);
    });

    test('sidereal = tropical minus ayanamsa', () {
      final r = _refs[2];
      final c = BirthChart.compute(DateTime.parse(r.utc), Place(
        name: 'Mumbai',
        region: 'India',
        latitude: r.lat,
        longitude: r.lon,
        standardOffsetMinutes: 330,
      ));
      for (var i = 0; i < 7; i++) {
        // Graha order: sun, moon, mars, mercury, jupiter, venus, saturn.
        expect(_err(c.grahas[i].longitude, r.trop[i] - c.ayanamsa), lessThan(const [0.03, 0.03, 0.1, 0.1, 0.3, 0.1, 0.5][i]));
      }
      expect(_err(c.lagna.longitude, r.asc - c.ayanamsa), lessThan(0.05));
      expect(_err(c.of(Graha.ketu).longitude, c.of(Graha.rahu).longitude + 180), lessThan(1e-9));
    });
  });

  group('nakshatra and pada', () {
    Placement at(double lon) => Placement(Graha.moon, lon, 1);

    test('boundaries', () {
      expect(at(0).nakshatra, 0);
      expect(at(0).pada, 1);
      expect(at(3.34).pada, 2);
      expect(at(13.34).nakshatra, 1); // Bharani
      expect(at(13.34).pada, 1);
      expect(at(100).nakshatra, 7); // Pushya
      expect(at(359.99).nakshatra, 26); // Revati
      expect(at(359.99).pada, 4);
      expect(nakshatraNames[at(215).nakshatra], 'Anuradha'); // 213.33 to 226.67
      expect(at(215).rashi, 7);
    });

    test('navamsa', () {
      expect(at(0).navamsa, 0);
      expect(at(3.4).navamsa, 1);
      expect(at(30).navamsa, 9);
    });
  });

  group('vimshottari dasha', () {
    test('balance at birth from the Moon', () {
      final c = BirthChart.compute(DateTime.utc(1990, 5, 20, 1), Place.newDelhi);
      final moon = c.moon;
      final elapsed = (moon.longitude % nakshatraSpan) / nakshatraSpan;
      final lord = dashaOrder[moon.nakshatra % 9];
      expect(c.birthDashaLord, lord);
      expect(c.dashaBalanceYears, closeTo((1 - elapsed) * dashaYears[lord]!, 1e-9));

      final d = c.dashas();
      // First mahadasha runs from before birth to birth + balance.
      final balanceMs = c.dashaBalanceYears * 365.25 * 86400000;
      expect(d.first.lord, lord);
      expect(d.first.end.difference(c.birthUtc).inMilliseconds, closeTo(balanceMs, 2000));
      expect(d.first.start.isBefore(c.birthUtc), isTrue);
      // Order follows Vimshottari.
      expect(d[1].lord, dashaOrder[(moon.nakshatra % 9 + 1) % 9]);
      // Consecutive and with 9 antardashas that tile the mahadasha.
      for (var i = 0; i < d.length; i++) {
        expect(d[i].sub.length, 9);
        expect(d[i].sub.first.lord, d[i].lord);
        expect(d[i].sub.first.start, d[i].start);
        expect(d[i].sub.last.end.difference(d[i].end).inSeconds.abs(), lessThan(2));
        if (i > 0) expect(d[i].start, d[i - 1].end);
      }
      // Full cycles are 120 years: the second mahadasha of the same lord is 120 y later.
      final full = d[1].end.difference(d[1].start).inDays / 365.25;
      expect(full, closeTo(dashaYears[d[1].lord]!.toDouble(), 0.01));
    });

    test('Moon at 10 deg Mesha: Ketu balance is 1.75 years', () {
      // 10 / 13.3333 = 0.75 of Ashwini is gone; Ketu has 7 * 0.25 left.
      const lon = 10.0;
      final elapsed = (lon % nakshatraSpan) / nakshatraSpan;
      expect((1 - elapsed) * dashaYears[Graha.ketu]!, closeTo(1.75, 1e-9));
    });
  });

  group('Guna Milan', () {
    Placement moonAt(double lon) => Placement(Graha.moon, lon, 1);

    test('Ashwini (Mesha) boy with Pushya (Karka) girl = 29.5', () {
      // Hand calculation: Varna 0 (Kshatriya < Brahmin), Vashya 1
      // (Chatushpada/Jalachara), Tara 1.5 (one unfavourable count), Yoni 2
      // (Horse/Sheep), Graha Maitri 4 (Mars friend, Moon neutral), Gana 6
      // (Deva/Deva), Bhakoot 7 (4th from boy), Nadi 8 (Adi/Madhya).
      final g = GunaMilan.compute(moonAt(5), moonAt(100));
      expect([for (final k in g.kootas) k.score], [0, 1, 1.5, 2, 4, 6, 7, 8]);
      expect(g.total, 29.5);
      expect(g.max, 36);
      expect(g.verdict, 'Good match');
    });

    test('same nakshatra and sign scores 28 (nadi dosha)', () {
      final g = GunaMilan.compute(moonAt(20), moonAt(20));
      expect([for (final k in g.kootas) k.score], [1, 2, 3, 4, 5, 6, 7, 0]);
      expect(g.total, 28);
    });

    test('bhakoot dosha 6/8', () {
      // Mesha boy, Vrishchika girl is the 8th from the boy.
      final g = GunaMilan.compute(moonAt(5), moonAt(215));
      expect(g.koota('Bhakoot').score, 0);
    });

    test('yoni matrix is symmetric with 4 on the diagonal', () {
      final m = GunaMilan.yoniMatrix;
      for (var i = 0; i < 14; i++) {
        expect(m[i][i], 4);
        for (var j = 0; j < 14; j++) {
          expect(m[i][j], m[j][i], reason: 'yoni $i,$j');
        }
      }
    });
  });

  test('Manglik: Mars in 7th house counts', () {
    final c = BirthChart.compute(DateTime.utc(2000, 1, 1, 12), Place.newDelhi);
    final bad = {1, 2, 4, 7, 8, 12}.contains(c.mars.house);
    expect(c.manglik.fromLagna, bad);
  });
}
