// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppL10nHi extends AppL10n {
  AppL10nHi([String locale = 'hi']) : super(locale);

  @override
  String get navHome => 'होम';

  @override
  String get navTasks => 'टास्क';

  @override
  String get navPost => 'पोस्ट';

  @override
  String get navBookings => 'बुकिंग';

  @override
  String get navActive => 'सक्रिय';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get goodMorning => 'सुप्रभात';

  @override
  String get goodAfternoon => 'शुभ दोपहर';

  @override
  String get goodEvening => 'शुभ संध्या';

  @override
  String get heroTitle => 'कोई भी काम करवाएँ';

  @override
  String get heroSubtitle =>
      'एक टास्क पोस्ट करें और अपने पास के भरोसेमंद टास्कर्स से ऑफ़र पाएँ।';

  @override
  String get howItWorks => 'यह कैसे काम करता है';

  @override
  String get howStep1Title => 'अपना टास्क पोस्ट करें';

  @override
  String get howStep1Caption => 'बताएँ कि आपको क्या करवाना है';

  @override
  String get howStep2Title => 'टास्कर्स से ऑफ़र पाएँ';

  @override
  String get howStep2Caption => 'कीमतों और समीक्षाओं की तुलना करें';

  @override
  String get howStep3Title => 'हायर करें और काम पूरा करवाएँ';

  @override
  String get howStep3Caption => 'काम पूरा होने पर सुरक्षित भुगतान करें';

  @override
  String get whatDoYouNeedHelp => 'आपको किसमें मदद चाहिए?';

  @override
  String get somethingElse => 'कुछ और';

  @override
  String get yourTasks => 'आपके टास्क';

  @override
  String get yourRecentTasks => 'आपके हाल के टास्क';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get noTasksYet => 'आपने अभी तक कोई टास्क पोस्ट नहीं किया';

  @override
  String get postFirstTask =>
      'अपना पहला टास्क पोस्ट करें और ऑफ़र पाना शुरू करें।';

  @override
  String get trustVerifiedTaskers => 'सत्यापित\nटास्कर्स';

  @override
  String get trustTopRated => 'टॉप रेटेड\nसेवा';

  @override
  String get trustSecurePayments => 'सुरक्षित\nभुगतान';

  @override
  String get postATask => 'टास्क पोस्ट करें';

  @override
  String get apply => 'अप्लाई करें';

  @override
  String get accept => 'स्वीकार करें';

  @override
  String get decline => 'अस्वीकार करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get save => 'सेव करें';

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get continueLabel => 'जारी रखें';

  @override
  String get submit => 'सबमिट करें';

  @override
  String get ok => 'ठीक है';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get close => 'बंद करें';

  @override
  String get report => 'रिपोर्ट करें';

  @override
  String get block => 'ब्लॉक करें';

  @override
  String get back => 'वापस';

  @override
  String get authTagline => 'मिनटों में पेशेवर घरेलू मदद पाएँ!';

  @override
  String get authLoginOrSignup => 'लॉग इन या साइन अप करें';

  @override
  String get authChangeNumber => 'नंबर बदलें';

  @override
  String get authResendOtp => 'OTP दोबारा भेजें';

  @override
  String authResendIn(int seconds) {
    return '$secondsसे में दोबारा भेजें';
  }

  @override
  String get authMobileNumber => 'मोबाइल नंबर';

  @override
  String get authTermsIntro => 'जारी रखें पर क्लिक करके, आप हमारी ';

  @override
  String get authTerms => 'नियम एवं शर्तें';

  @override
  String get authAnd => ' और ';

  @override
  String get authPrivacy => 'गोपनीयता नीति';

  @override
  String get settingsLanguage => 'भाषा';

  @override
  String get chooseLanguage => 'भाषा चुनें';

  @override
  String get languageSystemDefault => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get languagePunjabi => 'ਪੰਜਾਬੀ (Punjabi)';

  @override
  String get verified => 'सत्यापित';

  @override
  String get safetyMoreOptions => 'अधिक विकल्प';

  @override
  String get safetyBlockUser => 'उपयोगकर्ता को ब्लॉक करें';

  @override
  String safetyBlockBody(String name) {
    return '$name को ब्लॉक करें? आपको उनके ऑफ़र या सामग्री दिखाई नहीं देगी, और वे आपसे संपर्क नहीं कर पाएंगे।';
  }

  @override
  String safetyUserBlocked(String name) {
    return '$name को ब्लॉक कर दिया गया है';
  }

  @override
  String get safetyThisUser => 'इस उपयोगकर्ता';

  @override
  String get safetyReportUser => 'उपयोगकर्ता की शिकायत करें';

  @override
  String safetyReportUserNamed(String name) {
    return '$name की शिकायत करें';
  }

  @override
  String get safetyReportSubtitle =>
      'हमें बताएं कि क्या गलत हुआ। शिकायतें गोपनीय हैं।';

  @override
  String get safetyReportDetailHint => 'कोई विवरण जोड़ें (वैकल्पिक)';

  @override
  String get safetySubmitReport => 'शिकायत भेजें';

  @override
  String get safetyReportThanks =>
      'शिकायत भेज दी गई। TaskTeddy को सुरक्षित रखने के लिए धन्यवाद।';

  @override
  String get reasonInappropriate => 'अनुचित व्यवहार';

  @override
  String get reasonNoShow => 'नहीं आया';

  @override
  String get reasonSafety => 'सुरक्षा चिंता';

  @override
  String get reasonFraud => 'धोखाधड़ी या घोटाला';

  @override
  String get reasonPoorQuality => 'खराब गुणवत्ता';

  @override
  String get reasonSpam => 'स्पैम';

  @override
  String get reasonOther => 'अन्य';

  @override
  String get blockedUsersTitle => 'ब्लॉक किए गए उपयोगकर्ता';

  @override
  String get unblock => 'अनब्लॉक करें';

  @override
  String unblockedSuccess(String name) {
    return '$name अनब्लॉक कर दिया गया';
  }

  @override
  String get userLabel => 'उपयोगकर्ता';

  @override
  String get noBlockedUsers => 'कोई ब्लॉक किया उपयोगकर्ता नहीं';

  @override
  String get blockedUsersEmptyBody =>
      'आपके द्वारा ब्लॉक किए गए लोग यहाँ दिखेंगे। आप उन्हें कभी भी अनब्लॉक कर सकते हैं।';

  @override
  String get blockedUsersError => 'ब्लॉक किए गए उपयोगकर्ता लोड नहीं हो सके।';

  @override
  String get tasksMyTasks => 'मेरे टास्क';

  @override
  String get statusOpen => 'खुला';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusDone => 'पूरा';

  @override
  String get statusAll => 'सभी';

  @override
  String get tasksLoadError => 'आपके टास्क लोड नहीं हो सके।';

  @override
  String get tasksTotalTasks => 'कुल टास्क';

  @override
  String get tasksAcrossStatuses => 'सभी स्थितियों में';

  @override
  String get tasksWithBids => 'बोलियों के साथ';

  @override
  String get tasksReadyForReview => 'समीक्षा के लिए तैयार';

  @override
  String get tasksUpcoming => 'आगामी';

  @override
  String get tasksNotPastDeadline => 'समय-सीमा से पहले';

  @override
  String get tasksSearchHint => 'शीर्षक, स्थान या श्रेणी खोजें';

  @override
  String get tasksOnlyWithBids => 'केवल बोली वाले टास्क';

  @override
  String get splashPreparing => 'TaskTeddy तैयार हो रहा है';

  @override
  String get splashLoadingWorkspace => 'आपका वर्कस्पेस लोड हो रहा है';

  @override
  String get splashGettingReady => 'चीज़ें तैयार की जा रही हैं...';

  @override
  String get splashAlmostThere => 'बस थोड़ा और...';

  @override
  String get splashLocationOff =>
      'लोकेशन बंद है। आप इसे होम से सेट कर सकते हैं।';

  @override
  String get splashLocationSkipped => 'लोकेशन अनुमति छोड़ी गई। जारी है...';

  @override
  String get splashUsingDefaultLocation =>
      'डिफ़ॉल्ट लोकेशन का उपयोग हो रहा है।';

  @override
  String splashLocationLocked(String label) {
    return 'लोकेशन सेट: $label';
  }

  @override
  String get splashLocationFailed => 'लोकेशन प्राप्त नहीं हो सकी। जारी है...';

  @override
  String get favSaved => 'सहेजे गए';

  @override
  String get favTabServices => 'सेवाएँ';

  @override
  String get favTabTaskers => 'टास्कर्स';

  @override
  String get favNoServices => 'अभी तक कोई सेवा सहेजी नहीं गई';

  @override
  String get favNoServicesBody =>
      'किसी भी सेवा को यहाँ सहेजने के लिए हार्ट पर टैप करें।';

  @override
  String get favNoTaskers => 'अभी तक कोई टास्कर सहेजा नहीं गया';

  @override
  String get favNoTaskersBody =>
      'किसी टास्कर को सहेजें ताकि उन्हें दोबारा आसानी से ढूँढ सकें।';

  @override
  String get favLoadError => 'आपके सहेजे गए आइटम लोड नहीं हो सके।';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count समीक्षाएँ',
      one: '1 समीक्षा',
    );
    return '$_temp0';
  }

  @override
  String get portfolioTitle => 'पोर्टफोलियो';

  @override
  String get weeklyAvailability => 'साप्ताहिक उपलब्धता';

  @override
  String get recentReviews => 'हाल की समीक्षाएँ';

  @override
  String get profileStatRating => 'रेटिंग';

  @override
  String get profileStatJobs => 'पूरे किए कार्य';

  @override
  String get profileStatReliability => 'विश्वसनीयता';

  @override
  String get taskTheirOffer => 'उनकी पेशकश';

  @override
  String get noReviewsYet => 'अभी तक कोई समीक्षा नहीं।';

  @override
  String get availabilityNotSet => 'उपलब्धता सेट नहीं है।';

  @override
  String get unavailable => 'अनुपलब्ध';

  @override
  String get reviewerCustomer => 'ग्राहक';

  @override
  String get weekdayMon => 'सोम';

  @override
  String get weekdayTue => 'मंगल';

  @override
  String get weekdayWed => 'बुध';

  @override
  String get weekdayThu => 'गुरु';

  @override
  String get weekdayFri => 'शुक्र';

  @override
  String get weekdaySat => 'शनि';

  @override
  String get weekdaySun => 'रवि';

  @override
  String get sdSavedAddresses => 'सहेजे गए पते';

  @override
  String get sdDefault => 'डिफ़ॉल्ट';

  @override
  String get sdConfirmBooking => 'बुकिंग की पुष्टि करें';

  @override
  String get sdServicePrice => 'सेवा की कीमत';

  @override
  String get sdDiscount => 'छूट';

  @override
  String get sdTotalFromWallet => 'कुल (वॉलेट से)';

  @override
  String get sdTotalPayAfter => 'कुल (सेवा के बाद भुगतान)';

  @override
  String get sdPaymentMethod => 'भुगतान का तरीका';

  @override
  String get sdPayAfterService => 'सेवा के बाद भुगतान';

  @override
  String get sdPayAfterServiceSub => 'पूरा होने पर नकद / UPI';

  @override
  String get sdWallet => 'वॉलेट';

  @override
  String sdWalletAvailable(int amount) {
    return '₹$amount उपलब्ध';
  }

  @override
  String sdWalletLow(int amount) {
    return 'कम बैलेंस: ₹$amount';
  }

  @override
  String sdConfirmAndBook(int amount) {
    return 'पुष्टि करें और बुक करें  •  ₹$amount';
  }

  @override
  String get sessionExpired => 'सत्र समाप्त हो गया। कृपया दोबारा लॉग इन करें।';

  @override
  String get sdBookingConfirmed => 'बुकिंग की पुष्टि हो गई!';

  @override
  String sdPaidFromWallet(int amount) {
    return '₹$amount वॉलेट से भुगतान किया गया';
  }

  @override
  String sdBookingId(String ref) {
    return 'बुकिंग ID: $ref';
  }

  @override
  String get sdViewMyBookings => 'मेरी बुकिंग देखें';

  @override
  String get done => 'हो गया';

  @override
  String get sdPickTimeSlotError => 'कृपया एक समय स्लॉट चुनें';

  @override
  String get sdEnterAddressError => 'कृपया अपना पता दर्ज करें';

  @override
  String get sdRemoveFromSaved => 'सहेजे गए से हटाएँ';

  @override
  String get badgeHot => 'हॉट';

  @override
  String get badgeNew => 'नया';

  @override
  String percentOff(int percent) {
    return '$percent% छूट';
  }

  @override
  String get sdDescription => 'विवरण';

  @override
  String get sdWhatsIncluded => 'क्या शामिल है';

  @override
  String get sdPickDate => 'तारीख चुनें';

  @override
  String get dateToday => 'आज';

  @override
  String get dateTomorrowShort => 'कल';

  @override
  String get sdPickTimeSlot => 'समय स्लॉट चुनें';

  @override
  String get sdAddress => 'पता';

  @override
  String get sdUseSaved => 'सहेजा हुआ उपयोग करें';

  @override
  String get sdAddressHint => 'अपना पूरा पता दर्ज करें';

  @override
  String get sdNotesOptional => 'नोट्स (वैकल्पिक)';

  @override
  String get sdNotesHint => 'कोई विशेष निर्देश?';

  @override
  String sdBookNow(int amount) {
    return 'अभी बुक करें  •  ₹$amount';
  }

  @override
  String get bookingCancelTitle => 'बुकिंग रद्द करें?';

  @override
  String bookingCancelBody(String service, String when) {
    return '$when को $service रद्द कर दी जाएगी।';
  }

  @override
  String get bookingKeepIt => 'रहने दें';

  @override
  String get bookingCancelConfirm => 'बुकिंग रद्द करें';

  @override
  String get bookingCancelled => 'बुकिंग रद्द कर दी गई';

  @override
  String bookingCancelledRefund(int amount) {
    return 'बुकिंग रद्द कर दी गई • ₹$amount वॉलेट में वापस किए गए';
  }

  @override
  String bookingRescheduleTitle(String service) {
    return '$service का समय बदलें';
  }

  @override
  String get bookingConfirmNewTime => 'नया समय पुष्टि करें';

  @override
  String bookingRescheduledTo(String when) {
    return '$when के लिए समय बदला गया';
  }

  @override
  String get bookingsTitle => 'मेरी बुकिंग';

  @override
  String get bookingsTabUpcoming => 'आगामी';

  @override
  String get bookingsTabCompleted => 'पूर्ण';

  @override
  String get bookingsTabCancelled => 'रद्द';

  @override
  String get bookingsEmptyTitle => 'अभी तक कोई बुकिंग नहीं';

  @override
  String get bookingsEmptyBody => 'आपकी निर्धारित सेवाएँ यहाँ दिखाई देंगी।';

  @override
  String get bookingStatusPending => 'लंबित';

  @override
  String get bookingStatusConfirmed => 'पुष्ट';

  @override
  String get bookingStatusCompleted => 'पूर्ण';

  @override
  String get bookingStatusCancelled => 'रद्द';

  @override
  String get bookingDetailId => 'बुकिंग ID';

  @override
  String get bookingDetailScheduled => 'निर्धारित';

  @override
  String get bookingDetailAddress => 'पता';

  @override
  String get bookingDetailNotes => 'नोट्स';

  @override
  String get bookingDetailAmount => 'राशि';

  @override
  String get bookingDetailPayment => 'भुगतान';

  @override
  String get bookingPaidFromWallet => 'वॉलेट से भुगतान किया गया';

  @override
  String get bookingBookAgain => 'फिर से बुक करें';

  @override
  String get bookingReschedule => 'समय बदलें';

  @override
  String get notificationFallbackTitle => 'सूचना';

  @override
  String get notificationsTitle => 'सूचनाएँ';

  @override
  String get notificationsMarkAllRead => 'सभी पढ़ी हुई चिह्नित करें';

  @override
  String get notificationsEmptyTitle => 'आप पूरी तरह अपडेट हैं';

  @override
  String get notificationsEmptyBody =>
      'आपकी बुकिंग और टास्क के बारे में\nनए अपडेट यहाँ दिखेंगे।';

  @override
  String get timeJustNow => 'अभी-अभी';

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String timeHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String get messagesTitle => 'संदेश';

  @override
  String get messagesSearchHint => 'चैट खोजें…';

  @override
  String get messagesNoResults => 'कोई परिणाम नहीं मिला';

  @override
  String get messagesNoConversations => 'अभी तक कोई बातचीत नहीं';

  @override
  String get messagesTryDifferentSearch => 'कोई दूसरा खोज शब्द आज़माएँ';

  @override
  String get messagesBookToChat =>
      'अपने टास्कर के साथ चैट शुरू करने के लिए\nएक टास्क बुक करें!';

  @override
  String get messagesTapToOpen => 'चैट खोलने के लिए टैप करें';

  @override
  String get messagesCouldNotSend => 'संदेश नहीं भेजा जा सका';

  @override
  String get messagesCopied => 'क्लिपबोर्ड पर कॉपी किया गया';

  @override
  String get messagesOnline => 'ऑनलाइन';

  @override
  String get messagesSayHello => 'नमस्ते कहें!';

  @override
  String messagesStartConversation(String name) {
    return '$name के साथ\nबातचीत शुरू करें';
  }

  @override
  String get messagesTypeHint => 'एक संदेश टाइप करें…';

  @override
  String get messagesTakePhoto => 'फ़ोटो लें';

  @override
  String get messagesChooseGallery => 'गैलरी से चुनें';

  @override
  String get messagesCouldNotSendImage => 'छवि नहीं भेजी जा सकी';

  @override
  String messagesErrorSelectingImage(String error) {
    return 'छवि चुनने में त्रुटि: $error';
  }

  @override
  String get msgTimeNow => 'अभी';

  @override
  String msgTimeMinutes(int minutes) {
    return '$minutes मि';
  }

  @override
  String msgTimeHours(int hours) {
    return '$hours घं';
  }

  @override
  String msgTimeDays(int days) {
    return '$days दि';
  }

  @override
  String get dateYesterday => 'कल';

  @override
  String get weekdayFullMonday => 'सोमवार';

  @override
  String get weekdayFullTuesday => 'मंगलवार';

  @override
  String get weekdayFullWednesday => 'बुधवार';

  @override
  String get weekdayFullThursday => 'गुरुवार';

  @override
  String get weekdayFullFriday => 'शुक्रवार';

  @override
  String get weekdayFullSaturday => 'शनिवार';

  @override
  String get weekdayFullSunday => 'रविवार';

  @override
  String get monthJan => 'जन';

  @override
  String get monthFeb => 'फ़र';

  @override
  String get monthMar => 'मार्च';

  @override
  String get monthApr => 'अप्रैल';

  @override
  String get monthMay => 'मई';

  @override
  String get monthJun => 'जून';

  @override
  String get monthJul => 'जुल';

  @override
  String get monthAug => 'अग';

  @override
  String get monthSep => 'सित';

  @override
  String get monthOct => 'अक्टू';

  @override
  String get monthNov => 'नव';

  @override
  String get monthDec => 'दिस';

  @override
  String get profileAddPhone => 'फ़ोन नंबर जोड़ें';

  @override
  String profileCouldNotOpen(String url) {
    return '$url नहीं खोला जा सका';
  }

  @override
  String profileOpenExternalTitle(String title) {
    return '$title खोलें?';
  }

  @override
  String get profileOpenExternalBody => 'आप एक बाहरी वेबसाइट खोलने वाले हैं।';

  @override
  String get profileUpdatedSuccess => 'प्रोफ़ाइल सफलतापूर्वक अपडेट हुई';

  @override
  String get profileDefaultName => 'TaskTeddy उपयोगकर्ता';

  @override
  String get profileEditProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileAddressBookReady =>
      'तेज़ चेकआउट के लिए पता-पुस्तिका तैयार है';

  @override
  String get profileManage => 'प्रबंधित करें';

  @override
  String get profileQuickAccess => 'त्वरित पहुँच';

  @override
  String get profileTrackManage => 'ट्रैक और प्रबंधन';

  @override
  String get profileAddresses => 'पते';

  @override
  String get profileSaveForCheckout => 'चेकआउट के लिए सहेजें';

  @override
  String get profileHelp => 'मदद';

  @override
  String get profile24x7 => '24x7 सहायता';

  @override
  String get profileReferEarn => 'रेफ़र करें और कमाएँ';

  @override
  String get profileInviteFriends => 'दोस्तों को आमंत्रित करें और इनाम पाएँ';

  @override
  String get profileUpTo100 => '₹100 तक';

  @override
  String get profileSavedServicesTaskers => 'सहेजी सेवाएँ और टास्कर्स';

  @override
  String get profileSavedAddresses => 'सहेजे गए पते';

  @override
  String get profileAboutUs => 'हमारे बारे में';

  @override
  String get profileTermsConditions => 'नियम एवं शर्तें';

  @override
  String get profilePrivacyPolicy => 'गोपनीयता नीति';

  @override
  String get profileLogout => 'लॉग आउट';

  @override
  String get profileAccountSettings => 'खाता सेटिंग्स';

  @override
  String profileAppVersion(String version) {
    return 'ऐप संस्करण: $version';
  }

  @override
  String get profileErrFirstName => 'कृपया पहला नाम दर्ज करें';

  @override
  String get profileErrPhone => 'फ़ोन नंबर मान्य नहीं है';

  @override
  String get profileErrValidEmail => 'कृपया एक मान्य ईमेल पता दर्ज करें';

  @override
  String get profileChangeEmail => 'ईमेल बदलें';

  @override
  String get profileChangeEmailBody =>
      'सत्यापन से पहले ईमेल अपडेट करें। नए ईमेल पर एक नया OTP भेजा जाएगा।';

  @override
  String get profileEnterNewEmail => 'नया ईमेल दर्ज करें';

  @override
  String get profileUseThisEmail => 'यह ईमेल उपयोग करें';

  @override
  String get profileAddEmailFirst => 'कृपया पहले अपना ईमेल जोड़ें';

  @override
  String profileVerifCodeSent(String email) {
    return '$email पर सत्यापन कोड भेजा गया';
  }

  @override
  String get profileErrValidEmailShort => 'कृपया एक मान्य ईमेल दर्ज करें';

  @override
  String get profileEnterFullOtp => 'कृपया पूरा 6-अंकीय OTP कोड दर्ज करें';

  @override
  String get profileEmailVerified => 'ईमेल सफलतापूर्वक सत्यापित हुआ';

  @override
  String profileEmailLocked(String email) {
    return 'ईमेल सत्यापित है। अपना ईमेल बदलने के लिए $email से संपर्क करें।';
  }

  @override
  String get profileUpdateDetails => 'अपनी जानकारी अपडेट करें';

  @override
  String get profileUpdateDetailsBody =>
      'आसान बुकिंग के लिए अपनी प्रोफ़ाइल और संपर्क जानकारी सही रखें।';

  @override
  String get profileTitle => 'उपाधि';

  @override
  String get profileBasicInfo => 'बुनियादी जानकारी';

  @override
  String get profileFirstName => 'पहला नाम';

  @override
  String get profileFirstNameHint => 'पहला नाम दर्ज करें';

  @override
  String get profileLastName => 'अंतिम नाम';

  @override
  String get profileLastNameHint => 'अंतिम नाम दर्ज करें';

  @override
  String get profileContactVerification => 'संपर्क और सत्यापन';

  @override
  String get profileMobile => 'मोबाइल';

  @override
  String get profileEmail => 'ईमेल';

  @override
  String get profileVerify => 'सत्यापित करें';

  @override
  String get profileSaveChanges => 'बदलाव सहेजें';

  @override
  String get profileVerifyEmail => 'ईमेल सत्यापित करें';

  @override
  String profileVerifyEmailBody(String email) {
    return '$email पर भेजा गया 6-अंकीय सत्यापन कोड दर्ज करें। ईमेल अपडेट करना है? ईमेल बदलें पर टैप करें।';
  }

  @override
  String get walletNoTransactions => 'अभी तक कोई हालिया लेन-देन नहीं';

  @override
  String get walletTransaction => 'वॉलेट लेन-देन';

  @override
  String get walletMinAmount => 'न्यूनतम जोड़ने की राशि ₹100 है';

  @override
  String get walletHelpHint => 'बुकिंग पर तेज़ चेकआउट के लिए पैसे जोड़ें।';

  @override
  String get walletCardLabel => 'वॉलेट';

  @override
  String get walletBalance => 'वॉलेट बैलेंस';

  @override
  String get walletBalanceLow =>
      'आपका बैलेंस कम है। सुचारू बुकिंग जारी रखने के लिए पैसे जोड़ें।';

  @override
  String get walletBalanceUse =>
      'तेज़ चेकआउट और तुरंत ऑफ़र लाभ के लिए वॉलेट क्रेडिट का उपयोग करें।';

  @override
  String get walletGet5Extra => '5% अतिरिक्त पाएँ!';

  @override
  String get walletOnAdding250 => '₹250 या अधिक जोड़ने पर';

  @override
  String get walletAddMoney => 'पैसे जोड़ें';

  @override
  String get walletEnterAmount => 'राशि दर्ज करें';

  @override
  String walletCashback(String amount) {
    return '$amount कैशबैक पाएँ';
  }

  @override
  String walletYouWillGet(String amount) {
    return 'आपको वॉलेट में $amount मिलेंगे';
  }

  @override
  String walletAddToWallet(String amount) {
    return 'वॉलेट में $amount जोड़ें';
  }

  @override
  String get walletRecentTransactions => 'हालिया लेन-देन';

  @override
  String walletAddedBonus(String added, String bonus, String credited) {
    return '$added + बोनस $bonus जोड़ा गया। वॉलेट में $credited क्रेडिट हुए।';
  }

  @override
  String walletAdded(String amount) {
    return 'आपके वॉलेट में $amount जोड़े गए।';
  }

  @override
  String get helpCouldNotDial => 'इस डिवाइस पर डायलर नहीं खोला जा सका।';

  @override
  String get helpCouldNotEmail => 'इस डिवाइस पर ईमेल ऐप नहीं खोला जा सका।';

  @override
  String get helpTitle => 'मदद और सहायता';

  @override
  String helpReachOut(String phone, String email) {
    return 'ग्राहक सहायता से संपर्क करें\n$phone  •  $email';
  }

  @override
  String get helpCallUs => 'हमें कॉल करें';

  @override
  String get helpEmailUs => 'हमें ईमेल करें';

  @override
  String get helpNeedQuickHelp => 'त्वरित मदद चाहिए?';

  @override
  String get helpFindAnswers =>
      'तुरंत उत्तर पाएँ या कभी भी सहायता से संपर्क करें।';

  @override
  String get helpMyRefunds => 'मेरे रिफंड';

  @override
  String get helpNoRefunds => 'आपके पास अभी तक कोई रिफंड नहीं है।';

  @override
  String get helpBrowseTopics => 'सभी सहायता विषय ब्राउज़ करें';

  @override
  String helpRelatedTo(String topic) {
    return '$topic से संबंधित मदद';
  }

  @override
  String get helpCantFindAnswer => 'अपना उत्तर नहीं मिल रहा?';

  @override
  String get helpSupportHere => 'हमारी सहायता टीम मदद के लिए यहाँ है';

  @override
  String get helpTopicBooking => 'बुकिंग';

  @override
  String get helpTopicBookingSub => 'बुकिंग, रद्दीकरण और शेड्यूल प्रबंधित करें';

  @override
  String get helpTopicAccount => 'खाता';

  @override
  String get helpTopicAccountSub => 'प्रोफ़ाइल, लॉगिन और खाता सेटिंग्स';

  @override
  String get helpTopicPayments => 'भुगतान';

  @override
  String get helpTopicPaymentsSub => 'बिलिंग, रिफंड और लेन-देन';

  @override
  String get helpTopicServiceQuality => 'सेवा गुणवत्ता';

  @override
  String get helpTopicServiceQualitySub => 'प्रतिक्रिया, समस्याएँ और सेवा मानक';

  @override
  String get helpTopicSafety => 'सुरक्षा';

  @override
  String get helpTopicSafetySub => 'सुरक्षा से जुड़ी चिंताएँ';

  @override
  String get faqBookingRecurringQ => 'क्या मैं एक आवर्ती सेवा बुक कर सकता हूँ?';

  @override
  String get faqBookingRecurringA =>
      'हाँ। स्लॉट की पुष्टि करते समय अपनी पसंदीदा आवृत्ति चुनकर आप एक आवर्ती सेवा बुक कर सकते हैं। हम अधिकांश शहरों में साप्ताहिक और द्वि-साप्ताहिक दोहराव का समर्थन करते हैं।';

  @override
  String get faqBookingEquipmentQ =>
      'क्या मुझे सभी सफ़ाई उपकरण उपलब्ध कराने होंगे?';

  @override
  String get faqBookingEquipmentA =>
      'बुनियादी सामग्री आपके स्थान पर उपलब्ध होनी चाहिए। चुनिंदा प्रीमियम प्लान के लिए, पार्टनर सेवा विवरण पृष्ठ पर सूचीबद्ध ज़रूरी सामान ला सकते हैं।';

  @override
  String get faqBookingRescheduleQ =>
      'मैं बुकिंग को कैसे पुनर्निर्धारित या रद्द करूँ?';

  @override
  String get faqBookingRescheduleA =>
      'मेरी बुकिंग खोलें, बुकिंग चुनें, और पुनर्निर्धारित या रद्द करें चुनें। रद्दीकरण शुल्क इस पर निर्भर करता है कि आप सेवा समय के कितने करीब हैं।';

  @override
  String get faqBookingIssueQ => 'अगर कोई सेवा समस्या हो तो क्या करें?';

  @override
  String get faqBookingIssueA =>
      'बुकिंग विवरण के साथ इस पृष्ठ से एक सहायता अनुरोध दर्ज करें। हमारी टीम गुणवत्ता समस्याओं की समीक्षा करती है और जहाँ लागू हो वहाँ समाधान या मुआवज़े में मदद करती है।';

  @override
  String get faqBookingPriceQ => 'सेवा मूल्य की गणना कैसे होती है?';

  @override
  String get faqBookingPriceA =>
      'मूल्य सेवा प्रकार, अवधि, स्थान और ऐड-ऑन पर आधारित है। भुगतान पुष्टि से पहले आप हमेशा अंतिम राशि देखते हैं।';

  @override
  String get faqAccountUpdateAddressQ => 'मैं सहेजे गए पते को कैसे अपडेट करूँ?';

  @override
  String get faqAccountUpdateAddressA =>
      'प्रोफ़ाइल > सहेजे गए पते पर जाएँ। पता कार्ड चुनें और विवरण अपडेट करें, फिर सहेजें।';

  @override
  String get faqAccountAddAddressQ => 'मैं नया पता कैसे जोड़ूँ?';

  @override
  String get faqAccountAddAddressA =>
      'सहेजे गए पते से, पता जोड़ें पर टैप करें और लैंडमार्क तथा पिन कोड के साथ अपना पूरा पता दर्ज करें।';

  @override
  String get faqAccountContactQ => 'मैं सहायता से कैसे संपर्क करूँ?';

  @override
  String get faqAccountContactA =>
      'मदद और सहायता पृष्ठ पर हमें कॉल करें बटन का उपयोग करें। आप यहाँ कोई श्रेणी खोलकर नीचे सहायता कार्ड पर भी टैप कर सकते हैं।';

  @override
  String get faqPaymentsFailedQ =>
      'मेरा भुगतान विफल हो गया लेकिन पैसे मेरे खाते से कट गए';

  @override
  String get faqPaymentsFailedA =>
      'यदि भुगतान लंबित है, तो यह आमतौर पर बैंक समय-सीमा के भीतर स्वतः वापस हो जाता है। यदि वापस न हो, तो सहायता के साथ पेमेंट ID साझा करें और हम इसे ट्रैक करने में मदद करेंगे।';

  @override
  String get faqPaymentsCouponQ => 'मैं कूपन या ऑफ़र का उपयोग कैसे करूँ?';

  @override
  String get faqPaymentsCouponA =>
      'भुगतान स्क्रीन पर चेकआउट के दौरान कूपन कोड लागू करें। मान्य ऑफ़र बुकिंग करने से पहले तुरंत दिखते हैं।';

  @override
  String get faqPaymentsRefundQ =>
      'अगर मैं रद्द करूँ तो क्या मुझे रिफंड मिलेगा?';

  @override
  String get faqPaymentsRefundA =>
      'रिफंड पात्रता रद्दीकरण समय और सेवा शर्तों पर निर्भर करती है। रद्दीकरण की पुष्टि से पहले सटीक नीति दिखाई जाती है।';

  @override
  String get faqQualityDamageQ => 'क्या सेवा के लिए कोई क्षति नीति है?';

  @override
  String get faqQualityDamageA =>
      'हाँ। 24 घंटों के भीतर फ़ोटो और बुकिंग विवरण के साथ क्षति की रिपोर्ट करें। दावों की समीक्षा नीति और पार्टनर सत्यापन के अनुसार की जाती है।';

  @override
  String get faqQualityRateQ => 'मैं अपने पार्टनर को रेट कैसे करूँ?';

  @override
  String get faqQualityRateA =>
      'सेवा पूरी होने के बाद, बुकिंग खोलें और टिप्पणियों के साथ रेटिंग सबमिट करें। आपकी प्रतिक्रिया हमें गुणवत्ता मानक बनाए रखने में मदद करती है।';

  @override
  String get faqSafetyTrustQ => 'मैं आपकी सेवा पर भरोसा कैसे करूँ?';

  @override
  String get faqSafetyTrustA =>
      'TaskTeddy पार्टनरों को सत्यापित करता है, बुकिंग ट्रैक करता है और गुणवत्ता रिपोर्ट की निगरानी करता है। हम समस्या समाधान के लिए इन-ऐप सहायता भी प्रदान करते हैं।';

  @override
  String get faqSafetyVerifiedQ => 'क्या TaskTeddy पार्टनर सत्यापित हैं?';

  @override
  String get faqSafetyVerifiedA =>
      'हाँ, हम सक्रियण से पहले पहचान सत्यापन और बुनियादी सेवा स्क्रीनिंग सहित ऑनबोर्डिंग जाँच करते हैं।';

  @override
  String get faqSafetyShareQ =>
      'TaskTeddy मेरे बारे में पार्टनरों के साथ क्या साझा करता है?';

  @override
  String get faqSafetyShareA =>
      'पार्टनर केवल सेवा पूर्ति के लिए आवश्यक विवरण देखते हैं, जैसे नाम, स्थान, स्लॉट और सेवा नोट्स।';

  @override
  String get faqSafetyUnsafeQ =>
      'बुकिंग के दौरान मुझे असुरक्षित महसूस हो - मैं क्या करूँ?';

  @override
  String get faqSafetyUnsafeA =>
      'तुरंत बातचीत समाप्त करें, सुरक्षित स्थान पर जाएँ, और इस पृष्ठ से सहायता को कॉल करें। आपात स्थिति में, पहले स्थानीय अधिकारियों से संपर्क करें।';

  @override
  String get referCodeCopied => 'रेफ़रल कोड कॉपी किया गया';

  @override
  String get referLinkCopied =>
      'आमंत्रण लिंक कॉपी किया गया। इसे अपने दोस्तों के साथ साझा करें।';

  @override
  String get referCouldNotOpenTerms => 'नियम लिंक नहीं खोला जा सका';

  @override
  String get referShareLink => 'आमंत्रण लिंक साझा करें';

  @override
  String get referCopyCode => 'रेफ़रल कोड कॉपी करें';

  @override
  String get referTitle => 'किसी दोस्त को TaskTeddy पर रेफ़र करें';

  @override
  String get referGet100 => '₹100 पाएँ';

  @override
  String get referFriendGets =>
      'आपके दोस्त को उनकी पहली TaskTeddy सेवा पर सीधे ₹50 की छूट मिलती है।';

  @override
  String get referStep1 => 'अपने दोस्त के साथ लिंक साझा करें';

  @override
  String get referStep2 => 'आपका दोस्त आपके लिंक से ऐप डाउनलोड करता है';

  @override
  String get referStep3 =>
      'उनकी पहली पूर्ण बुकिंग के बाद उन्हें ₹50 और आपको ₹100 मिलते हैं';

  @override
  String get referReadTerms => 'अधिक जानने के लिए हमारी शर्तें पढ़ें।';

  @override
  String get addrDeleteTitle => 'पता हटाएँ?';

  @override
  String get addrDeleteBody => 'यह सहेजा गया पता हटा दिया जाएगा।';

  @override
  String get addrDelete => 'हटाएँ';

  @override
  String get addrMyAddresses => 'मेरे पते';

  @override
  String get addrSubtitle =>
      'तेज़ चेकआउट के लिए अपने डिलीवरी पते सहेजें। डिफ़ॉल्ट स्वतः उपयोग होता है।';

  @override
  String get addrSaveNew => 'नया पता सहेजें';

  @override
  String get addrEmpty =>
      'अभी तक कोई सहेजा पता नहीं। चेकआउट तेज़ करने के लिए एक सहेजें।';

  @override
  String addrLandmark(String landmark) {
    return 'लैंडमार्क: $landmark';
  }

  @override
  String get addrSetAsDefault => 'डिफ़ॉल्ट के रूप में सेट करें';

  @override
  String get addrLoadError => 'आपके पते लोड नहीं हो सके।';

  @override
  String get addrLabelHome => 'घर';

  @override
  String get addrLabelWork => 'कार्यालय';

  @override
  String get addrLabelOther => 'अन्य';

  @override
  String get addrErrLocationServices =>
      'अपना पता पहचानने के लिए लोकेशन सेवाएँ चालू करें।';

  @override
  String get addrErrPermissionNeeded =>
      'आपका पता पहचानने के लिए लोकेशन अनुमति आवश्यक है।';

  @override
  String get addrErrEnablePermission =>
      'ऐप सेटिंग्स से लोकेशन अनुमति सक्षम करें।';

  @override
  String get addrErrMockLocation =>
      'मॉक लोकेशन पाई गई। कृपया वास्तविक डिवाइस GPS का उपयोग करें।';

  @override
  String get addrSelectedLocation => 'चयनित स्थान';

  @override
  String get addrAddressDetected => 'पता पहचाना गया';

  @override
  String get addrExactCoords => 'सटीक निर्देशांक चयनित';

  @override
  String get addrLocationDetected => 'स्थान पहचाना गया';

  @override
  String get addrPickExact => 'सटीक स्थान चुनें';

  @override
  String get addrUseCurrent => 'वर्तमान उपयोग करें';

  @override
  String get addrUseThisLocation => 'यह स्थान उपयोग करें';

  @override
  String get addrErrEnterDetails => 'कृपया अपने पते का विवरण दर्ज करें।';

  @override
  String get addrErrPincode => 'पिनकोड ठीक 6 अंकों का होना चाहिए।';

  @override
  String get addrEditorAddTitle => 'पता विवरण जोड़ें';

  @override
  String get addrEditorEditTitle => 'पता विवरण संपादित करें';

  @override
  String get addrSaveAddress => 'पता सहेजें';

  @override
  String get addrLocateOnMap => 'मानचित्र पर ढूँढें';

  @override
  String get addrLocateSubtitle =>
      'वर्तमान स्थान का उपयोग करें या मानचित्र पिन टैप करें।';

  @override
  String get addrChange => 'बदलें';

  @override
  String get addrUseCurrentLocation => 'वर्तमान स्थान का उपयोग करें';

  @override
  String get addrAddAddress => 'पता जोड़ें';

  @override
  String get addrHouseLabel => 'मकान नं. और मंज़िल *';

  @override
  String get addrHouseHint => 'जैसे 216, B-14';

  @override
  String get addrBuildingLabel => 'इमारत और ब्लॉक नं. (वैकल्पिक)';

  @override
  String get addrBuildingHint => 'टावर, ब्लॉक, विंग, आदि';

  @override
  String get addrStreetLabel => 'गली / क्षेत्र *';

  @override
  String get addrStreetHint => 'गली, इलाका या सेक्टर';

  @override
  String get addrCityLabel => 'शहर *';

  @override
  String get addrCityHint => 'आपका शहर';

  @override
  String get addrLandmarkLabel => 'लैंडमार्क और क्षेत्र नाम (वैकल्पिक)';

  @override
  String get addrLandmarkHint => 'नज़दीकी ज्ञात स्थान';

  @override
  String get addrPincodeLabel => 'पिनकोड *';

  @override
  String get addrPincodeHint => '6-अंकीय पिन';

  @override
  String get addrAddLabel => 'पता लेबल जोड़ें';

  @override
  String get addrSetDefaultTitle => 'डिफ़ॉल्ट पते के रूप में सेट करें';

  @override
  String get addrSetDefaultSub => 'चेकआउट पर स्वतः उपयोग होता है।';

  @override
  String get tasksSortNewest => 'नवीनतम';

  @override
  String get tasksSortDueSoon => 'जल्द देय';

  @override
  String get tasksSortBudgetHigh => 'उच्च बजट';

  @override
  String get tasksNoTasksFound => 'कोई टास्क नहीं मिला';

  @override
  String get tasksEmptySubtitle =>
      'एक टास्क पोस्ट करें और आस-पास के टास्कर आपको ऑफ़र भेजेंगे।';

  @override
  String get taskBudgetFixed => 'निश्चित कीमत';

  @override
  String get taskBudgetHourly => 'प्रति घंटा दर';

  @override
  String get taskBudgetFixedHelper => 'पूरे टास्क के लिए एक अंतिम बजट';

  @override
  String get taskBudgetHourlyHelper =>
      'प्रति घंटा दर, फिर अपेक्षित घंटे जोड़ें';

  @override
  String get taskUrgencyStandard => 'सामान्य';

  @override
  String get taskUrgencyPriority => 'प्राथमिकता';

  @override
  String get taskUrgencyUrgent => 'अत्यावश्यक';

  @override
  String get taskUrgencyStandardSub => 'सामान्य समय-सीमा में';

  @override
  String get taskUrgencyPrioritySub => 'तेज़ प्रतिक्रिया चाहिए';

  @override
  String get taskUrgencyUrgentSub => 'तुरंत ध्यान देने की आवश्यकता';

  @override
  String get taskReviewThanks => 'आपकी समीक्षा के लिए धन्यवाद!';

  @override
  String get taskAcceptOffer => 'ऑफ़र स्वीकार करें';

  @override
  String taskAcceptOfferBody(String name, int amount) {
    return 'यह टास्क $name को ₹$amount में सौंपें?\n\nअन्य ऑफ़र स्वतः अस्वीकार कर दिए जाएँगे।';
  }

  @override
  String get taskOfferAccepted => 'ऑफ़र सफलतापूर्वक स्वीकार किया गया!';

  @override
  String get taskOfferDeclined => 'ऑफ़र अस्वीकार किया गया';

  @override
  String get taskCancelledSuccess => 'टास्क सफलतापूर्वक रद्द किया गया';

  @override
  String get taskYourTasker => 'आपका टास्कर';

  @override
  String get taskJustNow => 'अभी-अभी';

  @override
  String taskMinutesAgoFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count मिनट पहले',
      one: '1 मिनट पहले',
    );
    return '$_temp0';
  }

  @override
  String taskHoursAgoFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count घंटे पहले',
      one: '1 घंटा पहले',
    );
    return '$_temp0';
  }

  @override
  String taskDaysAgoFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count दिन पहले',
      one: '1 दिन पहले',
    );
    return '$_temp0';
  }

  @override
  String get taskOnTheWay => 'टास्कर रास्ते में है';

  @override
  String get taskLive => 'लाइव';

  @override
  String taskOnTheWaySince(String time) {
    return '$time से रास्ते में';
  }

  @override
  String taskLocationUpdated(String time) {
    return 'लोकेशन $time अपडेट हुई';
  }

  @override
  String get taskWaitingLocation => 'लोकेशन अपडेट का इंतज़ार';

  @override
  String taskMetersAway(int meters) {
    return '$meters मी दूर';
  }

  @override
  String taskKmAway(String km) {
    return '$km किमी दूर';
  }

  @override
  String get taskDetailsTitle => 'टास्क विवरण';

  @override
  String taskBidsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count बोलियाँ',
      one: '1 बोली',
    );
    return '$_temp0';
  }

  @override
  String get taskLocationLabel => 'स्थान';

  @override
  String get taskOffers => 'ऑफ़र';

  @override
  String taskOffersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ऑफ़र',
      one: '1 ऑफ़र',
    );
    return '$_temp0';
  }

  @override
  String get taskNoOffers =>
      'अभी तक कोई ऑफ़र नहीं — टास्कर जल्द ही ऑफ़र भेजेंगे';

  @override
  String get taskCompletionOtp => 'पूर्णता OTP';

  @override
  String get taskCompletionOtpHint =>
      'जब टास्कर काम पूरा करे तो यह OTP उनके साथ साझा करें';

  @override
  String get taskEditTask => 'टास्क संपादित करें';

  @override
  String get taskCancelTask => 'टास्क रद्द करें';

  @override
  String taskRateName(String name) {
    return '$name को रेट करें';
  }

  @override
  String get cancelReasonNoLongerNeeded => 'अब आवश्यकता नहीं';

  @override
  String get cancelReasonPostedByMistake => 'गलती से पोस्ट किया';

  @override
  String get cancelReasonFoundElsewhere => 'कहीं और मदद मिल गई';

  @override
  String get taskCancelTaskSheet => 'टास्क रद्द करें';

  @override
  String taskCancelWhy(String title) {
    return 'आप \"$title\" क्यों रद्द कर रहे हैं?';
  }

  @override
  String get taskCancelAssignedWarning =>
      'यह टास्क सौंपा जा चुका है। टास्कर को सूचित किया जाएगा कि आपने रद्द किया।';

  @override
  String get taskAddNoteOptional => 'एक नोट जोड़ें (वैकल्पिक)';

  @override
  String get taskKeepTask => 'टास्क रखें';

  @override
  String get taskReviewHint => 'कुछ शब्द साझा करें (वैकल्पिक)';

  @override
  String get taskSubmitReview => 'समीक्षा सबमिट करें';

  @override
  String get taskFailedOpenChat => 'चैट नहीं खोली जा सकी';

  @override
  String get chatClosed => 'यह चैट बंद है — कार्य पूरा हो चुका है।';

  @override
  String get taskChat => 'चैट';

  @override
  String get taskStatusAccepted => 'स्वीकृत';

  @override
  String get taskStatusRejected => 'अस्वीकृत';

  @override
  String get taskReject => 'अस्वीकार करें';

  @override
  String get taskAcceptBid => 'बोली स्वीकार करें';

  @override
  String taskBidAmount(int amount) {
    return 'बोली: ₹$amount';
  }

  @override
  String get taskLocationUpdatedPosition =>
      'आपकी वर्तमान स्थिति से लोकेशन अपडेट हुई';

  @override
  String get taskMaxPhotos => 'आप अधिकतम 6 फ़ोटो जोड़ सकते हैं';

  @override
  String get taskTakePhoto => 'फ़ोटो लें';

  @override
  String get taskChooseGallery => 'गैलरी से चुनें';

  @override
  String get taskCameraError => 'अभी कैमरा नहीं खोला जा सका';

  @override
  String taskOnlyFirstPhotos(int count) {
    return 'केवल पहली $count फ़ोटो जोड़ी गईं';
  }

  @override
  String get taskGalleryError => 'अभी गैलरी नहीं खोली जा सकी';

  @override
  String taskFieldRequired(String field) {
    return '$field आवश्यक है';
  }

  @override
  String get taskFieldTitle => 'टास्क शीर्षक';

  @override
  String get taskFieldDescription => 'विवरण';

  @override
  String get taskFieldBudget => 'बजट';

  @override
  String get taskFieldLocation => 'स्थान';

  @override
  String get taskTitleMin => 'शीर्षक कम से कम 8 अक्षरों का होना चाहिए';

  @override
  String get taskDescMin => 'अधिक विवरण जोड़ें ताकि टास्कर सही कोट कर सकें';

  @override
  String get taskBudgetInvalid => 'एक मान्य बजट राशि दर्ज करें';

  @override
  String get taskBudgetInsightPrompt =>
      'बाज़ार सीमा जाँचने के लिए बजट और स्थान दर्ज करें';

  @override
  String taskBudgetSuggested(String amount) {
    return 'सुझावित: ₹$amount';
  }

  @override
  String taskBudgetRecommended(String min, String max) {
    return 'आपके क्षेत्र में अनुशंसित: ₹$min - ₹$max';
  }

  @override
  String get taskBudgetInsightOk => 'बजट जानकारी सफलतापूर्वक प्राप्त हुई';

  @override
  String get taskBudgetInsightUnavailable =>
      'बाज़ार जानकारी फ़िलहाल उपलब्ध नहीं है। आप फिर भी अपना टास्क पोस्ट कर सकते हैं।';

  @override
  String get taskCompleteRequired => 'कृपया आवश्यक फ़ील्ड पूरी करें';

  @override
  String get taskPhotosUploadFailed =>
      'फ़ोटो अपलोड नहीं हो सकीं — उनके बिना पोस्ट किया जा रहा है।';

  @override
  String get taskBriefTagline =>
      'सत्यापित टास्कर्स से बेहतर बोलियाँ पाने के लिए स्पष्ट विवरण लिखें';

  @override
  String get taskGoodBriefs =>
      'अच्छे विवरण जल्दी बंद होते हैं। दायरा, पहुँच विवरण और वास्तविक बजट शामिल करें।';

  @override
  String get taskSecBasics => 'टास्क मूल बातें';

  @override
  String get taskSecBasicsSub => 'श्रेणी और टास्क विवरण';

  @override
  String get taskCategoryLabel => 'श्रेणी';

  @override
  String get taskTitleLabel => 'टास्क शीर्षक *';

  @override
  String get taskTitleHint => 'जैसे 2BHK अपार्टमेंट की गहरी सफ़ाई';

  @override
  String get taskDescLabel => 'विवरण *';

  @override
  String get taskDescHint =>
      'आकार, मंज़िलें, ज़रूरी उपकरण और स्वीकार करने से पहले टास्कर को जानने योग्य बातें बताएँ।';

  @override
  String get taskSecPhotos => 'टास्क फ़ोटो';

  @override
  String get taskSecPhotosSub =>
      'भरोसे और तेज़ बोलियों के लिए 6 तक असली फ़ोटो जोड़ें';

  @override
  String get taskNoPhotos => 'अभी तक कोई फ़ोटो नहीं जोड़ी';

  @override
  String taskPhotosAdded(int count) {
    return '$count/6 फ़ोटो जोड़ी गईं';
  }

  @override
  String get taskAddPhotos => 'फ़ोटो जोड़ें';

  @override
  String get taskPhotoHint =>
      'टास्क क्षेत्र, उपकरण/सामग्री और वर्तमान स्थिति दिखाएँ।';

  @override
  String get taskSecBudget => 'बजट और प्राथमिकता';

  @override
  String get taskSecBudgetSub => 'कीमत प्रारूप और तात्कालिकता सेट करें';

  @override
  String get taskBudgetFormat => 'बजट प्रारूप';

  @override
  String get taskTotalBudget => 'कुल बजट (₹) *';

  @override
  String get taskHourlyBudget => 'प्रति घंटा बजट (₹) *';

  @override
  String get taskHoursLabel => 'घंटे *';

  @override
  String get taskRequiredShort => 'आवश्यक';

  @override
  String get taskCheckMarket => 'बाज़ार सीमा जाँचें';

  @override
  String get taskUrgencyLabel => 'तात्कालिकता';

  @override
  String get taskSecLocation => 'स्थान और शेड्यूल';

  @override
  String get taskSecLocationSub => 'टास्क कहाँ और कब होना चाहिए';

  @override
  String get taskLocationMatchHint =>
      'तेज़ टास्क मिलान के लिए अपने फ़ोन की वर्तमान लोकेशन उपयोग करें।';

  @override
  String taskGps(String lat, String lng) {
    return 'GPS: $lat, $lng';
  }

  @override
  String get taskServiceLocationLabel => 'सेवा स्थान *';

  @override
  String get taskLocationHint => 'क्षेत्र, शहर';

  @override
  String get taskLandmarkLabel2 => 'लैंडमार्क (वैकल्पिक)';

  @override
  String get taskLandmarkHint2 => 'नज़दीकी मॉल, मेट्रो स्टेशन, गेट नंबर...';

  @override
  String get taskDeadlineLabel => 'समय-सीमा तारीख *';

  @override
  String get taskPreferredTime => 'पसंदीदा समय';

  @override
  String get taskAnytime => 'कभी भी';

  @override
  String get taskSecNotes => 'अतिरिक्त नोट्स';

  @override
  String get taskSecNotesSub =>
      'वैकल्पिक विवरण जो टास्कर को तैयारी में मदद करें';

  @override
  String get taskNotesHint =>
      'पार्किंग जानकारी, प्रवेश नियम, उपलब्ध उपकरण, पसंदीदा संचार...';

  @override
  String get taskSecSummary => 'लाइव सारांश';

  @override
  String get taskSecSummarySub => 'देखें कि आपकी पोस्टिंग कैसी दिखेगी';

  @override
  String get taskUntitled => 'बिना शीर्षक टास्क';

  @override
  String get taskSetBudget => 'बजट सेट करें';

  @override
  String get taskLocationPending => 'स्थान लंबित';

  @override
  String get taskNoPhotosShort => 'कोई फ़ोटो नहीं';

  @override
  String taskPhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ोटो',
      one: '1 फ़ोटो',
    );
    return '$_temp0';
  }

  @override
  String get taskUploadingPhotos => 'फ़ोटो अपलोड हो रही हैं...';

  @override
  String get taskPostTask => 'टास्क पोस्ट करें';

  @override
  String get taskStatusOpen => 'खुला';

  @override
  String get taskStatusAssigned => 'सौंपा गया';

  @override
  String get taskStatusInProgress => 'प्रगति में';

  @override
  String get taskStatusCompleted => 'पूर्ण';

  @override
  String get taskStatusCancelled => 'रद्द';

  @override
  String get taskStatusUnderReview => 'समीक्षा में';

  @override
  String get taskStatusNotApproved => 'स्वीकृत नहीं';

  @override
  String get taskUnderReviewTitle => 'समीक्षा में';

  @override
  String get taskUnderReviewNote =>
      'हमारी टीम इस टास्क की समीक्षा कर रही है — यह आमतौर पर 5 मिनट के भीतर लाइव हो जाता है।';

  @override
  String get taskNotApprovedTitle => 'स्वीकृत नहीं';

  @override
  String get taskNotApprovedNote =>
      'यह टास्क समीक्षा के दौरान स्वीकृत नहीं हुआ।';

  @override
  String taskRejectedReason(String reason) {
    return 'कारण: $reason';
  }

  @override
  String get taskPostAgain => 'फिर से पोस्ट करें';

  @override
  String get taskPostedTitle => 'टास्क समीक्षा के लिए भेजा गया';

  @override
  String taskPostedBody(String title) {
    return '\"$title\"';
  }

  @override
  String get taskPostedReviewNote =>
      'हमारी टीम हर टास्क की गुणवत्ता और सुरक्षा के लिए समीक्षा करती है — आमतौर पर 5 मिनट के भीतर स्वीकृत हो जाता है। लाइव होने पर आपको सूचित किया जाएगा।';

  @override
  String get taskViewMyTasks => 'मेरे टास्क देखें';

  @override
  String get taskPostAnother => 'एक और टास्क पोस्ट करें';

  @override
  String get taskUpdatedSuccess => 'टास्क सफलतापूर्वक अपडेट हुआ';

  @override
  String get taskEditTitle => 'टास्क शीर्षक';

  @override
  String get taskEditTitleHint => 'जैसे टपकता नल ठीक करें';

  @override
  String get taskEditTitleRequired => 'शीर्षक आवश्यक है';

  @override
  String get taskEditDescHint => 'समस्या का वर्णन करें...';

  @override
  String get taskEditDescRequired => 'विवरण आवश्यक है';

  @override
  String get taskEditDescMin => 'अधिक विवरण जोड़ें';

  @override
  String get taskEditLocHint => 'यह कहाँ किया जाना चाहिए?';

  @override
  String get taskEditLocRequired => 'स्थान आवश्यक है';

  @override
  String get taskEditBudgetLabel => 'बजट (₹)';

  @override
  String get taskEditBudgetHint => 'जैसे 500';

  @override
  String get taskEditBudgetRequired => 'बजट आवश्यक है';

  @override
  String get taskEditBudgetInvalid => 'एक मान्य राशि दर्ज करें';

  @override
  String get taskSaveChanges => 'बदलाव सहेजें';

  @override
  String taskDue(String date) {
    return 'देय $date';
  }

  @override
  String get commonChooseGallery => 'गैलरी से चुनें';

  @override
  String get commonTakePhoto => 'फ़ोटो लें';

  @override
  String get profileChangePhoto => 'फ़ोटो बदलें';

  @override
  String get profilePhotoUpdated => 'प्रोफ़ाइल फ़ोटो अपडेट हो गई';

  @override
  String reputationSummary(int jobs, int reliability) {
    return '$jobs काम • $reliability% भरोसेमंद';
  }

  @override
  String get taskTaskerCancelledReview =>
      'आपके टास्कर ने रद्द कर दिया — कृपया कोई और ऑफ़र चुनें।';
}
