import 'chart.dart';

/// One of the eight kootas of Ashtakoota matching.
class Koota {
  const Koota(this.name, this.meaning, this.max, this.score, this.detail);

  final String name;
  final String meaning;
  final int max;
  final double score;

  /// What was compared, e.g. "Deva / Manushya".
  final String detail;
}

/// Result of Guna Milan (Ashtakoota, 36 points).
class GunaMilan {
  const GunaMilan(this.kootas);

  final List<Koota> kootas;

  double get total => kootas.fold(0.0, (s, k) => s + k.score);
  int get max => kootas.fold(0, (s, k) => s + k.max);

  Koota koota(String name) => kootas.firstWhere((k) => k.name == name);

  /// Traditional reading of the total.
  String get verdict {
    final t = total;
    if (t < 18) return 'Not recommended';
    if (t < 25) return 'Average match';
    if (t < 33) return 'Good match';
    return 'Excellent match';
  }

  /// Boy's Moon is the first argument, girl's the second, as the tables
  /// are read in the tradition.
  static GunaMilan compute(Placement boyMoon, Placement girlMoon) {
    final bs = boyMoon.rashi, gs = girlMoon.rashi;
    final bn = boyMoon.nakshatra, gn = girlMoon.nakshatra;

    // 1. Varna (1)
    final bv = _varna[bs], gv = _varna[gs];
    final varna = bv >= gv ? 1.0 : 0.0;

    // 2. Vashya (2)
    final bvy = _vashya(boyMoon), gvy = _vashya(girlMoon);
    final vashya = _vashyaTable[bvy][gvy];

    // 3. Tara (3): count each nakshatra from the other, remainder of 9.
    bool badTara(int from, int to) {
      final r = (((to - from) % 27) + 1) % 9;
      return r == 3 || r == 5 || r == 7;
    }

    final taraBad = (badTara(gn, bn) ? 1 : 0) + (badTara(bn, gn) ? 1 : 0);
    final tara = const [3.0, 1.5, 0.0][taraBad];

    // 4. Yoni (4)
    final yoni = _yoniMatrix[_yoniOf[bn]][_yoniOf[gn]].toDouble();

    // 5. Graha Maitri (5)
    final bl = rashiLords[bs], gl = rashiLords[gs];
    final maitri = _maitriScore(bl, gl);

    // 6. Gana (6)
    final bg = _gana[bn], gg = _gana[gn];
    final gana = _ganaTable[bg][gg].toDouble();

    // 7. Bhakoot (7)
    final d = ((gs - bs + 12) % 12) + 1; // girl's sign counted from boy's
    final bhakoot = const {2, 12, 5, 9, 6, 8}.contains(d) ? 0.0 : 7.0;

    // 8. Nadi (8)
    final nadi = _nadi(bn) == _nadi(gn) ? 0.0 : 8.0;

    return GunaMilan([
      Koota('Varna', 'Work and ego', 1, varna, '${_varnaNames[bv]} / ${_varnaNames[gv]}'),
      Koota('Vashya', 'Mutual attraction', 2, vashya, '${_vashyaNames[bvy]} / ${_vashyaNames[gvy]}'),
      Koota('Tara', 'Health and luck', 3, tara, '${nakshatraNames[bn]} / ${nakshatraNames[gn]}'),
      Koota('Yoni', 'Intimacy', 4, yoni, '${_yoniNames[_yoniOf[bn]]} / ${_yoniNames[_yoniOf[gn]]}'),
      Koota('Graha Maitri', 'Mental friendship', 5, maitri, '${bl.sanskrit} / ${gl.sanskrit}'),
      Koota('Gana', 'Temperament', 6, gana, '${_ganaNames[bg]} / ${_ganaNames[gg]}'),
      Koota('Bhakoot', 'Love and family', 7, bhakoot, '${rashiNames[bs]} / ${rashiNames[gs]}'),
      Koota('Nadi', 'Health and progeny', 8, nadi, '${_nadiNames[_nadi(bn)]} / ${_nadiNames[_nadi(gn)]}'),
    ]);
  }

  // ---- Varna: 0 Shudra .. 3 Brahmin, by Moon rashi.
  static const _varnaNames = ['Shudra', 'Vaishya', 'Kshatriya', 'Brahmin'];
  static const _varna = [2, 1, 0, 3, 2, 1, 0, 3, 2, 1, 0, 3];

  // ---- Vashya: 0 Chatushpada, 1 Manava, 2 Jalachara, 3 Vanachara, 4 Keeta.
  static const _vashyaNames = ['Chatushpada', 'Manava', 'Jalachara', 'Vanachara', 'Keeta'];
  static int _vashya(Placement m) {
    final deg = m.degreeInRashi;
    switch (m.rashi) {
      case 0:
      case 1:
        return 0;
      case 2:
      case 5:
      case 6:
      case 10:
        return 1;
      case 3:
      case 11:
        return 2;
      case 4:
        return 3;
      case 7:
        return 4;
      case 8:
        return deg < 15 ? 1 : 0; // Dhanu: first half human, second half quadruped
      default: // Makara: first half quadruped, second half aquatic
        return deg < 15 ? 0 : 2;
    }
  }

