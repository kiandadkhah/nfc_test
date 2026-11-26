import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fa')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'KIANEX PTS50N1'**
  String get appName;

  /// No description provided for @brandSlogan.
  ///
  /// In en, this message translates to:
  /// **'Innovation that lasts'**
  String get brandSlogan;

  /// No description provided for @deviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Calendar-based relay timer'**
  String get deviceTitle;

  /// No description provided for @deviceSub.
  ///
  /// In en, this message translates to:
  /// **'Single 50 A relay · NFC connectivity · daily, weekly, monthly and annual cycles'**
  String get deviceSub;

  /// No description provided for @deviceEngName.
  ///
  /// In en, this message translates to:
  /// **'Engineering name in the Source of Truth: PST50R1'**
  String get deviceEngName;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @obKicker1.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get obKicker1;

  /// No description provided for @obTitle1.
  ///
  /// In en, this message translates to:
  /// **'KIANEX PTS50N1'**
  String get obTitle1;

  /// No description provided for @obText1.
  ///
  /// In en, this message translates to:
  /// **'The companion app for your calendar-based relay timer. Build timer programs on the phone and send them to the device over NFC; the device runs independently of the phone.'**
  String get obText1;

  /// No description provided for @obKicker2.
  ///
  /// In en, this message translates to:
  /// **'Device link'**
  String get obKicker2;

  /// No description provided for @obTitle2.
  ///
  /// In en, this message translates to:
  /// **'Connect over NFC'**
  String get obTitle2;

  /// No description provided for @obText2.
  ///
  /// In en, this message translates to:
  /// **'The device NFC tag is on its body. Touch the back of your phone to it and keep it steady until the transfer finishes.'**
  String get obText2;

  /// No description provided for @obPoint1.
  ///
  /// In en, this message translates to:
  /// **'A phone without the app still reads the tag and opens the product page (NDEF)'**
  String get obPoint1;

  /// No description provided for @obPoint2.
  ///
  /// In en, this message translates to:
  /// **'Writes run through a safe 8-step protocol'**
  String get obPoint2;

  /// No description provided for @obPoint3.
  ///
  /// In en, this message translates to:
  /// **'If a write is interrupted, the device keeps running its last valid program'**
  String get obPoint3;

  /// No description provided for @obKicker3.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get obKicker3;

  /// No description provided for @obTitle3.
  ///
  /// In en, this message translates to:
  /// **'Create your first program'**
  String get obTitle3;

  /// No description provided for @obText3.
  ///
  /// In en, this message translates to:
  /// **'Pick a cycle, arrange the events in a chain and set the execution days. Whenever you are ready, send it to the device with the hexagonal NFC button.'**
  String get obText3;

  /// No description provided for @timerPrograms.
  ///
  /// In en, this message translates to:
  /// **'Timer programs'**
  String get timerPrograms;

  /// No description provided for @countPrograms.
  ///
  /// In en, this message translates to:
  /// **'{n} programs'**
  String countPrograms(String n);

  /// No description provided for @countEmpty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get countEmpty;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No program defined yet'**
  String get emptyTitle;

  /// No description provided for @emptyText.
  ///
  /// In en, this message translates to:
  /// **'To get started, read the device status or create your first schedule.\nA program includes a cycle, an event chain and execution days.'**
  String get emptyText;

  /// No description provided for @emptyCta.
  ///
  /// In en, this message translates to:
  /// **'Create a new program'**
  String get emptyCta;

  /// No description provided for @seedSample.
  ///
  /// In en, this message translates to:
  /// **'Load sample programs'**
  String get seedSample;

  /// No description provided for @newProgram.
  ///
  /// In en, this message translates to:
  /// **'New Program'**
  String get newProgram;

  /// No description provided for @changeModel.
  ///
  /// In en, this message translates to:
  /// **'Change model'**
  String get changeModel;

  /// No description provided for @eventsInChain.
  ///
  /// In en, this message translates to:
  /// **'{n} events in chain'**
  String eventsInChain(String n);

  /// No description provided for @allDays.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get allDays;

  /// No description provided for @noAssign.
  ///
  /// In en, this message translates to:
  /// **'No days assigned'**
  String get noAssign;

  /// No description provided for @weekDaysOf.
  ///
  /// In en, this message translates to:
  /// **'{n} days of week'**
  String weekDaysOf(String n);

  /// No description provided for @monthDaysOf.
  ///
  /// In en, this message translates to:
  /// **'{n} days of month'**
  String monthDaysOf(String n);

  /// No description provided for @yearDaysOf.
  ///
  /// In en, this message translates to:
  /// **'{n} days of year'**
  String yearDaysOf(String n);

  /// No description provided for @onDeviceRunning.
  ///
  /// In en, this message translates to:
  /// **'On device: running version {v}'**
  String onDeviceRunning(String v);

  /// No description provided for @menuEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit programs'**
  String get menuEdit;

  /// No description provided for @menuStatus.
  ///
  /// In en, this message translates to:
  /// **'Device status'**
  String get menuStatus;

  /// No description provided for @menuStatusSub.
  ///
  /// In en, this message translates to:
  /// **'Logger read: operating hours, ongoing event, internal error'**
  String get menuStatusSub;

  /// No description provided for @menuGps.
  ///
  /// In en, this message translates to:
  /// **'Location settings (GPS)'**
  String get menuGps;

  /// No description provided for @menuGpsSub.
  ///
  /// In en, this message translates to:
  /// **'Basis for sunrise/sunset calculation'**
  String get menuGpsSub;

  /// No description provided for @menuSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get menuSettings;

  /// No description provided for @menuSettingsSub.
  ///
  /// In en, this message translates to:
  /// **'Language and theme'**
  String get menuSettingsSub;

  /// No description provided for @menuHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get menuHelp;

  /// No description provided for @menuAbout.
  ///
  /// In en, this message translates to:
  /// **'About / App version'**
  String get menuAbout;

  /// No description provided for @editProgram.
  ///
  /// In en, this message translates to:
  /// **'Edit program'**
  String get editProgram;

  /// No description provided for @deleteProgram.
  ///
  /// In en, this message translates to:
  /// **'Delete program'**
  String get deleteProgram;

  /// No description provided for @capacityEvents.
  ///
  /// In en, this message translates to:
  /// **'Events {e} of 255'**
  String capacityEvents(String e);

  /// No description provided for @capacityTimers.
  ///
  /// In en, this message translates to:
  /// **'Timers {t} of 50'**
  String capacityTimers(String t);

  /// No description provided for @nfcSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect to PTS50N1'**
  String get nfcSheetTitle;

  /// No description provided for @nfcSheetSub.
  ///
  /// In en, this message translates to:
  /// **'Choose one of the actions below. Then hold the back of the phone near the NFC tag on the relay and keep it steady until the operation finishes.'**
  String get nfcSheetSub;

  /// No description provided for @readStatusT.
  ///
  /// In en, this message translates to:
  /// **'Read device status'**
  String get readStatusT;

  /// No description provided for @readStatusD.
  ///
  /// In en, this message translates to:
  /// **'Logger read: running program version, ongoing event, operating counters and internal error'**
  String get readStatusD;

  /// No description provided for @settingsOnlyT.
  ///
  /// In en, this message translates to:
  /// **'Set time & location'**
  String get settingsOnlyT;

  /// No description provided for @settingsOnlyD.
  ///
  /// In en, this message translates to:
  /// **'Set the relay clock and record the location used to compute sunrise and sunset'**
  String get settingsOnlyD;

  /// No description provided for @programWriteT.
  ///
  /// In en, this message translates to:
  /// **'Write programs to the device'**
  String get programWriteT;

  /// No description provided for @programWriteD.
  ///
  /// In en, this message translates to:
  /// **'Send the enabled scheduled programs and settings to the relay memory; disabled programs are not sent'**
  String get programWriteD;

  /// No description provided for @noProgramsToast.
  ///
  /// In en, this message translates to:
  /// **'You have no programs to send yet. Create a scheduled program first, or choose the “Settings only” option.'**
  String get noProgramsToast;

  /// No description provided for @wcTitleSet.
  ///
  /// In en, this message translates to:
  /// **'Confirm transfer — settings only'**
  String get wcTitleSet;

  /// No description provided for @wcTitleProg.
  ///
  /// In en, this message translates to:
  /// **'Confirm transfer — programs and settings'**
  String get wcTitleProg;

  /// No description provided for @wcSub.
  ///
  /// In en, this message translates to:
  /// **'Review what will be written before starting; keep the phone close to the device and steady during the whole transfer.'**
  String get wcSub;

  /// No description provided for @wcTime.
  ///
  /// In en, this message translates to:
  /// **'Clock & calendar sync'**
  String get wcTime;

  /// No description provided for @wcTimeD.
  ///
  /// In en, this message translates to:
  /// **'Phone time and Persian date will be written to the device'**
  String get wcTimeD;

  /// No description provided for @wcAstro.
  ///
  /// In en, this message translates to:
  /// **'Sunrise & sunset calculation'**
  String get wcAstro;

  /// No description provided for @wcAstroD.
  ///
  /// In en, this message translates to:
  /// **'Based on the current location — sunrise and sunset times are calculated automatically'**
  String get wcAstroD;

  /// No description provided for @wcPrograms.
  ///
  /// In en, this message translates to:
  /// **'Timer programs'**
  String get wcPrograms;

  /// No description provided for @wcProgramsD.
  ///
  /// In en, this message translates to:
  /// **'{n} programs with {e} events and {t} timers'**
  String wcProgramsD(String n, String e, String t);

  /// No description provided for @wcVersion.
  ///
  /// In en, this message translates to:
  /// **'New program version'**
  String get wcVersion;

  /// No description provided for @wcVersionD.
  ///
  /// In en, this message translates to:
  /// **'After a successful write, this version is applied on the device'**
  String wcVersionD(String v);

  /// No description provided for @wcCapacity.
  ///
  /// In en, this message translates to:
  /// **'Device memory capacity'**
  String get wcCapacity;

  /// No description provided for @wcCapacityD.
  ///
  /// In en, this message translates to:
  /// **'Events {e} of 255 · Timers {t} of 50'**
  String wcCapacityD(String e, String t);

  /// No description provided for @wcScenario.
  ///
  /// In en, this message translates to:
  /// **'Transfer test scenarios — design-review tool'**
  String get wcScenario;

  /// No description provided for @scOk.
  ///
  /// In en, this message translates to:
  /// **'Successful transfer'**
  String get scOk;

  /// No description provided for @scBusy.
  ///
  /// In en, this message translates to:
  /// **'Device busy'**
  String get scBusy;

  /// No description provided for @scRf.
  ///
  /// In en, this message translates to:
  /// **'Connection cut mid-transfer'**
  String get scRf;

  /// No description provided for @scCrc.
  ///
  /// In en, this message translates to:
  /// **'Verification mismatch'**
  String get scCrc;

  /// No description provided for @scModel.
  ///
  /// In en, this message translates to:
  /// **'Device model mismatch'**
  String get scModel;

  /// No description provided for @wcStart.
  ///
  /// In en, this message translates to:
  /// **'Start transfer'**
  String get wcStart;

  /// No description provided for @keepSteady.
  ///
  /// In en, this message translates to:
  /// **'Keep the phone steady and do not move it away from the device until the transfer finishes'**
  String get keepSteady;

  /// No description provided for @wpTitle.
  ///
  /// In en, this message translates to:
  /// **'Transferring data to the device'**
  String get wpTitle;

  /// No description provided for @attemptOf.
  ///
  /// In en, this message translates to:
  /// **'Attempt {n} of 2'**
  String attemptOf(String n);

  /// No description provided for @wpPolling.
  ///
  /// In en, this message translates to:
  /// **'Waiting for the device to become ready…'**
  String get wpPolling;

  /// No description provided for @wpCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wpCancel;

  /// No description provided for @wpDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer complete'**
  String get wpDoneTitle;

  /// No description provided for @wpDoneSub.
  ///
  /// In en, this message translates to:
  /// **'Version {v} was written to the device and verified successfully; the device is applying the new program.'**
  String wpDoneSub(String v);

  /// No description provided for @wpDoneGo.
  ///
  /// In en, this message translates to:
  /// **'View device status'**
  String get wpDoneGo;

  /// No description provided for @wpFailTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer left unfinished'**
  String get wpFailTitle;

  /// No description provided for @wpFailStep.
  ///
  /// In en, this message translates to:
  /// **'The transfer stopped at the “{step}” stage.'**
  String wpFailStep(String step);

  /// No description provided for @wpFailBusy.
  ///
  /// In en, this message translates to:
  /// **'The device did not become free after a few seconds; try again shortly.'**
  String get wpFailBusy;

  /// No description provided for @wpRetryHint.
  ///
  /// In en, this message translates to:
  /// **'Per the Source of Truth, the protocol restarts from step 1.'**
  String get wpRetryHint;

  /// No description provided for @wpRetryFromStep1.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get wpRetryFromStep1;

  /// No description provided for @wpPowerOff.
  ///
  /// In en, this message translates to:
  /// **'Power-cycle guidance'**
  String get wpPowerOff;

  /// No description provided for @step1.
  ///
  /// In en, this message translates to:
  /// **'Prepare and identify the device'**
  String get step1;

  /// No description provided for @step1d.
  ///
  /// In en, this message translates to:
  /// **'Matching the device model with the app'**
  String get step1d;

  /// No description provided for @step2.
  ///
  /// In en, this message translates to:
  /// **'Check device status'**
  String get step2;

  /// No description provided for @step2d.
  ///
  /// In en, this message translates to:
  /// **'Health and readiness check for receiving data'**
  String get step2d;

  /// No description provided for @step3.
  ///
  /// In en, this message translates to:
  /// **'Start the transfer'**
  String get step3;

  /// No description provided for @step3d.
  ///
  /// In en, this message translates to:
  /// **'Opening a secure transfer path'**
  String get step3d;

  /// No description provided for @step4.
  ///
  /// In en, this message translates to:
  /// **'Write programs and settings'**
  String get step4;

  /// No description provided for @step4d.
  ///
  /// In en, this message translates to:
  /// **'Transferring data to the device memory'**
  String get step4d;

  /// No description provided for @step5.
  ///
  /// In en, this message translates to:
  /// **'Finish writing'**
  String get step5;

  /// No description provided for @step5d.
  ///
  /// In en, this message translates to:
  /// **'Ending the data transfer stage'**
  String get step5d;

  /// No description provided for @step6.
  ///
  /// In en, this message translates to:
  /// **'Read back the data'**
  String get step6;

  /// No description provided for @step6d.
  ///
  /// In en, this message translates to:
  /// **'Re-reading to make sure the transfer is correct'**
  String get step6d;

  /// No description provided for @step7.
  ///
  /// In en, this message translates to:
  /// **'Verify the data'**
  String get step7;

  /// No description provided for @step7d.
  ///
  /// In en, this message translates to:
  /// **'Comparing the written data with the original version'**
  String get step7d;

  /// No description provided for @step8.
  ///
  /// In en, this message translates to:
  /// **'Activate the new version'**
  String get step8;

  /// No description provided for @step8d.
  ///
  /// In en, this message translates to:
  /// **'The device runs the new program'**
  String get step8d;

  /// No description provided for @rcTitle.
  ///
  /// In en, this message translates to:
  /// **'Connection failed'**
  String get rcTitle;

  /// No description provided for @rcSub.
  ///
  /// In en, this message translates to:
  /// **'Two complete attempts failed — per RC-10 of the Source of Truth'**
  String get rcSub;

  /// No description provided for @rcMsgTitle.
  ///
  /// In en, this message translates to:
  /// **'User message (proposed OI-02 text)'**
  String get rcMsgTitle;

  /// No description provided for @rcMsg.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the device. Please power the device off and on once, then retry the transfer. If it still fails, do the programming while the device is powered off.'**
  String get rcMsg;

  /// No description provided for @rcS1.
  ///
  /// In en, this message translates to:
  /// **'Power the device off'**
  String get rcS1;

  /// No description provided for @rcS1d.
  ///
  /// In en, this message translates to:
  /// **'Open the fuse or breaker feeding the device and wait a few seconds.'**
  String get rcS1d;

  /// No description provided for @rcS2.
  ///
  /// In en, this message translates to:
  /// **'Power it back on and retry'**
  String get rcS2;

  /// No description provided for @rcS2d.
  ///
  /// In en, this message translates to:
  /// **'The device resets and frees the tag; then tap the NFC button.'**
  String get rcS2d;

  /// No description provided for @rcS3.
  ///
  /// In en, this message translates to:
  /// **'Or program while powered off'**
  String get rcS3;

  /// No description provided for @rcS3d.
  ///
  /// In en, this message translates to:
  /// **'With the device powered off, the transfer is more stable.'**
  String get rcS3d;

  /// No description provided for @rcRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get rcRetry;

  /// No description provided for @rcBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get rcBack;

  /// No description provided for @stTitle.
  ///
  /// In en, this message translates to:
  /// **'Device status'**
  String get stTitle;

  /// No description provided for @stSub.
  ///
  /// In en, this message translates to:
  /// **'Up-to-date device status after the last read'**
  String get stSub;

  /// No description provided for @stVersionCard.
  ///
  /// In en, this message translates to:
  /// **'Program version'**
  String get stVersionCard;

  /// No description provided for @stOnDevice.
  ///
  /// In en, this message translates to:
  /// **'On device'**
  String get stOnDevice;

  /// No description provided for @stLastWritten.
  ///
  /// In en, this message translates to:
  /// **'Last written'**
  String get stLastWritten;

  /// No description provided for @stSynced.
  ///
  /// In en, this message translates to:
  /// **'In sync — this version is running'**
  String get stSynced;

  /// No description provided for @stPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for device confirmation'**
  String get stPending;

  /// No description provided for @stOutdated.
  ///
  /// In en, this message translates to:
  /// **'No new program on device — send one'**
  String get stOutdated;

  /// No description provided for @stOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing event'**
  String get stOngoing;

  /// No description provided for @stOngoingNone.
  ///
  /// In en, this message translates to:
  /// **'No event is running right now'**
  String get stOngoingNone;

  /// No description provided for @stRelayOn.
  ///
  /// In en, this message translates to:
  /// **'Relay: ON'**
  String get stRelayOn;

  /// No description provided for @stRelayOff.
  ///
  /// In en, this message translates to:
  /// **'Relay: OFF'**
  String get stRelayOff;

  /// No description provided for @stCounters.
  ///
  /// In en, this message translates to:
  /// **'Operating counters'**
  String get stCounters;

  /// No description provided for @stHour.
  ///
  /// In en, this message translates to:
  /// **'Total operating hours'**
  String get stHour;

  /// No description provided for @stHourOn.
  ///
  /// In en, this message translates to:
  /// **'Output-on hours'**
  String get stHourOn;

  /// No description provided for @stCn.
  ///
  /// In en, this message translates to:
  /// **'Relay operations'**
  String get stCn;

  /// No description provided for @stErrCard.
  ///
  /// In en, this message translates to:
  /// **'Internal error'**
  String get stErrCard;

  /// No description provided for @stErrNone.
  ///
  /// In en, this message translates to:
  /// **'No error recorded'**
  String get stErrNone;

  /// No description provided for @stErrCode.
  ///
  /// In en, this message translates to:
  /// **'Non-zero code recorded — coding is open item OI-01'**
  String get stErrCode;

  /// No description provided for @stErrHint.
  ///
  /// In en, this message translates to:
  /// **'If you see this error, inspect the device or contact support.'**
  String get stErrHint;

  /// No description provided for @stTech.
  ///
  /// In en, this message translates to:
  /// **'Device technical details'**
  String get stTech;

  /// No description provided for @stLastRead.
  ///
  /// In en, this message translates to:
  /// **'Last read'**
  String get stLastRead;

  /// No description provided for @stReadSeq.
  ///
  /// In en, this message translates to:
  /// **'The data was read from the device and verified successfully.'**
  String get stReadSeq;

  /// No description provided for @stRefresh.
  ///
  /// In en, this message translates to:
  /// **'Read again'**
  String get stRefresh;

  /// No description provided for @gpsTitle.
  ///
  /// In en, this message translates to:
  /// **'Location settings (GPS)'**
  String get gpsTitle;

  /// No description provided for @gpsSub.
  ///
  /// In en, this message translates to:
  /// **'Location used as the basis for solar events'**
  String get gpsSub;

  /// No description provided for @gpsCoords.
  ///
  /// In en, this message translates to:
  /// **'Current coordinates'**
  String get gpsCoords;

  /// No description provided for @gpsLat.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get gpsLat;

  /// No description provided for @gpsLng.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get gpsLng;

  /// No description provided for @gpsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last update'**
  String get gpsUpdated;

  /// No description provided for @gpsRefresh.
  ///
  /// In en, this message translates to:
  /// **'Update location'**
  String get gpsRefresh;

  /// No description provided for @gpsUpdatedToast.
  ///
  /// In en, this message translates to:
  /// **'Location saved.'**
  String get gpsUpdatedToast;

  /// No description provided for @gpsUse.
  ///
  /// In en, this message translates to:
  /// **'This location is the reference for the device\'s sunrise and sunset calculation. It is stored only on your phone and on the device — it is never shared with any other service.'**
  String get gpsUse;

  /// No description provided for @gpsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy ±15 m'**
  String get gpsAccuracy;

  /// No description provided for @gpsPin.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get gpsPin;

  /// No description provided for @nameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'New program'**
  String get nameDialogTitle;

  /// No description provided for @nameDialogQ.
  ///
  /// In en, this message translates to:
  /// **'Pick a name to identify the program.'**
  String get nameDialogQ;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Program name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Courtyard lighting'**
  String get nameHint;

  /// No description provided for @nameErr.
  ///
  /// In en, this message translates to:
  /// **'Enter a program name'**
  String get nameErr;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Program creation cancelled'**
  String get cancelled;

  /// No description provided for @cycleTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose the cycle'**
  String get cycleTitle;

  /// No description provided for @cycleSub.
  ///
  /// In en, this message translates to:
  /// **'Program “{name}” — step 2 of 3'**
  String cycleSub(String name);

  /// No description provided for @cycleNext.
  ///
  /// In en, this message translates to:
  /// **'Next — build the event chain'**
  String get cycleNext;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @dailyD.
  ///
  /// In en, this message translates to:
  /// **'The same chain runs on every day — ideal for fixed daily routines.'**
  String get dailyD;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @weeklyD.
  ///
  /// In en, this message translates to:
  /// **'Assign a chain to each day of the week (Sat–Fri); 7 slots.'**
  String get weeklyD;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @monthlyD.
  ///
  /// In en, this message translates to:
  /// **'Assign chains to days of month (1–31); 31 slots.'**
  String get monthlyD;

  /// No description provided for @annual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get annual;

  /// No description provided for @annualD.
  ///
  /// In en, this message translates to:
  /// **'The full Persian calendar year with 366 slots; the most precise seasonal planning.'**
  String get annualD;

  /// No description provided for @poolNote.
  ///
  /// In en, this message translates to:
  /// **'Note: events of all programs are stored in the shared device memory; repeated events across days are shared automatically.'**
  String get poolNote;

  /// No description provided for @priorityNote.
  ///
  /// In en, this message translates to:
  /// **'Daily execution priority: annual ← monthly ← weekly ← daily. If a day appears in several cycles, only the higher-priority cycle runs.'**
  String get priorityNote;

  /// No description provided for @chainTitle.
  ///
  /// In en, this message translates to:
  /// **'Event chain'**
  String get chainTitle;

  /// No description provided for @chainSub.
  ///
  /// In en, this message translates to:
  /// **'“{name}” — {cycle} cycle — step 3 of 3'**
  String chainSub(String name, String cycle);

  /// No description provided for @chainEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get chainEmptyTitle;

  /// No description provided for @chainEmptyText.
  ///
  /// In en, this message translates to:
  /// **'Add the first event of the chain — e.g. relay ON at a fixed time or after sunrise.'**
  String get chainEmptyText;

  /// No description provided for @chainEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Create an event chain'**
  String get chainEmptyCta;

  /// No description provided for @addEvent.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get addEvent;

  /// No description provided for @assignWeekly.
  ///
  /// In en, this message translates to:
  /// **'Assign to weekdays'**
  String get assignWeekly;

  /// No description provided for @assignMonthly.
  ///
  /// In en, this message translates to:
  /// **'Assign to days of month'**
  String get assignMonthly;

  /// No description provided for @assignAnnual.
  ///
  /// In en, this message translates to:
  /// **'Assign to days of year'**
  String get assignAnnual;

  /// No description provided for @dailyAutoNote.
  ///
  /// In en, this message translates to:
  /// **'Daily cycle: the chain is assigned to every day automatically; no day picking is needed.'**
  String get dailyAutoNote;

  /// No description provided for @currentAssignment.
  ///
  /// In en, this message translates to:
  /// **'Current assignment:'**
  String get currentAssignment;

  /// No description provided for @saveProgram.
  ///
  /// In en, this message translates to:
  /// **'Save program'**
  String get saveProgram;

  /// No description provided for @needEvent.
  ///
  /// In en, this message translates to:
  /// **'Add at least one event to the chain first'**
  String get needEvent;

  /// No description provided for @capacityBlock.
  ///
  /// In en, this message translates to:
  /// **'The device event memory is full (255 events).'**
  String get capacityBlock;

  /// No description provided for @programSaved.
  ///
  /// In en, this message translates to:
  /// **'Program “{name}” saved'**
  String programSaved(String name);

  /// No description provided for @programDeleted.
  ///
  /// In en, this message translates to:
  /// **'Program “{name}” deleted'**
  String programDeleted(String name);

  /// No description provided for @delTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete program'**
  String get delTitle;

  /// No description provided for @delText.
  ///
  /// In en, this message translates to:
  /// **'Program “{name}” and all of its commands will be removed from this phone’s list. To apply the change on the relay, run the NFC transfer afterwards.'**
  String delText(String name);

  /// No description provided for @evNew.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get evNew;

  /// No description provided for @evEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get evEdit;

  /// No description provided for @evSub.
  ///
  /// In en, this message translates to:
  /// **'Define the event type, output command and settings'**
  String get evSub;

  /// No description provided for @evType.
  ///
  /// In en, this message translates to:
  /// **'Run-time basis'**
  String get evType;

  /// No description provided for @evFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed clock time'**
  String get evFixed;

  /// No description provided for @evAstro.
  ///
  /// In en, this message translates to:
  /// **'Based on sunrise or sunset'**
  String get evAstro;

  /// No description provided for @evTimeFmt.
  ///
  /// In en, this message translates to:
  /// **'The run time is set in 24-hour format.'**
  String get evTimeFmt;

  /// No description provided for @hourRange.
  ///
  /// In en, this message translates to:
  /// **'Hour (0–23)'**
  String get hourRange;

  /// No description provided for @minuteRange.
  ///
  /// In en, this message translates to:
  /// **'Minute (0–59)'**
  String get minuteRange;

  /// No description provided for @sunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunrise;

  /// No description provided for @sunriseD.
  ///
  /// In en, this message translates to:
  /// **'Event time is computed from sunrise'**
  String get sunriseD;

  /// No description provided for @sunset.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunset;

  /// No description provided for @sunsetD.
  ///
  /// In en, this message translates to:
  /// **'Event time is computed from sunset'**
  String get sunsetD;

  /// No description provided for @offsetLabel.
  ///
  /// In en, this message translates to:
  /// **'Offset (0–60 min)'**
  String get offsetLabel;

  /// No description provided for @signLabel.
  ///
  /// In en, this message translates to:
  /// **'Offset direction relative to base time'**
  String get signLabel;

  /// No description provided for @afterBase.
  ///
  /// In en, this message translates to:
  /// **'After {base}'**
  String afterBase(String base);

  /// No description provided for @beforeBase.
  ///
  /// In en, this message translates to:
  /// **'Before {base}'**
  String beforeBase(String base);

  /// No description provided for @sunriseShort.
  ///
  /// In en, this message translates to:
  /// **'sunrise'**
  String get sunriseShort;

  /// No description provided for @sunsetShort.
  ///
  /// In en, this message translates to:
  /// **'sunset'**
  String get sunsetShort;

  /// No description provided for @signExample.
  ///
  /// In en, this message translates to:
  /// **'Example: {base} {sign} {n} min'**
  String signExample(String base, String sign, String n);

  /// No description provided for @signZero.
  ///
  /// In en, this message translates to:
  /// **'Zero offset = exactly at base time'**
  String get signZero;

  /// No description provided for @cmdTitle.
  ///
  /// In en, this message translates to:
  /// **'Output type (relay command)'**
  String get cmdTitle;

  /// No description provided for @cmdOn.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get cmdOn;

  /// No description provided for @cmdOff.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get cmdOff;

  /// No description provided for @cmdTimer.
  ///
  /// In en, this message translates to:
  /// **'Cyclic ON/OFF'**
  String get cmdTimer;

  /// No description provided for @cmdOnD.
  ///
  /// In en, this message translates to:
  /// **'ON command: the relay turns on at the event moment and stays on until the next event.'**
  String get cmdOnD;

  /// No description provided for @cmdOffD.
  ///
  /// In en, this message translates to:
  /// **'OFF command: the relay turns off at the event moment and stays off until the next event.'**
  String get cmdOffD;

  /// No description provided for @timerNote.
  ///
  /// In en, this message translates to:
  /// **'Cyclic ON/OFF timer: the relay stays on for the “ON duration”, then off for the “OFF duration”, and repeats this cycle. Each duration is set in minutes within the range of 5 to 720 minutes.'**
  String get timerNote;

  /// No description provided for @phaseOn.
  ///
  /// In en, this message translates to:
  /// **'ON duration'**
  String get phaseOn;

  /// No description provided for @phaseOff.
  ///
  /// In en, this message translates to:
  /// **'OFF duration'**
  String get phaseOff;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start state'**
  String get startLabel;

  /// No description provided for @startOn.
  ///
  /// In en, this message translates to:
  /// **'Start with relay ON'**
  String get startOn;

  /// No description provided for @startOff.
  ///
  /// In en, this message translates to:
  /// **'Start with relay OFF'**
  String get startOff;

  /// No description provided for @phaseErr.
  ///
  /// In en, this message translates to:
  /// **'The ON duration and the OFF duration must each be a multiple of 5 minutes within the range of 5 to 720 minutes.'**
  String get phaseErr;

  /// No description provided for @phaseInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid; the value must be a multiple of 5 minutes between 5 minutes and 12 hours.'**
  String get phaseInvalid;

  /// No description provided for @phaseSum.
  ///
  /// In en, this message translates to:
  /// **'Total: {n} min'**
  String phaseSum(String n);

  /// No description provided for @hourUnit.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get hourUnit;

  /// No description provided for @minUnit.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get minUnit;

  /// No description provided for @saveEvent.
  ///
  /// In en, this message translates to:
  /// **'Save event'**
  String get saveEvent;

  /// No description provided for @eventSaved.
  ///
  /// In en, this message translates to:
  /// **'Event saved'**
  String get eventSaved;

  /// No description provided for @eventRemoved.
  ///
  /// In en, this message translates to:
  /// **'Event removed from chain'**
  String get eventRemoved;

  /// No description provided for @timerErr.
  ///
  /// In en, this message translates to:
  /// **'The timer settings are invalid. Check the ON and OFF durations; each must be a multiple of 5 minutes within the range of 5 to 720 minutes.'**
  String get timerErr;

  /// No description provided for @cmdIgnored.
  ///
  /// In en, this message translates to:
  /// **'In timer mode the ON/OFF command is ignored.'**
  String get cmdIgnored;

  /// No description provided for @onCmd.
  ///
  /// In en, this message translates to:
  /// **'Command: relay ON'**
  String get onCmd;

  /// No description provided for @offCmd.
  ///
  /// In en, this message translates to:
  /// **'Command: relay OFF'**
  String get offCmd;

  /// No description provided for @timerCmd.
  ///
  /// In en, this message translates to:
  /// **'Command: flasher timer — ON {on} / OFF {off} · {start}'**
  String timerCmd(String on, String off, String start);

  /// No description provided for @startOnTxt.
  ///
  /// In en, this message translates to:
  /// **'relay turns ON first'**
  String get startOnTxt;

  /// No description provided for @startOffTxt.
  ///
  /// In en, this message translates to:
  /// **'relay turns OFF first'**
  String get startOffTxt;

  /// No description provided for @sunriseBase.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get sunriseBase;

  /// No description provided for @sunsetBase.
  ///
  /// In en, this message translates to:
  /// **'Sunset'**
  String get sunsetBase;

  /// No description provided for @astroFmt.
  ///
  /// In en, this message translates to:
  /// **'{base} {sign} {n} min'**
  String astroFmt(String base, String sign, String n);

  /// No description provided for @minFmt.
  ///
  /// In en, this message translates to:
  /// **'{h} h {m} min'**
  String minFmt(String h, String m);

  /// No description provided for @minOnlyFmt.
  ///
  /// In en, this message translates to:
  /// **'{m} min'**
  String minOnlyFmt(String m);

  /// No description provided for @asWeekly.
  ///
  /// In en, this message translates to:
  /// **'Assign to weekdays'**
  String get asWeekly;

  /// No description provided for @asMonthly.
  ///
  /// In en, this message translates to:
  /// **'Assign to days of month'**
  String get asMonthly;

  /// No description provided for @asAnnual.
  ///
  /// In en, this message translates to:
  /// **'Assign to days of year'**
  String get asAnnual;

  /// No description provided for @asSub.
  ///
  /// In en, this message translates to:
  /// **'Tap days to select or clear them (multi-select)'**
  String get asSub;

  /// No description provided for @asCount.
  ///
  /// In en, this message translates to:
  /// **'So far: {n} days selected'**
  String asCount(String n);

  /// No description provided for @asAnnualNote.
  ///
  /// In en, this message translates to:
  /// **'Selections are kept per month; move between months and keep selecting.'**
  String get asAnnualNote;

  /// No description provided for @asOk.
  ///
  /// In en, this message translates to:
  /// **'Confirm assignment'**
  String get asOk;

  /// No description provided for @asClear.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get asClear;

  /// No description provided for @asCleared.
  ///
  /// In en, this message translates to:
  /// **'Selection cleared'**
  String get asCleared;

  /// No description provided for @asSaved.
  ///
  /// In en, this message translates to:
  /// **'Day assignment saved'**
  String get asSaved;

  /// No description provided for @w0.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get w0;

  /// No description provided for @w1.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get w1;

  /// No description provided for @w2.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get w2;

  /// No description provided for @w3.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get w3;

  /// No description provided for @w4.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get w4;

  /// No description provided for @w5.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get w5;

  /// No description provided for @w6.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get w6;

  /// No description provided for @m0.
  ///
  /// In en, this message translates to:
  /// **'Farvardin'**
  String get m0;

  /// No description provided for @m1.
  ///
  /// In en, this message translates to:
  /// **'Ordibehesht'**
  String get m1;

  /// No description provided for @m2.
  ///
  /// In en, this message translates to:
  /// **'Khordad'**
  String get m2;

  /// No description provided for @m3.
  ///
  /// In en, this message translates to:
  /// **'Tir'**
  String get m3;

  /// No description provided for @m4.
  ///
  /// In en, this message translates to:
  /// **'Mordad'**
  String get m4;

  /// No description provided for @m5.
  ///
  /// In en, this message translates to:
  /// **'Shahrivar'**
  String get m5;

  /// No description provided for @m6.
  ///
  /// In en, this message translates to:
  /// **'Mehr'**
  String get m6;

  /// No description provided for @m7.
  ///
  /// In en, this message translates to:
  /// **'Aban'**
  String get m7;

  /// No description provided for @m8.
  ///
  /// In en, this message translates to:
  /// **'Azar'**
  String get m8;

  /// No description provided for @m9.
  ///
  /// In en, this message translates to:
  /// **'Dey'**
  String get m9;

  /// No description provided for @m10.
  ///
  /// In en, this message translates to:
  /// **'Bahman'**
  String get m10;

  /// No description provided for @m11.
  ///
  /// In en, this message translates to:
  /// **'Esfand'**
  String get m11;

  /// No description provided for @peTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit programs'**
  String get peTitle;

  /// No description provided for @peSub.
  ///
  /// In en, this message translates to:
  /// **'Manage saved timer programs'**
  String get peSub;

  /// No description provided for @peSummary.
  ///
  /// In en, this message translates to:
  /// **'{cycle} · {ev} events · {assign}'**
  String peSummary(String cycle, String ev, String assign);

  /// No description provided for @seTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get seTitle;

  /// No description provided for @seSub.
  ///
  /// In en, this message translates to:
  /// **'UI language and visual theme'**
  String get seSub;

  /// No description provided for @seLang.
  ///
  /// In en, this message translates to:
  /// **'UI language'**
  String get seLang;

  /// No description provided for @seLangD.
  ///
  /// In en, this message translates to:
  /// **'Persian (RTL) or English (LTR)'**
  String get seLangD;

  /// No description provided for @seFa.
  ///
  /// In en, this message translates to:
  /// **'فارسی'**
  String get seFa;

  /// No description provided for @seEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get seEn;

  /// No description provided for @seTheme.
  ///
  /// In en, this message translates to:
  /// **'Visual theme'**
  String get seTheme;

  /// No description provided for @seThemeD.
  ///
  /// In en, this message translates to:
  /// **'Light or Dark — both built from the design-system tokens'**
  String get seThemeD;

  /// No description provided for @seLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get seLight;

  /// No description provided for @seDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get seDark;

  /// No description provided for @heTitle.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get heTitle;

  /// No description provided for @heSub.
  ///
  /// In en, this message translates to:
  /// **'Working with the KIANEX app and PTS50N1'**
  String get heSub;

  /// No description provided for @heT1.
  ///
  /// In en, this message translates to:
  /// **'Getting started'**
  String get heT1;

  /// No description provided for @heD1.
  ///
  /// In en, this message translates to:
  /// **'Create a program with the orange “New Program” button: name, cycle (daily/weekly/monthly/annual), the event chain and execution days.'**
  String get heD1;

  /// No description provided for @heT2.
  ///
  /// In en, this message translates to:
  /// **'Fixed and solar events'**
  String get heT2;

  /// No description provided for @heD2.
  ///
  /// In en, this message translates to:
  /// **'An event can fire at a fixed clock time, or be tied to sunrise/sunset with a 0–60 minute offset (before or after the base time).'**
  String get heD2;

  /// No description provided for @heT3.
  ///
  /// In en, this message translates to:
  /// **'Flasher timer'**
  String get heT3;

  /// No description provided for @heD3.
  ///
  /// In en, this message translates to:
  /// **'In timer mode the relay alternates ON/OFF phases. Each phase is 5 minutes to 12 hours (multiple of 5) and you choose whether it starts with the ON or OFF phase.'**
  String get heD3;

  /// No description provided for @heT4.
  ///
  /// In en, this message translates to:
  /// **'Transfer to device'**
  String get heT4;

  /// No description provided for @heD4.
  ///
  /// In en, this message translates to:
  /// **'The orange hexagonal NFC button at the bottom of the screen has three modes: read device status, set time & location, and write programs to the device.'**
  String get heD4;

  /// No description provided for @heT5.
  ///
  /// In en, this message translates to:
  /// **'Time conflicts'**
  String get heT5;

  /// No description provided for @heD5.
  ///
  /// In en, this message translates to:
  /// **'Two events cannot run in the same minute; the app detects the conflict at save time and blocks it.'**
  String get heD5;

  /// No description provided for @heT6.
  ///
  /// In en, this message translates to:
  /// **'Failed write or connection'**
  String get heT6;

  /// No description provided for @heD6.
  ///
  /// In en, this message translates to:
  /// **'If a transfer stops at any stage, “Try again” restarts it from the beginning; you can also use “Back to the app” to return. After two consecutive failures, the power-cycle guidance is shown.'**
  String get heD6;

  /// No description provided for @heT7.
  ///
  /// In en, this message translates to:
  /// **'Memory capacity'**
  String get heT7;

  /// No description provided for @heD7.
  ///
  /// In en, this message translates to:
  /// **'The event memory holds 255 events and the timer memory 50 timers; all programs share this capacity. The capacity indicator appears in the program creation flow.'**
  String get heD7;

  /// No description provided for @abTitle.
  ///
  /// In en, this message translates to:
  /// **'About / App version'**
  String get abTitle;

  /// No description provided for @abVer.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get abVer;

  /// No description provided for @abMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get abMode;

  /// No description provided for @abModeV.
  ///
  /// In en, this message translates to:
  /// **'Full implementation — Phase 2'**
  String get abModeV;

  /// No description provided for @abTarget.
  ///
  /// In en, this message translates to:
  /// **'Target model'**
  String get abTarget;

  /// No description provided for @abImpl.
  ///
  /// In en, this message translates to:
  /// **'Implementation'**
  String get abImpl;

  /// No description provided for @abImplV.
  ///
  /// In en, this message translates to:
  /// **'Flutter + Material 3 (Android)'**
  String get abImplV;

  /// No description provided for @abSot.
  ///
  /// In en, this message translates to:
  /// **'Protocol & memory reference'**
  String get abSot;

  /// No description provided for @abSotV.
  ///
  /// In en, this message translates to:
  /// **'Source of Truth v3.1-Final + two CSV maps'**
  String get abSotV;

  /// No description provided for @abNote.
  ///
  /// In en, this message translates to:
  /// **'This build implements the real NFC layer (ISO 15693 / NFC Forum Type 5) behind the NfcService contract, together with the 8-step SOT write protocol, CRC verification and the relay power-off flows.'**
  String get abNote;

  /// No description provided for @dsheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Select device'**
  String get dsheetTitle;

  /// No description provided for @dsheetSub.
  ///
  /// In en, this message translates to:
  /// **'Pick the device from the product list, or identify it with an NFC scan.'**
  String get dsheetSub;

  /// No description provided for @dsheetCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get dsheetCurrent;

  /// No description provided for @dsheetNote.
  ///
  /// In en, this message translates to:
  /// **'In this release, the product list includes PTS50N1; future models will be added to this list.'**
  String get dsheetNote;

  /// No description provided for @addCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a new program'**
  String get addCardTitle;

  /// No description provided for @addCardDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new schedule for the device'**
  String get addCardDesc;

  /// No description provided for @emptyBtnRead.
  ///
  /// In en, this message translates to:
  /// **'Read device status'**
  String get emptyBtnRead;

  /// No description provided for @emptyBtnAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a new program'**
  String get emptyBtnAdd;

  /// No description provided for @metaFmt.
  ///
  /// In en, this message translates to:
  /// **'{on} ON commands | {off} OFF commands | {t} timer'**
  String metaFmt(String on, String off, String t);

  /// No description provided for @relay1.
  ///
  /// In en, this message translates to:
  /// **'Output 1'**
  String get relay1;

  /// No description provided for @viewEvents.
  ///
  /// In en, this message translates to:
  /// **'View event details'**
  String get viewEvents;

  /// No description provided for @progOnToast.
  ///
  /// In en, this message translates to:
  /// **'Program enabled'**
  String get progOnToast;

  /// No description provided for @progOffToast.
  ///
  /// In en, this message translates to:
  /// **'Program disabled'**
  String get progOffToast;

  /// No description provided for @progOffBadge.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get progOffBadge;

  /// No description provided for @chartMemTitle.
  ///
  /// In en, this message translates to:
  /// **'Program memory'**
  String get chartMemTitle;

  /// No description provided for @chartMemValue.
  ///
  /// In en, this message translates to:
  /// **'{u} of {m} event slots'**
  String chartMemValue(String u, String m);

  /// No description provided for @chartTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Timers'**
  String get chartTimerTitle;

  /// No description provided for @chartTimerValue.
  ///
  /// In en, this message translates to:
  /// **'{u} of {m} timer slots'**
  String chartTimerValue(String u, String m);

  /// No description provided for @wcAstroSide.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get wcAstroSide;

  /// No description provided for @wcSetSide.
  ///
  /// In en, this message translates to:
  /// **'3 sections'**
  String get wcSetSide;

  /// No description provided for @wcSetD2.
  ///
  /// In en, this message translates to:
  /// **'Time and Jalali calendar sync + sunrise/sunset calculation'**
  String get wcSetD2;

  /// No description provided for @wcBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get wcBack;

  /// No description provided for @wpClose.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get wpClose;

  /// No description provided for @wpBackApp.
  ///
  /// In en, this message translates to:
  /// **'Back to the app'**
  String get wpBackApp;

  /// No description provided for @wpBackToast.
  ///
  /// In en, this message translates to:
  /// **'You are back in the app; you can try again later.'**
  String get wpBackToast;

  /// No description provided for @dsIdentifyBtn.
  ///
  /// In en, this message translates to:
  /// **'Identify device with NFC scan'**
  String get dsIdentifyBtn;

  /// No description provided for @dsIdentifyD.
  ///
  /// In en, this message translates to:
  /// **'While scanning, the device model is detected automatically.'**
  String get dsIdentifyD;

  /// No description provided for @dsScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Identify device'**
  String get dsScanTitle;

  /// No description provided for @dsScanSub.
  ///
  /// In en, this message translates to:
  /// **'Hold the phone near the device NFC tag and keep it steady until identification finishes.'**
  String get dsScanSub;

  /// No description provided for @dsScanPh1.
  ///
  /// In en, this message translates to:
  /// **'Connecting to the device…'**
  String get dsScanPh1;

  /// No description provided for @dsScanPh2.
  ///
  /// In en, this message translates to:
  /// **'Reading device info…'**
  String get dsScanPh2;

  /// No description provided for @dsScanPh3.
  ///
  /// In en, this message translates to:
  /// **'Detecting the device model…'**
  String get dsScanPh3;

  /// No description provided for @dsFound.
  ///
  /// In en, this message translates to:
  /// **'Device identified'**
  String get dsFound;

  /// No description provided for @dsFoundD.
  ///
  /// In en, this message translates to:
  /// **'The device model was detected automatically and matched with the product list.'**
  String get dsFoundD;

  /// No description provided for @dsDoneToast.
  ///
  /// In en, this message translates to:
  /// **'Device model confirmed: PTS50N1'**
  String get dsDoneToast;

  /// No description provided for @asSelTitle.
  ///
  /// In en, this message translates to:
  /// **'Selected days'**
  String get asSelTitle;

  /// No description provided for @asNoneSelected.
  ///
  /// In en, this message translates to:
  /// **'No days selected yet'**
  String get asNoneSelected;

  /// No description provided for @asDayN.
  ///
  /// In en, this message translates to:
  /// **'Day {n}'**
  String asDayN(String n);

  /// No description provided for @asRemoveOne.
  ///
  /// In en, this message translates to:
  /// **'Remove this day from the selection'**
  String get asRemoveOne;

  /// No description provided for @asRemovedOne.
  ///
  /// In en, this message translates to:
  /// **'The day was removed from the selection list'**
  String get asRemovedOne;

  /// No description provided for @asRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get asRequired;

  /// No description provided for @needDays.
  ///
  /// In en, this message translates to:
  /// **'Assign the execution days of the chain before saving the program.'**
  String get needDays;

  /// No description provided for @needDaysHint.
  ///
  /// In en, this message translates to:
  /// **'Select execution days to enable the “Save program” button.'**
  String get needDaysHint;

  /// No description provided for @phaseRange.
  ///
  /// In en, this message translates to:
  /// **'Allowed range: 5 to 720 minutes — adjusted in 5-minute steps.'**
  String get phaseRange;

  /// No description provided for @countActiveFmt.
  ///
  /// In en, this message translates to:
  /// **'{n} active · {m} disabled'**
  String countActiveFmt(String n, String m);

  /// No description provided for @allDisabledToast.
  ///
  /// In en, this message translates to:
  /// **'All programs are disabled; disabled programs are not sent to the relay. Enable a program first.'**
  String get allDisabledToast;

  /// No description provided for @wcOffNote.
  ///
  /// In en, this message translates to:
  /// **'{m} disabled program(s) are not included in this transfer; disabled programs are not sent to the relay.'**
  String wcOffNote(String m);

  /// No description provided for @scPower.
  ///
  /// In en, this message translates to:
  /// **'Relay unpowered'**
  String get scPower;

  /// No description provided for @wpPwSetT.
  ///
  /// In en, this message translates to:
  /// **'Clock and location cannot be set'**
  String get wpPwSetT;

  /// No description provided for @wpPwSetM.
  ///
  /// In en, this message translates to:
  /// **'The relay has no power supply. In this state the clock, date and location cannot be stored on the relay, and the settings transfer was stopped. Restore the relay power supply and repeat this operation.'**
  String get wpPwSetM;

  /// No description provided for @wpPwAck.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get wpPwAck;

  /// No description provided for @wpPwSetToast.
  ///
  /// In en, this message translates to:
  /// **'The settings transfer was stopped; try again after restoring the relay power supply.'**
  String get wpPwSetToast;

  /// No description provided for @wpPwProgT.
  ///
  /// In en, this message translates to:
  /// **'The relay is unpowered'**
  String get wpPwProgT;

  /// No description provided for @wpPwProgM.
  ///
  /// In en, this message translates to:
  /// **'The relay has no power supply. In this state programs can be transferred, but the relay clock, date and location will not be updated. After restoring the relay power supply, send “Settings only” to update the clock and date.'**
  String get wpPwProgM;

  /// No description provided for @wpPwContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue sending'**
  String get wpPwContinue;

  /// No description provided for @wpPwCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get wpPwCancel;

  /// No description provided for @wpPwCancelled.
  ///
  /// In en, this message translates to:
  /// **'Program transfer was cancelled.'**
  String get wpPwCancelled;

  /// No description provided for @wpPwSkipped.
  ///
  /// In en, this message translates to:
  /// **'The relay clock and date are not updated in this operation.'**
  String get wpPwSkipped;

  /// No description provided for @wpDoneSubNoClock.
  ///
  /// In en, this message translates to:
  /// **'Programs were written to the relay and verified; the relay clock, date and location were not updated. After restoring the relay power supply, send “Settings only”.'**
  String wpDoneSubNoClock(String v);

  /// No description provided for @step4dNoClock.
  ///
  /// In en, this message translates to:
  /// **'Programs are stored in the relay memory; the clock and date are not updated.'**
  String get step4dNoClock;

  /// No description provided for @ruleTitle.
  ///
  /// In en, this message translates to:
  /// **'Command chain rules'**
  String get ruleTitle;

  /// No description provided for @ruleIntro.
  ///
  /// In en, this message translates to:
  /// **'In these rules, two commands placed back-to-back in the chain list with no other command between them are called consecutive commands.'**
  String get ruleIntro;

  /// No description provided for @ruleR1.
  ///
  /// In en, this message translates to:
  /// **'Two commands in one chain cannot have the same run time; simultaneous execution of two commands on one output is not permitted.'**
  String get ruleR1;

  /// No description provided for @ruleR2.
  ///
  /// In en, this message translates to:
  /// **'The interval between two consecutive commands must not be less than 5 minutes.'**
  String get ruleR2;

  /// No description provided for @ruleR3.
  ///
  /// In en, this message translates to:
  /// **'Two consecutive commands cannot have the same relay action; otherwise the relay output state would not change after the second command. If another command with a different action exists between the two, this rule does not apply.'**
  String get ruleR3;

  /// No description provided for @ruleR4.
  ///
  /// In en, this message translates to:
  /// **'Two consecutive commands cannot have identical timer settings; otherwise the output behaviour would repeat in both commands.'**
  String get ruleR4;

  /// No description provided for @ruleSameTime.
  ///
  /// In en, this message translates to:
  /// **'Commands {n1} and {n2} share the same run time ({t}). The run time of one of the two commands must be changed.'**
  String ruleSameTime(String n1, String n2, String t);

  /// No description provided for @ruleSameTimeSolar.
  ///
  /// In en, this message translates to:
  /// **'Commands {n1} and {n2} are both bound to the same solar moment with the same offset. The settings of one of the two commands must be changed.'**
  String ruleSameTimeSolar(String n1, String n2);

  /// No description provided for @ruleMinGap.
  ///
  /// In en, this message translates to:
  /// **'Commands {n1} and {n2} are {d} minute(s) apart ({t1} and {t2}); the minimum allowed interval between two consecutive commands is 5 minutes.'**
  String ruleMinGap(String n1, String n2, String d, String t1, String t2);

  /// No description provided for @ruleSameAct.
  ///
  /// In en, this message translates to:
  /// **'Commands {n1} and {n2} both perform “{act}” ({t1} and {t2}); two consecutive commands with the same relay action are not permitted, because the relay output state would not change.'**
  String ruleSameAct(String n1, String n2, String act, String t1, String t2);

  /// No description provided for @ruleSameTimer.
  ///
  /// In en, this message translates to:
  /// **'Commands {n1} and {n2} have identical timer settings ({t1} and {t2} · {tmr}); two consecutive commands with identical timer settings are not permitted, because the output behaviour would repeat.'**
  String ruleSameTimer(String n1, String n2, String t1, String t2, String tmr);

  /// No description provided for @ruleTimerFmt.
  ///
  /// In en, this message translates to:
  /// **'ON {on} / OFF {off}'**
  String ruleTimerFmt(String on, String off);

  /// No description provided for @rulesBlock.
  ///
  /// In en, this message translates to:
  /// **'Program not saved: {n} non-conformity item(s) with the command-chain rules.'**
  String rulesBlock(String n);

  /// No description provided for @evRuleSameTime.
  ///
  /// In en, this message translates to:
  /// **'This command shares the same run time ({t}) as command No. {n}; the run time of one of the two commands must be changed.'**
  String evRuleSameTime(String n, String t);

  /// No description provided for @evRuleSameTimeSolar.
  ///
  /// In en, this message translates to:
  /// **'This command is bound to the same solar moment with the same offset as command No. {n}; change the settings of one of the two commands.'**
  String evRuleSameTimeSolar(String n);

  /// No description provided for @evRuleMinGap.
  ///
  /// In en, this message translates to:
  /// **'This command is {d} minute(s) apart from command No. {n}; the minimum allowed interval between two consecutive commands is 5 minutes.'**
  String evRuleMinGap(String n, String d);

  /// No description provided for @evRuleSameAct.
  ///
  /// In en, this message translates to:
  /// **'This command and command No. {n} both perform “{act}”; two consecutive commands with the same relay action are not permitted, because the relay output state would not change.'**
  String evRuleSameAct(String n, String act);

  /// No description provided for @evRuleSameTimer.
  ///
  /// In en, this message translates to:
  /// **'This command and command No. {n} have identical timer settings; change the timer settings or the run time of one of the two commands.'**
  String evRuleSameTimer(String n);

  /// No description provided for @hourFmt.
  ///
  /// In en, this message translates to:
  /// **'{h} h'**
  String hourFmt(String h);

  /// No description provided for @gpsInvalid.
  ///
  /// In en, this message translates to:
  /// **'The entered value is not valid; latitude must be between −90 and 90 and longitude between −180 and 180.'**
  String get gpsInvalid;

  /// No description provided for @logTitle.
  ///
  /// In en, this message translates to:
  /// **'Application log'**
  String get logTitle;

  /// No description provided for @logSub.
  ///
  /// In en, this message translates to:
  /// **'Every application operation is recorded here with its exact time. Send the exported log file to the development team together with the field-test report.'**
  String get logSub;

  /// No description provided for @logCount.
  ///
  /// In en, this message translates to:
  /// **'{n} recorded events · {m} shown'**
  String logCount(String n, String m);

  /// No description provided for @logEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events recorded yet. After any operation (NFC session, location fix or program edit) the events appear on this page.'**
  String get logEmpty;

  /// No description provided for @logExport.
  ///
  /// In en, this message translates to:
  /// **'Save and share log'**
  String get logExport;

  /// No description provided for @logCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get logCopy;

  /// No description provided for @logClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get logClear;

  /// No description provided for @logShareSubject.
  ///
  /// In en, this message translates to:
  /// **'KIANEX PTS50N1 application log'**
  String get logShareSubject;

  /// No description provided for @logExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Sharing the log failed.'**
  String get logExportFailed;

  /// No description provided for @logCopiedToast.
  ///
  /// In en, this message translates to:
  /// **'The log was copied to the clipboard.'**
  String get logCopiedToast;

  /// No description provided for @logClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear the application log?'**
  String get logClearTitle;

  /// No description provided for @logClearText.
  ///
  /// In en, this message translates to:
  /// **'All recorded events will be deleted. This action cannot be undone.'**
  String get logClearText;

  /// No description provided for @logClearedToast.
  ///
  /// In en, this message translates to:
  /// **'The log was cleared.'**
  String get logClearedToast;

  /// No description provided for @logLevelNfc.
  ///
  /// In en, this message translates to:
  /// **'NFC'**
  String get logLevelNfc;

  /// No description provided for @logLevelGps.
  ///
  /// In en, this message translates to:
  /// **'GPS'**
  String get logLevelGps;

  /// No description provided for @logLevelAction.
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get logLevelAction;

  /// No description provided for @logLevelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get logLevelError;

  /// No description provided for @logLevelWarn.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get logLevelWarn;

  /// No description provided for @logLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logLevelInfo;

  /// No description provided for @seLogs.
  ///
  /// In en, this message translates to:
  /// **'Application log (logger)'**
  String get seLogs;

  /// No description provided for @seLogsD.
  ///
  /// In en, this message translates to:
  /// **'Automatic recording of all operations; the log file can be viewed, saved and shared.'**
  String get seLogsD;

  /// No description provided for @gpsGetFix.
  ///
  /// In en, this message translates to:
  /// **'Get position via GPS'**
  String get gpsGetFix;

  /// No description provided for @gpsFixing.
  ///
  /// In en, this message translates to:
  /// **'Reading the position…'**
  String get gpsFixing;

  /// No description provided for @gpsAccm.
  ///
  /// In en, this message translates to:
  /// **'Position accuracy: ±{m} m'**
  String gpsAccm(String m);

  /// No description provided for @gpsManual.
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates manually'**
  String get gpsManual;

  /// No description provided for @gpsDenied.
  ///
  /// In en, this message translates to:
  /// **'The location permission was not granted. Enable the “Location” permission for this application in the system settings.'**
  String get gpsDenied;

  /// No description provided for @gpsDeniedForever.
  ///
  /// In en, this message translates to:
  /// **'Location access is permanently denied. Enable the “Location” permission for this application in the system settings.'**
  String get gpsDeniedForever;

  /// No description provided for @gpsServiceOff.
  ///
  /// In en, this message translates to:
  /// **'The device location service is off. Turn it on in the system settings.'**
  String get gpsServiceOff;

  /// No description provided for @gpsTimeout.
  ///
  /// In en, this message translates to:
  /// **'Reading the position failed. Try again in a few moments.'**
  String get gpsTimeout;

  /// No description provided for @idModelWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag read — model not matched'**
  String get idModelWarnTitle;

  /// No description provided for @idModelWarnText.
  ///
  /// In en, this message translates to:
  /// **'The NDEF payload of the tag does not carry the KIANEX identifiers; the tag may not belong to a factory PST50R1 device. The NDEF message is shown below.'**
  String get idModelWarnText;

  /// No description provided for @idMemoryWarnText.
  ///
  /// In en, this message translates to:
  /// **'The tag memory is not large enough for the PST50R1 shared-memory layout; an ST25DV16K (512 blocks) or larger Type 5 tag is required.'**
  String get idMemoryWarnText;

  /// No description provided for @idTagModel.
  ///
  /// In en, this message translates to:
  /// **'Tag model'**
  String get idTagModel;

  /// No description provided for @idTagMemory.
  ///
  /// In en, this message translates to:
  /// **'Tag memory'**
  String get idTagMemory;

  /// No description provided for @idTagUid.
  ///
  /// In en, this message translates to:
  /// **'Tag UID'**
  String get idTagUid;

  /// No description provided for @idTagUri.
  ///
  /// In en, this message translates to:
  /// **'NDEF message'**
  String get idTagUri;

  /// No description provided for @idRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get idRetry;

  /// No description provided for @idFailTitle.
  ///
  /// In en, this message translates to:
  /// **'Device identification did not complete'**
  String get idFailTitle;

  /// No description provided for @idFailNoTag.
  ///
  /// In en, this message translates to:
  /// **'No NFC tag was read in range. First make sure the phone NFC is on; then hold the back of the phone near the tag on the device and keep it steady until identification finishes.'**
  String get idFailNoTag;

  /// No description provided for @idFailNotIso.
  ///
  /// In en, this message translates to:
  /// **'The presented tag is not NFC Forum Type 5 (ISO 15693) and is not compatible with this device.'**
  String get idFailNotIso;

  /// No description provided for @idFailModel.
  ///
  /// In en, this message translates to:
  /// **'The NDEF payload of the tag does not carry the KIANEX identifiers; the tag may belong to another device.'**
  String get idFailModel;

  /// No description provided for @idFailMemory.
  ///
  /// In en, this message translates to:
  /// **'The tag memory is not large enough for the shared-memory layout (at least 512 blocks of 4 bytes are required).'**
  String get idFailMemory;

  /// No description provided for @stNoTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading the device status failed'**
  String get stNoTagTitle;

  /// No description provided for @stNoTagText.
  ///
  /// In en, this message translates to:
  /// **'No NFC tag was read in range or the device did not answer. First make sure the phone NFC is on; then hold the back of the phone near the relay tag and press “Read again”.'**
  String get stNoTagText;

  /// No description provided for @stPressRefresh.
  ///
  /// In en, this message translates to:
  /// **'To read the device status, turn the phone NFC on, hold the back of the phone near the relay NFC tag and press “Read again”.'**
  String get stPressRefresh;

  /// No description provided for @asAnnualLeapNote.
  ///
  /// In en, this message translates to:
  /// **'Year {year} is a leap year; Esfand has 30 days and day 366 exists in the annual day grid.'**
  String asAnnualLeapNote(String year);

  /// No description provided for @idFailNfcOff.
  ///
  /// In en, this message translates to:
  /// **'The phone NFC adapter is not enabled. Turn NFC on from the quick settings and try again.'**
  String get idFailNfcOff;

  /// No description provided for @evFixedTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Run time'**
  String get evFixedTimeLabel;

  /// No description provided for @evFixedPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Set the run time'**
  String get evFixedPickerTitle;

  /// No description provided for @offsetPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Set the offset from sunrise/sunset'**
  String get offsetPickerTitle;

  /// No description provided for @offsetHint.
  ///
  /// In en, this message translates to:
  /// **'Offset from the astronomical base, 0 to 60 minutes in 5-minute steps.'**
  String get offsetHint;

  /// No description provided for @phaseOnLabel.
  ///
  /// In en, this message translates to:
  /// **'ON duration'**
  String get phaseOnLabel;

  /// No description provided for @phaseOffLabel.
  ///
  /// In en, this message translates to:
  /// **'OFF duration'**
  String get phaseOffLabel;

  /// No description provided for @phaseOnPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Set the ON duration'**
  String get phaseOnPickerTitle;

  /// No description provided for @phaseOffPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Set the OFF duration'**
  String get phaseOffPickerTitle;

  /// No description provided for @plusMinute.
  ///
  /// In en, this message translates to:
  /// **'+'**
  String get plusMinute;

  /// No description provided for @minusMinute.
  ///
  /// In en, this message translates to:
  /// **'−'**
  String get minusMinute;

  /// No description provided for @chainSortNote.
  ///
  /// In en, this message translates to:
  /// **'The chain is sorted automatically by execution time — sunrise commands first, then the fixed-time commands from 00:00, then the sunset commands. Every new command takes its time-based position on its own.'**
  String get chainSortNote;

  /// No description provided for @astroToday.
  ///
  /// In en, this message translates to:
  /// **'Today: {t}'**
  String astroToday(String t);

  /// No description provided for @overlapTitle.
  ///
  /// In en, this message translates to:
  /// **'Annual coincidence notice'**
  String get overlapTitle;

  /// No description provided for @overlapDetail.
  ///
  /// In en, this message translates to:
  /// **'The fixed command {time} coincides with the {base} command on {days} days of the year (from {from} to {to}).'**
  String overlapDetail(
      String time, String base, String days, String from, String to);

  /// No description provided for @overlapNote.
  ///
  /// In en, this message translates to:
  /// **'This is normal: sunrise and sunset move through the year. The device runs the commands in chain order; at the shared instant the later chain entry wins. You can keep or adjust the times.'**
  String get overlapNote;

  /// No description provided for @overlapAccept.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get overlapAccept;

  /// No description provided for @gateNfcOffTitle.
  ///
  /// In en, this message translates to:
  /// **'NFC is off'**
  String get gateNfcOffTitle;

  /// No description provided for @gateNfcOffText.
  ///
  /// In en, this message translates to:
  /// **'The NFC adapter of your phone is off. The app needs NFC to identify the relay and transfer programs. Please turn NFC on.'**
  String get gateNfcOffText;

  /// No description provided for @gateNfcMissing.
  ///
  /// In en, this message translates to:
  /// **'This phone has no NFC hardware — the relay cannot be reached from this device.'**
  String get gateNfcMissing;

  /// No description provided for @gateLocAsked.
  ///
  /// In en, this message translates to:
  /// **'Location permission requested — it is used only to find the sunrise and sunset times.'**
  String get gateLocAsked;

  /// No description provided for @gateLocPermTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get gateLocPermTitle;

  /// No description provided for @gateLocPermText.
  ///
  /// In en, this message translates to:
  /// **'The app needs the location permission to compute the sunrise and sunset times of your area. Please grant the permission in the app settings.'**
  String get gateLocPermText;

  /// No description provided for @gateLocServiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Location service is off'**
  String get gateLocServiceTitle;

  /// No description provided for @gateLocServiceText.
  ///
  /// In en, this message translates to:
  /// **'The phone\'s location service is off. Turn it on so the app can find your position for the sunrise/sunset calculation.'**
  String get gateLocServiceText;

  /// No description provided for @gateGoSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get gateGoSettings;

  /// No description provided for @gateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get gateLater;

  /// No description provided for @gateStripHint.
  ///
  /// In en, this message translates to:
  /// **'NFC or location is not ready — some features cannot work until it is fixed.'**
  String get gateStripHint;

  /// No description provided for @gpsMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the position on the map'**
  String get gpsMapTitle;

  /// No description provided for @gpsMapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere on the map to move the marker, then confirm.'**
  String get gpsMapHint;

  /// No description provided for @gpsPhonePos.
  ///
  /// In en, this message translates to:
  /// **'Phone position'**
  String get gpsPhonePos;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
