/// Domain constants — Source of Truth v3.1-Final (§3.3, §5).
library;

/// Cycle kinds supported by the device (priority order: annual > monthly > weekly > daily, C-05).
enum CycleType { daily, weekly, monthly, annual }

enum EventType { fixed, astro }

enum SolarBase { sunrise, sunset }

enum OffsetDirection { after, before }

enum RelayCommand { on, off, timer }

enum TimerStart { onPhase, offPhase }

/// Hard limits from the Source of Truth — UI must never accept values outside these.
abstract final class DomainLimits {
  /// Shared event pool (blocks 119–373). [Q-03]
  static const int maxEvents = 255;

  /// Shared timer pool (blocks 375–399).
  static const int maxTimers = 50;

  /// One timer unit equals 5 minutes. [Q-06]
  static const int timerStepMinutes = 5;

  /// Maximum phase duration = 144 × 5 = 720 minutes (12 h); zero is forbidden.
  static const int timerPhaseMaxMinutes = 720;

  /// Solar offset magnitude 0–60 minutes (0 = exactly at base time). [Q-06]
  static const int astroOffsetMaxMinutes = 60;

  /// R-02: two consecutive commands must be at least 5 minutes apart.
  static const int minGapMinutes = 5;

  /// Phase byte of the device timer pool: total minutes divided by 5.
  static const int timerPhaseMaxUnits = 144;

  /// Fixed-event time range in minutes from midnight. [Q-06]
  static const int dayMaxMinute = 1439;

  /// Program name maximum length (UI contract).
  static const int programNameMaxLength = 40;

  /// Weekly cycle days, Saturday first (device product rule).
  static const int weeklyDays = 7;

  /// Monthly cycle days.
  static const int monthlyDays = 31;

  /// Annual cycle slots (Persian calendar, leap year included).
  static const int annualSlots = 366;

  /// Persian month lengths (Esfand 29; leap handled by firmware).
  static const List<int> monthLengths = [31, 31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 29];

  /// CRC-32/MPEG-2 test vectors from SOT table 4-8. [TV-01..TV-03]
  static const List<int> crcTestVectorValues = [0x0376E6E7, 0xA97AFF4D, 0x6B6DC92A];
}

/// Factory NDEF contract of the onboarding area (A1, blocks 1–15).
/// The tag carries a single well-known URI record pointing at the product
/// page; the app reads it for identification and never rewrites it.
/// [SOT §3.2 ناحیه آنبوردینگ, OI-05 — factory URL confirmed by KIANEX]
abstract final class NdefContract {
  /// Exact product URL of the supported model (PTS50R1) — confirmed on the
  /// real tag (v4.1.0 field report).
  static const String productUrl = 'https://kianex.co/products/pts50r1';

  /// The model this app build programs (the PTS50 family shares the
  /// hardware layout; the PTS50R15 is a different product of the family).
  static const String supportedModel = 'PTS50R1';

  /// EXACT whitelist of the factory product URLs — the model is decoded
  /// from the NDEF link itself. v4.3 rule from the field report: the link
  /// must be matched EXACTLY, never by prefix (a tag carrying
  /// …/pts50r15 is a PTS50R15 and must NOT be reported as an identified
  /// PTS50R1 device). Only URLs listed here can ever pass identification;
  /// every other value fails with «لینک شناسایی نشد».
  static const Map<String, String> productModels = {
    productUrl: 'PTS50R1',
    'https://kianex.co/products/pts50r15': 'PTS50R15',
  };

  /// Model decoded from the decoded NDEF URI — null when the URI is not a
  /// whitelisted KIANEX product link (unknown / tampered tag).
  static String? modelOfUri(String uri) {
    final u = uri.trim().toLowerCase();
    for (final entry in productModels.entries) {
      if (u == entry.key) return entry.value;
    }
    return null;
  }

  /// True when the decoded URI identifies THIS app's supported model.
  static bool uriMatchesProduct(String uri) =>
      modelOfUri(uri) == supportedModel;

  /// UID signature of the ST25DV16KC (human-readable order, MSB first):
  /// E0 = fixed ISO 15693 manufacturer nibble, 02 = ST vendor code,
  /// 26 = IC_REF of the ST25DV16K/64K family. v4.3 device check:
  /// «برای تطابق مدل تگ و شناسه UID و حافظه تگ بررسی شود».
  static const List<int> st25dv16kUidSignature = [0xE0, 0x02, 0x26];

  /// True when a human-order UID hex string carries the ST25DV16KC
  /// signature (also accepts the LSB-first wire order defensively).
  static bool uidHasSt25dv16kSignature(String uidHex) {
    final hex = uidHex.replaceAll(':', '').toUpperCase();
    if (hex.length < 6 || !RegExp(r'^[0-9A-F]+$').hasMatch(hex)) return false;
    final bytes = [
      for (var i = 0; i + 1 < hex.length; i += 2)
        int.tryParse(hex.substring(i, i + 2), radix: 16) ?? 0,
    ];
    final normal = (bytes[0] == 0xE0 && bytes[1] == 0x02 && bytes[2] == 0x26);
    // LSB-first wire order — E0/02/26 sit at the END of the byte list.
    final wireOrder = (bytes[bytes.length - 1] == 0xE0 &&
        bytes[bytes.length - 2] == 0x02 &&
        bytes[bytes.length - 3] == 0x26);
    return normal || wireOrder;
  }
}
