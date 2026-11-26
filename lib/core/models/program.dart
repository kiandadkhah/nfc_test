/// Domain models mirroring the shared-memory contract
/// (SOT v3.1-Final + map_bit_2.csv field names).
library;

import '../constants/domain.dart';

/// One timer phase: 5-minute units, 5..720 minutes, zero forbidden. [Q-06]
class TimerPhase {
  TimerPhase({required this.hours, required this.minutes});

  int hours;
  int minutes;

  int get totalMinutes => hours * 60 + minutes;

  /// Minutes-only setter used by the minutes-only stepper UI (step 5,
  /// 5..720). The h/m pair stays the storage format of the device payload.
  set totalMinutes(int value) {
    final clamped = value.clamp(0, DomainLimits.timerPhaseMaxMinutes);
    hours = clamped ~/ 60;
    minutes = clamped % 60;
  }

  bool get isValid {
    final t = totalMinutes;
    return t >= DomainLimits.timerStepMinutes &&
        t <= DomainLimits.timerPhaseMaxMinutes &&
        t % DomainLimits.timerStepMinutes == 0;
  }

  TimerPhase copy() => TimerPhase(hours: hours, minutes: minutes);

  Map<String, dynamic> toJson() => {'h': hours, 'm': minutes};

  factory TimerPhase.fromJson(Map<String, dynamic> j) =>
      TimerPhase(hours: (j['h'] as num?)?.toInt() ?? 0, minutes: (j['m'] as num?)?.toInt() ?? 0);
}

/// Event record — mirrors the 4-byte event block of map_bit_2.csv. [Q-04]
class Event {
  Event({
    required this.type,
    this.hh = 6,
    this.mm = 30,
    this.astro = SolarBase.sunrise,
    this.offsetMinutes = 0,
    this.offsetDirection = OffsetDirection.after,
    this.cmd = RelayCommand.on,
    required this.onPhase,
    required this.offPhase,
    this.start = TimerStart.onPhase,
  });

  EventType type;
  int hh;
  int mm;
  SolarBase astro;
  int offsetMinutes;
  OffsetDirection offsetDirection;
  RelayCommand cmd;
  TimerPhase onPhase;
  TimerPhase offPhase;
  TimerStart start;

  /// Execution minute for fixed events (0..1439) — used for the Q-10 check.
  int? get fixedMinute => type == EventType.fixed ? hh * 60 + mm : null;

  /// Static key for solar events: same base + direction + offset = same minute every day.
  String? get solarKey => type == EventType.astro
      ? '${astro.name}|${offsetDirection.name}|$offsetMinutes'
      : null;

  Event copy() => Event(
        type: type,
        hh: hh,
        mm: mm,
        astro: astro,
        offsetMinutes: offsetMinutes,
        offsetDirection: offsetDirection,
        cmd: cmd,
        onPhase: onPhase.copy(),
        offPhase: offPhase.copy(),
        start: start,
      );

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'hh': hh,
        'mm': mm,
        'astro': astro.name,
        'offset': offsetMinutes,
        'sign': offsetDirection.name,
        'cmd': cmd.name,
        'onPhase': onPhase.toJson(),
        'offPhase': offPhase.toJson(),
        'start': start.name,
      };

  factory Event.fromJson(Map<String, dynamic> j) => Event(
        type: EventType.values.firstWhere(
          (e) => e.name == j['type'],
          orElse: () => EventType.fixed,
        ),
        hh: (j['hh'] as num?)?.toInt() ?? 6,
        mm: (j['mm'] as num?)?.toInt() ?? 30,
        astro: SolarBase.values.firstWhere(
          (e) => e.name == j['astro'],
          orElse: () => SolarBase.sunrise,
        ),
        offsetMinutes: (j['offset'] as num?)?.toInt() ?? 0,
        offsetDirection: OffsetDirection.values.firstWhere(
          (e) => e.name == j['sign'],
          orElse: () => OffsetDirection.after,
        ),
        cmd: RelayCommand.values.firstWhere(
          (e) => e.name == j['cmd'],
          orElse: () => RelayCommand.on,
        ),
        onPhase: TimerPhase.fromJson((j['onPhase'] as Map?)?.cast<String, dynamic>() ?? {}),
        offPhase: TimerPhase.fromJson((j['offPhase'] as Map?)?.cast<String, dynamic>() ?? {}),
        start: TimerStart.values.firstWhere(
          (e) => e.name == j['start'],
          orElse: () => TimerStart.onPhase,
        ),
      );
}

