/// Shared-memory layout of the ST25DV16KC tag (512 × 4-byte blocks),
/// faithful to map_memory_2.csv and Source of Truth v3.1-Final §3.2/§4.
/// Also contains the payload encoder used by the real NFC transport and
/// the unit tests (FakeTagLink golden path).
library;

import 'dart:typed_data';

import '../constants/domain.dart';
import '../crypto/crc32_stm32.dart';
import '../models/program.dart';
import '../validation/validators.dart';

/// Block addresses and register positions (Byte_0 is the first byte).
abstract final class SotMemoryMap {
  static const int blockSize = 4;
  static const int totalBlocks = 512; // 2048 bytes

  // A1 — onboarding area (factory-written, never rewritten by the app).
  static const int blockCc = 0;
  static const int onboardingStartBlock = 0;
  static const int onboardingEndBlock = 15;

  // A2 — planning area (app writes / MCU reads).
  static const int planningStartBlock = 16;
  static const int planningEndBlock = 431;
  static const int blockAnnualStart = 16; // 366 day slots × 1 B (0 = no chain)
  static const int annualDays = 366;
  static const int blockMonthlyStart = 108; // 31 day slots × 1 B
  static const int monthlyDays = 31;
  static const int blockWeeklyStart = 116; // 7 day slots × 1 B (Sat first)
  static const int weeklyDays = 7;
  static const int blockDailyCycl = 118; // 1 day slot
  static const int blockEventsStart = 119; // 255 events × 4 B
  static const int blockEventsEnd = 373;
  static const int blockTimersStart = 375; // 50 timers: ON/OFF unit bytes
  static const int blockTimersEnd = 399;
  static const int blockChebyshevSrStart = 416; // 12 × 16-bit Q14
  static const int blockChebyshevSsStart = 422;
  static const int blockSet = 428; // sec/min/hour/week
  static const int blockSetDate = 429; // day/month/year/RES
  static const int blockPlanningRegister = 430; // Process_Record_Planning +
  // Program_Counter (LE, Byte_2..3)
  static const int blockAppCrc32 = 431;

  // A3 — logger area (MCU writes / app reads).
  static const int loggerStartBlock = 504;
  static const int loggerEndBlock = 511;
  static const int blockOperatingHour = 504;
  static const int blockOperatingHourOn = 505;
  static const int blockOperatingHourCn = 506;
  static const int blockOngoingEvent = 507;
  static const int blockInternalError = 508;
  static const int blockRunProgramCounter = 509;
  static const int blockProcessRecordLog = 510;
  static const int blockLogCrc32 = 511;
}

/// The six legal values of Process_Record_Planning / Process_Record_LOG.
/// Any other value means a failed write process. [§4.4]
abstract final class ProcessCodes {
  static const int settingsStart = 0xA5;
  static const int settingsCompleteWrite = 0xB4;
  static const int settingsEnd = 0xC3;
  static const int programStart = 0x5A;
  static const int programCompleteWrite = 0x4B;
  static const int programEnd = 0x3C;
}

/// ---------------------------------------------------------------
/// Shared-memory image — the byte-exact model of blocks 16..431.
/// Used to build the write payload and to decode the read-back step.
/// ---------------------------------------------------------------
class PlanningImage {
  PlanningImage() : _bytes = Uint8List(_imageSize);

  /// Blocks 16..431 → 416 blocks × 4 bytes.
  static const int _imageSize =
      (SotMemoryMap.planningEndBlock - SotMemoryMap.planningStartBlock + 1) *
          SotMemoryMap.blockSize;

  final Uint8List _bytes;

  int _blockOffset(int block) =>
      (block - SotMemoryMap.planningStartBlock) * SotMemoryMap.blockSize;

  void setByte(int block, int byteIndex, int value) {
    _bytes[_blockOffset(block) + byteIndex] = value & 0xFF;
  }

  int getByte(int block, int byteIndex) => _bytes[_blockOffset(block) + byteIndex];