  // Rows: boy; columns: girl.
  static const _vashyaTable = <List<double>>[
    [2, 1, 1, 0.5, 1],
    [1, 2, 0.5, 0, 1],
    [1, 0.5, 2, 1, 1],
    [0, 0, 0, 2, 0],
    [1, 1, 1, 0, 2],
  ];

  // ---- Yoni.
  static const _yoniNames = [
    'Horse', 'Elephant', 'Sheep', 'Serpent', 'Dog', 'Cat', 'Rat', //
    'Cow', 'Buffalo', 'Tiger', 'Deer', 'Monkey', 'Mongoose', 'Lion',
  ];
  static const _yoniOf = [
    0, 1, 2, 3, 3, 4, 5, 2, 5, 6, 6, 7, 8, 9, 8, 9, 10, 10, 4, 11, 12, 11, 13, 0, 13, 7, 1, //
  ];
  static const yoniMatrix = _yoniMatrix;
  static const _yoniMatrix = <List<int>>[
    [4, 2, 2, 3, 2, 2, 2, 1, 0, 1, 3, 3, 2, 1],
    [2, 4, 3, 3, 2, 2, 2, 2, 3, 1, 2, 3, 2, 0],
    [2, 3, 4, 2, 1, 2, 1, 3, 3, 1, 2, 0, 3, 1],
    [3, 3, 2, 4, 2, 1, 1, 1, 1, 2, 2, 2, 0, 2],
    [2, 2, 1, 2, 4, 2, 1, 2, 2, 1, 0, 2, 1, 1],
    [2, 2, 2, 1, 2, 4, 0, 2, 2, 1, 3, 3, 2, 1],
    [2, 2, 1, 1, 1, 0, 4, 2, 2, 2, 2, 2, 1, 2],
    [1, 2, 3, 1, 2, 2, 2, 4, 3, 0, 3, 2, 2, 1],
    [0, 3, 3, 1, 2, 2, 2, 3, 4, 1, 2, 2, 2, 1],
    [1, 1, 1, 2, 1, 1, 2, 0, 1, 4, 1, 1, 2, 1],
    [3, 2, 2, 2, 0, 3, 2, 3, 2, 1, 4, 2, 2, 1],
    [3, 3, 0, 2, 2, 3, 2, 2, 2, 1, 2, 4, 3, 2],
    [2, 2, 3, 0, 1, 2, 1, 2, 2, 2, 2, 3, 4, 2],
    [1, 0, 1, 2, 1, 1, 2, 1, 1, 1, 1, 2, 2, 4],
  ];

  // ---- Graha Maitri: natural friendships (row looks at column).
  static const _friends = {
    Graha.sun: [Graha.moon, Graha.mars, Graha.jupiter],
    Graha.moon: [Graha.sun, Graha.mercury],
    Graha.mars: [Graha.sun, Graha.moon, Graha.jupiter],
    Graha.mercury: [Graha.sun, Graha.venus],
    Graha.jupiter: [Graha.sun, Graha.moon, Graha.mars],
    Graha.venus: [Graha.mercury, Graha.saturn],
    Graha.saturn: [Graha.mercury, Graha.venus],
  };
  static const _enemies = {
    Graha.sun: [Graha.venus, Graha.saturn],
    Graha.moon: <Graha>[],
    Graha.mars: [Graha.mercury],
    Graha.mercury: [Graha.moon],
    Graha.jupiter: [Graha.mercury, Graha.venus],
    Graha.venus: [Graha.sun, Graha.moon],
    Graha.saturn: [Graha.sun, Graha.moon, Graha.mars],
  };

  /// 1 friend, 0 neutral, -1 enemy.
  static int _attitude(Graha a, Graha b) {
    if (_friends[a]!.contains(b)) return 1;
    if (_enemies[a]!.contains(b)) return -1;
    return 0;
  }

  static double _maitriScore(Graha boyLord, Graha girlLord) {
    if (boyLord == girlLord) return 5;
    final a = _attitude(boyLord, girlLord), b = _attitude(girlLord, boyLord);
    final hi = a > b ? a : b, lo = a > b ? b : a;
    if (hi == 1 && lo == 1) return 5;
    if (hi == 1 && lo == 0) return 4;
    if (hi == 0 && lo == 0) return 3;
    if (hi == 1 && lo == -1) return 1;
    if (hi == 0 && lo == -1) return 0.5;
    return 0;
  }

  // ---- Gana: 0 Deva, 1 Manushya, 2 Rakshasa.
  static const _ganaNames = ['Deva', 'Manushya', 'Rakshasa'];
  static const _gana = [
    0, 1, 2, 1, 0, 1, 0, 0, 2, 2, 1, 1, 0, 2, 0, 2, 0, 2, 2, 1, 1, 0, 2, 2, 1, 1, 0, //
  ];
  static const _ganaTable = <List<int>>[
    [6, 6, 0],
    [5, 6, 0],
    [1, 0, 6],
  ];

  // ---- Nadi: 0 Adi, 1 Madhya, 2 Antya.
  static const _nadiNames = ['Adi', 'Madhya', 'Antya'];
  static int _nadi(int nakshatra) => const [0, 1, 2, 2, 1, 0][nakshatra % 6];
}
