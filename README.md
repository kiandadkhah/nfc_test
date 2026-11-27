# KIANEX PTS50N1 — Companion Application (v4.2.0)

Flutter companion app for the **KIANEX PTS50N1 / PST50R1** programmable
single-relay timer. The app plans timer programs, validates the command
chain, and transfers the user configuration to the device shared memory
(**ST25DV16KC**, NFC Forum Type 5) through the 8-step safe write protocol
defined in `PST50R1_SourceOfTruth` (SOT v3.1-Final).

> Android only. iOS was removed from the delivery scope («فقط app برای
> اندروید ساخته می‌شود»).

## What is new in v4.2.0 (field-report release: real ST25DV addressing,
NDEF dispatch claim, chain-wipe fix, map connectivity)

Based on the v4.1.0 field test (installed APK + exported log). The tag
answered correctly in the field — the app asked the wrong questions.

| # | Field report / log evidence | Root cause | Fix in v4.2.0 |
|---|------------------------------|------------|---------------|
| 1 | `identify: uri=...pts50r1 … enoughMemory=false modelMatched=true` + «مدل تطبیق نشد / ظرفیت حافظه تگ برای نگاشت کافی نیست» + write aborted `memory_too_small:256x4` | **Wrong addressing model** — the app set the ISO `Protocol_Extension` flag (0x08) for blocks ≥ 256. Per DS10925 Rev 9 the PE flag is «reserved for future use» on ST25DV: the tag rejected every PE-flagged frame with `0x02`/`0x03` (the field log), the open-time self-check then fell back to standard addressing and **clamped the geometry to 256 blocks** → the 433-block layout check failed. Additionally the ST25DV16K/64K standard Get System Info carries **NO memory size** (info flags `0x0B` = DSFID+AFI+IC_REF, Table 158) — the old parser mis-called the correct 13-byte answer «not parseable» | **Real ST command set** (`tag_link.dart`, Table 101): blocks ≥ 256 use the dedicated **extended commands** `0x30` Ext Read Single / `0x31` Ext Write Single / `0x33` Ext Read Multi (2-byte block number LSB first, 16-bit block count in multi) — PE flag is never set. Geometry: standard Get System Info parsed per Table 158 (IC_REF `0x26` ⇒ ST25DV16K/64K family), **Extended Get System Info `0x3B`** (param `0x04`) reads the 16-bit MEM_SIZE (Table 165), and IC_REF profiles (`24h`→128×4, `26h`→512×4) replace the bogus fallback — the production ST25DV16KC now reports 512 × 4 B and `enoughMemory=true` |
| 2 | When the app is running, Android opens the onboarding web page (`kianex.co/products/pts50r1`) in the background on tag tap | The factory NDEF URI dispatches `ACTION_NDEF_DISCOVERED`; with no claiming app Android hands it to the browser | The activity now **claims the factory URI** in the manifest (`NDEF_DISCOVERED`, `https://kianex.co` + `/products/pts50` prefix): the tap is routed to the app — no browser behind it; when the app is closed, tapping the tag launches the app directly (nice onboarding flow) |
| 3 | **Bug — creating the second event deleted every event** («ساخت رویداد دوم باعث حذف تمام رویدادها می‌شود») | Cascade self-reference: `_draft!.events..clear()..addAll(sortChain(_draft!.events))` evaluates its argument **after** `clear()`, so the sort read the already-emptied list. Same pattern in `restoreFromLocalJson` wiped every persisted event on every app start | Both spots now sort a **copy** of the list first. Regression tests added (`test/programs_state_test.dart`): two adds keep two events, save keeps the chain, restore keeps every event and re-sorts old chains |
| 4 | Both map screens (location + picker) stayed grey — no tiles ever loaded | The manifest declared **no `INTERNET` permission** — every OSM tile request was silently blocked by Android | `<uses-permission android:name="android.permission.INTERNET"/>` added; failed tiles now also raise a visible banner «نمایش نقشه به اینترنت نیاز دارد…» via `TileLayer.errorTileCallback` instead of a silent grey page |
| 5 | The app showed the UID as `AF24ADD7002602E0` while the tag print reads `E0 02 26 00 D7 AD 24 AF` | Android reports the ISO 15693 UID LSB-first | The link reports the **human-readable order** (`uidInHumanOrder`) everywhere — UI and logs match the printed tag |
| 6 | Identify log `expected="https://kianex.co/products/pts50"` looked like a wrong URL | Prefix logging obscured the exact contract | The identify log now shows the exact product URL **and** the accepted prefix; the result screen shows a **memory-specific** warning title when only the capacity fails (new `idMemoryWarnTitle`), and the texts say PTS50R1 (typo PST50R1 fixed) |
| 7 | Log lines truncated the raw frames to 10 bytes (`00 0b af 24 …` looked like a truncated system-info answer) | `_hex` capped at 10 bytes | Log hex dumps now show up to 24 bytes; unit tests (`test/system_info_test.dart`) replay the **exact field frames** — the 13-byte `0x0B` answer and the 16-bit MEM_SIZE frame — so a field log can be matched byte-for-byte |

Verification: `flutter analyze` — 0 errors (4 pre-existing infos) ·
`flutter test` — **67/67 passed** (SDK 3.50.1, the exact CI version).

## What was new in v4.1.0 (field-report release: permissions, real map,
chain ordering, time UX, NFC protocol fixes)

Based on the v4.0.1 field test (installed APK + exported application log
`لاگر.html`) and the product identification URL confirmed by KIANEX
(`https://kianex.co/products/pts50r1`).