  void setBlock(int block, List<int> b0to3) {
    for (var i = 0; i < 4; i++) {
      setByte(block, i, b0to3.length > i ? b0to3[i] : 0);
    }
  }

  Uint8List get bytes => Uint8List.fromList(_bytes);

  /// CRC-32/MPEG-2 over blocks 16..429 (the APP_CRC32 domain, §4.11).
  int get appCrc32 {
    const domainEnd =
        (SotMemoryMap.blockSetDate - SotMemoryMap.planningStartBlock + 1) *
            SotMemoryMap.blockSize;
    final crcDomain = Uint8List.sublistView(_bytes, 0, domainEnd);
    return crc32Stm32(crcDomain);
  }

  /// Writes one annual day pointer. [dayOfYear] is 1-based (device
  /// contract: block 16 Byte_0 = day 1 of the year; 366 = Esfand 30 of a
  /// leap year); value 0 = no program, 1..255 = event number.
  void setAnnualDay(int dayOfYear, int value) {
    final n = dayOfYear - 1;
    final idx = n % 4;
    final block = SotMemoryMap.blockAnnualStart + n ~/ 4;
    setByte(block, idx, value);
  }

  /// Weekly/monthly day pointers use the same 4-per-block packing.
  void setWeeklyDay(int day, int value) =>
      setByte(SotMemoryMap.blockWeeklyStart + day ~/ 4, day % 4, value);

  void setMonthlyDay(int day, int value) =>
      setByte(SotMemoryMap.blockMonthlyStart + day ~/ 4, day % 4, value);

  void setDailyHead(int value) => setByte(SotMemoryMap.blockDailyCycl, 0, value);

  /// Encodes one event record (4 bytes) per map_bit_2.csv:
  /// B0 = EVENT_TIME_L, B1 = [EVENT_TIME_H ×3 | CMD | ASTRO | TYPE | SIGN |
  /// TIMER_PHASE], B2 = EVENT_CHAIN (next event, 0 = end), B3 = TIMER_ADDRESS.
  void setEvent(int eventNo, Event ev, int? nextEventNo, int? timerAddress) {
    final block = SotMemoryMap.blockEventsStart + eventNo - 1;
    final time = ev.type == EventType.fixed ? ev.fixedMinute! : ev.offsetMinutes;
    final b1 = ((time >> 8) & 0x07) |
        (ev.cmd == RelayCommand.on ? 0x08 : 0x00) |
        (ev.type == EventType.astro ? 0x10 : 0x00) |
        (ev.type == EventType.astro && ev.astro == SolarBase.sunrise ? 0x20 : 0x00) |
        (ev.type == EventType.astro && ev.offsetDirection == OffsetDirection.before ? 0x40 : 0x00) |
        (ev.cmd == RelayCommand.timer && ev.start == TimerStart.onPhase ? 0x80 : 0x00);
    setBlock(block, [
      time & 0xFF,
      b1,
      nextEventNo ?? 0,
      timerAddress ?? 0,
    ]);
  }

  /// Encodes the timer pool: each block holds two timers
  /// (B0 = ON_0, B1 = OFF_0, B2 = ON_1, B3 = OFF_1), each byte = minutes/5.
  void setTimer(int timerNo, Event ev) {
    final block = SotMemoryMap.blockTimersStart + (timerNo - 1) ~/ 2;
    final slot = (timerNo - 1) % 2 * 2;
    setByte(block, slot, ev.onPhase.totalMinutes ~/ DomainLimits.timerStepMinutes);
    setByte(block, slot + 1, ev.offPhase.totalMinutes ~/ DomainLimits.timerStepMinutes);
  }

  /// SET blocks 428/429 — clock, Persian calendar and RTC weekday.
  void setClock(DateTime now, {required int jalaliYear2, required int jalaliMonth, required int jalaliDay}) {
    setBlock(SotMemoryMap.blockSet, [
      now.second,
      now.minute,
      now.hour,
      now.weekday % 7, // device week encoding — Saturday-based index
    ]);
    setBlock(SotMemoryMap.blockSetDate, [
      jalaliDay,
      jalaliMonth,
      jalaliYear2,
      0x00, // RES must stay zero (Q-01)
    ]);
  }

