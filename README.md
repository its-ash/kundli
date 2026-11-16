# Kundli

Offline Vedic birth chart and Guna Milan marriage matching, North and South Indian styles.

**[Website](https://kundli.itsash.in)** · **[Download APK](https://github.com/its-ash/kundli/releases/latest/download/kundli.apk)** · Get it in **[Ash Store](https://store.itsash.in)**

## Features

- **Profiles**: save several people with name, birth date, time and place, picked from a built-in list of about 340 cities. The time zone is set from the place and can be changed by hand.
- **Birth chart**: Lagna, Sun, Moon, Mars, Mercury, Jupiter, Venus, Saturn, Rahu and Ketu with the Lahiri ayanamsa and whole-sign houses. Switch between a North Indian diamond and a South Indian chart.
- **Planet table**: sign, degree, nakshatra, pada and house of every graha, retrograde marked.
- **Dasha**: Moon sign, nakshatra, balance at birth and the full Vimshottari mahadasha and antardasha timeline, with the running period highlighted.
- **Guna Milan**: Ashtakoota 36-point matching of two profiles with the score of each of the eight kootas (Varna, Vashya, Tara, Yoni, Graha Maitri, Gana, Bhakoot, Nadi), plus a Manglik check.
- **English with Sanskrit names**, light mode by default with Dark and System in Settings.
- **Offline and private**: everything is calculated on your phone. The only network call is the update check in Settings.

Kundli follows traditional methods. It is guidance from tradition, not certainty.

## Install

- **Ash Store**: install [Ash Store](https://store.itsash.in) once, then install and update Kundli from it.
- **APK**: download the [latest APK](https://github.com/its-ash/kundli/releases/latest/download/kundli.apk) on your phone and open it. Allow your browser to install unknown apps if Android asks.

Requires Android 8.0 (API 26) or later.

## Accuracy

Sun and Moon use the series of Jean Meeus, *Astronomical Algorithms*. The five planets use the JPL Keplerian approximation (1800-2050). In the tests, all seven longitudes and the ascendant match astropy (ERFA ephemeris) within 0.03 degrees for Sun and Moon, 0.1 degrees for Mars, Mercury and Venus, 0.3 degrees for Jupiter, 0.5 degrees for Saturn, and 0.05 degrees for the ascendant, on six dates between 1947 and 2026. Rahu is the mean node. The ascendant needs an exact birth time and place, and old civil time zones (such as wartime summer time) are not known, so set the zone by hand if needed.

## Develop

Needs Flutter ≥ 3.44 and the shared theme package at `../theme`.

```bash
make run      # run on a connected device
make test     # flutter analyze + flutter test
make build    # release APK
make deploy   # bump version, build, tag, push, GitHub release (see store.mk)
```

## Release

`make deploy` follows the Ash Store kit (`store.mk`, `store.json`): it bumps the
version in `pubspec.yaml`, builds, commits, tags `vX.Y.Z`, pushes, and publishes
a GitHub release with `kundli.apk`. Ash Store and the website pick up the new
version from that release.

## Project layout

```
lib/
  main.dart            UiApp from the shared theme, light by default
  engine/              pure Dart: astro (Sun, Moon, ayanamsa), planets, chart, matching, place
  data/places.dart     offline city list loader (assets/geo/cities.json)
  app/                 Profile, AppModel (profiles and chart style in shared_preferences)
  ui/                  home, profiles, profile form, chart, dasha, match, settings
test/engine_test.dart  reference charts, nakshatra, dasha, Guna Milan
assets/icon/           pixel-art icon sources
```

## License

All rights reserved.

Built by [itsash.in](https://itsash.in).