| # | Field report | Fix in v4.1.0 |
|---|--------------|---------------|
| 1 | The app must ask for the permissions at start and ask the user to turn NFC and location on | **Startup system gate** (`system_gate.dart`): NFC hardware detection (absent → explanatory notice), NFC off → guidance into the system NFC panel (native `Settings.ACTION_NFC_SETTINGS` channel), location permission requested at the first start, denied-forever → app settings, service off → location settings. A readiness strip on the home screen stays visible until everything is ready |
| 2 | Location screen: the position is not shown on a real map; manual entry must be a map picker | Real OpenStreetMap (flutter_map, no API key) shows the relay position with an accuracy chip; «ورود دستی مختصات» opens a full-screen picker — tap moves the marker, «موقعیت فعلی گوشی» recenters, «تایید» stores the coordinates |
| 3 | The paragraph under the location screen leaks implementation data | Replaced by a formal privacy notice («این موقعیت، مبنای محاسبه زمان طلوع و غروب خورشید در دستگاه است …») — no registers, no block numbers |
| 4 | Bug 2 — the command chain is not sorted by time from 00:00 | The chain is **auto-sorted on every add/edit/delete** with a year-stable strategy: sunrise-anchored commands → fixed times (ascending from 00:00) → sunset-anchored commands. The same order is used by the UI, the validators and the device payload (`buildProgramWritePlan`) — one order everywhere; chains persisted by older versions are re-sorted on restore |
| 5 | Sunrise/sunset move through the year — separate them from rule R-3; choose a strategy so a fixed hour cannot collide with them | **R-03 (same action adjacency) is exempt for solar commands** — their real time moves through the year, so static adjacency is meaningless. Fixed↔solar collisions are handled by the **annual overlap analysis** (`astroOverlapWarnings`): the NOAA sunrise/sunset sweep of the whole year is computed for the stored location, and when a fixed minute falls inside the sweep the editor shows the exact coinciding date range and the number of days — the user approves explicitly before saving (non-blocking, informational) |
| 6 | UI/UX — the up/down steppers hide the value under the finger; a 720-minute duration takes 144 taps | All three time inputs reworked (`time_edit_fields.dart`): «ساعت مشخص» → wheel-picker sheet (value always visible, one gesture to any time); «انحراف از طلوع/غروب» and «مدت روشن/خاموش بودن» → sheet with a 5-minute-step slider, quick-value chips and ±5 fine buttons — 720 minutes is one drag instead of 144 taps |
| 7 | Messages must appear at the top of the screen | All toasts replaced by a top overlay banner (`app_toasts.dart`) — slides down from the safe area, auto-dismisses, tap to close; never overlapped by the thumb or the black NFC footer |
| 8 | NFC still does not communicate (log: `01 03` error codes, `Communication error`, `system info unknown`) | **Protocol root causes fixed** (`tag_link.dart`): Read Multiple Blocks was issued with command code `0x2A` — that is **Lock DSFID** in ISO 15693-3 — now `0x23`; Get System Info is tried **standard first** (the PE-flagged variant stayed silent on the field phone/tag combination), and the MEM_SIZE parser now accepts both the ST25 3-byte layout (16-bit block count, LSB first) and the classic ISO layout — the ST25DV16KC answers 512 × 4 B and the `system info unknown` fallback is gone; ISO error texts in the log corrected (01 = not supported, 02 = not recognised) |
| 9 | Product identification URL | `NdefContract.productUrl = https://kianex.co/products/pts50r1` — the factory NDEF URI record (blocks 1..15, well-known type U, prefix code 0x04) is read for identification; any PTS50-family product page on the factory domain (`https://kianex.co/products/pts50…`) is accepted; the app never rewrites the onboarding area |

## What was new in v4.0.1 (CI build fix release)

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
* **Addressing** (DS10925 Rev 9 — corrected in v4.2): the ST25DV does
  NOT use the ISO `Protocol_Extension` flag (reserved on ST25DV — the
  v4.1.0 field log shows every PE-flagged frame rejected with
  `0x02`/`0x03`). Standard commands reach **only blocks 0..255** of a
  16K/64K tag; blocks ≥ 256 require the dedicated **extended command
  family**: Ext Read Single `0x30`, Ext Write Single `0x31`, Ext Read
  Multi `0x33` (2-byte block number LSB first; multi count is 16 bits),
  Ext Get System Info `0x3B`. `0x2A` is Lock DSFID — never use it as a
  read; the Option flag is rejected by some Type 5 models (plain reads
  and writes everywhere). Tags ≤ 256 blocks use the standard set; the
  link probes the extended family once at open time and falls back to
  the standard set + an honest 256-block geometry when a tag rejects it.
* **Geometry discovery**: the standard Get System Info of a
  ST25DV16K/64K carries NO memory size (info flags `0x0B` = DSFID +
  AFI + IC_REF, Table 158) — the size comes from Extended Get System
  Info `0x3B` (16-bit MEM_SIZE, Table 165: `0x03FF` ⇒ 512 × 4 B) or
  from the IC_REF profile (Table 166: `24h` ⇒ ST25DV04K 128×4,
  `26h` ⇒ ST25DV16K/64K ⇒ 512×4 conservative). The factory CC file of
  the KC series (`E2 40 00 01`) does not encode the size either —
  deriving it from the CC byte is a trap.
* **Writes**: plain Write Single Block — NO option flag (the
  write-verify variant is not supported by every Type 5 model and was
  one of the rejected combinations in the field logs); each EEPROM
  block write takes ≈ 5 ms. Retry-once covers the RF/I²C arbitration
  window of SOT §4.1 (busy `0Fh` answers).
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
Node 24 compatible, no deprecation warnings). The v4.0.1 pipeline was
fully reproduced locally with Flutter 3.50.1 / Dart 3.14.0 (analyze
0 issues, all unit tests green) and v4.1.0 ships the same pipeline —
the release APK of this version is produced by the GitHub Actions run
of this repository.

The
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
