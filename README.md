# KIANEX PTS50N1 — Companion Application (v4.4.0)

Flutter companion app for the **KIANEX PTS50N1 / PST50R1** programmable
single-relay timer. The app plans timer programs, validates the command
chain, and transfers the user configuration to the device shared memory
(**ST25DV16KC**, NFC Forum Type 5) through the 8-step safe write protocol
defined in `PST50R1_SourceOfTruth` (SOT v3.1-Final).

> Android only. iOS was removed from the delivery scope («فقط app برای
> اندروید ساخته می‌شود»).

## What is new in v4.4.0 (field-report release: the programs really reach
the tag, ST25DV power register, day-assignment rule)

Based on the v4.3.0 field test (APK from Actions + exported log + the
independent memory analysis `pst50r1-analysis-…json`). The decisive
v4.3.0 evidence: step 4 wrote ONLY blocks 416..429 (the 14-block
settings-only payload, all zeros) and APP_CRC32 came out `0x0993D8D7` —
the CRC of an all-zero planning area — so the cycle tables, event pool
and timer pool were never part of the transfer at all.

| # | Field report | Root cause | Fix in v4.4.0 |
|---|--------------|------------|---------------|
| 1 | «اپ همچنان ناتوان از انتقال برنامه بر روی حافظه تگ است، تمام مقدار حافظه تگ صفر است» (v4.3.0 log: three complete transfers, each writing only blocks 416..429 with zero payloads) | `_buildPlan` diverted EVERY `skipClock=true` run to the settings-only branch — and the relay was unpowered in the whole session, so the user always continued with «ادامه ارسال بدون همگام‌سازی ساعت», which sets `skipClock=true`. Result: cycle tables (blocks 16..107), monthly/weekly/daily tables, event pool (119..373) and timer pool (375..399) were NEVER written. The v4.3 sentinel skipped exactly this path (`&& !skipClock`) | The program mode now builds the **FULL planning image (blocks 16..431) in every case** (`memory_map.dart` + `sot_protocol.dart`). `skipClock` only decides the SET blocks: powered → new clock written; unpowered-continue → the tag's current clock/calendar bytes (blocks 428/429) are **read from the tag and preserved byte-exactly**. The step-7 all-zero sentinel now guards both paths (regression test: «skipClock continue writes the FULL program image») |
| 2 | Chebyshev coefficient blocks also reached the tag as zeros | The old Q14 encoding multiplied MINUTES by 16384 — the mean sunrise value (c0 ≈ 363 min) needs 24 bits and cannot fit the 16-bit storage of map_bit_2.csv; truncation produced garbage/zeros | New scale — **fraction-of-day Q14** (`chebyshev.dart`): stored = round(minutes / 1440 × 16384) as a signed 16-bit word; the firmware reconstructs minutes = stored × 1440 / 16384 (LSB ≈ 5.3 s). Every coefficient now fits comfortably (max ≈ 12 500 of ±32 767). [OI — the scale interpretation must be confirmed with the firmware engineer; changing it touches only `fitChebyshevQ14`] |
| 3 | «برای بررسی تغذیه تگ باید از رجیسترهای st25dv16kc استفاده کنی — یک ثبات در ای‌سی وضعیت تغذیه را اعلام می کند» | The power decision used the logger heuristic (run=0 / logCrc=0) — an indirect «has the MCU ever run» guess, not the live supply state | The protocol reads the **EH_CTRL_Dyn dynamic register** through the ST25DV custom command **«Read Dynamic Register» (B2h, addressed mode, IC mfg code 02h)**: bit FIELD_ON (sanity — the RF field carrying the read must be on), bit **VCC_ON = the tag VCC pin is powered → the relay is alive**. Candidate addresses 0001h (ST25DV-I2C) and 0002h (KC generation layout) are probed and validated via FIELD_ON; when the register is unavailable the logger heuristic stays as the documented fallback. Every raw register value is logged (`step2: power register EH_CTRL_Dyn@0x1=0x…`) |
| 4 | «در چرخه ها هفتگی، ماهانه و سالانه کاربر می تواند بدون اختصاص روز برنامه را ثبت کند. زنجیره رویداد بدون اختصاص روز بی معناست» | The `needsDays` check summed ALL THREE day lists — a stale list of another cycle (cycle switching never cleared them) satisfied the rule, and the payload builder reads only the program's OWN cycle list, so the saved program wrote orphan events no day slot ever pointed at | **Per-cycle day rule (P-06)** (`validators.dart: programNeedsDays`): weekly needs ≥ 1 weekday, monthly ≥ 1 month-day, annual ≥ 1 year-day. Enforced three times: editor popup with «متوجه شدم», `saveDraft` hard guard, and the transfer guard (`program_without_days` failure with its own wording). `setDraftCycle` now clears the stale day lists of the other cycles |
| 5 | ENDA clarification: «ناحیه ها در سند حقیقت ناحیه فرضی است و ربطی به ناحیه بندی حافظه با ریجیستر ENDA ندارد؛ ENDA1/ENDA2/ENDA3 = 0x3F» | — | Documented behaviour: the app treats the truth-document areas purely as LOGICAL block ranges and never touches the hardware sectioning — no ENDA access, no area-boundary writes; the read/write range logic (chunk splitting on area boundaries) already tolerates any factory ENDA configuration |

