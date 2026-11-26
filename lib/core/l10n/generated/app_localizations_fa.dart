// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appName => 'KIANEX PTS50N1';

  @override
  String get brandSlogan => 'نوآوری که می‌ماند';

  @override
  String get deviceTitle => 'رله‌گاه فرمان تقویمی';

  @override
  String get deviceSub =>
      'تک‌رله ۵۰ آمپر · ارتباط NFC · چرخه روزانه، هفتگی، ماهانه و سالانه';

  @override
  String get deviceEngName => 'نام مهندسی در سند حقیقت: PST50R1';

  @override
  String get ok => 'تایید';

  @override
  String get confirm => 'تایید';

  @override
  String get cancel => 'انصراف';

  @override
  String get close => 'بستن';

  @override
  String get back => 'بازگشت';

  @override
  String get save => 'ذخیره';

  @override
  String get edit => 'ویرایش';

  @override
  String get delete => 'حذف';

  @override
  String get skip => 'رد شدن';

  @override
  String get next => 'ادامه';

  @override
  String get getStarted => 'شروع کار';

  @override
  String get obKicker1 => 'خوش آمدید';

  @override
  String get obTitle1 => 'KIANEX PTS50N1';

  @override
  String get obText1 =>
      'همراه برنامه‌ریزی رله‌گاه فرمان تقویمی شما. برنامه‌های زمانی را روی گوشی می‌سازید و با NFC به دستگاه می‌فرستید؛ دستگاه مستقل از گوشی اجرا می‌کند.';

  @override
  String get obKicker2 => 'ارتباط با دستگاه';

  @override
  String get obTitle2 => 'ارتباط با NFC';

  @override
  String get obText2 =>
      'تگ NFC دستگاه روی بدنه آن است. برای نوشتن، پشت گوشی را به دستگاه نزدیک کنید و تا پایان انتقال ثابت نگه دارید.';

  @override
  String get obPoint1 =>
      'گوشی بدون اپ هم تگ را می‌بیند و به صفحه محصول می‌رود (NDEF)';

  @override
  String get obPoint2 => 'نوشتن با پروتکل امن ۸ گامی انجام می‌شود';

  @override
  String get obPoint3 =>
      'در قطع شدن نوشتن، دستگاه با آخرین برنامه معتبر به کار ادامه می‌دهد';

  @override
  String get obKicker3 => 'شروع';

  @override
  String get obTitle3 => 'اولین برنامه را بسازید';

  @override
  String get obText3 =>
      'یک چرخه زمانی انتخاب کنید، رویدادها را در زنجیره بچینید و روزهای اجرا را تعیین کنید. هر وقت آماده بودید با دکمه شش‌ضلعی NFC به دستگاه بفرستید.';

  @override
  String get timerPrograms => 'برنامه‌های زمانی';

  @override
  String countPrograms(String n) {
    return '$n برنامه';
  }

  @override
  String get countEmpty => 'خالی';

  @override
  String get emptyTitle => 'هنوز برنامه‌ای تعریف نشده';

  @override
  String get emptyText =>
      'برای شروع، وضعیت دستگاه را بخوانید یا اولین برنامه زمانی را بسازید.\nبرنامه شامل چرخه زمانی، زنجیره رویدادها و روزهای اجرا است.';

  @override
  String get emptyCta => 'ساخت برنامه زمانی جدید';

  @override
  String get seedSample => 'نمایش با برنامه نمونه آزمایشی';

  @override
  String get newProgram => 'برنامه جدید';

  @override
  String get changeModel => 'تغییر مدل';

  @override
  String eventsInChain(String n) {
    return '$n رویداد در زنجیره';
  }

  @override
  String get allDays => 'همه روزها';

  @override
  String get noAssign => 'بدون اختصاص';

  @override
  String weekDaysOf(String n) {
    return '$n روز از هفته';
  }

  @override
  String monthDaysOf(String n) {
    return '$n روز از ماه';
  }

  @override
  String yearDaysOf(String n) {
    return '$n روز از سال';
  }

  @override
  String onDeviceRunning(String v) {
    return 'روی دستگاه: نسخه $v اجرا می‌شود';
  }

  @override
  String get menuEdit => 'ویرایش برنامه‌ها';

  @override
  String get menuStatus => 'وضعیت دستگاه';

  @override
  String get menuStatusSub => 'خواندن لاگر: ساعت کار، رویداد جاری، خطای داخلی';

  @override
  String get menuGps => 'تنظیمات موقعیت (GPS)';

  @override
  String get menuGpsSub => 'مبنای محاسبه طلوع و غروب خورشید';

  @override
  String get menuSettings => 'تنظیمات';

  @override
  String get menuSettingsSub => 'زبان و تم';

  @override
  String get menuHelp => 'راهنما';

  @override
  String get menuAbout => 'درباره ما / نسخه نرم‌افزار';

  @override
  String get editProgram => 'ویرایش برنامه';

  @override
  String get deleteProgram => 'حذف برنامه';

  @override
  String capacityEvents(String e) {
    return 'رویدادها $e از ۲۵۵';
  }

  @override
  String capacityTimers(String t) {
    return 'تایمرها $t از ۵۰';
  }

  @override
  String get nfcSheetTitle => 'ارتباط با دستگاه PTS50N1';

  @override
  String get nfcSheetSub =>
      'یکی از عملیات زیر را انتخاب کنید. سپس پشت گوشی را به محل تگ NFC روی رله نزدیک کنید و تا پایان عملیات ثابت نگه دارید.';

  @override
  String get readStatusT => 'خواندن وضعیت دستگاه';

  @override
  String get readStatusD =>
      'خواندن ناحیه لاگر: شماره برنامه در حال اجرا، رویداد جاری، شمارنده‌های کارکرد و خطای داخلی';

  @override
  String get settingsOnlyT => 'تنظیم زمان و موقعیت';

  @override
  String get settingsOnlyD =>
      'تنظیم ساعت رله و ثبت موقعیت مکانی برای محاسبه زمان طلوع و غروب خورشید';

  @override
  String get programWriteT => 'نوشتن برنامه‌ها روی دستگاه';

  @override
  String get programWriteD =>
      'ارسال برنامه‌های فعال زمان‌بندی‌شده و تنظیمات به حافظه رله؛ برنامه‌های غیرفعال ارسال نمی‌شوند';

  @override
  String get noProgramsToast =>
      'هنوز برنامه‌ای برای ارسال ندارید. ابتدا یک برنامه زمان‌بندی‌شده بسازید یا گزینه «فقط تنظیمات» را انتخاب کنید.';

  @override
  String get wcTitleSet => 'تأیید انتقال — فقط تنظیمات';

  @override
  String get wcTitleProg => 'تأیید انتقال — برنامه‌ها و تنظیمات';

  @override
  String get wcSub =>
      'پیش از شروع، فهرست نوشتنی را بازبینی کنید؛ گوشی را در تمام مراحل نزدیک دستگاه و ثابت نگه دارید.';

  @override
  String get wcTime => 'همگام‌سازی ساعت و تقویم';

  @override
  String get wcTimeD => 'زمان و تاریخ شمسی گوشی روی دستگاه نوشته می‌شود';

  @override
  String get wcAstro => 'محاسبه طلوع و غروب خورشید';

  @override
  String get wcAstroD =>
      'بر اساس موقعیت فعلی — زمان طلوع و غروب به‌طور خودکار محاسبه می‌شود';

  @override
  String get wcPrograms => 'برنامه‌های زمانی';

  @override
  String wcProgramsD(String n, String e, String t) {
    return '$n برنامه با $e رویداد و $t تایمر';
  }

  @override
  String get wcVersion => 'نسخه جدید برنامه';

  @override
  String wcVersionD(String v) {
    return 'پس از نوشتن موفق، این نسخه روی دستگاه اعمال می‌شود';
  }

  @override
  String get wcCapacity => 'ظرفیت حافظه دستگاه';

  @override
  String wcCapacityD(String e, String t) {
    return 'رویدادها $e از ۲۵۵ · تایمرها $t از ۵۰';
  }

  @override
  String get wcScenario => 'سناریوهای آزمایش انتقال — ابزار بازبینی طراحی';

  @override
  String get scOk => 'انتقال موفق';

  @override
  String get scBusy => 'دستگاه مشغول';

  @override
  String get scRf => 'قطع ارتباط در میانه انتقال';

  @override
  String get scCrc => 'ناهمخوانی در صحت‌سنجی';

  @override
  String get scModel => 'ناهمخوانی مدل دستگاه';

  @override
  String get wcStart => 'شروع انتقال';

  @override
  String get keepSteady =>
      'گوشی را ثابت نگه دارید و تا پایان انتقال آن را از دستگاه دور نکنید';

  @override
  String get wpTitle => 'در حال انتقال اطلاعات به دستگاه';

  @override
  String attemptOf(String n) {
    return 'تلاش $n از ۲';
  }

  @override
  String get wpPolling => 'در انتظار آماده شدن دستگاه…';

  @override
  String get wpCancel => 'لغو';

  @override
  String get wpDoneTitle => 'انتقال انجام شد';

  @override
  String wpDoneSub(String v) {
    return 'نسخه $v با موفقیت روی دستگاه نوشته و صحت‌سنجی شد؛ دستگاه برنامه جدید را اعمال می‌کند.';
  }

  @override
  String get wpDoneGo => 'دیدن وضعیت دستگاه';

  @override
  String get wpFailTitle => 'انتقال ناتمام ماند';

  @override
  String wpFailStep(String step) {
    return 'انتقال در مرحله «$step» ناتمام ماند.';
  }

  @override
  String get wpFailBusy =>
      'دستگاه پس از چند لحظه آزاد نشد؛ کمی بعد دوباره تلاش کنید.';

  @override
  String get wpRetryHint => 'طبق سند حقیقت، پروتکل از گام ۱ تکرار می‌شود.';

  @override
  String get wpRetryFromStep1 => 'تلاش دوباره';

  @override
  String get wpPowerOff => 'راهنمای قطع و وصل برق دستگاه';

  @override
  String get step1 => 'آماده‌سازی و شناسایی دستگاه';

  @override
  String get step1d => 'تطبیق مدل دستگاه با اپلیکیشن';

  @override
  String get step2 => 'بررسی وضعیت دستگاه';

  @override
  String get step2d => 'کنترل سلامت و آمادگی برای دریافت اطلاعات';

  @override
  String get step3 => 'شروع انتقال';

  @override
  String get step3d => 'باز شدن مسیر امن انتقال اطلاعات';

  @override
  String get step4 => 'نوشتن برنامه‌ها و تنظیمات';

  @override
  String get step4d => 'انتقال اطلاعات به حافظه دستگاه';

  @override
  String get step5 => 'تکمیل نوشتن';

  @override
  String get step5d => 'پایان‌بخشیدن به مرحله انتقال اطلاعات';

  @override
  String get step6 => 'بازخوانی اطلاعات';

  @override
  String get step6d => 'خواندن مجدد برای اطمینان از درستی انتقال';

  @override
  String get step7 => 'صحت‌سنجی اطلاعات';

  @override
  String get step7d => 'مقایسه اطلاعات نوشته‌شده با نسخه اصلی';

  @override
  String get step8 => 'فعال‌سازی نسخه جدید';

  @override
  String get step8d => 'دستگاه برنامه جدید را اجرا می‌کند';

  @override
  String get rcTitle => 'ارتباط برقرار نشد';

  @override
  String get rcSub => 'دو تلاش کامل ناموفق بود — طبق RC-10 سند حقیقت';

  @override
  String get rcMsgTitle => 'پیام به کاربر (پیشنهاد متن OI-02)';

  @override
  String get rcMsg =>
      'ارتباط با دستگاه برقرار نشد. لطفاً برق دستگاه را یک‌بار قطع و وصل کنید و پس از روشن شدن مجدد، انتقال را تلاش کنید. اگر باز هم ناموفق بود، برنامه‌ریزی را در حالت خاموش بودن دستگاه انجام دهید.';

  @override
  String get rcS1 => 'برق دستگاه را قطع کنید';

  @override
  String get rcS1d =>
      'فیوز یا کلید مربوط به دستگاه را باز کنید و چند ثانیه صبر کنید.';

  @override
  String get rcS2 => 'دستگاه را دوباره وصل کنید';

  @override
  String get rcS2d =>
      'دستگاه ری‌ست می‌شود و تگ آزاد می‌شود؛ سپس دکمه NFC را بزنید.';

  @override
  String get rcS3 => 'یا در حالت خاموش برنامه‌ریزی کنید';

  @override
  String get rcS3d =>
      'وقتی دستگاه خاموش است، انتقال اطلاعات پایدارتر انجام می‌شود.';

  @override
  String get rcRetry => 'تلاش مجدد';

  @override
  String get rcBack => 'بازگشت';

  @override
  String get stTitle => 'وضعیت دستگاه';

  @override
  String get stSub => 'وضعیت به‌روز دستگاه پس از آخرین خواندن';

  @override
  String get stVersionCard => 'نسخه برنامه';

  @override
  String get stOnDevice => 'روی دستگاه';

  @override
  String get stLastWritten => 'آخرین نوشته‌شده';

  @override
  String get stSynced => 'همگام — همین نسخه اجرا می‌شود';

  @override
  String get stPending => 'در انتظار تأیید دستگاه';

  @override
  String get stOutdated => 'برنامه جدیدی روی دستگاه نیست — ارسال کنید';

  @override
  String get stOngoing => 'رویداد در حال اجرا';

  @override
  String get stOngoingNone => 'رویداد فعالی در این لحظه اجرا نمی‌شود';

  @override
  String get stRelayOn => 'رله: روشن';

  @override
  String get stRelayOff => 'رله: خاموش';

  @override
  String get stCounters => 'شمارنده‌های کارکرد';

  @override
  String get stHour => 'ساعت کار کل';

  @override
  String get stHourOn => 'ساعت فعال بودن خروجی';

  @override
  String get stCn => 'تعداد عملکرد رله';

  @override
  String get stErrCard => 'خطای داخلی';

  @override
  String get stErrNone => 'خطایی ثبت نشده است';

  @override
  String get stErrCode => 'کد غیرصفر ثبت شده — ساختار کدها موضوع باز OI-01 است';

  @override
  String get stErrHint =>
      'در صورت مشاهده این خطا، دستگاه را بازبینی کنید یا با پشتیبانی تماس بگیرید.';

  @override
  String get stTech => 'جزئیات فنی دستگاه';

  @override
  String get stLastRead => 'آخرین خواندن';

  @override
  String get stReadSeq => 'داده‌ها با موفقیت از دستگاه خوانده و صحت‌سنجی شد.';

  @override
  String get stRefresh => 'خواندن مجدد';

  @override
  String get gpsTitle => 'تنظیمات موقعیت (GPS)';

  @override
  String get gpsSub => 'موقعیت مبنای محاسبه رویدادهای نجومی دستگاه';

  @override
  String get gpsCoords => 'مختصات فعلی';

  @override
  String get gpsLat => 'عرض جغرافیایی';

  @override
  String get gpsLng => 'طول جغرافیایی';

  @override
  String get gpsUpdated => 'آخرین به‌روزرسانی';

  @override
  String get gpsRefresh => 'به‌روزرسانی موقعیت';

  @override
  String get gpsUpdatedToast => 'موقعیت مکانی ذخیره شد.';

  @override
  String get gpsUse =>
      'کاربرد موقعیت: اپ با برازش چبیشف روی نمونه‌های سالانه طلوع/غروب، ۲۴ ضریب ۱۶ بیتی Q14 می‌سازد و در بلوک ۴۱۶ تا ۴۲۷ می‌نویسد. MCU روزانه با ارزیابی نقطه‌ثابت زمان طلوع و غروب را محاسبه می‌کند.';

  @override
  String get gpsAccuracy => 'دقت ±۱۵ متر';

  @override
  String get gpsPin => 'موقعیت فعلی';

  @override
  String get nameDialogTitle => 'برنامه جدید';

  @override
  String get nameDialogQ => 'یک نام برای شناسایی برنامه انتخاب کنید.';

  @override
  String get nameLabel => 'نام برنامه';

  @override
  String get nameHint => 'مثلاً: روشنایی محوطه';

  @override
  String get nameErr => 'نام برنامه را وارد کنید';

  @override
  String get cancelled => 'ایجاد برنامه لغو شد';

  @override
  String get cycleTitle => 'انتخاب چرخه زمانی';

  @override
  String cycleSub(String name) {
    return 'برنامه «$name» — گام ۲ از ۳';
  }

  @override
  String get cycleNext => 'مرحله بعد — ساخت زنجیره رویدادها';

  @override
  String get daily => 'روزانه';

  @override
  String get dailyD =>
      'زنجیره در همه روزها یکسان اجرا می‌شود؛ مناسب برنامه‌های ثابت هر روز.';

  @override
  String get weekly => 'هفتگی';

  @override
  String get weeklyD =>
      'به هر روز هفته (شنبه تا جمعه) می‌توانید یک زنجیره اختصاص دهید؛ ۷ روز.';

  @override
  String get monthly => 'ماهانه';

  @override
  String get monthlyD =>
      'به هر روز ماه (۱ تا ۳۱) می‌توانید زنجیره اختصاص دهید؛ ۳۱ خانه.';

  @override
  String get annual => 'سالانه';

  @override
  String get annualD =>
      'تقویم کامل سال شمسی با ۳۶۶ خانه؛ دقیق‌ترین حالت برنامه‌ریزی فصلی.';

  @override
  String get poolNote =>
      'توجه: رویدادهای همه برنامه‌ها در حافظه مشترک دستگاه ذخیره می‌شوند و رویدادهای تکراری بین روزها به‌صورت خودکار اشتراک گذاری می‌شوند.';

  @override
  String get priorityNote =>
      'اولویت اجرا در یک روز: سالانه ← ماهانه ← هفتگی ← روزانه. اگر روزی در چند چرخه برنامه داشته باشد، فقط چرخه با اولویت بالاتر اجرا می‌شود.';

  @override
  String get chainTitle => 'زنجیره رویدادها';

  @override
  String chainSub(String name, String cycle) {
    return '«$name» — چرخه $cycle — گام ۳ از ۳';
  }

  @override
  String get chainEmptyTitle => 'هنوز رویدادی تعریف نشده';

  @override
  String get chainEmptyText =>
      'اولین رویداد زنجیره را اضافه کنید؛ مثلاً روشن شدن رله در ساعت مشخص یا پس از طلوع آفتاب.';

  @override
  String get chainEmptyCta => 'یک زنجیره رویداد بسازید';

  @override
  String get addEvent => 'افزودن رویداد';

  @override
  String get assignWeekly => 'اختصاص به روزهای هفته';

  @override
  String get assignMonthly => 'اختصاص به روزهای ماه';

  @override
  String get assignAnnual => 'اختصاص به روزهای سال';

  @override
  String get dailyAutoNote =>
      'چرخه روزانه: زنجیره به‌صورت خودکار به همه روزها اختصاص می‌یابد و نیازی به انتخاب روز نیست.';

  @override
  String get currentAssignment => 'اختصاص فعلی:';

  @override
  String get saveProgram => 'ثبت برنامه';

  @override
  String get needEvent => 'اول حداقل یک رویداد به زنجیره اضافه کنید';

  @override
  String get capacityBlock => 'حافظه رویدادهای دستگاه پر است (۲۵۵ رویداد).';

  @override
  String programSaved(String name) {
    return 'برنامه «$name» ثبت شد';
  }

  @override
  String programDeleted(String name) {
    return 'برنامه «$name» حذف شد';
  }

  @override
  String get delTitle => 'حذف برنامه';

  @override
  String delText(String name) {
    return 'برنامه «$name» و تمام دستورات آن از فهرست همین گوشی حذف می‌شوند؛ برای اعمال روی رله، پس از حذف، انتقال NFC را انجام دهید.';
  }

  @override
  String get evNew => 'رویداد جدید';

  @override
  String get evEdit => 'ویرایش رویداد';

  @override
  String get evSub => 'نوع رویداد، فرمان خروجی و تنظیمات را مشخص کنید';

  @override
  String get evType => 'مبنای زمان اجرا';

  @override
  String get evFixed => 'ساعت مشخص';

  @override
  String get evAstro => 'بر اساس طلوع یا غروب';

  @override
  String get evTimeFmt => 'زمان اجرا در قالب ۲۴ ساعته تنظیم می‌شود.';

  @override
  String get hourRange => 'ساعت (۰–۲۳)';

  @override
  String get minuteRange => 'دقیقه (۰–۵۹)';

  @override
  String get sunrise => 'طلوع آفتاب';

  @override
  String get sunriseD => 'رویداد در زمان طلوع خورشید محاسبه می‌شود';

  @override
  String get sunset => 'غروب آفتاب';

  @override
  String get sunsetD => 'رویداد در زمان غروب خورشید محاسبه می‌شود';

  @override
  String get offsetLabel => 'انحراف (۰–۶۰ دقیقه)';

  @override
  String get signLabel => 'جهت انحراف نسبت به زمان پایه';

  @override
  String afterBase(String base) {
    return 'بعد از $base';
  }

  @override
  String beforeBase(String base) {
    return 'قبل از $base';
  }

  @override
  String get sunriseShort => 'طلوع';

  @override
  String get sunsetShort => 'غروب';

  @override
  String signExample(String base, String sign, String n) {
    return 'مثال: $base $sign $n دقیقه';
  }

  @override
  String get signZero => 'انحراف صفر = دقیقاً در زمان پایه';

  @override
  String get cmdTitle => 'نوع خروجی (فرمان رله)';

  @override
  String get cmdOn => 'روشن';

  @override
  String get cmdOff => 'خاموش';

  @override
  String get cmdTimer => 'روشن/خاموش متناوب';

  @override
  String get cmdOnD =>
      'فرمان روشن: رله در لحظه وقوع رویداد روشن می‌شود و تا رویداد بعدی در همین وضعیت می‌ماند.';

  @override
  String get cmdOffD =>
      'فرمان خاموش: رله در لحظه وقوع رویداد خاموش می‌شود و تا رویداد بعدی در همین وضعیت می‌ماند.';

  @override
  String get timerNote =>
      'تایمر روشن/خاموش متناوب: رله به مدت «مدت روشن بودن» روشن می‌ماند، سپس به مدت «مدت خاموش بودن» خاموش می‌شود و این چرخه تکرار می‌شود. هر مدت بر حسب دقیقه و در بازه ۵ تا ۷۲۰ دقیقه تنظیم می‌شود.';

  @override
  String get phaseOn => 'مدت روشن بودن';

  @override
  String get phaseOff => 'مدت خاموش بودن';

  @override
  String get startLabel => 'وضعیت شروع';

  @override
  String get startOn => 'شروع با رله روشن';

  @override
  String get startOff => 'شروع با رله خاموش';

  @override
  String get phaseErr =>
      'مدت روشن بودن و مدت خاموش بودن باید هرکدام مضربی از ۵ دقیقه و در بازه ۵ تا ۷۲۰ دقیقه باشند.';

  @override
  String get phaseInvalid =>
      'نامعتبر؛ مقدار باید مضربی از ۵ دقیقه و بین ۵ دقیقه تا ۱۲ ساعت باشد.';

  @override
  String phaseSum(String n) {
    return 'مجموع: $n دقیقه';
  }

  @override
  String get hourUnit => 'ساعت';

  @override
  String get minUnit => 'دقیقه';

  @override
  String get saveEvent => 'ثبت رویداد';

  @override
  String get eventSaved => 'رویداد ثبت شد';

  @override
  String get eventRemoved => 'رویداد از زنجیره حذف شد';

  @override
  String get timerErr =>
      'تنظیم تایمر معتبر نیست. مدت روشن بودن و مدت خاموش بودن را بررسی کنید؛ هرکدام باید مضربی از ۵ دقیقه و در بازه ۵ تا ۷۲۰ دقیقه باشد.';

  @override
  String get cmdIgnored =>
      'در حالت تایمر، فرمان روشن/خاموش نادیده گرفته می‌شود.';

  @override
  String get onCmd => 'فرمان: روشن شدن رله';

  @override
  String get offCmd => 'فرمان: خاموش شدن رله';

  @override
  String timerCmd(String on, String off, String start) {
    return 'فرمان: تایمر فلاشر — فاز روشن $on / فاز خاموش $off · $start';
  }

  @override
  String get startOnTxt => 'ابتدا رله روشن می‌شود';

  @override
  String get startOffTxt => 'ابتدا رله خاموش می‌شود';

  @override
  String get sunriseBase => 'طلوع آفتاب';

  @override
  String get sunsetBase => 'غروب آفتاب';

  @override
  String astroFmt(String base, String sign, String n) {
    return '$base $sign $n دقیقه';
  }

  @override
  String minFmt(String h, String m) {
    return '$h ساعت $m دقیقه';
  }

  @override
  String minOnlyFmt(String m) {
    return '$m دقیقه';
  }

  @override
  String get asWeekly => 'اختصاص به روزهای هفته';

  @override
  String get asMonthly => 'اختصاص به روزهای ماه';

  @override
  String get asAnnual => 'اختصاص به روزهای سال';

  @override
  String get asSub => 'روی روزها بزنید تا انتخاب یا لغو شوند (چند انتخابی)';

  @override
  String asCount(String n) {
    return 'تاکنون: $n روز انتخاب شده است';
  }

  @override
  String get asAnnualNote =>
      'روزهای انتخاب‌شده در هر ماه ذخیره می‌شوند؛ بین ماه‌ها جابه‌جا شوید و انتخاب‌ها را ادامه دهید.';

  @override
  String get asOk => 'تایید اختصاص';

  @override
  String get asClear => 'پاک‌کردن انتخاب‌ها';

  @override
  String get asCleared => 'انتخاب‌ها پاک شد';

  @override
  String get asSaved => 'اختصاص روزها ذخیره شد';

  @override
  String get w0 => 'شنبه';

  @override
  String get w1 => 'یکشنبه';

  @override
  String get w2 => 'دوشنبه';

  @override
  String get w3 => 'سه‌شنبه';

  @override
  String get w4 => 'چهارشنبه';

  @override
  String get w5 => 'پنجشنبه';

  @override
  String get w6 => 'جمعه';

  @override
  String get m0 => 'فروردین';

  @override
  String get m1 => 'اردیبهشت';

  @override
  String get m2 => 'خرداد';

  @override
  String get m3 => 'تیر';

  @override
  String get m4 => 'مرداد';

  @override
  String get m5 => 'شهریور';

  @override
  String get m6 => 'مهر';

  @override
  String get m7 => 'آبان';

  @override
  String get m8 => 'آذر';

  @override
  String get m9 => 'دی';

  @override
  String get m10 => 'بهمن';

  @override
  String get m11 => 'اسفند';

  @override
  String get peTitle => 'ویرایش برنامه‌ها';

  @override
  String get peSub => 'مدیریت برنامه‌های زمانی ذخیره‌شده';

  @override
  String peSummary(String cycle, String ev, String assign) {
    return '$cycle · $ev رویداد · $assign';
  }

  @override
  String get seTitle => 'تنظیمات';

  @override
  String get seSub => 'زبان رابط کاربری و تم بصری';

  @override
  String get seLang => 'زبان رابط کاربری';

  @override
  String get seLangD => 'فارسی (راست‌به‌چپ) یا English (چپ‌به‌راست)';

  @override
  String get seFa => 'فارسی';

  @override
  String get seEn => 'English';

  @override
  String get seTheme => 'تم بصری';

  @override
  String get seThemeD =>
      'روشن یا تیره — هر دو از توکن‌های سیستم طراحی ساخته می‌شوند';

  @override
  String get seLight => 'روشن';

  @override
  String get seDark => 'تیره';

  @override
  String get heTitle => 'راهنما';

  @override
  String get heSub => 'کار با اپلیکشن KIANEX و دستگاه PTS50N1';

  @override
  String get heT1 => 'شروع کار';

  @override
  String get heD1 =>
      'از دکمه نارنجی «برنامه جدید» یک برنامه زمانی بسازید: نام برنامه، چرخه زمانی (روزانه/هفتگی/ماهانه/سالانه)، زنجیره رویدادها و روزهای اجرا.';

  @override
  String get heT2 => 'رویداد زمانی و نجومی';

  @override
  String get heD2 =>
      'رویداد می‌تواند در ساعت مشخصی از شبانه‌روز رخ دهد یا به طلوع/غروب خورشید با انحراف ۰ تا ۶۰ دقیقه (قبل یا بعد از زمان پایه) متصل باشد.';

  @override
  String get heT3 => 'تایمر فلاشر';

  @override
  String get heD3 =>
      'در حالت تایمر، رله به‌صورت متناوب بین فاز روشن و خاموش تغییر می‌کند. هر فاز بین ۵ دقیقه تا ۱۲ ساعت (مضرب ۵ دقیقه) است و می‌توانید شروع را با فاز روشن یا خاموش تعیین کنید.';

  @override
  String get heT4 => 'انتقال به دستگاه';

  @override
  String get heD4 =>
      'دکمه شش‌ضلعی نارنجی NFC در پایین صفحه سه حالت دارد: خواندن وضعیت دستگاه، تنظیم زمان و موقعیت، و نوشتن برنامه‌ها روی دستگاه.';

  @override
  String get heT5 => 'تعارض زمانی';

  @override
  String get heD5 =>
      'دو رویداد نمی‌توانند در یک دقیقه اجرا شوند؛ اپ در لحظه ثبت رویداد، تعارض را پیدا می‌کند و اجازه ذخیره نمی‌دهد.';

  @override
  String get heT6 => 'قطع نوشتن یا خطای ارتباط';

  @override
  String get heD6 =>
      'اگر انتقال در یکی از مراحل ناتمام بماند، با «تلاش دوباره» از ابتدا انجام می‌شود؛ همچنین می‌توانید با «بازگشت به برنامه» به محیط اپ برگردید. پس از دو شکست پیاپی، راهنمای قطع و وصل برق دستگاه نمایش داده می‌شود.';

  @override
  String get heT7 => 'ظرفیت حافظه';

  @override
  String get heD7 =>
      'حافظه رویدادها ۲۵۵ رویداد و حافظه تایمر ۵۰ تایمر دارد؛ همه برنامه‌ها از همین ظرفیت مشترک استفاده می‌کنند. نشانگر ظرفیت در جریان ساخت برنامه دیده می‌شود.';

  @override
  String get abTitle => 'درباره ما / نسخه نرم‌افزار';

  @override
  String get abVer => 'نسخه نرم‌افزار';

  @override
  String get abMode => 'حالت';

  @override
  String get abModeV => 'پیاده‌سازی کامل اپلیکیشن — فاز ۲';

  @override
  String get abTarget => 'مدل هدف';

  @override
  String get abImpl => 'پیاده‌سازی';

  @override
  String get abImplV => 'Flutter + Material 3 (Android)';

  @override
  String get abSot => 'مرجع پروتکل و حافظه';

  @override
  String get abSotV => 'سند حقیقت v3.1-Final + دو نقشه CSV';

  @override
  String get abNote =>
      'این نسخه لایه NFC واقعی (ISO 15693 / NFC Forum Type 5) را پشت قرارداد NfcService پیاده می‌کند و پروتکل نوشتن ۸ گامی سند حقیقت، صحت‌سنجی CRC و سناریوهای قطع تغذیه رله را شامل می‌شود.';

  @override
  String get dsheetTitle => 'انتخاب دستگاه';

  @override
  String get dsheetSub =>
      'دستگاه مورد نظر را از فهرست محصولات انتخاب کنید یا با اسکن NFC شناسایی‌اش کنید.';

  @override
  String get dsheetCurrent => 'فعلی';

  @override
  String get dsheetNote =>
      'در این نسخه، فهرست محصولات شامل PTS50N1 است؛ مدل‌های بعدی به همین فهرست اضافه خواهند شد.';

  @override
  String get addCardTitle => 'افزودن برنامه جدید';

  @override
  String get addCardDesc => 'ساخت برنامه زمانی جدید برای دستگاه';

  @override
  String get emptyBtnRead => 'خواندن وضعیت دستگاه';

  @override
  String get emptyBtnAdd => 'افزودن برنامه جدید';

  @override
  String metaFmt(String on, String off, String t) {
    return '$on دستور روشن | $off دستور خاموش | $t تایمر';
  }

  @override
  String get relay1 => 'خروجی ۱';

  @override
  String get viewEvents => 'مشاهده ریزه‌رویدادها';

  @override
  String get progOnToast => 'برنامه فعال شد';

  @override
  String get progOffToast => 'برنامه غیرفعال شد';

  @override
  String get progOffBadge => 'غیرفعال';

  @override
  String get chartMemTitle => 'حافظه برنامه‌ها';

  @override
  String chartMemValue(String u, String m) {
    return '$u از $m اسلات رویداد';
  }

  @override
  String get chartTimerTitle => 'تایمرها';

  @override
  String chartTimerValue(String u, String m) {
    return '$u از $m اسلات تایمر';
  }

  @override
  String get wcAstroSide => 'خودکار';

  @override
  String get wcSetSide => '۳ بخش';

  @override
  String get wcSetD2 => 'همگام‌سازی ساعت و تقویم شمسی + محاسبه طلوع و غروب';

  @override
  String get wcBack => 'بازگشت';

  @override
  String get wpClose => 'متوجه شدم';

  @override
  String get wpBackApp => 'بازگشت به برنامه';

  @override
  String get wpBackToast =>
      'به محیط برنامه برگشتید؛ می‌توانید بعداً دوباره تلاش کنید.';

  @override
  String get dsIdentifyBtn => 'شناسایی دستگاه با اسکن NFC';

  @override
  String get dsIdentifyD =>
      'هنگام اسکن، مدل دستگاه به‌طور خودکار تشخیص داده می‌شود.';

  @override
  String get dsScanTitle => 'شناسایی دستگاه';

  @override
  String get dsScanSub =>
      'گوشی را به تگ NFC دستگاه نزدیک کنید و تا پایان شناسایی ثابت نگه دارید.';

  @override
  String get dsScanPh1 => 'اتصال به دستگاه…';

  @override
  String get dsScanPh2 => 'خواندن اطلاعات دستگاه…';

  @override
  String get dsScanPh3 => 'تشخیص مدل دستگاه…';

  @override
  String get dsFound => 'دستگاه شناسایی شد';

  @override
  String get dsFoundD =>
      'مدل دستگاه به‌طور خودکار تشخیص داده شد و با فهرست محصولات تطبیق داده شد.';

  @override
  String get dsDoneToast => 'مدل دستگاه تأیید شد: PTS50N1';

  @override
  String get asSelTitle => 'روزهای انتخاب‌شده';

  @override
  String get asNoneSelected => 'هنوز روزی انتخاب نشده است';

  @override
  String asDayN(String n) {
    return 'روز $n';
  }

  @override
  String get asRemoveOne => 'حذف این روز از انتخاب‌ها';

  @override
  String get asRemovedOne => 'روز از فهرست انتخاب‌ها حذف شد';

  @override
  String get asRequired => 'الزامی';

  @override
  String get needDays =>
      'برای ثبت برنامه، ابتدا روزهای اجرای زنجیره را اختصاص دهید.';

  @override
  String get needDaysHint =>
      'برای فعال شدن دکمه «ثبت برنامه»، روزهای اجرا را انتخاب کنید.';

  @override
  String get phaseRange => 'بازه مجاز: ۵ تا ۷۲۰ دقیقه — گام تنظیم ۵ دقیقه.';

  @override
  String countActiveFmt(String n, String m) {
    return '$n فعال · $m غیرفعال';
  }

  @override
  String get allDisabledToast =>
      'همه برنامه‌ها غیرفعال هستند؛ برنامه غیرفعال به رله ارسال نمی‌شود. ابتدا یک برنامه را فعال کنید.';

  @override
  String wcOffNote(String m) {
    return '$m برنامه غیرفعال در این ارسال لحاظ نمی‌شود؛ برنامه غیرفعال به رله ارسال نمی‌شود.';
  }

  @override
  String get scPower => 'رله بدون تغذیه';

  @override
  String get wpPwSetT => 'تنظیم ساعت و موقعیت انجام نمی‌شود';

  @override
  String get wpPwSetM =>
      'تغذیه رله قطع است. در این وضعیت، ساعت، تاریخ و موقعیت مکانی روی رله ثبت نمی‌شود و ارسال تنظیمات انجام نشد. پس از وصل‌کردن تغذیه رله، این عملیات را دوباره انجام دهید.';

  @override
  String get wpPwAck => 'متوجه شدم';

  @override
  String get wpPwSetToast =>
      'ارسال تنظیمات متوقف شد؛ پس از وصل‌کردن تغذیه رله دوباره تلاش کنید.';

  @override
  String get wpPwProgT => 'رله بدون تغذیه است';

  @override
  String get wpPwProgM =>
      'تغذیه رله قطع است. در این وضعیت، انتقال برنامه‌ها امکان‌پذیر است، اما ساعت، تاریخ و موقعیت مکانی رله به‌روزرسانی نمی‌شود. پس از وصل‌کردن تغذیه رله، گزینه «فقط تنظیمات» را برای به‌روزرسانی ساعت و تاریخ ارسال کنید.';

  @override
  String get wpPwContinue => 'ادامه ارسال';

  @override
  String get wpPwCancel => 'لغو';

  @override
  String get wpPwCancelled => 'ارسال برنامه‌ها لغو شد.';

  @override
  String get wpPwSkipped =>
      'ساعت و تاریخ رله در این عملیات به‌روزرسانی نمی‌شود.';

  @override
  String wpDoneSubNoClock(String v) {
    return 'برنامه‌ها روی رله نوشته و بررسی شد؛ ساعت، تاریخ و موقعیت رله به‌روزرسانی نشد. پس از وصل‌کردن تغذیه رله، گزینه «فقط تنظیمات» را ارسال کنید.';
  }

  @override
  String get step4dNoClock =>
      'برنامه‌ها در حافظه رله ذخیره می‌شوند؛ ساعت و تاریخ به‌روزرسانی نمی‌شود.';

  @override
  String get ruleTitle => 'قواعد زنجیره دستور';

  @override
  String get ruleIntro =>
      'در این قواعد، دو دستوری که در فهرست زنجیره بدون هیچ دستور دیگری پشت یکدیگر قرار دارند، «دستور متوالی» نامیده می‌شوند.';

  @override
  String get ruleR1 =>
      'دو دستور در یک زنجیره نمی‌توانند زمان اجرای یکسان داشته باشند؛ اجرای هم‌زمان دو دستور بر یک خروجی مجاز نیست.';

  @override
  String get ruleR2 =>
      'فاصله زمانی اجرای دو دستور متوالی نباید کمتر از ۵ دقیقه باشد.';

  @override
  String get ruleR3 =>
      'دو دستور متوالی نمی‌توانند عملکرد رله یکسان داشته باشند؛ در این صورت، وضعیت خروجی رله پس از اجرای دستور دوم تغییری نمی‌کند. در صورت وجود دستور دیگری با عملکرد متفاوت میان آن دو، این قاعده اعمال نمی‌شود.';

  @override
  String get ruleR4 =>
      'دو دستور متوالی نمی‌توانند تنظیمات تایمر یکسان داشته باشند؛ در این صورت، رفتار خروجی در هر دو دستور تکرار می‌شود.';

  @override
  String ruleSameTime(String n1, String n2, String t) {
    return 'دستورهای $n1 و $n2 زمان اجرای یکسان دارند ($t). زمان اجرای یکی از دو دستور باید اصلاح شود.';
  }

  @override
  String ruleSameTimeSolar(String n1, String n2) {
    return 'دستورهای $n1 و $n2 هر دو به یک لحظه نجومی با انحراف یکسان متصل هستند. تنظیمات یکی از دو دستور باید اصلاح شود.';
  }

  @override
  String ruleMinGap(String n1, String n2, String d, String t1, String t2) {
    return 'فاصله اجرای دستورهای $n1 و $n2 برابر $d دقیقه است ($t1 و $t2)؛ حداقل فاصله مجاز میان دو دستور متوالی ۵ دقیقه است.';
  }

  @override
  String ruleSameAct(String n1, String n2, String act, String t1, String t2) {
    return 'دستورهای $n1 و $n2 هر دو عملکرد «$act» دارند ($t1 و $t2)؛ دو دستور متوالی با عملکرد رله یکسان مجاز نیست، زیرا وضعیت خروجی رله تغییر نمی‌کند.';
  }

  @override
  String ruleSameTimer(String n1, String n2, String t1, String t2, String tmr) {
    return 'دستورهای $n1 و $n2 تنظیمات تایمر یکسان دارند ($t1 و $t2 · $tmr)؛ دو دستور متوالی با تنظیمات تایمر یکسان مجاز نیست، زیرا رفتار خروجی تکرار می‌شود.';
  }

  @override
  String ruleTimerFmt(String on, String off) {
    return 'روشن $on / خاموش $off';
  }

  @override
  String rulesBlock(String n) {
    return 'ثبت برنامه انجام نشد: $n مورد عدم انطباق با قواعد زنجیره دستور وجود دارد.';
  }

  @override
  String evRuleSameTime(String n, String t) {
    return 'این دستور با دستور شماره $n زمان اجرای یکسان دارد ($t)؛ زمان اجرای یکی از دو دستور باید اصلاح شود.';
  }

  @override
  String evRuleSameTimeSolar(String n) {
    return 'این دستور با دستور شماره $n به یک لحظه نجومی با انحراف یکسان متصل است؛ تنظیمات یکی از دو دستور باید اصلاح شود.';
  }

  @override
  String evRuleMinGap(String n, String d) {
    return 'فاصله اجرای این دستور با دستور شماره $n برابر $d دقیقه است؛ حداقل فاصله مجاز میان دو دستور متوالی ۵ دقیقه است.';
  }

  @override
  String evRuleSameAct(String n, String act) {
    return 'این دستور و دستور شماره $n هر دو عملکرد «$act» دارند؛ دو دستور متوالی با عملکرد رله یکسان مجاز نیست، زیرا وضعیت خروجی رله تغییر نمی‌کند.';
  }

  @override
  String evRuleSameTimer(String n) {
    return 'این دستور و دستور شماره $n تنظیمات تایمر یکسان دارند؛ تنظیمات تایمر یا زمان اجرای یکی از دو دستور باید اصلاح شود.';
  }

  @override
  String hourFmt(String h) {
    return '$h ساعت';
  }

  @override
  String get gpsInvalid =>
      'مقدار واردشده معتبر نیست؛ عرض جغرافیایی باید بین ۹۰− تا ۹۰ و طول جغرافیایی بین ۱۸۰− تا ۱۸۰ باشد.';

  @override
  String get logTitle => 'گزارش‌های کاربرد (لاگر)';

  @override
  String get logSub =>
      'تمام عملیات اپلیکیشن با زمان دقیق در این گزارش ثبت می‌شود؛ فایل گزارش را همراه گزارش آزمون میدانی برای تیم توسعه ارسال کنید.';

  @override
  String logCount(String n, String m) {
    return '$n رخداد ثبت‌شده · $m مورد نمایش داده‌شده';
  }

  @override
  String get logEmpty =>
      'هنوز رخدادی ثبت نشده است. پس از انجام عملیات (ارتباط NFC، تنظیم موقعیت یا ویرایش برنامه‌ها) رخدادها در همین صفحه نمایش داده می‌شوند.';

  @override
  String get logExport => 'ذخیره و ارسال گزارش';

  @override
  String get logCopy => 'رونوشت';

  @override
  String get logClear => 'پاک‌سازی';

  @override
  String get logShareSubject => 'گزارش کاربرد اپلیکیشن KIANEX PTS50N1';

  @override
  String get logExportFailed => 'ارسال گزارش ناموفق بود.';

  @override
  String get logCopiedToast => 'گزارش در حافظه موقت کپی شد.';

  @override
  String get logClearTitle => 'پاک‌سازی گزارش؟';

  @override
  String get logClearText =>
      'تمام رخدادهای ثبت‌شده حذف می‌شوند و این عملیات قابل بازگشت نیست.';

  @override
  String get logClearedToast => 'گزارش پاک‌سازی شد.';

  @override
  String get logLevelNfc => 'NFC';

  @override
  String get logLevelGps => 'GPS';

  @override
  String get logLevelAction => 'عملیات';

  @override
  String get logLevelError => 'خطا';

  @override
  String get logLevelWarn => 'هشدار';

  @override
  String get logLevelInfo => 'اطلاع';

  @override
  String get seLogs => 'گزارش‌های کاربرد (لاگر)';

  @override
  String get seLogsD =>
      'ثبت خودکار تمام عملیات؛ امکان مشاهده، ذخیره و ارسال فایل گزارش';

  @override
  String get gpsGetFix => 'دریافت موقعیت با GPS';

  @override
  String get gpsFixing => 'در حال دریافت موقعیت…';

  @override
  String gpsAccm(String m) {
    return 'دقت موقعیت: ±$m متر';
  }

  @override
  String get gpsManual => 'ورود دستی مختصات';

  @override
  String get gpsDenied =>
      'مجوز دسترسی به موقعیت داده نشد؛ در تنظیمات سیستم، مجوز «موقعیت مکانی» را برای این اپلیکیشن فعال کنید.';

  @override
  String get gpsDeniedForever =>
      'دسترسی به موقعیت مکانی به‌صورت دائمی رد شده است؛ از بخش تنظیمات سیستم، مجوز مربوطه را فعال کنید.';

  @override
  String get gpsServiceOff =>
      'سرویس موقعیت‌یابی دستگاه خاموش است؛ آن را از بخش تنظیمات سیستم روشن کنید.';

  @override
  String get gpsTimeout => 'دریافت موقعیت ناموفق بود؛ چند لحظه دیگر تلاش کنید.';

  @override
  String get idModelWarnTitle => 'تگ شناسایی شد — مدل تطبیق نشد';

  @override
  String get idModelWarnText =>
      'محتوای NDEF تگ با شناسه‌های KIANEX تطبیق ندارد؛ ممکن است تگ مربوط به دستگاه PST50R1 کارخانه نباشد. پیام NDEF در زیر نمایش داده شده است.';

  @override
  String get idMemoryWarnText =>
      'ظرفیت حافظه تگ برای نگاشت حافظه اشتراکی PST50R1 کافی نیست؛ تگ ST25DV16K (۵۱۲ بلوک) یا بزرگ‌تر لازم است.';

  @override
  String get idTagModel => 'مدل تگ';

  @override
  String get idTagMemory => 'حافظه تگ';

  @override
  String get idTagUid => 'شناسه UID';

  @override
  String get idTagUri => 'پیام NDEF';

  @override
  String get idRetry => 'تلاش دوباره';

  @override
  String get idFailTitle => 'شناسایی دستگاه ناتمام ماند';

  @override
  String get idFailNoTag =>
      'تگ NFC در محدوده خوانده نشد. ابتدا مطمئن شوید NFC گوشی روشن است؛ سپس پشت گوشی را به محل تگ روی دستگاه نزدیک کنید و تا پایان شناسایی ثابت نگه دارید.';

  @override
  String get idFailNotIso =>
      'برچسب ارائه‌شده از نوع NFC Type 5 (ISO 15693) نیست و با این دستگاه سازگار نیست.';

  @override
  String get idFailModel =>
      'محتوای NDEF تگ با شناسه‌های KIANEX تطبیق ندارد؛ تگ ممکن است مربوط به دستگاه دیگری باشد.';

  @override
  String get idFailMemory =>
      'ظرفیت حافظه تگ برای نگاشت حافظه اشتراکی کافی نیست (حداقل ۵۱۲ بلوک ۴ بایتی لازم است).';

  @override
  String get stNoTagTitle => 'خواندن وضعیت دستگاه ناموفق بود';

  @override
  String get stNoTagText =>
      'تگ NFC در محدوده خوانده نشد یا دستگاه پاسخ نداد. ابتدا مطمئن شوید NFC گوشی روشن است؛ سپس پشت گوشی را به محل تگ روی رله نزدیک کنید و «خواندن مجدد» را بزنید.';

  @override
  String get stPressRefresh =>
      'برای خواندن وضعیت دستگاه، ابتدا NFC گوشی را روشن کنید، سپس پشت گوشی را به تگ NFC رله نزدیک کنید و «خواندن مجدد» را بزنید.';

  @override
  String asAnnualLeapNote(String year) {
    return 'سال $year کبیسه است؛ اسفند ۳۰ روز دارد و روز ۳۶۶ سال در جدول روزهای سالانه موجود است.';
  }

  @override
  String get idFailNfcOff =>
      'دسترسی NFC گوشی فعال نیست. NFC را از تنظیمات سریع گوشی روشن کنید و دوباره تلاش کنید.';
}
