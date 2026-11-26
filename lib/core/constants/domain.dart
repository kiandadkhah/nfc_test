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