Verification pipeline unchanged: `flutter gen-l10n` → `flutter analyze` →
`flutter test` → `flutter build apk --release`.

## What is new in v4.3.0 (field-report release: exclusive NFC, write
verification, Iranian map, exact-link identification, program rules)

Based on the v4.2.0 field test (APK installed from Actions, tag memory
dumped independently after the transfer). The decisive evidence: the
**APP_CRC32 stored on the tag was `0x0993D8D7` — mathematically exactly
the CRC of an all-zero payload** (CRC-32/MPEG-2 over 1656 zero bytes),
so the pools were empty because the payload writes never committed, and
the old verification (CRC over read-back vs stored) validated that
failure as success.

| # | Field report | Root cause | Fix in v4.3.0 |
|---|--------------|------------|---------------|
| 1 | «اپ هنوز دسترسی انحصاری به NFC در موقع اجرا را ندارد… اندروید هنوز در پشت زمینه صفحه وب در NDEF را باز می کند» — the browser opened right after the identify step and again after «انتقال انجام شد» | Every `FlutterNfcKit.finish()` released the adapter; the still-present tag was re-dispatched to the system → browser. The v4.2 manifest filter only helps when the system dispatch actually runs | **flutter_nfc_kit removed entirely.** A native layer (`MainActivity.kt`, channel `kianex/nfc`) holds the adapter in **reader mode with `SKIP_NDEF_CHECK` for the whole foreground lifetime** (`onResume` → `onPause`): no NDEF intent is ever produced while the app is running, so no browser can open — between steps, between sessions or after completion. poll/transceive/finish keep the exact previous semantics (raw ISO 15693 frames, response CRC stripped by the link, UID byte order unchanged) |
| 2 | Tag memory after transfer: `Process_Record_Planning=0x3C`, `Program_Counter=1`, `APP_CRC32=0x0993D8D7` = CRC of zeros — weekly/monthly/yearly cycles, event pool, timer pool, Chebyshev coefficients and clock/date ALL zero, although the app showed all 8 steps green and «انتقال انجام شد» | The 416-block write burst of step 4 returned RF success but the EEPROM never committed; step 5 computed APP_CRC32 **over the read-back content** (zeros) and step 7 compared CRC-vs-CRC — the check was tautological, it could never detect a lost write | **Verified writes** (`sot_protocol.dart`): step 4 now writes in 8-block chunks, **reads each chunk back and compares byte-exactly**, rewrites stale blocks up to twice (with 4 ms EEPROM breathing room per block), and fails honestly with `write_verify_failed:<block>` if a block still refuses. Plus a step-7 **sentinel**: a program-mode CRC equal to the all-zero payload CRC (`payload_not_written`) is rejected. `flutter build` cannot mask this anymore — and the log names the first failing block |
| 3 | The identification accepted a tampered link: changing the tag URL to `…/products/pts50r15` still printed «دستگاه شناسایی شد» | The acceptance check was a **prefix match** (`startsWith("https://kianex.co/products/pts50")`), so `pts50r15` matched `pts50r…` | **Exact whitelist** (`NdefContract.productModels`): only `https://kianex.co/products/pts50r1` → PTS50R1 (supported) and `https://kianex.co/products/pts50r15` → PTS50R15 (explicit «model not supported» message) pass identification; ANY other URI fails with «لینک تگ معتبر نیست». Protocol step 1 enforces the same rule (new codes `link_invalid` / `model_unsupported`) |
| 4 | «برای تطابق مدل تگ و شناسه UID و حافظه تگ بررسی شود» | The UID and memory signature were only informational | Identification now checks the **three device signatures**: ① exact whitelisted link → model, ② **UID prefix `E0 02 26`** (ISO 15693 fixed E0 + ST vendor 02 + ST25DV16K/64K IC_REF 26 — matches the real tag `E0 02 26 00 D7 AD 24 AF`), ③ memory geometry ≥ 433 blocks. The identity sheet shows all rows (including «مدل استخراج‌شده از لینک») and the write protocol blocks a UID-signature mismatch (`uid_signature`) |
| 5 | «نقشه لود نمی شود… سرعت لود پایین… مکان نما در مشهد ولی تصویر اصفهان… دریافت موقعیت با GPS مختصات فعلی را نمایش نمی دهند» + «پیشنهاد می شود از سرویس های ایرانی استفاده شود» | ① OSM tiles crawl inside Iran; ② the map camera was built once from `initialCenter` — a fresh GPS fix moved the marker but never the camera, so marker and tiles showed different cities; ③ the picker's «موقعیت فعلی گوشی» button only jumped back to the stale opening point, it never read GPS | **map.ir tiles** (`lib/core/map/map_tiles.dart`, `https://map.ir/shiveh/{z}/{x}/{y}.png` + `x-api-key` header, key via `--dart-define=MAP_IR_API_KEY`, automatic OpenStreetMap fallback when the key is absent or the service is unreachable); the **camera now follows the marker** on every location change (GPS fix or picked point); the picker's GPS button **really fetches the current position** (permission + service checks) and re-centers camera + marker |
| 6 | Logical report: two weekly programs assigned to the same weekdays create two chains for one day slot — «از لحاظ منطقی و معماری حافظه این امکان‌پذیر نیست» | Nothing validated program-level day overlaps (the chain rules R-01..R-04 only looked INSIDE one chain) | **Program rules P-01..P-05** (`validators.dart`): P-01 one daily program max (single daily slot), P-02/P-03/P-04 weekly/monthly/annual programs must not share any day slot, P-05 (advisory) a daily program coexisting with other cycles never runs on their days (C-05 priority). Blocking violations stop the save; the save button stays tappable and opens the formal popup with «متوجه شدم» |
| 7 | «پیغام‌های مربوط به قوائد به‌صورت پاپ‌آپ با دکمه متوجه شدم» + «زیر خط پیغام‌ها را حذف کن» | Rule messages appeared as 2.6-second top toasts; the toast shadow rendered as a hard line under the banner | Chain-rule violations (event editor + chain screen) and program-rule violations (chain + assign screens) open as **scrollable popups with a single «متوجه شدم» button** (`rule_popup.dart`); the toast drop shadow is removed |
| 8 | Screen-off during a long transfer would kill the session | Not handled | The native `setKeepScreenOn` channel keeps the screen awake from «شروع انتقال» until the flow ends |