  /// Chebyshev coefficients: 12 × 16-bit Q14 for sunrise (SR) and sunset (SS).
  void setSolarCoefficients({required List<int> sunriseQ14, required List<int> sunsetQ14}) {
    for (var i = 0; i < 12; i++) {
      final v = sunriseQ14[i];
      setByte(SotMemoryMap.blockChebyshevSrStart + i ~/ 2, (i % 2) * 2, v & 0xFF);
      setByte(SotMemoryMap.blockChebyshevSrStart + i ~/ 2, (i % 2) * 2 + 1, (v >> 8) & 0xFF);
      final w = sunsetQ14[i];
      setByte(SotMemoryMap.blockChebyshevSsStart + i ~/ 2, (i % 2) * 2, w & 0xFF);
      setByte(SotMemoryMap.blockChebyshevSsStart + i ~/ 2, (i % 2) * 2 + 1, (w >> 8) & 0xFF);
    }
  }

  /// Block 430/431 — Process_Record_Planning, Program_Counter, APP_CRC32.
  void setPlanningRegister(int code, int programCounter) {
    setBlock(SotMemoryMap.blockPlanningRegister, [
      code,
      0x00, // RES
      programCounter & 0xFF,
      (programCounter >> 8) & 0xFF,
    ]);
  }

  void setAppCrc32(int crc) {
    setBlock(SotMemoryMap.blockAppCrc32, [
      crc & 0xFF,
      (crc >> 8) & 0xFF,
      (crc >> 16) & 0xFF,
      (crc >> 24) & 0xFF,
    ]);
  }
}

/// Builds the ordered write plan for one write mode: the list of
/// (block, bytes) operations, honoring §4.5 step 4 (RES bytes = 0x00).
class WritePlan {
  WritePlan(this.blocks);

  /// Target blocks in mandatory order (low → high).
  final List<int> blocks;
  final Map<int, Uint8List> _data = {};

  void put(int block, Uint8List b0to3) => _data[block] = b0to3;
  Uint8List? dataOf(int block) => _data[block];
  Iterable<int> get targetBlocks => blocks;
}

