# KIANEX PTS50N1 — Companion Application (v4.0.1)

Flutter companion app for the **KIANEX PTS50N1 / PST50R1** programmable
single-relay timer. The app plans timer programs, validates the command
chain, and transfers the user configuration to the device shared memory
(**ST25DV16KC**, NFC Forum Type 5) through the 8-step safe write protocol
defined in `PST50R1_SourceOfTruth` (SOT v3.1-Final).

> Android only. iOS was removed from the delivery scope («فقط app برای
> اندروید ساخته می‌شود»).

## What is new in v4.0.1 (CI build fix release)

The v4.0.0 GitHub Actions build failed in the `Analyze code` and `Run tests`
steps. v4.0.1 fixes every reported issue and **reproduces the complete CI
pipeline locally with the exact CI Flutter version (3.50.1)**:
`pub get` ✓ · `gen-l10n` ✓ · `analyze` **0 issues** ✓ · `flutter test`
**48/48 passed** ✓ · `gradlew assembleRelease` resolves and compiles ✓.

| # | Failure in v4.0.0 | Fix in v4.0.1 |
|---|-------------------|---------------|
| 1 | Analyzer error: `readBlock` called on a nullable tag link (`real_nfc_service.dart`) | Null-safe probe after `Iso15693TagLink.open()` — a poll window without a tag is logged and retried |
| 2 | Analyzer error ×2: un-awaited `FlutterNfcKit.transceive` in `_readSystemInfo` (`tag_link.dart`) | `_readSystemInfo` is now `async` and both (Extended) Get System Info frames are awaited |
| 3 | Analyzer error: `Position.source` does not exist in geolocator 14 (`gps_screen.dart`) | Log line now uses `Position.isMocked` (also detects fake/mock locations — useful for field reports) |
| 4 | Analyzer warnings (unused import/field/parameter, `use_build_context_synchronously`) | All cleaned — `flutter analyze` reports **zero issues** |
| 5 | Unit tests ×2 failed: `SotProtocol` threw `model_mismatch:` with an empty URI | Root cause: `ndefProductUri()` scanned the raw onboarding bytes from offset 0 and mis-parsed the **Type 5 CC file** (`E1 40 …`) as a TLV entry, skipping the whole NDEF area. The parser now skips the 4-byte CC header before the TLV scan — on a real tag the same bug would have blocked every write |
| 6 | Gradle: `ndkVersion` forced NDK validation although the app itself has no native code | App-level `ndkVersion` line removed (plugin modules keep their own); NDK 28.2 is fetched automatically by AGP on CI because `flutter_nfc_kit → jni` ships C/C++ (CMake) — expect a longer **first** CI build |

## What was new in v4.0.0

| # | Field report | Fix in v4.0.0 |
|---|--------------|---------------|
| 1 | GitHub Actions node-deprecation warnings | Workflow updated: `checkout@v7`, `setup-java@v6`, `upload-artifact@v7` (all Node 24) |
| 2 | App icon distorted the logo aspect ratio | Icon generator crops to the artwork bounding box and scales **uniformly** (aspect-true), all densities regenerated |
| 3 | NFC button/footer too small on the home page | Footer bar 56→76 px, hexagonal button 58→80 px |
| 4 | No permissions were requested; app never touched NFC | Real NFC layer enabled (`NFC` + runtime `NFC` usage; `ACCESS_FINE/COARSE_LOCATION` declared and requested at runtime) |
| 5 | App did not communicate over NFC | The production ISO 15693 transport (flutter_nfc_kit → Android `NfcV`) now drives every flow: identify, logger read, 8-step write |
| 6 | Persian calendar ignored the current year leap state | Annual cycle uses the **current Jalali year** calendar (1403/1408 leap: Esfand = 30 days, day-of-year 1..366); solar table day-366 fixed |
| 7 | Disabled programs still counted in the memory/timer gauges | Gauges, capacity chips and the write payload are derived from **enabled programs only** |
| 8 | Simulated GPS | Real GNSS fix via `geolocator` (permission request, accuracy read-out, manual entry kept as fallback) |
| 9 | Write programs/settings to ST25DV16KC, read its status | Full SOT §4.5 protocol over the tag: onboarding check, logger read (§4.10), start/data/CRC/end codes, read-back verification |
| 10 | Support other tag models | The NFC layer auto-detects tag geometry via **(Extended) Get System Info** and switches between standard and **extended (2-byte addressing)** command sets — ST25DV04K/16K/64K (C-series included) and other Type 5 tags |
| 11 | Remove the simulation section | QA simulator, scenario picker and the fake identify animation are removed; every operation talks to the physical tag |
| 12 | In-app logger with export | Settings → «گزارش‌های کاربرد»: JSONL log file (NFC/GPS/program events), viewer with filters, share/copy/clear |

## NFC layer — datasheet notes (ST25DV04KC/16KC/64KC)

* **Memory**: 2048 bytes = 512 × 4-byte blocks (ST25DV16KC). The app maps
  blocks 16..431 (planning area, app-writable) and reads blocks 504..511
  (logger area, MCU-owned). Blocks 0..15 (CC + NDEF) are factory-written
  and never rewritten (R-01).