Verification pipeline unchanged: `flutter gen-l10n` → `flutter analyze` →
`flutter test` → `flutter build apk --release`. The map.ir key is passed
as a repository secret (`MAP_IR_API_KEY`) — builds without it succeed and
render the OSM fallback.

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

# 5. Release APK — with the map.ir key (recommended)
flutter build apk --release \
  --dart-define=MAP_IR_API_KEY=<YOUR_MAP_IR_KEY>
# → build/app/outputs/flutter-apk/app-release.apk
```

### map.ir access key (v4.3)

The Location map renders the Iranian **map.ir** raster tiles
(`https://map.ir/shiveh/{z}/{x}/{y}.png`) which load fast inside Iran.
map.ir authenticates the requests with an `x-api-key` header.

* **GitHub Actions (recommended):** add a repository secret named
  `MAP_IR_API_KEY` (Settings → Secrets and variables → Actions → New
  repository secret) and paste the key from the map.ir dashboard. The
  workflow already passes it to the build with `--dart-define`.
* **No key?** The build still succeeds and the map falls back to the
  key-less OpenStreetMap tiles (and to OSM automatically at runtime when
  map.ir is unreachable or the key expires — the map keys have a limited
  validity and must be renewed in the map.ir dashboard).
* The key is never hard-coded into the repository; it is injected at
  build time.

### GitHub Actions

`.github/workflows/flutter-build.yml` builds the release APK on every
push/PR and uploads it as the artifact `kianex-pts50n1-release-apk`
(checkout@v7, setup-java@v6, flutter-action@v2, upload-artifact@v7 —
Node 24 compatible, no deprecation warnings). The v4.0.1 pipeline was
fully reproduced locally with Flutter 3.50.1 / Dart 3.14.0 (analyze
0 issues, all unit tests green) and v4.1.0 ships the same pipeline —
the release APK of this version is produced by the GitHub Actions run
of this repository.

v4.3 note: **flutter_nfc_kit was removed** — the NFC transport is the
native reader-mode layer in `MainActivity.kt`. The NDK download of the
earlier builds (pulled by the plugin's `jni` layer) is gone: CI builds
are leaner and faster.

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
