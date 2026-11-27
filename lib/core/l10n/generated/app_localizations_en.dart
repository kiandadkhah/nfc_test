// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'KIANEX PTS50N1';

  @override
  String get brandSlogan => 'Innovation that lasts';

  @override
  String get deviceTitle => 'Calendar-based relay timer';

  @override
  String get deviceSub =>
      'Single 50 A relay · NFC connectivity · daily, weekly, monthly and annual cycles';

  @override
  String get deviceEngName =>
      'Engineering name in the Source of Truth: PST50R1';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get obKicker1 => 'Welcome';

  @override
  String get obTitle1 => 'KIANEX PTS50N1';

  @override
  String get obText1 =>
      'The companion app for your calendar-based relay timer. Build timer programs on the phone and send them to the device over NFC; the device runs independently of the phone.';

  @override
  String get obKicker2 => 'Device link';

  @override
  String get obTitle2 => 'Connect over NFC';

  @override
  String get obText2 =>
      'The device NFC tag is on its body. Touch the back of your phone to it and keep it steady until the transfer finishes.';

  @override
  String get obPoint1 =>
      'A phone without the app still reads the tag and opens the product page (NDEF)';

  @override
  String get obPoint2 => 'Writes run through a safe 8-step protocol';

  @override
  String get obPoint3 =>
      'If a write is interrupted, the device keeps running its last valid program';

  @override
  String get obKicker3 => 'Start';

  @override
  String get obTitle3 => 'Create your first program';

  @override
  String get obText3 =>
      'Pick a cycle, arrange the events in a chain and set the execution days. Whenever you are ready, send it to the device with the hexagonal NFC button.';

  @override
  String get timerPrograms => 'Timer programs';

  @override
  String countPrograms(String n) {
    return '$n programs';
  }

  @override
  String get countEmpty => 'Empty';

  @override
  String get emptyTitle => 'No program defined yet';

  @override
  String get emptyText =>
      'To get started, read the device status or create your first schedule.\nA program includes a cycle, an event chain and execution days.';

  @override
  String get emptyCta => 'Create a new program';

  @override
  String get seedSample => 'Load sample programs';

  @override
  String get newProgram => 'New Program';

  @override
  String get changeModel => 'Change model';

  @override
  String eventsInChain(String n) {
    return '$n events in chain';
  }

  @override
  String get allDays => 'Every day';

  @override
  String get noAssign => 'No days assigned';

  @override
  String weekDaysOf(String n) {
    return '$n days of week';
  }

  @override
  String monthDaysOf(String n) {
    return '$n days of month';
  }

  @override
  String yearDaysOf(String n) {
    return '$n days of year';
  }

  @override
  String onDeviceRunning(String v) {
    return 'On device: running version $v';
  }

  @override
  String get menuEdit => 'Edit programs';

  @override
  String get menuStatus => 'Device status';

  @override
  String get menuStatusSub =>
      'Logger read: operating hours, ongoing event, internal error';

  @override
  String get menuGps => 'Location settings (GPS)';

  @override
  String get menuGpsSub => 'Basis for sunrise/sunset calculation';

  @override
  String get menuSettings => 'Settings';

  @override
  String get menuSettingsSub => 'Language and theme';

  @override
  String get menuHelp => 'Help';

  @override
  String get menuAbout => 'About / App version';

  @override
  String get editProgram => 'Edit program';

  @override
  String get deleteProgram => 'Delete program';

  @override
  String capacityEvents(String e) {
    return 'Events $e of 255';
  }

  @override
  String capacityTimers(String t) {
    return 'Timers $t of 50';
  }

  @override
  String get nfcSheetTitle => 'Connect to PTS50N1';

  @override
  String get nfcSheetSub =>
      'Choose one of the actions below. Then hold the back of the phone near the NFC tag on the relay and keep it steady until the operation finishes.';

  @override
  String get readStatusT => 'Read device status';

  @override
  String get readStatusD =>
      'Logger read: running program version, ongoing event, operating counters and internal error';

  @override
  String get settingsOnlyT => 'Set time & location';

  @override
  String get settingsOnlyD =>
      'Set the relay clock and record the location used to compute sunrise and sunset';

  @override
  String get programWriteT => 'Write programs to the device';

  @override
  String get programWriteD =>
      'Send the enabled scheduled programs and settings to the relay memory; disabled programs are not sent';

  @override
  String get noProgramsToast =>
      'You have no programs to send yet. Create a scheduled program first, or choose the “Settings only” option.';

  @override
  String get wcTitleSet => 'Confirm transfer — settings only';

  @override
  String get wcTitleProg => 'Confirm transfer — programs and settings';

  @override
  String get wcSub =>
      'Review what will be written before starting; keep the phone close to the device and steady during the whole transfer.';

  @override
  String get wcTime => 'Clock & calendar sync';

  @override
  String get wcTimeD =>
      'Phone time and Persian date will be written to the device';

  @override
  String get wcAstro => 'Sunrise & sunset calculation';

  @override
  String get wcAstroD =>
      'Based on the current location — sunrise and sunset times are calculated automatically';

  @override
  String get wcPrograms => 'Timer programs';

  @override
  String wcProgramsD(String n, String e, String t) {
    return '$n programs with $e events and $t timers';
  }

  @override
  String get wcVersion => 'New program version';

  @override
  String wcVersionD(String v) {
    return 'After a successful write, this version is applied on the device';
  }

  @override
  String get wcCapacity => 'Device memory capacity';

  @override
  String wcCapacityD(String e, String t) {
    return 'Events $e of 255 · Timers $t of 50';
  }

  @override
  String get wcScenario => 'Transfer test scenarios — design-review tool';

  @override
  String get scOk => 'Successful transfer';

  @override
  String get scBusy => 'Device busy';

  @override
  String get scRf => 'Connection cut mid-transfer';

  @override
  String get scCrc => 'Verification mismatch';

  @override
  String get scModel => 'Device model mismatch';

  @override
  String get wcStart => 'Start transfer';

  @override
  String get keepSteady =>
      'Keep the phone steady and do not move it away from the device until the transfer finishes';

  @override
  String get wpTitle => 'Transferring data to the device';

  @override
  String attemptOf(String n) {
    return 'Attempt $n of 2';
  }

  @override
  String get wpPolling => 'Waiting for the device to become ready…';

  @override
  String get wpCancel => 'Cancel';

  @override
  String get wpDoneTitle => 'Transfer complete';

  @override
  String wpDoneSub(String v) {
    return 'Version $v was written to the device and verified successfully; the device is applying the new program.';
  }

  @override
  String get wpDoneGo => 'View device status';

  @override
  String get wpFailTitle => 'Transfer left unfinished';

  @override
  String wpFailStep(String step) {
    return 'The transfer stopped at the “$step” stage.';
  }

  @override
  String get wpFailBusy =>
      'The device did not become free after a few seconds; try again shortly.';

  @override
  String get wpRetryHint =>
      'Per the Source of Truth, the protocol restarts from step 1.';

  @override
  String get wpRetryFromStep1 => 'Try again';

  @override
  String get wpPowerOff => 'Power-cycle guidance';

  @override
  String get step1 => 'Prepare and identify the device';

  @override
  String get step1d => 'Matching the device model with the app';

  @override
  String get step2 => 'Check device status';

  @override
  String get step2d => 'Health and readiness check for receiving data';

  @override
  String get step3 => 'Start the transfer';

  @override
  String get step3d => 'Opening a secure transfer path';

  @override
  String get step4 => 'Write programs and settings';

  @override
  String get step4d => 'Transferring data to the device memory';

  @override
  String get step5 => 'Finish writing';

  @override
  String get step5d => 'Ending the data transfer stage';

  @override
  String get step6 => 'Read back the data';

  @override
  String get step6d => 'Re-reading to make sure the transfer is correct';

  @override
  String get step7 => 'Verify the data';

  @override
  String get step7d => 'Comparing the written data with the original version';

  @override
  String get step8 => 'Activate the new version';

  @override
  String get step8d => 'The device runs the new program';

  @override
  String get rcTitle => 'Connection failed';

  @override
  String get rcSub =>
      'Two complete attempts failed — per RC-10 of the Source of Truth';

  @override
  String get rcMsgTitle => 'User message (proposed OI-02 text)';

  @override
  String get rcMsg =>
      'Could not reach the device. Please power the device off and on once, then retry the transfer. If it still fails, do the programming while the device is powered off.';

  @override
  String get rcS1 => 'Power the device off';

  @override
  String get rcS1d =>
      'Open the fuse or breaker feeding the device and wait a few seconds.';

  @override
  String get rcS2 => 'Power it back on and retry';

  @override
  String get rcS2d =>
      'The device resets and frees the tag; then tap the NFC button.';

  @override
  String get rcS3 => 'Or program while powered off';

  @override
  String get rcS3d =>
      'With the device powered off, the transfer is more stable.';

  @override
  String get rcRetry => 'Retry';

  @override
  String get rcBack => 'Back';

  @override
  String get stTitle => 'Device status';

  @override
  String get stSub => 'Up-to-date device status after the last read';

  @override
  String get stVersionCard => 'Program version';

  @override
  String get stOnDevice => 'On device';

  @override
  String get stLastWritten => 'Last written';

  @override
  String get stSynced => 'In sync — this version is running';

  @override
  String get stPending => 'Waiting for device confirmation';

  @override
  String get stOutdated => 'No new program on device — send one';

  @override
  String get stOngoing => 'Ongoing event';

  @override
  String get stOngoingNone => 'No event is running right now';

  @override
  String get stRelayOn => 'Relay: ON';

  @override
  String get stRelayOff => 'Relay: OFF';

  @override
  String get stCounters => 'Operating counters';

  @override
  String get stHour => 'Total operating hours';

  @override
  String get stHourOn => 'Output-on hours';

  @override
  String get stCn => 'Relay operations';

  @override
  String get stErrCard => 'Internal error';

  @override
  String get stErrNone => 'No error recorded';

  @override
  String get stErrCode => 'Non-zero code recorded — coding is open item OI-01';

  @override
  String get stErrHint =>
      'If you see this error, inspect the device or contact support.';

  @override
  String get stTech => 'Device technical details';

  @override
  String get stLastRead => 'Last read';

  @override
  String get stReadSeq =>
      'The data was read from the device and verified successfully.';

  @override
  String get stRefresh => 'Read again';

  @override
  String get gpsTitle => 'Location settings (GPS)';

  @override
  String get gpsSub => 'Location used as the basis for solar events';

  @override
  String get gpsCoords => 'Current coordinates';

  @override
  String get gpsLat => 'Latitude';

  @override
  String get gpsLng => 'Longitude';

  @override
  String get gpsUpdated => 'Last update';

  @override
  String get gpsRefresh => 'Update location';

  @override
  String get gpsUpdatedToast => 'Location saved.';

  @override
  String get gpsUse =>
      'This location is the reference for the device\'s sunrise and sunset calculation. It is stored only on your phone and on the device — it is never shared with any other service.';

  @override
  String get gpsAccuracy => 'Accuracy ±15 m';

  @override
  String get gpsPin => 'Current location';

  @override
  String get nameDialogTitle => 'New program';

  @override
  String get nameDialogQ => 'Pick a name to identify the program.';

  @override
  String get nameLabel => 'Program name';

  @override
  String get nameHint => 'e.g. Courtyard lighting';

  @override
  String get nameErr => 'Enter a program name';

  @override
  String get cancelled => 'Program creation cancelled';

  @override
  String get cycleTitle => 'Choose the cycle';

  @override
  String cycleSub(String name) {
    return 'Program “$name” — step 2 of 3';
  }

  @override
  String get cycleNext => 'Next — build the event chain';

  @override
  String get daily => 'Daily';

  @override
  String get dailyD =>
      'The same chain runs on every day — ideal for fixed daily routines.';

  @override
  String get weekly => 'Weekly';

  @override
  String get weeklyD =>
      'Assign a chain to each day of the week (Sat–Fri); 7 slots.';

  @override
  String get monthly => 'Monthly';

  @override
  String get monthlyD => 'Assign chains to days of month (1–31); 31 slots.';

  @override
  String get annual => 'Annual';

  @override
  String get annualD =>
      'The full Persian calendar year with 366 slots; the most precise seasonal planning.';

  @override
  String get poolNote =>
      'Note: events of all programs are stored in the shared device memory; repeated events across days are shared automatically.';

  @override
  String get priorityNote =>
      'Daily execution priority: annual ← monthly ← weekly ← daily. If a day appears in several cycles, only the higher-priority cycle runs.';

  @override
  String get chainTitle => 'Event chain';

  @override
  String chainSub(String name, String cycle) {
    return '“$name” — $cycle cycle — step 3 of 3';
  }

  @override
  String get chainEmptyTitle => 'No events yet';

  @override
  String get chainEmptyText =>
      'Add the first event of the chain — e.g. relay ON at a fixed time or after sunrise.';

  @override
  String get chainEmptyCta => 'Create an event chain';

  @override
  String get addEvent => 'Add event';

  @override
  String get assignWeekly => 'Assign to weekdays';

  @override
  String get assignMonthly => 'Assign to days of month';

  @override
  String get assignAnnual => 'Assign to days of year';

  @override
  String get dailyAutoNote =>
      'Daily cycle: the chain is assigned to every day automatically; no day picking is needed.';

  @override
  String get currentAssignment => 'Current assignment:';

  @override
  String get saveProgram => 'Save program';

  @override
  String get needEvent => 'Add at least one event to the chain first';

  @override
  String get capacityBlock => 'The device event memory is full (255 events).';

  @override
  String programSaved(String name) {
    return 'Program “$name” saved';
  }

  @override
  String programDeleted(String name) {
    return 'Program “$name” deleted';
  }

  @override
  String get delTitle => 'Delete program';

  @override
  String delText(String name) {
    return 'Program “$name” and all of its commands will be removed from this phone’s list. To apply the change on the relay, run the NFC transfer afterwards.';
  }

  @override
  String get evNew => 'New event';

  @override
  String get evEdit => 'Edit event';

  @override
  String get evSub => 'Define the event type, output command and settings';

  @override
  String get evType => 'Run-time basis';

  @override
  String get evFixed => 'Fixed clock time';

  @override
  String get evAstro => 'Based on sunrise or sunset';

  @override
  String get evTimeFmt => 'The run time is set in 24-hour format.';

  @override
  String get hourRange => 'Hour (0–23)';

  @override
  String get minuteRange => 'Minute (0–59)';

  @override
  String get sunrise => 'Sunrise';

  @override
  String get sunriseD => 'Event time is computed from sunrise';

  @override
  String get sunset => 'Sunset';

  @override
  String get sunsetD => 'Event time is computed from sunset';

  @override
  String get offsetLabel => 'Offset (0–60 min)';

  @override
  String get signLabel => 'Offset direction relative to base time';

  @override
  String afterBase(String base) {
    return 'After $base';
  }

  @override
  String beforeBase(String base) {
    return 'Before $base';
  }

  @override
  String get sunriseShort => 'sunrise';

  @override
  String get sunsetShort => 'sunset';

  @override
  String signExample(String base, String sign, String n) {
    return 'Example: $base $sign $n min';
  }

  @override
  String get signZero => 'Zero offset = exactly at base time';

  @override
  String get cmdTitle => 'Output type (relay command)';

  @override
  String get cmdOn => 'ON';

  @override
  String get cmdOff => 'OFF';

  @override
  String get cmdTimer => 'Cyclic ON/OFF';

  @override
  String get cmdOnD =>
      'ON command: the relay turns on at the event moment and stays on until the next event.';

  @override
  String get cmdOffD =>
      'OFF command: the relay turns off at the event moment and stays off until the next event.';

  @override
  String get timerNote =>
      'Cyclic ON/OFF timer: the relay stays on for the “ON duration”, then off for the “OFF duration”, and repeats this cycle. Each duration is set in minutes within the range of 5 to 720 minutes.';

  @override
  String get phaseOn => 'ON duration';

  @override
  String get phaseOff => 'OFF duration';

  @override
  String get startLabel => 'Start state';

  @override
  String get startOn => 'Start with relay ON';

  @override
  String get startOff => 'Start with relay OFF';

  @override
  String get phaseErr =>
      'The ON duration and the OFF duration must each be a multiple of 5 minutes within the range of 5 to 720 minutes.';

  @override
  String get phaseInvalid =>
      'Invalid; the value must be a multiple of 5 minutes between 5 minutes and 12 hours.';

  @override
  String phaseSum(String n) {
    return 'Total: $n min';
  }

  @override
  String get hourUnit => 'h';

  @override
  String get minUnit => 'min';

  @override
  String get saveEvent => 'Save event';

  @override
  String get eventSaved => 'Event saved';

  @override
  String get eventRemoved => 'Event removed from chain';

  @override
  String get timerErr =>
      'The timer settings are invalid. Check the ON and OFF durations; each must be a multiple of 5 minutes within the range of 5 to 720 minutes.';

  @override
  String get cmdIgnored => 'In timer mode the ON/OFF command is ignored.';

  @override
  String get onCmd => 'Command: relay ON';

  @override
  String get offCmd => 'Command: relay OFF';

  @override
  String timerCmd(String on, String off, String start) {
    return 'Command: flasher timer — ON $on / OFF $off · $start';
  }

  @override
  String get startOnTxt => 'relay turns ON first';

  @override
  String get startOffTxt => 'relay turns OFF first';

  @override
  String get sunriseBase => 'Sunrise';

  @override
  String get sunsetBase => 'Sunset';

  @override
  String astroFmt(String base, String sign, String n) {
    return '$base $sign $n min';
  }

  @override
  String minFmt(String h, String m) {
    return '$h h $m min';
  }

  @override
  String minOnlyFmt(String m) {
    return '$m min';
  }

  @override
  String get asWeekly => 'Assign to weekdays';

  @override
  String get asMonthly => 'Assign to days of month';

  @override
  String get asAnnual => 'Assign to days of year';

  @override
  String get asSub => 'Tap days to select or clear them (multi-select)';

  @override
  String asCount(String n) {
    return 'So far: $n days selected';
  }

  @override
  String get asAnnualNote =>
      'Selections are kept per month; move between months and keep selecting.';

  @override
  String get asOk => 'Confirm assignment';

  @override
  String get asClear => 'Clear selection';

  @override
  String get asCleared => 'Selection cleared';

  @override
  String get asSaved => 'Day assignment saved';

  @override
  String get w0 => 'Sat';

  @override
  String get w1 => 'Sun';

  @override
  String get w2 => 'Mon';

  @override
  String get w3 => 'Tue';

  @override
  String get w4 => 'Wed';

  @override
  String get w5 => 'Thu';

  @override
  String get w6 => 'Fri';

  @override
  String get m0 => 'Farvardin';

  @override
  String get m1 => 'Ordibehesht';

  @override
  String get m2 => 'Khordad';

  @override
  String get m3 => 'Tir';

  @override
  String get m4 => 'Mordad';

  @override
  String get m5 => 'Shahrivar';

  @override
  String get m6 => 'Mehr';

  @override
  String get m7 => 'Aban';

  @override
  String get m8 => 'Azar';

  @override
  String get m9 => 'Dey';

  @override
  String get m10 => 'Bahman';

  @override
  String get m11 => 'Esfand';

  @override
  String get peTitle => 'Edit programs';

  @override
  String get peSub => 'Manage saved timer programs';

  @override
  String peSummary(String cycle, String ev, String assign) {
    return '$cycle · $ev events · $assign';
  }

  @override
  String get seTitle => 'Settings';

  @override
  String get seSub => 'UI language and visual theme';

  @override
  String get seLang => 'UI language';

  @override
  String get seLangD => 'Persian (RTL) or English (LTR)';

  @override
  String get seFa => 'فارسی';

  @override
  String get seEn => 'English';

  @override
  String get seTheme => 'Visual theme';

  @override
  String get seThemeD =>
      'Light or Dark — both built from the design-system tokens';

  @override
  String get seLight => 'Light';

  @override
  String get seDark => 'Dark';

  @override
  String get heTitle => 'Help';

  @override
  String get heSub => 'Working with the KIANEX app and PTS50N1';

  @override
  String get heT1 => 'Getting started';

  @override
  String get heD1 =>
      'Create a program with the orange “New Program” button: name, cycle (daily/weekly/monthly/annual), the event chain and execution days.';

  @override
  String get heT2 => 'Fixed and solar events';

  @override
  String get heD2 =>
      'An event can fire at a fixed clock time, or be tied to sunrise/sunset with a 0–60 minute offset (before or after the base time).';

  @override
  String get heT3 => 'Flasher timer';

  @override
  String get heD3 =>
      'In timer mode the relay alternates ON/OFF phases. Each phase is 5 minutes to 12 hours (multiple of 5) and you choose whether it starts with the ON or OFF phase.';

  @override
  String get heT4 => 'Transfer to device';

  @override
  String get heD4 =>
      'The orange hexagonal NFC button at the bottom of the screen has three modes: read device status, set time & location, and write programs to the device.';

  @override
  String get heT5 => 'Time conflicts';

  @override
  String get heD5 =>
      'Two events cannot run in the same minute; the app detects the conflict at save time and blocks it.';

  @override
  String get heT6 => 'Failed write or connection';

  @override
  String get heD6 =>
      'If a transfer stops at any stage, “Try again” restarts it from the beginning; you can also use “Back to the app” to return. After two consecutive failures, the power-cycle guidance is shown.';

  @override
  String get heT7 => 'Memory capacity';

  @override
  String get heD7 =>
      'The event memory holds 255 events and the timer memory 50 timers; all programs share this capacity. The capacity indicator appears in the program creation flow.';

  @override
  String get abTitle => 'About / App version';

  @override
  String get abVer => 'App version';

  @override
  String get abMode => 'Mode';

  @override
  String get abModeV => 'Full implementation — Phase 2';

  @override
  String get abTarget => 'Target model';

  @override
  String get abImpl => 'Implementation';

  @override
  String get abImplV => 'Flutter + Material 3 (Android)';

  @override
  String get abSot => 'Protocol & memory reference';

  @override
  String get abSotV => 'Source of Truth v3.1-Final + two CSV maps';

  @override
  String get abNote =>
      'This build implements the real NFC layer (ISO 15693 / NFC Forum Type 5) behind the NfcService contract, together with the 8-step SOT write protocol, CRC verification and the relay power-off flows.';

  @override
  String get dsheetTitle => 'Select device';

  @override
  String get dsheetSub =>
      'Pick the device from the product list, or identify it with an NFC scan.';

  @override
  String get dsheetCurrent => 'Current';

  @override
  String get dsheetNote =>
      'In this release, the product list includes PTS50N1; future models will be added to this list.';

  @override
  String get addCardTitle => 'Add a new program';

  @override
  String get addCardDesc => 'Create a new schedule for the device';

  @override
  String get emptyBtnRead => 'Read device status';

  @override
  String get emptyBtnAdd => 'Add a new program';

  @override
  String metaFmt(String on, String off, String t) {
    return '$on ON commands | $off OFF commands | $t timer';
  }

  @override
  String get relay1 => 'Output 1';

  @override
  String get viewEvents => 'View event details';

  @override
  String get progOnToast => 'Program enabled';

  @override
  String get progOffToast => 'Program disabled';

  @override
  String get progOffBadge => 'Off';

  @override
  String get chartMemTitle => 'Program memory';

  @override
  String chartMemValue(String u, String m) {
    return '$u of $m event slots';
  }

  @override
  String get chartTimerTitle => 'Timers';

  @override
  String chartTimerValue(String u, String m) {
    return '$u of $m timer slots';
  }

  @override
  String get wcAstroSide => 'Auto';

  @override
  String get wcSetSide => '3 sections';

  @override
  String get wcSetD2 =>
      'Time and Jalali calendar sync + sunrise/sunset calculation';

  @override
  String get wcBack => 'Back';

  @override
  String get wpClose => 'Got it';

  @override
  String get wpBackApp => 'Back to the app';

  @override
  String get wpBackToast => 'You are back in the app; you can try again later.';

  @override
  String get dsIdentifyBtn => 'Identify device with NFC scan';

  @override
  String get dsIdentifyD =>
      'While scanning, the device model is detected automatically.';

  @override
  String get dsScanTitle => 'Identify device';

  @override
  String get dsScanSub =>
      'Hold the phone near the device NFC tag and keep it steady until identification finishes.';

  @override
  String get dsScanPh1 => 'Connecting to the device…';

  @override
  String get dsScanPh2 => 'Reading device info…';

  @override
  String get dsScanPh3 => 'Detecting the device model…';

  @override
  String get dsFound => 'Device identified';

  @override
  String get dsFoundD =>
      'The device model was detected automatically and matched with the product list.';

  @override
  String get dsDoneToast => 'Device model confirmed: PTS50N1';

  @override
  String get asSelTitle => 'Selected days';

  @override
  String get asNoneSelected => 'No days selected yet';

  @override
  String asDayN(String n) {
    return 'Day $n';
  }

  @override
  String get asRemoveOne => 'Remove this day from the selection';

  @override
  String get asRemovedOne => 'The day was removed from the selection list';

  @override
  String get asRequired => 'Required';

  @override
  String get needDays =>
      'Assign the execution days of the chain before saving the program.';

  @override
  String get needDaysHint =>
      'Select execution days to enable the “Save program” button.';

  @override
  String get phaseRange =>
      'Allowed range: 5 to 720 minutes — adjusted in 5-minute steps.';

  @override
  String countActiveFmt(String n, String m) {
    return '$n active · $m disabled';
  }

  @override
  String get allDisabledToast =>
      'All programs are disabled; disabled programs are not sent to the relay. Enable a program first.';

  @override
  String wcOffNote(String m) {
    return '$m disabled program(s) are not included in this transfer; disabled programs are not sent to the relay.';
  }

  @override
  String get scPower => 'Relay unpowered';

  @override
  String get wpPwSetT => 'Clock and location cannot be set';

  @override
  String get wpPwSetM =>
      'The relay has no power supply. In this state the clock, date and location cannot be stored on the relay, and the settings transfer was stopped. Restore the relay power supply and repeat this operation.';

  @override
  String get wpPwAck => 'Understood';

  @override
  String get wpPwSetToast =>
      'The settings transfer was stopped; try again after restoring the relay power supply.';

  @override
  String get wpPwProgT => 'The relay is unpowered';

  @override
  String get wpPwProgM =>
      'The relay has no power supply. In this state programs can be transferred, but the relay clock, date and location will not be updated. After restoring the relay power supply, send “Settings only” to update the clock and date.';

  @override
  String get wpPwContinue => 'Continue sending';

  @override
  String get wpPwCancel => 'Cancel';

  @override
  String get wpPwCancelled => 'Program transfer was cancelled.';

  @override
  String get wpPwSkipped =>
      'The relay clock and date are not updated in this operation.';

  @override
  String wpDoneSubNoClock(String v) {
    return 'Programs were written to the relay and verified; the relay clock, date and location were not updated. After restoring the relay power supply, send “Settings only”.';
  }

  @override
  String get step4dNoClock =>
      'Programs are stored in the relay memory; the clock and date are not updated.';

  @override
  String get ruleTitle => 'Command chain rules';

  @override
  String get ruleIntro =>
      'In these rules, two commands placed back-to-back in the chain list with no other command between them are called consecutive commands.';

  @override
  String get ruleR1 =>
      'Two commands in one chain cannot have the same run time; simultaneous execution of two commands on one output is not permitted.';

  @override
  String get ruleR2 =>
      'The interval between two consecutive commands must not be less than 5 minutes.';

  @override
  String get ruleR3 =>
      'Two consecutive commands cannot have the same relay action; otherwise the relay output state would not change after the second command. If another command with a different action exists between the two, this rule does not apply.';

  @override
  String get ruleR4 =>
      'Two consecutive commands cannot have identical timer settings; otherwise the output behaviour would repeat in both commands.';

  @override
  String ruleSameTime(String n1, String n2, String t) {
    return 'Commands $n1 and $n2 share the same run time ($t). The run time of one of the two commands must be changed.';
  }

  @override
  String ruleSameTimeSolar(String n1, String n2) {
    return 'Commands $n1 and $n2 are both bound to the same solar moment with the same offset. The settings of one of the two commands must be changed.';
  }

  @override
  String ruleMinGap(String n1, String n2, String d, String t1, String t2) {
    return 'Commands $n1 and $n2 are $d minute(s) apart ($t1 and $t2); the minimum allowed interval between two consecutive commands is 5 minutes.';
  }

  @override
  String ruleSameAct(String n1, String n2, String act, String t1, String t2) {
    return 'Commands $n1 and $n2 both perform “$act” ($t1 and $t2); two consecutive commands with the same relay action are not permitted, because the relay output state would not change.';
  }

  @override
  String ruleSameTimer(String n1, String n2, String t1, String t2, String tmr) {
    return 'Commands $n1 and $n2 have identical timer settings ($t1 and $t2 · $tmr); two consecutive commands with identical timer settings are not permitted, because the output behaviour would repeat.';
  }

  @override
  String ruleTimerFmt(String on, String off) {
    return 'ON $on / OFF $off';
  }

  @override
  String rulesBlock(String n) {
    return 'Program not saved: $n non-conformity item(s) with the command-chain rules.';
  }

  @override
  String evRuleSameTime(String n, String t) {
    return 'This command shares the same run time ($t) as command No. $n; the run time of one of the two commands must be changed.';
  }

  @override
  String evRuleSameTimeSolar(String n) {
    return 'This command is bound to the same solar moment with the same offset as command No. $n; change the settings of one of the two commands.';
  }

  @override
  String evRuleMinGap(String n, String d) {
    return 'This command is $d minute(s) apart from command No. $n; the minimum allowed interval between two consecutive commands is 5 minutes.';
  }

  @override
  String evRuleSameAct(String n, String act) {
    return 'This command and command No. $n both perform “$act”; two consecutive commands with the same relay action are not permitted, because the relay output state would not change.';
  }

  @override
  String evRuleSameTimer(String n) {
    return 'This command and command No. $n have identical timer settings; change the timer settings or the run time of one of the two commands.';
  }

  @override
  String hourFmt(String h) {
    return '$h h';
  }

  @override
  String get gpsInvalid =>
      'The entered value is not valid; latitude must be between −90 and 90 and longitude between −180 and 180.';

  @override
  String get logTitle => 'Application log';

  @override
  String get logSub =>
      'Every application operation is recorded here with its exact time. Send the exported log file to the development team together with the field-test report.';

  @override
  String logCount(String n, String m) {
    return '$n recorded events · $m shown';
  }

  @override
  String get logEmpty =>
      'No events recorded yet. After any operation (NFC session, location fix or program edit) the events appear on this page.';

  @override
  String get logExport => 'Save and share log';

  @override
  String get logCopy => 'Copy';

  @override
  String get logClear => 'Clear';

  @override
  String get logShareSubject => 'KIANEX PTS50N1 application log';

  @override
  String get logExportFailed => 'Sharing the log failed.';

  @override
  String get logCopiedToast => 'The log was copied to the clipboard.';

  @override
  String get logClearTitle => 'Clear the application log?';

  @override
  String get logClearText =>
      'All recorded events will be deleted. This action cannot be undone.';

  @override
  String get logClearedToast => 'The log was cleared.';

  @override
  String get logLevelNfc => 'NFC';

  @override
  String get logLevelGps => 'GPS';

  @override
  String get logLevelAction => 'Action';

  @override
  String get logLevelError => 'Error';

  @override
  String get logLevelWarn => 'Warning';

  @override
  String get logLevelInfo => 'Info';

  @override
  String get seLogs => 'Application log (logger)';

  @override
  String get seLogsD =>
      'Automatic recording of all operations; the log file can be viewed, saved and shared.';

  @override
  String get gpsGetFix => 'Get position via GPS';

  @override
  String get gpsFixing => 'Reading the position…';

  @override
  String gpsAccm(String m) {
    return 'Position accuracy: ±$m m';
  }

  @override
  String get gpsManual => 'Enter coordinates manually';

  @override
  String get gpsDenied =>
      'The location permission was not granted. Enable the “Location” permission for this application in the system settings.';

  @override
  String get gpsDeniedForever =>
      'Location access is permanently denied. Enable the “Location” permission for this application in the system settings.';

  @override
  String get gpsServiceOff =>
      'The device location service is off. Turn it on in the system settings.';

  @override
  String get gpsTimeout =>
      'Reading the position failed. Try again in a few moments.';

  @override
  String get mapOffline =>
      'Map tiles need an internet connection — check the phone connectivity.';

  @override
  String get idModelWarnTitle => 'Tag read — model not matched';

  @override
  String get idModelWarnText =>
      'The NDEF payload of the tag does not carry the KIANEX identifiers; the tag may not belong to a factory PTS50R1 device. The NDEF message is shown below.';

  @override
  String get idMemoryWarnTitle => 'Tag read — insufficient memory';

  @override
  String get idMemoryWarnText =>
      'The tag memory is not large enough for the PTS50R1 shared-memory layout; an ST25DV16K (512 blocks) or larger Type 5 tag is required.';

  @override
  String get idTagModel => 'Tag model';

  @override
  String get idTagMemory => 'Tag memory';

  @override
  String get idTagUid => 'Tag UID';

  @override
  String get idTagUri => 'NDEF message';

  @override
  String get idRetry => 'Retry';

  @override
  String get idFailTitle => 'Device identification did not complete';

  @override
  String get idFailNoTag =>
      'No NFC tag was read in range. First make sure the phone NFC is on; then hold the back of the phone near the tag on the device and keep it steady until identification finishes.';

  @override
  String get idFailNotIso =>
      'The presented tag is not NFC Forum Type 5 (ISO 15693) and is not compatible with this device.';

  @override
  String get idFailModel =>
      'The NDEF payload of the tag does not carry the KIANEX identifiers; the tag may belong to another device.';

  @override
  String get idFailMemory =>
      'The tag memory is not large enough for the shared-memory layout (at least 512 blocks of 4 bytes are required).';

  @override
  String get stNoTagTitle => 'Reading the device status failed';

  @override
  String get stNoTagText =>
      'No NFC tag was read in range or the device did not answer. First make sure the phone NFC is on; then hold the back of the phone near the relay tag and press “Read again”.';

  @override
  String get stPressRefresh =>
      'To read the device status, turn the phone NFC on, hold the back of the phone near the relay NFC tag and press “Read again”.';

  @override
  String asAnnualLeapNote(String year) {
    return 'Year $year is a leap year; Esfand has 30 days and day 366 exists in the annual day grid.';
  }

  @override
  String get idFailNfcOff =>
      'The phone NFC adapter is not enabled. Turn NFC on from the quick settings and try again.';

  @override
  String get evFixedTimeLabel => 'Run time';

  @override
  String get evFixedPickerTitle => 'Set the run time';

  @override
  String get offsetPickerTitle => 'Set the offset from sunrise/sunset';

  @override
  String get offsetHint =>
      'Offset from the astronomical base, 0 to 60 minutes in 5-minute steps.';

  @override
  String get phaseOnLabel => 'ON duration';

  @override
  String get phaseOffLabel => 'OFF duration';

  @override
  String get phaseOnPickerTitle => 'Set the ON duration';

  @override
  String get phaseOffPickerTitle => 'Set the OFF duration';

  @override
  String get plusMinute => '+';

  @override
  String get minusMinute => '−';

  @override
  String get chainSortNote =>
      'The chain is sorted automatically by execution time — sunrise commands first, then the fixed-time commands from 00:00, then the sunset commands. Every new command takes its time-based position on its own.';

  @override
  String astroToday(String t) {
    return 'Today: $t';
  }

  @override
  String get overlapTitle => 'Annual coincidence notice';

  @override
  String overlapDetail(
      String time, String base, String days, String from, String to) {
    return 'The fixed command $time coincides with the $base command on $days days of the year (from $from to $to).';
  }

  @override
  String get overlapNote =>
      'This is normal: sunrise and sunset move through the year. The device runs the commands in chain order; at the shared instant the later chain entry wins. You can keep or adjust the times.';

  @override
  String get overlapAccept => 'Save anyway';

  @override
  String get gateNfcOffTitle => 'NFC is off';

  @override
  String get gateNfcOffText =>
      'The NFC adapter of your phone is off. The app needs NFC to identify the relay and transfer programs. Please turn NFC on.';

  @override
  String get gateNfcMissing =>
      'This phone has no NFC hardware — the relay cannot be reached from this device.';

  @override
  String get gateLocAsked =>
      'Location permission requested — it is used only to find the sunrise and sunset times.';

  @override
  String get gateLocPermTitle => 'Location permission needed';

  @override
  String get gateLocPermText =>
      'The app needs the location permission to compute the sunrise and sunset times of your area. Please grant the permission in the app settings.';

  @override
  String get gateLocServiceTitle => 'Location service is off';

  @override
  String get gateLocServiceText =>
      'The phone\'s location service is off. Turn it on so the app can find your position for the sunrise/sunset calculation.';

  @override
  String get gateGoSettings => 'Open settings';

  @override
  String get gateLater => 'Later';

  @override
  String get gateStripHint =>
      'NFC or location is not ready — some features cannot work until it is fixed.';

  @override
  String get gpsMapTitle => 'Pick the position on the map';

  @override
  String get gpsMapHint =>
      'Tap anywhere on the map to move the marker, then confirm.';

  @override
  String get gpsPhonePos => 'Phone position';
}