* **Addressing**: tags larger than 256 blocks use the extended command set
  — `Protocol_Extension` flag + 2-byte block number:
  `0x30` Extended Read Single Block, `0x31` Extended Write Single Block,
  `0x33` Extended Read Multiple Blocks, `0x3B` Extended Get System Info.
  Smaller tags fall back to the standard `0x20/0x21/0x23/0x2B` set with
  1-byte block numbers.
* **Writes**: `Option` flag set (ISO 15693 requirement); each EEPROM block
  write takes ≈ 5 ms. Retry-once covers the RF/I²C arbitration window of
  SOT §4.1 (busy `0Fh` answers).
* **Model identification** (protocol step 1): valid Type 5 CC (magic `E1`),
  factory NDEF URI carrying the KIANEX marker, tag memory ≥ 512 × 4 B.
  `IC_REF` and the NDEF URI are logged for diagnostics instead of a
  hard-coded IC table.
* **CRC**: APP_CRC32 = CRC-32/MPEG-2 (poly `0x04C11DB7`, init
  `0xFFFFFFFF`, no reflection) over blocks 16..429 — test vectors TV-01..
  TV-03 of SOT table 4-8 are unit-tested (`test/crc32_test.dart`).

### Why not the ST25 SDK (STSW-ST25SDK001)?

ST provides the ST25 SDK for Android, but it is distributed as an AAR via
the ST website under a click-through license — it cannot be fetched
automatically by CI (GitHub Actions) and would require committing a
binary blob into the repository. The app instead implements the same RF
command layer the SDK uses internally (raw ISO 15693 through Android
`NfcV`), which keeps the build reproducible and works with any Type 5
tag family. Revisit this decision if protection/I2C-password features of
the SDK are ever required.

## Project layout

```
lib/
├── main.dart                  # bootstrap: prefs, logger init, DI overrides
├── app.dart                   # MaterialApp.router (fa/en, light/dark)
├── core/
│   ├── logging/app_logger.dart      # JSONL logger (viewer + export)
│   ├── nfc/
│   │   ├── tag_link.dart            # ISO 15693 command layer (ext + std)
│   │   ├── memory_map.dart          # SOT byte layout + payload encoder
│   │   ├── sot_protocol.dart        # 8-step write protocol + §4.10 read
│   │   ├── real_nfc_service.dart    # production service (no simulator)
│   │   └── nfc_service.dart         # contracts (WriteProgress, TagIdentity)
│   ├── solar/                       # sunrise/sunset + Chebyshev Q14 fit
│   ├── utils/jalali.dart            # jalaali port + leap/day-of-year API
│   ├── crypto/crc32_stm32.dart      # CRC-32/MPEG-2 (STM32 hardware parity)
│   ├── validation/validators.dart   # Q-06/Q-10 + chain rules R-01..R-04
│   ├── l10n/                        # ARB decks + generated classes
│   └── router/, settings/, theme/, widgets/, constants/
├── features/                  # home, program flow, event editor, assign,
│                              # nfc write, device status, gps, settings,
│                              # logs, onboarding, help/about
└── state/                     # Riverpod controllers
```

## Build

### Prerequisites
* Flutter stable (3.5x) with Dart 3 — Android toolchain only
* JDK 17
* A device/emulator is **not** required for building

### Commands

```bash
# 1. Clone / extract the project and enter it
cd kianex_pts50n1_app

# 2. Fetch dependencies
flutter pub get

# 3. (optional) regenerate localizations from the ARB decks
flutter gen-l10n

# 4. Static analysis + unit tests
flutter analyze --no-fatal-infos
flutter test

# 5. Release APK
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### GitHub Actions

`.github/workflows/flutter-build.yml` builds the release APK on every
push/PR and uploads it as the artifact `kianex-pts50n1-release-apk`
(checkout@v7, setup-java@v6, flutter-action@v2, upload-artifact@v7 —
Node 24 compatible, no deprecation warnings). Every CI step was locally
reproduced with Flutter 3.50.1 / Dart 3.14.0 before this release. The
first CI build additionally downloads the Android NDK (≈ 2.5 GB, required
by the `jni` native layer of `flutter_nfc_kit`) — later builds are cached
and fast.

## Field-test loop

1. Install the APK on the Android test phone.
2. Run the flows: identify the relay tag, read the device status, send
   programs, update time & location.
3. Settings → «گزارش‌های کاربرد (لاگر)» → «ذخیره و ارسال گزارش» — share
   the JSONL log with the test report back to the development team.
4. The log contains every NFC frame-level event, protocol step timing,
   GPS fix, and program edit needed to reproduce field failures.

## Safety properties implemented (SOT compliance)

* R-01/R-02 — the app never writes blocks 0..15 or 432..511.
* §4.5 — the eight protocol steps in mandatory order with the two write
  modes (`0xA5/0xB4/0xC3` settings-only; `0x5A/0x4B/0x3C` full program).
* §4.10 — consistent logger read with LOG_CRC32 verification.
* Q-01 — every RES byte is written as `0x00`.
* Q-05 — disabled programs are never part of the payload.
* Q-10 + R-01..R-04 — chain rules enforced in the editor.
* RC-10 — two failed attempts lead to the power-off guidance dialog.