/// Builds the full-program payload (blocks 16..431) from the enabled programs.
/// Only enabled programs are encoded — disabled programs are never sent.
///
/// v4.4 — [writeClock] = false (the unpowered-continue path) keeps the SET
/// blocks 428/429 out of the clock update: when [preservedSetBytes] carries
/// the 8 bytes currently stored on the tag they are written back unchanged,
/// otherwise the SET blocks stay zero. The program areas (cycle tables,
/// event pool, timer pool, coefficients) are ALWAYS part of the payload —
/// the v4.3.0 field bug (skipClock silently downgraded the transfer to the
/// 14-block settings-only plan, leaving every program value at zero) is
/// closed by construction.
WritePlan buildProgramWritePlan({
  required List<Program> enabledPrograms,
  required DateTime deviceTime,
  required JalaliClock jalali,
  required List<int> sunriseQ14,
  required List<int> sunsetQ14,
  required int newProgramCounter,
  bool writeClock = true,
  List<int>? preservedSetBytes,
}) {
  final img = PlanningImage();
  var eventNo = 0;
  var timerNo = 0;
  final timerAddressOf = <String, int>{};

  int ensureTimer(Event ev) {
    final key = '${ev.onPhase.totalMinutes}|${ev.offPhase.totalMinutes}|${ev.start.name}';
    return timerAddressOf.putIfAbsent(key, () {
      timerNo += 1;
      img.setTimer(timerNo, ev);
      return timerNo;
    });
  }

  for (final p in enabledPrograms) {
    // Encode the chain; remember the head event number of this program.
    // The chain order is the sorted order (sunrise group → fixed times →
    // sunset group) — the same order the UI displays, so the device
    // executes exactly what the user sees. [v4.1 chain sorting]
    final head = eventNo + 1;
    final sortedEvents = sortChain(p.events);
    for (var i = 0; i < sortedEvents.length; i++) {
      final ev = sortedEvents[i];
      eventNo += 1;
      final next = i + 1 < sortedEvents.length ? eventNo + 1 : null;
      final timerAddr = ev.cmd == RelayCommand.timer ? ensureTimer(ev) : null;
      img.setEvent(eventNo, ev, next, timerAddr);
    }
    switch (p.cycle) {
      case CycleType.daily:
        img.setDailyHead(head);
      case CycleType.weekly:
        for (final d in p.assign.weekly) {
          img.setWeeklyDay(d, head);
        }
      case CycleType.monthly:
        for (final d in p.assign.monthly) {
          img.setMonthlyDay(d, head);
        }
      case CycleType.annual:
        for (final d in p.assign.annualDays) {
          img.setAnnualDay(d, head);
        }
    }
  }

  img.setSolarCoefficients(sunriseQ14: sunriseQ14, sunsetQ14: sunsetQ14);
  if (preservedSetBytes != null && preservedSetBytes.length == 8) {
    // Keep the device clock/calendar exactly as it currently is on the tag.
    img.setBlock(SotMemoryMap.blockSet, preservedSetBytes.sublist(0, 4));
    img.setBlock(SotMemoryMap.blockSetDate, preservedSetBytes.sublist(4, 8));
  } else if (writeClock) {
    img.setClock(deviceTime,
        jalaliYear2: jalali.year2, jalaliMonth: jalali.month, jalaliDay: jalali.day);
  }
  img.setPlanningRegister(ProcessCodes.programStart, newProgramCounter);
  img.setAppCrc32(img.appCrc32);

  final plan = WritePlan(
      List<int>.generate(416, (i) => SotMemoryMap.planningStartBlock + i));
  final raw = img.bytes;
  for (var i = 0; i < 416; i++) {
    plan.put(SotMemoryMap.planningStartBlock + i,
        Uint8List.sublistView(raw, i * 4, i * 4 + 4));
  }
  return plan;
}

/// Jalali clock fields written to the SET blocks (two-digit year is the
/// device contract: «SET_YEAR دو رقم کم‌ارزش سال»).
class JalaliClock {
  const JalaliClock({required this.year2, required this.month, required this.day});
  final int year2;
  final int month;
  final int day;
}

/// Decoded logger snapshot (blocks 504..511) — the same fields the UI shows.
class LoggerSnapshot {
  const LoggerSnapshot({
    required this.operatingHour,
    required this.operatingHourOn,
    required this.operatingHourCn,
    required this.ongoingEvent,
    required this.internalError,
    required this.runProgramCounter,
    required this.processRecordLog,
    required this.logCrc32,
  });

  final int operatingHour;
  final int operatingHourOn;
  final int operatingHourCn;
  final int ongoingEvent;
  final int internalError;
  final int runProgramCounter;
  final int processRecordLog;
  final int logCrc32;

  static int _le32(Uint8List b, int base) =>
      b[base] | (b[base + 1] << 8) | (b[base + 2] << 16) | (b[base + 3] << 24);

  /// [blocks] = 8 decoded blocks (504..511), each 4 bytes Byte_0..Byte_3.
  factory LoggerSnapshot.fromBlocks(List<Uint8List> blocks) {
    Uint8List flat(int from, int count) {
      final out = <int>[];
      for (var i = from; i < from + count; i++) {
        out.addAll(blocks[i]);
      }
      return Uint8List.fromList(out);
    }

    final counters = flat(0, 3);
    final run = blocks[5];
    return LoggerSnapshot(
      operatingHour: _le32(counters, 0),
      operatingHourOn: _le32(counters, 4),
      operatingHourCn: _le32(counters, 8),
      ongoingEvent: _le32(Uint8List.fromList(blocks[3]), 0),
      internalError: _le32(Uint8List.fromList(blocks[4]), 0),
      runProgramCounter: run[0] | (run[1] << 8),
      processRecordLog: blocks[6][0],
      logCrc32: _le32(Uint8List.fromList(blocks[7]), 0),
    );
  }
}

