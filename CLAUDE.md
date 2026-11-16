# Kundli (package: kundli / com.itsash.kundli)

Offline Vedic birth chart and Guna Milan marriage matching. Profiles (name,
date, time, place, time zone) are saved on the phone. No backend; INTERNET is
used only by the update check in Settings.

## Engine (`lib/engine/`, pure Dart)

- `astro.dart`, `place.dart`: copies of `panchang/lib/engine/` (Sun, Moon,
  mean Lahiri ayanamsa, GMST, delta T, `Place` with DST rule). Longitudes are
  mean equinox of date, no nutation (cancels in sidereal values).
- `planets.dart`: Mars..Saturn from the JPL Keplerian elements (Standish,
  1800-2050; about 0.1 deg for Mars/Mercury/Venus, up to 0.2 deg for Jupiter, 0.45 deg for Saturn), mean lunar node (Rahu; Ketu = +180), and the
  ascendant from local sidereal time, obliquity and latitude.
- `chart.dart`: `BirthChart.compute(birthUtc, place)` gives sidereal
  `Placement`s (rashi, degree, nakshatra, pada, navamsa, whole-sign house,
  retrograde), Vimshottari `dashas()` (365.25-day year, balance from the Moon's
  nakshatra), and Manglik (Mars in 1/2/4/7/8/12 from Lagna and from Moon).
- `matching.dart`: `GunaMilan.compute(boyMoon, girlMoon)` with the eight
  kootas (Varna 1, Vashya 2, Tara 3, Yoni 4, Graha Maitri 5, Gana 6, Bhakoot 7,
  Nadi 8). Tables are the common textbook ones; sources differ on a few cells
  (Vashya, Gana, Graha Maitri).

## Code layout

- `lib/app/`: `Profile` (JSON, lazy `chart`), `AppModel` (profiles, selected,
  chart style) + `AppScope`.
- `lib/ui/`: `home_screen.dart` (UiShell: Profiles / Chart / Dasha / Match),
  `chart_painter.dart` (CustomPainter, North diamond and South grid),
  `chart_page`, `dasha_page`, `match_page`, `profiles_page`, `profile_form`,
  `place_picker`, `settings_screen` (ends with `UiAppearanceSection`,
  `UiUpdateSection(storeId: 'kundli')`, `UiDeveloperSection`).
- Tests: `test/engine_test.dart`. Reference longitudes and ascendants come from
  astropy (ERFA ephemeris) for six birth moments; Guna Milan cases are hand
  calculated.

## Commands

- `make run`, `make build` (release APK), `make test` (`flutter analyze` +
  `flutter test`), `make clean`.
- Icon: SVG sources in `assets/icon/` -> `*-1024.png` -> `dart run flutter_launcher_icons`.

## Conventions

- minSdk 26. UI only from the shared `theme` package; no hardcoded colors
  (indigo accent via `UiApp(accent:)`). English UI with Sanskrit names.
- Keep the "traditional guidance, not certainty" note on chart, dasha and match.

## Release (Ash Store)

- `store.json` (id `kundli`, repo its-ash/kundli), `store.mk`, `index.html` +
  `CNAME` (`kundli.itsash.in`). See `../ash-store/store-kit/STORE.md`.
- `make deploy` = bump version -> build -> commit, tag, push, GitHub release
  with `kundli.apk`. Never create releases by hand.
- Do not edit `store.mk` here; edit `../ash-store/store-kit/store.mk`, then run
  `make store-sync` at the workspace root.