/// Day assignment for a program (which cycle slots point at the chain).
class Assignment {
  Assignment({List<int>? weekly, List<int>? monthly, List<int>? annualDays})
      : weekly = weekly ?? [],
        monthly = monthly ?? [],
        annualDays = annualDays ?? [];

  List<int> weekly;
  List<int> monthly;
  List<int> annualDays;

  Assignment copy() => Assignment(
        weekly: List<int>.from(weekly),
        monthly: List<int>.from(monthly),
        annualDays: List<int>.from(annualDays),
      );

  Map<String, dynamic> toJson() => {'weekly': weekly, 'monthly': monthly, 'annual': annualDays};

  factory Assignment.fromJson(Map<String, dynamic> j) => Assignment(
        weekly: ((j['weekly'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
        monthly: ((j['monthly'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
        annualDays: ((j['annual'] as List?) ?? const []).map((e) => (e as num).toInt()).toList(),
      );
}

/// A timer program as the user builds it in the app.
class Program {
  Program({
    required this.id,
    required this.name,
    required this.cycle,
    required this.events,
    required this.assign,
    this.enabled = true,
  });

  int id;
  String name;
  CycleType cycle;
  List<Event> events;
  Assignment assign;

  /// Master enable/disable of the program. Disabled programs stay in the
  /// list and on the device but are greyed out in the UI (same size). [Q-05]
  bool enabled;

  Program copy() => Program(
        id: id,
        name: name,
        cycle: cycle,
        events: events.map((e) => e.copy()).toList(),
        assign: assign.copy(),
        enabled: enabled,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'cycle': cycle.name,
        'events': events.map((e) => e.toJson()).toList(),
        'assign': assign.toJson(),
        'enabled': enabled,
      };

  factory Program.fromJson(Map<String, dynamic> j) => Program(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        cycle: CycleType.values.firstWhere(
          (e) => e.name == j['cycle'],
          orElse: () => CycleType.daily,
        ),
        events: ((j['events'] as List?) ?? const [])
            .map((e) => Event.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        assign: Assignment.fromJson((j['assign'] as Map?)?.cast<String, dynamic>() ?? {}),
        enabled: (j['enabled'] as bool?) ?? true,
      );
}

/// Snapshot of the logger area (blocks 504–511) as shown on the status dashboard.
class DeviceStatus {
  DeviceStatus({
    required this.runVersion,
    required this.writtenVersion,
    required this.pendingAccept,
    required this.hasOngoing,
    required this.ongoingRelayOn,
    required this.operatingHour,
    required this.outputOnHour,
    required this.relayOps,
    required this.internalError,
    required this.logCrc,
    required this.lastRead,
  });

  /// RUN_Program_Counter — the version the MCU is running. [OI-03]
  final int runVersion;

  /// Program_Counter — the version the app last wrote.
  final int writtenVersion;

  /// True between the app's end code and MCU's three-condition acceptance. [SS-01]
  final bool pendingAccept;
  final bool hasOngoing;
  final bool ongoingRelayOn;
  final int operatingHour;
  final int outputOnHour;
  final int relayOps;

  /// Non-zero means an error is recorded; coding is open item OI-01.
  final int internalError;
  final int logCrc;
  final DateTime lastRead;

  DeviceStatus copyWith({bool? pendingAccept, int? runVersion}) => DeviceStatus(
        runVersion: runVersion ?? this.runVersion,
        writtenVersion: writtenVersion,
        pendingAccept: pendingAccept ?? this.pendingAccept,
        hasOngoing: hasOngoing,
        ongoingRelayOn: ongoingRelayOn,
        operatingHour: operatingHour,
        outputOnHour: outputOnHour,
        relayOps: relayOps,
        internalError: internalError,
        logCrc: logCrc,
        lastRead: lastRead,
      );
}
