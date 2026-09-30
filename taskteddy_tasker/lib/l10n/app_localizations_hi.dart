// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppL10nHi extends AppL10n {
  AppL10nHi([String locale = 'hi']) : super(locale);

  @override
  String get walletDuesSettled =>
      'बकाया चुकता — अब आप फिर से ब्राउज़ कर सकते हैं।';

  @override
  String get browseDuesTitle => 'ब्राउज़िंग रुकी हुई है';

  @override
  String get browseDuesBody =>
      'नकद कामों से आपके प्लेटफ़ॉर्म शुल्क बकाया हैं। कार्य ब्राउज़ करना जारी रखने के लिए अपना वॉलेट सेटल करें।';

  @override
  String browseDuesAmount(String amount) {
    return 'बकाया: ₹$amount';
  }

  @override
  String get browseSettleNow => 'अभी सेटल करें';

  @override
  String get appTagline => 'अपने समय के अनुसार काम पाएँ और पैसे कमाएँ!';

  @override
  String get navHome => 'होम';

  @override
  String get navBrowse => 'खोजें';

  @override
  String get navApplied => 'आवेदित';

  @override
  String get navEarnings => 'कमाई';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get goodMorning => 'सुप्रभात';

  @override
  String get goodAfternoon => 'नमस्कार';

  @override
  String get goodEvening => 'शुभ संध्या';

  @override
  String get statusOnline => 'ऑनलाइन';

  @override
  String get statusOffline => 'ऑफ़लाइन';

  @override
  String get dashAvailableForWork => 'नए कार्यों के लिए उपलब्ध';

  @override
  String get dashTapToGoOnline => 'ऑनलाइन होकर कार्य पाने के लिए टैप करें';

  @override
  String get dashStatReliability => 'विश्वसनीयता';

  @override
  String get dashStatLevel => 'स्तर';

  @override
  String get dashLevelNew => 'नया';

  @override
  String get earningsOverview => 'कमाई का सारांश';

  @override
  String get wallet => 'वॉलेट';

  @override
  String get today => 'आज';

  @override
  String get thisWeek => 'इस सप्ताह';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get statRating => 'रेटिंग';

  @override
  String get statTasks => 'कार्य';

  @override
  String get statRank => 'रैंक';

  @override
  String get statCoins => 'कॉइन';

  @override
  String get qaBrowseTasks => 'कार्य खोजें';

  @override
  String get qaApplications => 'आवेदन';

  @override
  String get qaCompleted => 'पूर्ण';

  @override
  String get qaMessages => 'संदेश';

  @override
  String get tasksNearYou => 'आपके नज़दीकी कार्य';

  @override
  String get myActiveJobs => 'मेरे सक्रिय कार्य';

  @override
  String get myBookings => 'मेरी बुकिंग';

  @override
  String get seeAll => 'सभी देखें';

  @override
  String get noTasksAvailable => 'अभी कोई कार्य उपलब्ध नहीं है';

  @override
  String get noActiveJobs => 'कोई सक्रिय कार्य नहीं';

  @override
  String get searchTasksHint => 'कार्य, स्थान खोजें...';

  @override
  String get filterTasks => 'कार्य फ़िल्टर करें';

  @override
  String get budgetRange => 'बजट सीमा';

  @override
  String get applyFilters => 'फ़िल्टर लागू करें';

  @override
  String get budget => 'बजट';

  @override
  String get quickApply => 'त्वरित आवेदन';

  @override
  String get getVerifiedToApply => 'आवेदन के लिए सत्यापित हों';

  @override
  String get verificationRequired => 'सत्यापन आवश्यक है';

  @override
  String get completeKyc =>
      'कार्यों के लिए आवेदन शुरू करने हेतु अपना केवाईसी सत्यापन पूरा करें।';

  @override
  String get getVerified => 'सत्यापित हों';

  @override
  String get noTasksFound => 'कोई कार्य नहीं मिला';

  @override
  String get tryAdjustingFilters => 'फ़िल्टर या खोज बदलकर देखें';

  @override
  String get loginOrSignup => 'लॉग इन या साइन अप करें';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get enterValidMobile => 'मान्य 10-अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get enterFullOtp => 'कृपया पूरा 6-अंकों का ओटीपी दर्ज करें';

  @override
  String get changeNumber => 'नंबर बदलें';

  @override
  String get resendOtp => 'ओटीपी दोबारा भेजें';

  @override
  String resendInSeconds(int seconds) {
    return '$seconds सेकंड में दोबारा भेजें';
  }

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get langEnglish => 'English';

  @override
  String get langHindi => 'हिन्दी (Hindi)';

  @override
  String get langPunjabi => 'ਪੰਜਾਬੀ (Punjabi)';

  @override
  String get safety => 'सुरक्षा';

  @override
  String get blockedUsers => 'अवरुद्ध उपयोगकर्ता';

  @override
  String get manage => 'प्रबंधित करें';

  @override
  String get noBlockedUsers => 'कोई अवरुद्ध उपयोगकर्ता नहीं';

  @override
  String get workPreferences => 'कार्य प्राथमिकताएँ';

  @override
  String get availability => 'उपलब्धता';

  @override
  String get actionApply => 'आवेदन करें';

  @override
  String get actionAccept => 'स्वीकार करें';

  @override
  String get actionDecline => 'अस्वीकार करें';

  @override
  String get actionCancel => 'रद्द करें';

  @override
  String get actionSave => 'सहेजें';

  @override
  String get actionRetry => 'पुनः प्रयास करें';

  @override
  String get actionContinue => 'जारी रखें';

  @override
  String get actionSubmit => 'जमा करें';

  @override
  String get actionOk => 'ठीक है';

  @override
  String get actionYes => 'हाँ';

  @override
  String get actionNo => 'नहीं';

  @override
  String get actionClose => 'बंद करें';

  @override
  String get actionReport => 'रिपोर्ट करें';

  @override
  String get actionBlock => 'अवरुद्ध करें';

  @override
  String get actionOnMyWay => 'मैं रास्ते में हूँ';

  @override
  String get bankTitle => 'बैंक और भुगतान';

  @override
  String get bankPayoutMethods => 'भुगतान के तरीके';

  @override
  String get bankNoMethods => 'अभी तक कोई भुगतान तरीका नहीं जोड़ा गया।';

  @override
  String bankSetDefaultSuccess(String name) {
    return '$name को डिफ़ॉल्ट भुगतान तरीका बनाया गया';
  }

  @override
  String get bankAddPaymentMethod => 'भुगतान तरीका जोड़ें';

  @override
  String get profileMyApplications => 'मेरे आवेदन';

  @override
  String get profileTotal => 'कुल';

  @override
  String get profilePending => 'लंबित';

  @override
  String get profileAccepted => 'स्वीकृत';

  @override
  String get profileCompleted => 'पूर्ण';

  @override
  String get profileRejected => 'अस्वीकृत';

  @override
  String get profileAll => 'सभी';

  @override
  String get profileNothingHere => 'यहाँ अभी कुछ नहीं है';

  @override
  String get profileBrowseTasksStart => 'शुरू करने के लिए टास्क देखें';

  @override
  String get profileWithdrawBid => 'बोली वापस लें';

  @override
  String get profileWithdrawBidConfirm =>
      'क्या आप वाकई यह बोली वापस लेना चाहते हैं?';

  @override
  String get profileWithdraw => 'वापस लें';

  @override
  String get profileBidWithdrawn => 'बोली वापस ले ली गई';

  @override
  String get profileCompleteTask => 'टास्क पूरा करें';

  @override
  String get profileCompleteTaskOtpPrompt =>
      'इस टास्क को पूरा करने के लिए ग्राहक द्वारा साझा किया गया OTP दर्ज करें।';

  @override
  String get profileOtp => 'OTP';

  @override
  String get profileEnterOtp => 'OTP दर्ज करें';

  @override
  String get chatClosed => 'यह चैट बंद है — कार्य पूरा हो चुका है।';

  @override
  String get walletMyWallet => 'मेरा वॉलेट';

  @override
  String get walletTotalBalance => 'कुल बैलेंस';

  @override
  String get walletAvailable => 'उपलब्ध';

  @override
  String get walletEarnings => 'कमाई';

  @override
  String get walletTransactions => 'लेन-देन';

  @override
  String get walletWithdraw => 'निकालें';

  @override
  String get walletTasksDone => 'पूरे किए टास्क';

  @override
  String get walletNoTransactions => 'अभी तक कोई लेन-देन नहीं';

  @override
  String get walletNoTransactionsBody =>
      'आपकी कमाई और निकासी यहाँ दिखाई देंगी।';

  @override
  String walletPlatformDues(String amount) {
    return 'प्लेटफ़ॉर्म बकाया: ₹$amount';
  }

  @override
  String get walletDuesBody =>
      'यह नकद कामों पर बकाया कमीशन है। इसे चुकाने के लिए अपना वॉलेट टॉप-अप रखें।';

  @override
  String timeMinutesAgo(int count) {
    return '$count मिनट पहले';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count घंटे पहले';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count दिन पहले';
  }

  @override
  String get commonChooseGallery => 'गैलरी से चुनें';

  @override
  String get commonTakePhoto => 'फ़ोटो लें';

  @override
  String get profileStatusNotSelected => 'चयनित नहीं';

  @override
  String get profileStatusUnderReview => 'समीक्षाधीन';

  @override
  String get profileApplied => 'आवेदित';

  @override
  String get profileStepDecision => 'निर्णय';

  @override
  String get profileYourBid => 'आपकी बोली';

  @override
  String get profileTaskBudget => 'कार्य बजट';

  @override
  String get profileYouEarn => 'आपकी कमाई';

  @override
  String get profileStartTask => 'कार्य शुरू करें';

  @override
  String profileAppliedAgo(String time) {
    return '$time आवेदन किया';
  }

  @override
  String get profileMyProfile => 'मेरी प्रोफ़ाइल';

  @override
  String profileReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count समीक्षाएँ',
      one: '1 समीक्षा',
    );
    return '$_temp0';
  }

  @override
  String get profileTasksDone => 'पूरे किए कार्य';

  @override
  String get profileEarned => 'कमाए';

  @override
  String get profileAvailableForTasks => 'कार्यों के लिए उपलब्ध';

  @override
  String get profileNotAvailable => 'उपलब्ध नहीं';

  @override
  String get profileVisibleToCustomers => 'आप ग्राहकों को दिख रहे हैं';

  @override
  String get profileWontReceiveTasks => 'आपको नए कार्य नहीं मिलेंगे';

  @override
  String get profileCompletion => 'पूर्णता';

  @override
  String get profileAvgResponse => 'औसत प्रतिक्रिया';

  @override
  String get profileMemberSince => 'सदस्य बने';

  @override
  String get profileAboutMe => 'मेरे बारे में';

  @override
  String get profileEdit => 'संपादित करें';

  @override
  String get profileMySkills => 'मेरे कौशल';

  @override
  String get profileMyWork => 'मेरा काम';

  @override
  String get profileAdd => 'जोड़ें';

  @override
  String get profileViewAll => 'सभी देखें';

  @override
  String get profileSecAccount => 'खाता';

  @override
  String get profileSecWork => 'कार्य';

  @override
  String get profileSecSupportLegal => 'सहायता और कानूनी';

  @override
  String get profileEditProfile => 'प्रोफ़ाइल संपादित करें';

  @override
  String get profileVerificationDocuments => 'सत्यापन और दस्तावेज़';

  @override
  String get profileBankPayment => 'बैंक और भुगतान';

  @override
  String get profileSetWorkingHours => 'अपने कार्य घंटे तय करें';

  @override
  String get profileWorkPortfolio => 'कार्य पोर्टफोलियो';

  @override
  String get profileShowcaseWork => 'अपना बेहतरीन काम दिखाएँ';

  @override
  String profilePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count फ़ोटो',
      one: '1 फ़ोटो',
    );
    return '$_temp0';
  }

  @override
  String get profileCompletedTasks => 'पूर्ण किए कार्य';

  @override
  String get profileMyReviews => 'मेरी समीक्षाएँ';

  @override
  String get profileEarningsPayouts => 'कमाई और भुगतान';

  @override
  String get profileHelpSupport => 'सहायता और समर्थन';

  @override
  String get profileTerms => 'नियम और शर्तें';

  @override
  String get profilePrivacy => 'गोपनीयता नीति';

  @override
  String get profileRateUs => 'प्ले स्टोर पर हमें रेट करें';

  @override
  String get profileReferEarn => 'रेफ़र करें और ₹200 कमाएँ';

  @override
  String get profileSignOut => 'साइन आउट';

  @override
  String profileVersion(String version) {
    return 'संस्करण $version';
  }

  @override
  String get profileRedirectTitle => 'बाहरी लिंक पर रीडायरेक्ट';

  @override
  String profileRedirectBody(String url) {
    return 'आपको एक बाहरी वेबसाइट पर रीडायरेक्ट किया जा रहा है:\n\n$url\n\nक्या आप जारी रखना चाहते हैं?';
  }

  @override
  String get profileCouldNotOpenLink => 'लिंक नहीं खोल सके';

  @override
  String get profileUploadingPhoto => 'फ़ोटो अपलोड हो रही है…';

  @override
  String get profilePictureUpdated => 'प्रोफ़ाइल फ़ोटो अपडेट हुई';

  @override
  String get profileUpdatePicture => 'प्रोफ़ाइल फ़ोटो अपडेट करें';

  @override
  String get profileEditAboutMe => 'मेरे बारे में संपादित करें';

  @override
  String get profileWriteAboutYourself => 'अपने बारे में लिखें...';

  @override
  String get profileBioUpdated => 'बायो अपडेट हुआ';

  @override
  String get profileEditSkills => 'कौशल संपादित करें';

  @override
  String get profileSaveSkills => 'कौशल सहेजें';

  @override
  String get profileSkillsUpdated => 'कौशल अपडेट हुए';

  @override
  String get profileNoCoins => 'कोई TaskCoins नहीं';

  @override
  String get profileNoCoinsBody =>
      'आपके वॉलेट में भुनाने के लिए 0 TaskCoins हैं।';

  @override
  String get profileRedeemCoins => 'TaskCoins भुनाएँ';

  @override
  String profileCoinsValue(int coins) {
    return '$coins कॉइन = ₹$coins';
  }

  @override
  String get profileCoinsCredited =>
      'कॉइन आपके डिफ़ॉल्ट भुगतान तरीके में जमा किए जाएँगे।';

  @override
  String profileCoinsWillCredit(int amount) {
    return '₹$amount आपके खाते में जमा किए जाएँगे';
  }

  @override
  String get profileRedeemAll => 'सभी भुनाएँ';

  @override
  String get profileAddPhotosWork => 'अपने काम की फ़ोटो जोड़ें';

  @override
  String get profilePortfolioHelps =>
      'एक मज़बूत पोर्टफोलियो आपको ज़्यादा काम दिलाने में मदद करता है';

  @override
  String get profileNotSet => 'तय नहीं';

  @override
  String get profileEveryDay => 'हर दिन';

  @override
  String get profileHoursVary => 'घंटे अलग-अलग';

  @override
  String get walletWithdrawMoney => 'पैसे निकालें';

  @override
  String get walletAmount => 'राशि';

  @override
  String walletAvailableBalance(String amount) {
    return 'उपलब्ध: ₹$amount';
  }

  @override
  String get walletEnterValidAmount => 'कृपया एक मान्य राशि दर्ज करें';

  @override
  String get walletInsufficientBalance => 'अपर्याप्त बैलेंस';

  @override
  String walletWithdrawalRequested(String amount) {
    return '₹$amount की निकासी का अनुरोध किया गया!';
  }

  @override
  String get walletNoEarnings7Days => 'पिछले 7 दिनों में कोई कमाई नहीं';

  @override
  String get walletEarningsLast7 => 'कमाई - पिछले 7 दिन';

  @override
  String get walletTotalEarned => 'कुल कमाई';

  @override
  String get walletJobsCompleted => 'पूरे किए काम';

  @override
  String get walletAvgPerJob => 'प्रति काम औसत';

  @override
  String get verifTitle => 'सत्यापन और दस्तावेज़';

  @override
  String get verifProgress => 'सत्यापन प्रगति';

  @override
  String verifDocsVerified(int verified, int total) {
    return '$total में से $verified दस्तावेज़ सत्यापित';
  }

  @override
  String get verifDocuments => 'दस्तावेज़';

  @override
  String get verifAadhaar => 'आधार कार्ड';

  @override
  String get verifAadhaarUpload => 'पहचान सत्यापन के लिए आधार अपलोड करें';

  @override
  String get verifPan => 'पैन कार्ड';

  @override
  String get verifPanUpload => 'कर उद्देश्यों के लिए पैन अपलोड करें';

  @override
  String get verifUnderReview => 'समीक्षाधीन';

  @override
  String get verifAddressProof => 'पते का प्रमाण';

  @override
  String get verifAddressVerified => 'पता सफलतापूर्वक सत्यापित';

  @override
  String get verifAddressUpload => 'बिजली बिल या किराया अनुबंध अपलोड करें';

  @override
  String get verifSelfie => 'सेल्फी सत्यापन';

  @override
  String get verifIdentityConfirmed => 'पहचान की पुष्टि हुई';

  @override
  String get verifSelfieUpload => 'पहचान की पुष्टि के लिए सेल्फी लें';

  @override
  String get verifUnlockPremium =>
      'प्रीमियम कार्य और अधिक भुगतान अनलॉक करने के लिए सभी सत्यापन पूरे करें।';

  @override
  String get verifStatusVerified => 'सत्यापित';

  @override
  String get verifStatusPending => 'लंबित';

  @override
  String get verifStatusRejected => 'अस्वीकृत';

  @override
  String get verifStatusUpload => 'अपलोड';

  @override
  String verifAlreadyVerified(String title) {
    return '$title पहले से सत्यापित है!';
  }

  @override
  String verifUploadTitle(String title) {
    return '$title अपलोड करें';
  }

  @override
  String verifUploading(String title) {
    return '$title अपलोड हो रहा है…';
  }

  @override
  String verifSubmitted(String title) {
    return '$title जमा किया गया। हमारी टीम इसकी जल्द समीक्षा करेगी।';
  }

  @override
  String get availSaveSchedule => 'शेड्यूल सहेजें';

  @override
  String get availSaved => 'उपलब्धता सहेजी गई';

  @override
  String get availEndAfterStart => 'समाप्ति समय शुरू समय के बाद होना चाहिए';

  @override
  String get availStartTime => 'शुरू समय';

  @override
  String get availEndTime => 'समाप्ति समय';

  @override
  String get availYourWeeklyHours => 'आपके साप्ताहिक घंटे';

  @override
  String get availNotSetTap => 'तय नहीं - कार्य घंटे जोड़ने के लिए टैप करें';

  @override
  String get availStart => 'शुरू';

  @override
  String get availEnd => 'समाप्त';

  @override
  String get availAvailableDay => 'उपलब्ध';

  @override
  String get availOff => 'बंद';

  @override
  String get dayMonday => 'सोमवार';

  @override
  String get dayTuesday => 'मंगलवार';

  @override
  String get dayWednesday => 'बुधवार';

  @override
  String get dayThursday => 'गुरुवार';

  @override
  String get dayFriday => 'शुक्रवार';

  @override
  String get daySaturday => 'शनिवार';

  @override
  String get daySunday => 'रविवार';

  @override
  String timeWeeksAgo(int count) {
    return '$count सप्ताह पहले';
  }

  @override
  String get msgSearchChats => 'चैट खोजें…';

  @override
  String get msgNoResults => 'कोई परिणाम नहीं मिला';

  @override
  String get msgNoConversations => 'अभी कोई बातचीत नहीं';

  @override
  String get msgTryDifferentSearch => 'कोई दूसरा खोज शब्द आज़माएँ';

  @override
  String get msgChatsWillAppear =>
      'जब आप कोई कार्य शुरू करेंगे,\nतो आपकी चैट यहाँ दिखेंगी।';

  @override
  String get msgTapToOpen => 'चैट खोलने के लिए टैप करें';

  @override
  String get msgYesterday => 'कल';

  @override
  String get msgSayHello => 'नमस्ते कहें!';

  @override
  String get msgStartConversation => 'बातचीत शुरू करें और\nकाम आगे बढ़ाएँ।';

  @override
  String get msgTakePhoto => 'फ़ोटो लें';

  @override
  String msgErrorSelectingImage(String error) {
    return 'इमेज चुनने में त्रुटि: $error';
  }

  @override
  String get msgCouldNotSend => 'संदेश नहीं भेज सके';

  @override
  String get msgMessageCopied => 'संदेश कॉपी हुआ';

  @override
  String get msgTypeMessage => 'संदेश लिखें…';

  @override
  String get notifTitle => 'सूचनाएँ';

  @override
  String notifUnreadCount(int count) {
    return '$count अपठित';
  }

  @override
  String get notifAllCaughtUp => 'सब देख लिया';

  @override
  String get notifMarkAll => 'सभी पढ़ा हुआ करें';

  @override
  String get notifNoNotifications => 'अभी कोई सूचना नहीं';

  @override
  String get notifEmptyBody => 'जॉब लीड, बुकिंग और भुगतान यहाँ दिखेंगे';

  @override
  String get notifSomethingWrong => 'कुछ गलत हो गया';

  @override
  String get notifJustNow => 'अभी-अभी';

  @override
  String get editProfileUpdated => 'प्रोफ़ाइल सफलतापूर्वक अपडेट हुई';

  @override
  String editProfileFailed(String error) {
    return 'प्रोफ़ाइल अपडेट करने में विफल: $error';
  }

  @override
  String get editFullName => 'पूरा नाम';

  @override
  String get editFullNameHint => 'अपना पूरा नाम दर्ज करें';

  @override
  String get editNameRequired => 'नाम आवश्यक है';

  @override
  String get editEmail => 'ईमेल';

  @override
  String get editEmailHint => 'अपना ईमेल दर्ज करें';

  @override
  String get editEmailRequired => 'ईमेल आवश्यक है';

  @override
  String get editEmailInvalid => 'एक मान्य ईमेल दर्ज करें';

  @override
  String get editPhone => 'फ़ोन नंबर';

  @override
  String get editPhoneHint => 'अपना फ़ोन नंबर दर्ज करें';

  @override
  String get editPhoneRequired => 'फ़ोन आवश्यक है';

  @override
  String get editCity => 'शहर / स्थान';

  @override
  String get editCityHint => 'अपना शहर दर्ज करें';

  @override
  String get editCityRequired => 'शहर आवश्यक है';

  @override
  String get editSaveChanges => 'परिवर्तन सहेजें';

  @override
  String get splashPreparing => 'TaskTeddy तैयार हो रहा है';

  @override
  String get splashGettingReady => 'सब कुछ तैयार किया जा रहा है...';

  @override
  String get splashGettingThingsReady => 'चीज़ें तैयार की जा रही हैं...';

  @override
  String get splashLocationOff => 'लोकेशन बंद है। जारी है...';

  @override
  String get splashLocationSkipped => 'लोकेशन अनुमति छोड़ी गई। जारी है...';

  @override
  String splashLocationLocked(String label) {
    return 'लोकेशन तय हुई: $label';
  }

  @override
  String get splashLocationFailed => 'लोकेशन नहीं मिल सकी। जारी है...';

  @override
  String get commonRemove => 'हटाएँ';

  @override
  String get completedEmptyBody =>
      'अभी तक कोई पूर्ण कार्य नहीं।\nआपका पूरा किया काम यहाँ दिखेगा।';

  @override
  String get reviewsRecent => 'हाल की समीक्षाएँ';

  @override
  String get reviewsNone => 'अभी कोई समीक्षा नहीं';

  @override
  String portfolioFull(int max) {
    return 'पोर्टफोलियो भर गया (अधिकतम $max फ़ोटो)';
  }

  @override
  String get portfolioAddCaption => 'एक कैप्शन जोड़ें';

  @override
  String get portfolioCaptionHint => 'वैकल्पिक - जैसे रसोई की गहरी सफ़ाई';

  @override
  String get portfolioSkip => 'छोड़ें';

  @override
  String get portfolioPhotoAdded => 'फ़ोटो पोर्टफोलियो में जोड़ी गई';

  @override
  String get portfolioAddWorkPhoto => 'कार्य फ़ोटो जोड़ें';

  @override
  String get portfolioRemovePhoto => 'फ़ोटो हटाएँ';

  @override
  String get portfolioRemoveConfirm =>
      'क्या इस फ़ोटो को अपने पोर्टफोलियो से हटाएँ?';

  @override
  String get portfolioPhotoRemoved => 'फ़ोटो हटाई गई';

  @override
  String get portfolioUploading => 'अपलोड हो रहा है...';

  @override
  String get portfolioAddPhoto => 'फ़ोटो जोड़ें';

  @override
  String get portfolioEmpty => 'अभी कोई पोर्टफोलियो फ़ोटो नहीं';

  @override
  String get portfolioEmptyBody =>
      'अधिक काम पाने के लिए अपना बेहतरीन काम दिखाएँ।';

  @override
  String get portfolioUntitled => 'बिना शीर्षक';

  @override
  String get referTitle => 'रेफ़र करें और कमाएँ';

  @override
  String get referEarnHero => 'हर रेफ़रल पर ₹200 कमाएँ!';

  @override
  String get referInviteFriends =>
      'दोस्तों को TaskTeddy पर बुलाएँ और साथ में इनाम कमाएँ।';

  @override
  String get referHowItWorks => 'यह कैसे काम करता है';

  @override
  String get referStep1 => 'अपना रेफ़रल कोड दोस्तों के साथ साझा करें';

  @override
  String get referStep2 =>
      'आपका दोस्त साइन अप करता है और पहला कार्य पूरा करता है';

  @override
  String get referStep3 => 'आप दोनों को ₹200 TaskCoins में मिलते हैं!';

  @override
  String get referYourCode => 'आपका रेफ़रल कोड';

  @override
  String get referCodeCopied => 'कोड कॉपी हुआ!';

  @override
  String get referShareWhatsApp => 'WhatsApp पर साझा करें';

  @override
  String get referShareDialogOpened => 'साझा करने का डायलॉग खुला!';

  @override
  String get referYourReferrals => 'आपके रेफ़रल';

  @override
  String get referTotalReferrals => 'कुल रेफ़रल';

  @override
  String get referEarningsFrom => 'रेफ़रल से कमाई';

  @override
  String referStep(int number) {
    return 'चरण $number';
  }

  @override
  String referShareMessage(String code) {
    return 'मेरे रेफ़रल कोड $code का उपयोग करके TaskTeddy जॉइन करें और ₹200 कमाएँ! अभी डाउनलोड करें: https://taskteddy.app';
  }

  @override
  String bankRemoveConfirmTitle(String name) {
    return '$name हटाएँ?';
  }

  @override
  String get bankRemoveConfirmBody =>
      'यह भुगतान तरीका आपके खाते से हटा दिया जाएगा।';

  @override
  String bankMethodRemoved(String name) {
    return '$name हटाया गया';
  }

  @override
  String get bankBankAccount => 'बैंक खाता';

  @override
  String get bankBankAccountSub => 'बचत या चालू खाता जोड़ें';

  @override
  String get bankUpiId => 'UPI ID';

  @override
  String get bankUpiSub => 'अपना UPI पता जोड़ें';

  @override
  String get bankAddBankAccount => 'बैंक खाता जोड़ें';

  @override
  String get bankAccountHolderName => 'खाताधारक का नाम';

  @override
  String get bankAccountNumber => 'खाता संख्या';

  @override
  String get bankIfscCode => 'IFSC कोड';

  @override
  String get bankFillAllFields => 'कृपया सभी फ़ील्ड भरें';

  @override
  String bankSavingsMask(String last4) {
    return 'बचत खाता •••• $last4';
  }

  @override
  String get bankAccountAdded => 'बैंक खाता सफलतापूर्वक जोड़ा गया';

  @override
  String get bankAddUpiId => 'UPI ID जोड़ें';

  @override
  String get bankUpiHint => 'जैसे name@upi';

  @override
  String get bankEnterValidUpi => 'कृपया एक मान्य UPI ID दर्ज करें';

  @override
  String get bankUpiAdded => 'UPI ID सफलतापूर्वक जोड़ी गई';

  @override
  String get bankPayoutInfo => 'भुगतान जानकारी';

  @override
  String get bankProcessingTime => 'प्रोसेसिंग समय';

  @override
  String get bankProcessingTimeVal => 'कार्य पूरा होने के 24 घंटे बाद';

  @override
  String get bankMinWithdrawal => 'न्यूनतम निकासी';

  @override
  String get bankPlatformFee => 'प्लेटफ़ॉर्म शुल्क';

  @override
  String get bankPlatformFeeVal => 'प्रति कार्य 15%';

  @override
  String get bankPaymentCycle => 'भुगतान चक्र';

  @override
  String get bankPaymentCycleVal => 'डिफ़ॉल्ट तरीके में तुरंत';

  @override
  String get bankDefault => 'डिफ़ॉल्ट';

  @override
  String get bankSetDefault => 'डिफ़ॉल्ट सेट करें';

  @override
  String get helpMyTicketsTooltip => 'मेरे टिकट';

  @override
  String get helpMessageSupport => 'सपोर्ट को संदेश भेजें';

  @override
  String get helpRespond24 => 'हम आमतौर पर 24 घंटों के भीतर जवाब देते हैं।';

  @override
  String get helpSubject => 'विषय';

  @override
  String get helpDescribeIssue => 'अपनी समस्या बताएँ…';

  @override
  String get helpAddSubjectDesc =>
      'कृपया एक विषय और एक संक्षिप्त विवरण जोड़ें।';

  @override
  String get helpTicketSent => 'टिकट भेजा गया! हम ऐप में जवाब देंगे।';

  @override
  String get helpSend => 'भेजें';

  @override
  String get helpNoTickets => 'अभी कोई सपोर्ट टिकट नहीं';

  @override
  String get helpResolved => 'हल हुआ';

  @override
  String get helpOpen => 'खुला';

  @override
  String helpSupportReply(String reply) {
    return 'सपोर्ट: $reply';
  }

  @override
  String helpReachOut(String phone, String email) {
    return 'पार्टनर सपोर्ट से संपर्क करें\n$phone  •  $email';
  }

  @override
  String get helpCallUs => 'हमें कॉल करें';

  @override
  String get helpEmailUs => 'हमें ईमेल करें';

  @override
  String get helpCouldNotDial => 'इस डिवाइस पर डायलर नहीं खोल सके।';

  @override
  String get helpCouldNotEmail => 'इस डिवाइस पर ईमेल ऐप नहीं खोल सके।';

  @override
  String get helpNeedQuickHelp => 'त्वरित मदद चाहिए?';

  @override
  String get helpFindAnswers =>
      'तुरंत जवाब पाएँ या कभी भी सपोर्ट से संपर्क करें।';

  @override
  String get helpMyDisputes => 'मेरे भुगतान विवाद';

  @override
  String get helpNoDisputes => 'आपके पास कोई सक्रिय विवाद नहीं है।';

  @override
  String get helpBrowseTopics => 'सभी सहायता विषय देखें';

  @override
  String helpRelatedTo(String topic) {
    return '$topic से संबंधित सहायता';
  }

  @override
  String get helpCantFind => 'अपना जवाब नहीं मिल रहा?';

  @override
  String get helpTeamHere => 'हमारी सपोर्ट टीम मदद के लिए यहाँ है';

  @override
  String get helpT1Title => 'कार्य और आवेदन';

  @override
  String get helpT1Sub => 'आवेदन, बोली, स्लॉट विवरण और कवर लेटर प्रबंधित करें';

  @override
  String get helpT1Q1 => 'मैं किसी कार्य के लिए आवेदन कैसे करूँ?';

  @override
  String get helpT1A1 =>
      'खोजें टैब में उपलब्ध कार्य देखें, अपनी विशेषज्ञता से मेल खाता कार्य चुनें, अपनी बोली राशि तय करें, अपने अनुभव का संक्षिप्त कवर लेटर लिखें, और आवेदन करें पर टैप करें।';

  @override
  String get helpT1Q2 => 'क्या मैं अपना आवेदन रद्द या वापस ले सकता हूँ?';

  @override
  String get helpT1A2 =>
      'हाँ। प्रोफ़ाइल टैब पर मेरे आवेदन में जाएँ, जिस लंबित आवेदन को वापस लेना है उसे चुनें, और अपनी बोली हटाने के लिए वापस लें विकल्प पर टैप करें।';

  @override
  String get helpT1Q3 => 'मेरा आवेदन स्वीकार होने पर क्या होता है?';

  @override
  String get helpT1A3 =>
      'आपको तुरंत एक सूचना मिलेगी, और कार्य आपके \"मेरे सक्रिय कार्य\" में चला जाएगा। ग्राहक विवरण और स्थान देखने के लिए आप कार्य खोल सकते हैं।';

  @override
  String get helpT1Q4 => 'कार्य पूरा होने का OTP क्या है?';

  @override
  String get helpT1A4 =>
      'कार्य सफलतापूर्वक पूरा करने पर, ग्राहक से 4-अंकों का सत्यापन OTP माँगें। इसे सक्रिय कार्य विंडो में दर्ज करें ताकि कार्य पूरा हो और आपका भुगतान जारी हो।';

  @override
  String get helpT1Q5 =>
      'मेरे पहुँचने के बाद ग्राहक कार्य रद्द कर दे तो क्या होगा?';

  @override
  String get helpT1A5 =>
      'यदि आपके पहुँचने या स्थान की ओर यात्रा शुरू करने के बाद ग्राहक रद्द करता है, तो तय की गई दूरी के आधार पर आप ₹50-₹150 की रद्दीकरण क्षतिपूर्ति के पात्र हो सकते हैं। सक्रिय बुकिंग स्क्रीन से सपोर्ट से संपर्क करें।';

  @override
  String get helpT1Q6 => 'कार्य रेटिंग की गणना कैसे होती है?';

  @override
  String get helpT1A6 =>
      'आपकी समग्र रेटिंग कार्य पूरा होने पर ग्राहकों द्वारा दी गई रेटिंग का औसत है। उच्च रेटिंग (4.5+) आपकी दृश्यता बढ़ाती है और उच्च-मूल्य कार्यों तक जल्दी पहुँच देती है।';

  @override
  String get helpT2Title => 'कमाई और भुगतान';

  @override
  String get helpT2Sub => 'प्लेटफ़ॉर्म शुल्क, बैंक निकासी और लेजर भुगतान';

  @override
  String get helpT2Q1 => 'मैं अपनी कमाई कैसे निकालूँ?';

  @override
  String get helpT2A1 =>
      'अपनी प्रोफ़ाइल से कमाई और भुगतान में जाएँ, निकालें पर टैप करें, राशि दर्ज करें (न्यूनतम ₹100), और धनराशि तुरंत आपके डिफ़ॉल्ट भुगतान लक्ष्य में स्थानांतरित हो जाती है।';

  @override
  String get helpT2Q2 => 'प्लेटफ़ॉर्म सेवा शुल्क क्या है?';

  @override
  String get helpT2A2 =>
      'TaskTeddy बीमा, मार्केटिंग और संचालन के भुगतान में मदद के लिए सफल कार्य पूर्णताओं पर एक समान 15% प्लेटफ़ॉर्म सेवा शुल्क लेता है।';

  @override
  String get helpT2Q3 => 'बैंक भुगतान निकासी में कितना समय लगता है?';

  @override
  String get helpT2A3 =>
      'भुगतान स्थानांतरण तुरंत शुरू किए जाते हैं। आपके बैंक की IMPS प्रोसेसिंग गति के आधार पर, भुगतान आमतौर पर कुछ ही मिनटों में आपके बैंक खाते या UPI में दिखते हैं।';

  @override
  String get helpT2Q4 => 'मेरा भुगतान लंबित स्थिति में क्यों अटका है?';

  @override
  String get helpT2A4 =>
      'यदि आपका भुगतान लंबित है, तो यह आमतौर पर बैंकिंग नेटवर्क देरी या सत्यापन जाँच के कारण होता है। अधिकांश लंबित भुगतान 2-4 घंटों में अपने आप हल हो जाते हैं। अधिक समय लगने पर, Payout ID के साथ संपर्क करें।';

  @override
  String get helpT2Q5 =>
      'क्या मैं अपना डिफ़ॉल्ट भुगतान बैंक खाता बदल सकता हूँ?';

  @override
  String get helpT2A5 =>
      'हाँ, आप अपनी प्रोफ़ाइल टैब पर बैंक और भुगतान स्क्रीन से कभी भी बैंक खाते और UPI ID संपादित या जोड़ सकते हैं। बस एक नया तरीका जोड़ें और स्टार पर टैप करें या डिफ़ॉल्ट के रूप में सेट करें।';

  @override
  String get helpT3Title => 'सत्यापन और प्रोफ़ाइल';

  @override
  String get helpT3Sub => 'आधार जाँच, पैन सत्यापन और प्रोफ़ाइल फ़ोटो सेटिंग्स';

  @override
  String get helpT3Q1 => 'दस्तावेज़ सत्यापन में कितना समय लगता है?';

  @override
  String get helpT3A1 =>
      'स्वचालित बैकग्राउंड जाँच तुरंत सत्यापित होती हैं। मैन्युअल समीक्षा वाले मामलों में, अनुमोदन में 24 घंटे तक लग सकते हैं। आपका प्रगति बार अपने आप अपडेट होता है।';

  @override
  String get helpT3Q2 => 'कौन-से पते के प्रमाण स्वीकार्य हैं?';

  @override
  String get helpT3A2 =>
      'हम 3 महीने से पुराने न होने वाले मानक उपयोगिता बिल (बिजली, पाइपलाइन गैस, या पानी का बिल), पंजीकृत किराया अनुबंध, या आपके नाम के सरकारी प्रमाणपत्र स्वीकार करते हैं।';

  @override
  String get helpT3Q3 => 'मेरा पैन कार्ड अपलोड क्यों अस्वीकार हुआ?';

  @override
  String get helpT3A3 =>
      'सुनिश्चित करें कि फ़ोटो स्पष्ट है, सभी किनारे दिख रहे हैं, कोई फ़्लैश प्रतिबिंब नहीं है, और नाम आपके सरकारी ID विवरण से मेल खाता है।';

  @override
  String get helpT3Q4 =>
      'सत्यापन के बाद मैं अपने प्रोफ़ाइल विवरण कैसे अपडेट करूँ?';

  @override
  String get helpT3A4 =>
      'एक बार आपकी पहचान सत्यापित हो जाने पर, आपके कानूनी नाम और सरकारी ID जैसे प्रमुख फ़ील्ड सीधे संपादित नहीं किए जा सकते। अपना पंजीकृत फ़ोन नंबर बदलने या नाम की त्रुटि ठीक करने के लिए, सहायक दस्तावेज़ों के साथ पार्टनर सपोर्ट से संपर्क करें।';

  @override
  String get helpT3Q5 =>
      'यदि मेरा दस्तावेज़ सत्यापन विफल हो तो मुझे क्या करना चाहिए?';

  @override
  String get helpT3A5 =>
      'यदि आपका आधार या पैन अस्वीकार होता है, तो आपको कारण बताते हुए एक सूचना मिलेगी। दोबारा जमा करने से पहले सुनिश्चित करें कि आपका अपलोड उच्च गुणवत्ता का है, धुंधला नहीं है, और आपके पंजीकृत प्रोफ़ाइल नाम से मेल खाता है।';

  @override
  String get helpT4Title => 'सुरक्षा और आचार संहिता';

  @override
  String get helpT4Sub => 'आपातकालीन सहायता, स्थान ट्रैकिंग और नियम';

  @override
  String get helpT4Q1 => 'कार्य के दौरान मुझे असुरक्षित लगे - मैं क्या करूँ?';

  @override
  String get helpT4A1 =>
      'सुरक्षा हमारी सर्वोच्च प्राथमिकता है। तुरंत उस स्थान को छोड़कर किसी सार्वजनिक स्थान पर जाएँ और सपोर्ट को कॉल करें। किसी भी आपात स्थिति में, पहले स्थानीय पुलिस (100/112) को डायल करें।';

  @override
  String get helpT4Q2 =>
      'क्या मैं ग्राहकों से सीधे भुगतान स्वीकार कर सकता हूँ?';

  @override
  String get helpT4A2 =>
      'नहीं। ग्राहकों से ऑफ़लाइन या सीधे कैश/UPI स्थानांतरण माँगना पार्टनर दिशानिर्देशों का उल्लंघन है और इससे आपके TaskTeddy खाते का स्थायी निलंबन होता है।';

  @override
  String get helpT4Q3 =>
      'यदि स्थान पर कार्य का दायरा बदल जाए तो मुझे क्या करना चाहिए?';

  @override
  String get helpT4A3 =>
      'यदि कोई ग्राहक आपसे मूल कार्य विवरण में उल्लेख न किया गया अतिरिक्त काम करने को कहे, तो विनम्रता से उन्हें ऐप में कार्य अपडेट करने या मानक दरों का भुगतान करने को कहें। सपोर्ट को सूचित किए बिना ऑफ़लाइन भुगतान समायोजन स्वीकार न करें।';

  @override
  String get helpT4Q4 =>
      'सक्रिय कार्यों के दौरान मेरा स्थान कैसे ट्रैक होता है?';

  @override
  String get helpT4A4 =>
      'हम आपका स्थान बैकग्राउंड में केवल तभी ट्रैक करते हैं जब आप किसी कार्य की ओर यात्रा कर रहे हों या सक्रिय रूप से कोई सेवा पूरी कर रहे हों, ताकि पार्टनर सुरक्षा सुनिश्चित हो और ग्राहकों को लाइव ETA मिले।';

  @override
  String get setWeeklyHours => 'साप्ताहिक घंटे';

  @override
  String get setNotifications => 'सूचनाएँ';

  @override
  String get setPushNotif => 'पुश सूचनाएँ';

  @override
  String get setPushNotifSub => 'कार्य अलर्ट और अपडेट प्राप्त करें';

  @override
  String get setEmailNotif => 'ईमेल सूचनाएँ';

  @override
  String get setEmailNotifSub => 'साप्ताहिक सारांश और प्रचार';

  @override
  String get setSmsNotif => 'SMS सूचनाएँ';

  @override
  String get setSmsNotifSub => 'केवल OTP और महत्वपूर्ण अलर्ट';

  @override
  String get setAppearance => 'दिखावट';

  @override
  String get setDarkMode => 'डार्क मोड';

  @override
  String get setComingSoon => 'जल्द आ रहा है';

  @override
  String get setDataStorage => 'डेटा और स्टोरेज';

  @override
  String get setClearCache => 'कैश साफ़ करें';

  @override
  String get setCacheCleared => 'कैश साफ़ हुआ';

  @override
  String get setDownloadData => 'मेरा डेटा डाउनलोड करें';

  @override
  String get setDataExportEmailed => 'डेटा निर्यात आपको ईमेल किया जाएगा';

  @override
  String get setDangerZone => 'खतरनाक क्षेत्र';

  @override
  String get setDeleteAccount => 'खाता हटाएँ';

  @override
  String get setDeleteAccountTitle => 'खाता हटाएँ?';

  @override
  String get setDeleteAccountBody =>
      'यह क्रिया अपरिवर्तनीय है। आपका सारा डेटा, कमाई और समीक्षाएँ स्थायी रूप से हटा दी जाएँगी।';

  @override
  String get setDelete => 'हटाएँ';

  @override
  String get setDeletionSubmitted => 'खाता हटाने का अनुरोध जमा किया गया';

  @override
  String get reportThisUser => 'इस उपयोगकर्ता';

  @override
  String reportUserTitle(String name) {
    return '$name की रिपोर्ट करें';
  }

  @override
  String get reportChooseReason => 'एक कारण चुनें। रिपोर्ट गोपनीय हैं।';

  @override
  String get reportDetailsOptional => 'विवरण (वैकल्पिक)';

  @override
  String get reportDetailHint =>
      'जो हुआ उसे समझने में मदद करने वाली कोई भी बात जोड़ें…';

  @override
  String get reportSubmit => 'रिपोर्ट जमा करें';

  @override
  String get reportSubmitted =>
      'रिपोर्ट जमा हुई। हमारी टीम इसकी समीक्षा करेगी।';

  @override
  String get reportReasonInappropriate => 'अनुचित व्यवहार';

  @override
  String get reportReasonNoShow => 'नहीं आया';

  @override
  String get reportReasonSafety => 'सुरक्षा चिंता';

  @override
  String get reportReasonFraud => 'धोखाधड़ी या घोटाला';

  @override
  String get reportReasonPoorQuality => 'खराब गुणवत्ता';

  @override
  String get reportReasonSpam => 'स्पैम';

  @override
  String get reportReasonOther => 'अन्य';

  @override
  String blockConfirmTitle(String name) {
    return '$name को अवरुद्ध करें?';
  }

  @override
  String get blockConfirmBody =>
      'वे अब आपको संदेश नहीं भेज सकेंगे या आपके कार्यों से मेल नहीं खा सकेंगे। आप उन्हें सेटिंग्स से कभी भी अनब्लॉक कर सकते हैं।';

  @override
  String blockedSuccess(String name) {
    return '$name को अवरुद्ध कर दिया गया';
  }

  @override
  String get blockedUserFallback => 'उपयोगकर्ता';

  @override
  String get unblockAction => 'अनब्लॉक करें';

  @override
  String unblockedSuccess(String name) {
    return '$name अनब्लॉक हुआ';
  }

  @override
  String get blockedEmptyBody => 'आपके द्वारा अवरुद्ध किए गए लोग यहाँ दिखेंगे।';

  @override
  String loginSendingOtp(String phone) {
    return '$phone पर OTP भेजा जा रहा है';
  }

  @override
  String loginOtpSent(String phone) {
    return '$phone पर OTP भेजा गया';
  }

  @override
  String get loginEnterOtpSent => 'अपने नंबर पर भेजा गया OTP दर्ज करें';

  @override
  String get loginErrConnect =>
      'कनेक्ट नहीं हो सका। कृपया अपना इंटरनेट जाँचें और फिर कोशिश करें।';

  @override
  String get loginErrServer =>
      'सर्वर तक नहीं पहुँच सके। कृपया बाद में कोशिश करें।';

  @override
  String get loginErrInvalidOtp =>
      'अमान्य OTP। कृपया जाँचें और फिर कोशिश करें।';

  @override
  String get loginErrExpiredOtp => 'OTP समाप्त हो गया। कृपया नया अनुरोध करें।';

  @override
  String get loginErrTooMany =>
      'बहुत अधिक प्रयास। कृपया थोड़ी देर रुकें और फिर कोशिश करें।';

  @override
  String get loginErrGeneric => 'कुछ गलत हो गया। कृपया फिर कोशिश करें।';

  @override
  String get loginTermsPrefix => 'जारी रखें पर क्लिक करके, आप हमारी ';

  @override
  String get loginAnd => ' और ';

  @override
  String get loginTermsSuffix => ' स्वीकार करते हैं।';

  @override
  String get dashLoading => 'आपका डैशबोर्ड लोड हो रहा है…';

  @override
  String get dashLocationPicker => 'लोकेशन पिकर खुला...';

  @override
  String dashAssigned(int count) {
    return '$count सौंपे गए';
  }

  @override
  String dashAvailable(int count) {
    return '$count उपलब्ध';
  }

  @override
  String dashOngoing(int count) {
    return '$count जारी';
  }

  @override
  String get dashUseAppliedTab => 'नीचे नेविगेशन में आवेदित टैब का उपयोग करें';

  @override
  String get dashCheckBackSoon =>
      'जल्द फिर देखें — नए कार्य रोज़ पोस्ट होते हैं!';

  @override
  String get dashBrowseStartEarning => 'उपलब्ध कार्य देखें और कमाई शुरू करें!';

  @override
  String get dashSpecialOffer => 'विशेष ऑफ़र!';

  @override
  String get dashBonusRewards => 'बोनस इनाम कमाने के लिए कार्य पूरे करें';

  @override
  String get dashCompleteBooking => 'बुकिंग पूरी करें';

  @override
  String dashBookingOtpPrompt(String service) {
    return '\"$service\" के लिए ग्राहक से पूर्णता OTP माँगें और उसे नीचे दर्ज करें।';
  }

  @override
  String get dashComplete => 'पूरा करें';

  @override
  String get dashBookingComplete => 'बुकिंग पूर्ण के रूप में चिह्नित!';

  @override
  String get dashThisBooking => 'इस बुकिंग';

  @override
  String get dashMarkComplete => 'पूर्ण चिह्नित करें';

  @override
  String get dashScheduled => 'निर्धारित';

  @override
  String get dashServiceFallback => 'सेवा';

  @override
  String get dashCustomerFallback => 'ग्राहक';

  @override
  String get dashOverdue => 'समय बीता';

  @override
  String dashMinLeft(int count) {
    return '$count मि. बाकी';
  }

  @override
  String dashHrLeft(int count) {
    return '$count घं. बाकी';
  }

  @override
  String dashDayLeft(int count) {
    return '$count दि. बाकी';
  }

  @override
  String dashApplied(int count) {
    return '$count ने आवेदन किया';
  }

  @override
  String get dashStatusPending => 'लंबित';

  @override
  String get dashStatusConfirmed => 'पुष्ट';

  @override
  String get dashStatusCompleted => 'पूर्ण';

  @override
  String get dashStatusCancelled => 'रद्द';

  @override
  String get dashTip1 =>
      'गोल्ड स्थिति तक पहुँचने के लिए इस सप्ताह 3 और कार्य पूरे करें';

  @override
  String get dashTip2 =>
      'त्वरित प्रतिक्रिया वाले कार्यों को 2x अधिक बुकिंग मिलती है';

  @override
  String get dashTip3 =>
      'प्राथमिकता लिस्टिंग के लिए अपनी प्रोफ़ाइल 100% पूर्ण रखें';

  @override
  String get dashTip4 =>
      'प्रीमियम कार्य पहुँच अनलॉक करने के लिए 4.8+ रेटिंग बनाए रखें';

  @override
  String get dashTip5 =>
      'अपने क्षेत्र में बेहतर कार्य मिलान के लिए लोकेशन सक्षम करें';

  @override
  String get browseNotNow => 'अभी नहीं';

  @override
  String get browseTaskCompleted => 'कार्य पूरा हुआ';

  @override
  String browseCollectedCash(String amount) {
    return 'आपने ग्राहक से ₹$amount नकद वसूले।';
  }

  @override
  String get browseCashCollected => 'नकद वसूला';

  @override
  String browsePlatformFeeMethod(String method) {
    return 'प्लेटफ़ॉर्म शुल्क ($method)';
  }

  @override
  String get browseNetEarning => 'शुद्ध कमाई';

  @override
  String browseFeeDeducted(String amount) {
    return '₹$amount प्लेटफ़ॉर्म शुल्क आपके वॉलेट से काटा गया। बकाया से बचने के लिए अपना वॉलेट टॉप-अप रखें।';
  }

  @override
  String get browseDone => 'हो गया';

  @override
  String get browseLeadDismissed => 'लीड हटाई गई';

  @override
  String get browseUndo => 'पूर्ववत करें';

  @override
  String get browseGpsPinging => 'GPS सैटेलाइट को पिंग किया जा रहा है...';

  @override
  String get browseGpsResolving => 'निर्देशांक हल किए जा रहे हैं...';

  @override
  String get browseGpsFetching => 'नज़दीकी कार्य लाए जा रहे हैं...';

  @override
  String browseLocationDetected(String city) {
    return 'लोकेशन $city पर स्वतः पहचानी गई! नज़दीकी कार्य लोड हुए।';
  }

  @override
  String get browseSelectLocation => 'स्थान चुनें';

  @override
  String get browseSelectLocationSub =>
      'अपने पसंदीदा शहर में नज़दीकी खुले कार्य देखें';

  @override
  String get browseAutoDetect => 'मेरी लोकेशन स्वतः पहचानें';

  @override
  String get browseAccessingGps => 'उच्च-सटीक GPS निर्देशांक एक्सेस हो रहे हैं';

  @override
  String get browseSimulateGps => 'उच्च-सटीक GPS जाँच का अनुकरण';

  @override
  String get browsePopularCities => 'लोकप्रिय शहर';

  @override
  String browseBrowsingNearest(String city) {
    return '$city के सबसे नज़दीकी कार्य देखे जा रहे हैं।';
  }

  @override
  String get browseReset => 'रीसेट';

  @override
  String get browsePresetAll => 'सभी';

  @override
  String get browsePresetUnder500 => '₹500 से कम';

  @override
  String get browsePreset500to2000 => '₹500-₹2000';

  @override
  String get browsePresetAbove2000 => '₹2000 से ऊपर';

  @override
  String get browseMinBudget => 'न्यूनतम बजट (₹)';

  @override
  String get browseMaxBudget => 'अधिकतम बजट (₹)';

  @override
  String get browseHintAny => 'कोई भी';

  @override
  String get browseFailedLoad => 'कार्य लोड करने में विफल';

  @override
  String get browseRefresh => 'रीफ़्रेश करें';

  @override
  String get browseCatAll => 'सभी';

  @override
  String browseOpenTasks(int count) {
    return '$count खुले कार्य';
  }

  @override
  String browseSortLabel(String label) {
    return 'क्रमबद्ध: $label';
  }

  @override
  String get browseSortLatest => 'नवीनतम';

  @override
  String get browseSortBudget => 'बजट';

  @override
  String get browseSortDeadline => 'समय-सीमा';

  @override
  String get browseSortLeastBids => 'कम बोलियाँ';

  @override
  String browsePosted(String ago) {
    return '$ago पोस्ट किया';
  }

  @override
  String get browseJustNow => 'अभी-अभी';

  @override
  String browsePostedBy(String name) {
    return '$name द्वारा पोस्ट किया गया';
  }

  @override
  String get browseBudgetSmall => 'बजट';

  @override
  String get browseUrgent => 'अत्यावश्यक';

  @override
  String get browseDueToday => '· आज देय!';

  @override
  String get browseDueTomorrow => '· कल देय';

  @override
  String browseDueInDays(int days) {
    return '· $days दिनों में देय';
  }

  @override
  String browseDue(String date) {
    return 'देय $date';
  }

  @override
  String browseBids(int count) {
    return '$count बोलियाँ';
  }

  @override
  String get browseDismiss => 'हटाएँ';

  @override
  String browseBidLower(String amount) {
    return 'आपकी बोली ₹$amount कम है — बेहतर मौका!';
  }

  @override
  String get browseBidAbove => 'बजट से ऊपर — अपने कवर लेटर में मूल्य समझाएँ';

  @override
  String get browseBidMatches => 'आपकी बोली बजट से मेल खाती है';

  @override
  String browseCompBelow(String pct) {
    return 'आप औसत बोलियों से $pct% कम हैं';
  }

  @override
  String browseCompAbove(String pct) {
    return 'आप औसत बोलियों से $pct% अधिक हैं';
  }

  @override
  String get browseCompMatches => 'आपकी बोली औसत से मेल खाती है';

  @override
  String get browseYourBidAmount => 'आपकी बोली राशि (₹)';

  @override
  String get browseCompetitiveAnalysis => 'प्रतिस्पर्धी विश्लेषण';

  @override
  String get browseAvgBid => 'औसत बोली';

  @override
  String get browseEstTakeHome => 'अनुमानित शुद्ध राशि';

  @override
  String get browseAfterFee => '10% प्लेटफ़ॉर्म शुल्क के बाद';

  @override
  String get browseCoverLetter => 'कवर लेटर *';

  @override
  String get browseCoverLetterOptional => 'कवर लेटर (वैकल्पिक)';

  @override
  String get browseCoverHint =>
      'अपना परिचय दें। आप सबसे उपयुक्त क्यों हैं? अपना अनुभव और उपलब्धता बताएँ...';

  @override
  String get browseCoverTip => 'अच्छे कवर लेटर चयन की संभावना 70% बढ़ाते हैं';

  @override
  String get browseFeeNote =>
      'TaskTeddy केवल कार्य पूरा होने पर 10% प्लेटफ़ॉर्म शुल्क लेता है।';

  @override
  String get browseSubmitApplication => 'आवेदन जमा करें';

  @override
  String get browseTaskRefMissing => 'कार्य संदर्भ अनुपलब्ध';

  @override
  String get browseCustomerNotifiedSharing =>
      'ग्राहक को सूचित किया गया। आपकी लोकेशन साझा हो रही है।';

  @override
  String get browseBackedOut => 'आप पीछे हट गए। कार्य फिर से खुला है।';

  @override
  String get browseInvalidOtp => 'अमान्य OTP';

  @override
  String get browseActiveTask => 'सक्रिय कार्य';

  @override
  String browseYouEarnAmt(String amount) {
    return 'आपकी कमाई: ₹$amount';
  }

  @override
  String get browseFailedOpenChat => 'चैट नहीं खोल सके';

  @override
  String get browseChat => 'चैट';

  @override
  String browseRatingLabel(String rating) {
    return '$rating रेटिंग';
  }

  @override
  String get browseHeadingToCustomer => 'ग्राहक की ओर जा रहे हैं';

  @override
  String get browseOtwActiveBody =>
      'ग्राहक को सूचित किया गया। जब तक यह स्क्रीन खुली है, आपकी लाइव लोकेशन साझा हो रही है।';

  @override
  String get browseOtwIdleBody =>
      'ग्राहक को बताएँ कि आप रास्ते में हैं। हम आपकी लाइव लोकेशन साझा करेंगे ताकि वे आपके आगमन को ट्रैक कर सकें।';

  @override
  String get browseCustomerNotified => 'ग्राहक को सूचित किया गया';

  @override
  String get browseNotifying => 'सूचित किया जा रहा है...';

  @override
  String get browseCancelling => 'रद्द किया जा रहा है...';

  @override
  String get browseCancelJob => 'कार्य रद्द करें';

  @override
  String get browseEnterCompletionOtp => 'पूर्णता OTP दर्ज करें';

  @override
  String get browseOtpPrompt =>
      'कार्य पूर्ण करने और भुगतान पाने के लिए ग्राहक की स्क्रीन पर दिख रहा OTP माँगें।';

  @override
  String get browseVerifyComplete => 'सत्यापित करें और कार्य पूरा करें';

  @override
  String get browseReasonEmergency => 'आपात स्थिति';

  @override
  String get browseReasonTooFar => 'बहुत दूर';

  @override
  String get browseReasonSchedule => 'समय-सारणी टकराव';

  @override
  String get browseReasonOther => 'अन्य';

  @override
  String get browseBackOutTitle => 'इस कार्य से पीछे हटें?';

  @override
  String get browseBackOutWarning =>
      'इससे कार्य अन्य टास्करों के लिए फिर से खुल जाता है। बार-बार रद्द करना आपके विश्वसनीयता स्कोर को नुकसान पहुँचाता है।';

  @override
  String get browseReason => 'कारण';

  @override
  String get browseAddNote => 'एक नोट जोड़ें (वैकल्पिक)';

  @override
  String get browseKeepJob => 'कार्य रखें';

  @override
  String get browseThanksRating => 'ग्राहक को रेटिंग देने के लिए धन्यवाद।';

  @override
  String browseRateCustomer(String name) {
    return '$name को रेट करें';
  }

  @override
  String get browseRateExperience =>
      'इस ग्राहक के साथ काम करने का आपका अनुभव कैसा रहा?';

  @override
  String get browseAddComment => 'एक टिप्पणी जोड़ें (वैकल्पिक)';

  @override
  String get browseSubmitRating => 'रेटिंग जमा करें';

  @override
  String get browseAppSubmitted => 'आवेदन जमा हुआ!';

  @override
  String browseAppSubmittedBody(String title) {
    return '\"$title\"\nग्राहक समीक्षा करके सर्वश्रेष्ठ बोली स्वीकार करेगा।';
  }

  @override
  String get browseAppSubmittedNote =>
      'स्वीकार होने पर आपको सूचना मिलेगी। और कार्यों के लिए आवेदन करते रहें!';

  @override
  String get browseViewMyApps => 'मेरे आवेदन देखें';

  @override
  String get browseBrowseMore => 'और कार्य देखें';

  @override
  String get browsePhotos => 'फ़ोटो';

  @override
  String get reputationYourLevel => 'आपका स्तर';

  @override
  String get reputationReliability => 'विश्वसनीयता';

  @override
  String reputationJobsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count काम पूरे',
      one: '1 काम पूरा',
    );
    return '$_temp0';
  }

  @override
  String reputationJobsToNext(int completed, int next, String tier) {
    return '$tier तक $completed/$next काम';
  }

  @override
  String get reputationTopLevel => 'सर्वोच्च स्तर';

  @override
  String get reputationExplainer =>
      'स्तर बढ़ाने के लिए काम पूरे करें और रेटिंग ऊँची रखें।';

  @override
  String get reputationLevelNew => 'नया';

  @override
  String get reputationLevelBronze => 'ब्रॉन्ज़';

  @override
  String get reputationLevelSilver => 'सिल्वर';

  @override
  String get reputationLevelGold => 'गोल्ड';

  @override
  String get reputationLevelPro => 'प्रो';
}
