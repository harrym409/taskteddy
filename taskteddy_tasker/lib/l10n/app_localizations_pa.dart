// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppL10nPa extends AppL10n {
  AppL10nPa([String locale = 'pa']) : super(locale);

  @override
  String get walletDuesSettled =>
      'ਬਕਾਇਆ ਸੈਟਲ — ਹੁਣ ਤੁਸੀਂ ਫਿਰ ਬ੍ਰਾਊਜ਼ ਕਰ ਸਕਦੇ ਹੋ।';

  @override
  String get browseDuesTitle => 'ਬ੍ਰਾਊਜ਼ਿੰਗ ਰੁਕੀ ਹੋਈ ਹੈ';

  @override
  String get browseDuesBody =>
      'ਨਕਦ ਕੰਮਾਂ ਤੋਂ ਤੁਹਾਡੀਆਂ ਪਲੇਟਫਾਰਮ ਫੀਸਾਂ ਬਕਾਇਆ ਹਨ। ਕੰਮ ਬ੍ਰਾਊਜ਼ ਕਰਨਾ ਜਾਰੀ ਰੱਖਣ ਲਈ ਆਪਣਾ ਵਾਲਿਟ ਸੈਟਲ ਕਰੋ।';

  @override
  String browseDuesAmount(String amount) {
    return 'ਬਕਾਇਆ: ₹$amount';
  }

  @override
  String get browseSettleNow => 'ਹੁਣੇ ਸੈਟਲ ਕਰੋ';

  @override
  String get appTagline => 'ਆਪਣੇ ਸਮੇਂ ਅਨੁਸਾਰ ਕੰਮ ਲੱਭੋ ਅਤੇ ਪੈਸੇ ਕਮਾਓ!';

  @override
  String get navHome => 'ਹੋਮ';

  @override
  String get navBrowse => 'ਖੋਜੋ';

  @override
  String get navApplied => 'ਅਰਜ਼ੀਆਂ';

  @override
  String get navEarnings => 'ਕਮਾਈ';

  @override
  String get navProfile => 'ਪ੍ਰੋਫਾਈਲ';

  @override
  String get goodMorning => 'ਸ਼ੁਭ ਸਵੇਰ';

  @override
  String get goodAfternoon => 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ';

  @override
  String get goodEvening => 'ਸ਼ੁਭ ਸ਼ਾਮ';

  @override
  String get statusOnline => 'ਆਨਲਾਈਨ';

  @override
  String get statusOffline => 'ਆਫਲਾਈਨ';

  @override
  String get dashAvailableForWork => 'ਨਵੇਂ ਕੰਮਾਂ ਲਈ ਉਪਲਬਧ';

  @override
  String get dashTapToGoOnline => 'ਆਨਲਾਈਨ ਹੋ ਕੇ ਕੰਮ ਲੈਣ ਲਈ ਟੈਪ ਕਰੋ';

  @override
  String get dashStatReliability => 'ਭਰੋਸੇਯੋਗਤਾ';

  @override
  String get dashStatLevel => 'ਪੱਧਰ';

  @override
  String get dashLevelNew => 'ਨਵਾਂ';

  @override
  String get earningsOverview => 'ਕਮਾਈ ਦਾ ਸਾਰ';

  @override
  String get wallet => 'ਵਾਲਿਟ';

  @override
  String get today => 'ਅੱਜ';

  @override
  String get thisWeek => 'ਇਸ ਹਫ਼ਤੇ';

  @override
  String get thisMonth => 'ਇਸ ਮਹੀਨੇ';

  @override
  String get statRating => 'ਰੇਟਿੰਗ';

  @override
  String get statTasks => 'ਕੰਮ';

  @override
  String get statRank => 'ਰੈਂਕ';

  @override
  String get statCoins => 'ਸਿੱਕੇ';

  @override
  String get qaBrowseTasks => 'ਕੰਮ ਖੋਜੋ';

  @override
  String get qaApplications => 'ਅਰਜ਼ੀਆਂ';

  @override
  String get qaCompleted => 'ਪੂਰੇ ਹੋਏ';

  @override
  String get qaMessages => 'ਸੁਨੇਹੇ';

  @override
  String get tasksNearYou => 'ਤੁਹਾਡੇ ਨੇੜੇ ਦੇ ਕੰਮ';

  @override
  String get myActiveJobs => 'ਮੇਰੇ ਚੱਲ ਰਹੇ ਕੰਮ';

  @override
  String get myBookings => 'ਮੇਰੀਆਂ ਬੁਕਿੰਗਾਂ';

  @override
  String get seeAll => 'ਸਾਰੇ ਵੇਖੋ';

  @override
  String get noTasksAvailable => 'ਇਸ ਵੇਲੇ ਕੋਈ ਕੰਮ ਉਪਲਬਧ ਨਹੀਂ ਹੈ';

  @override
  String get noActiveJobs => 'ਕੋਈ ਚੱਲ ਰਿਹਾ ਕੰਮ ਨਹੀਂ';

  @override
  String get searchTasksHint => 'ਕੰਮ, ਟਿਕਾਣਾ ਖੋਜੋ...';

  @override
  String get filterTasks => 'ਕੰਮ ਫਿਲਟਰ ਕਰੋ';

  @override
  String get budgetRange => 'ਬਜਟ ਸੀਮਾ';

  @override
  String get applyFilters => 'ਫਿਲਟਰ ਲਾਗੂ ਕਰੋ';

  @override
  String get budget => 'ਬਜਟ';

  @override
  String get quickApply => 'ਤੁਰੰਤ ਅਰਜ਼ੀ';

  @override
  String get getVerifiedToApply => 'ਅਰਜ਼ੀ ਲਈ ਤਸਦੀਕ ਕਰਵਾਓ';

  @override
  String get verificationRequired => 'ਤਸਦੀਕ ਲੋੜੀਂਦੀ ਹੈ';

  @override
  String get completeKyc =>
      'ਕੰਮਾਂ ਲਈ ਅਰਜ਼ੀ ਦੇਣੀ ਸ਼ੁਰੂ ਕਰਨ ਵਾਸਤੇ ਆਪਣੀ ਕੇਵਾਈਸੀ ਤਸਦੀਕ ਪੂਰੀ ਕਰੋ।';

  @override
  String get getVerified => 'ਤਸਦੀਕ ਕਰਵਾਓ';

  @override
  String get noTasksFound => 'ਕੋਈ ਕੰਮ ਨਹੀਂ ਮਿਲਿਆ';

  @override
  String get tryAdjustingFilters => 'ਫਿਲਟਰ ਜਾਂ ਖੋਜ ਬਦਲ ਕੇ ਵੇਖੋ';

  @override
  String get loginOrSignup => 'ਲੌਗ ਇਨ ਜਾਂ ਸਾਈਨ ਅੱਪ ਕਰੋ';

  @override
  String get mobileNumber => 'ਮੋਬਾਈਲ ਨੰਬਰ';

  @override
  String get enterValidMobile => 'ਵੈਧ 10-ਅੰਕਾਂ ਦਾ ਮੋਬਾਈਲ ਨੰਬਰ ਦਰਜ ਕਰੋ';

  @override
  String get enterFullOtp => 'ਕਿਰਪਾ ਕਰਕੇ ਪੂਰਾ 6-ਅੰਕਾਂ ਦਾ ਓਟੀਪੀ ਦਰਜ ਕਰੋ';

  @override
  String get changeNumber => 'ਨੰਬਰ ਬਦਲੋ';

  @override
  String get resendOtp => 'ਓਟੀਪੀ ਦੁਬਾਰਾ ਭੇਜੋ';

  @override
  String resendInSeconds(int seconds) {
    return '$seconds ਸਕਿੰਟਾਂ ਵਿੱਚ ਦੁਬਾਰਾ ਭੇਜੋ';
  }

  @override
  String get settings => 'ਸੈਟਿੰਗਾਂ';

  @override
  String get language => 'ਭਾਸ਼ਾ';

  @override
  String get selectLanguage => 'ਭਾਸ਼ਾ ਚੁਣੋ';

  @override
  String get langEnglish => 'English';

  @override
  String get langHindi => 'हिन्दी (Hindi)';

  @override
  String get langPunjabi => 'ਪੰਜਾਬੀ (Punjabi)';

  @override
  String get safety => 'ਸੁਰੱਖਿਆ';

  @override
  String get blockedUsers => 'ਬਲੌਕ ਕੀਤੇ ਉਪਭੋਗਤਾ';

  @override
  String get manage => 'ਪ੍ਰਬੰਧ ਕਰੋ';

  @override
  String get noBlockedUsers => 'ਕੋਈ ਬਲੌਕ ਕੀਤਾ ਉਪਭੋਗਤਾ ਨਹੀਂ';

  @override
  String get workPreferences => 'ਕੰਮ ਦੀਆਂ ਤਰਜੀਹਾਂ';

  @override
  String get availability => 'ਉਪਲਬਧਤਾ';

  @override
  String get actionApply => 'ਅਰਜ਼ੀ ਦਿਓ';

  @override
  String get actionAccept => 'ਸਵੀਕਾਰ ਕਰੋ';

  @override
  String get actionDecline => 'ਅਸਵੀਕਾਰ ਕਰੋ';

  @override
  String get actionCancel => 'ਰੱਦ ਕਰੋ';

  @override
  String get actionSave => 'ਸੰਭਾਲੋ';

  @override
  String get actionRetry => 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get actionContinue => 'ਜਾਰੀ ਰੱਖੋ';

  @override
  String get actionSubmit => 'ਜਮ੍ਹਾਂ ਕਰੋ';

  @override
  String get actionOk => 'ਠੀਕ ਹੈ';

  @override
  String get actionYes => 'ਹਾਂ';

  @override
  String get actionNo => 'ਨਹੀਂ';

  @override
  String get actionClose => 'ਬੰਦ ਕਰੋ';

  @override
  String get actionReport => 'ਰਿਪੋਰਟ ਕਰੋ';

  @override
  String get actionBlock => 'ਬਲੌਕ ਕਰੋ';

  @override
  String get actionOnMyWay => 'ਮੈਂ ਰਸਤੇ ਵਿੱਚ ਹਾਂ';

  @override
  String get bankTitle => 'ਬੈਂਕ ਅਤੇ ਭੁਗਤਾਨ';

  @override
  String get bankPayoutMethods => 'ਭੁਗਤਾਨ ਦੇ ਤਰੀਕੇ';

  @override
  String get bankNoMethods => 'ਹਾਲੇ ਤੱਕ ਕੋਈ ਭੁਗਤਾਨ ਤਰੀਕਾ ਨਹੀਂ ਜੋੜਿਆ ਗਿਆ।';

  @override
  String bankSetDefaultSuccess(String name) {
    return '$name ਨੂੰ ਡਿਫੌਲਟ ਭੁਗਤਾਨ ਤਰੀਕਾ ਬਣਾਇਆ ਗਿਆ';
  }

  @override
  String get bankAddPaymentMethod => 'ਭੁਗਤਾਨ ਤਰੀਕਾ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get profileMyApplications => 'ਮੇਰੀਆਂ ਅਰਜ਼ੀਆਂ';

  @override
  String get profileTotal => 'ਕੁੱਲ';

  @override
  String get profilePending => 'ਬਕਾਇਆ';

  @override
  String get profileAccepted => 'ਸਵੀਕਾਰ';

  @override
  String get profileCompleted => 'ਪੂਰਾ';

  @override
  String get profileRejected => 'ਰੱਦ';

  @override
  String get profileAll => 'ਸਾਰੇ';

  @override
  String get profileNothingHere => 'ਇੱਥੇ ਹਾਲੇ ਕੁਝ ਨਹੀਂ ਹੈ';

  @override
  String get profileBrowseTasksStart => 'ਸ਼ੁਰੂ ਕਰਨ ਲਈ ਟਾਸਕ ਵੇਖੋ';

  @override
  String get profileWithdrawBid => 'ਬੋਲੀ ਵਾਪਸ ਲਵੋ';

  @override
  String get profileWithdrawBidConfirm =>
      'ਕੀ ਤੁਸੀਂ ਸੱਚਮੁੱਚ ਇਹ ਬੋਲੀ ਵਾਪਸ ਲੈਣਾ ਚਾਹੁੰਦੇ ਹੋ?';

  @override
  String get profileWithdraw => 'ਵਾਪਸ ਲਵੋ';

  @override
  String get profileBidWithdrawn => 'ਬੋਲੀ ਵਾਪਸ ਲੈ ਲਈ ਗਈ';

  @override
  String get profileCompleteTask => 'ਟਾਸਕ ਪੂਰਾ ਕਰੋ';

  @override
  String get profileCompleteTaskOtpPrompt =>
      'ਇਸ ਟਾਸਕ ਨੂੰ ਪੂਰਾ ਕਰਨ ਲਈ ਗਾਹਕ ਵੱਲੋਂ ਸਾਂਝਾ ਕੀਤਾ OTP ਦਰਜ ਕਰੋ।';

  @override
  String get profileOtp => 'OTP';

  @override
  String get profileEnterOtp => 'OTP ਦਰਜ ਕਰੋ';

  @override
  String get chatClosed => 'ਇਹ ਚੈਟ ਬੰਦ ਹੈ — ਕੰਮ ਪੂਰਾ ਹੋ ਗਿਆ ਹੈ।';

  @override
  String get walletMyWallet => 'ਮੇਰਾ ਵਾਲਿਟ';

  @override
  String get walletTotalBalance => 'ਕੁੱਲ ਬਕਾਇਆ';

  @override
  String get walletAvailable => 'ਉਪਲਬਧ';

  @override
  String get walletEarnings => 'ਕਮਾਈ';

  @override
  String get walletTransactions => 'ਲੈਣ-ਦੇਣ';

  @override
  String get walletWithdraw => 'ਕਢਵਾਓ';

  @override
  String get walletTasksDone => 'ਪੂਰੇ ਕੀਤੇ ਟਾਸਕ';

  @override
  String get walletNoTransactions => 'ਹਾਲੇ ਕੋਈ ਲੈਣ-ਦੇਣ ਨਹੀਂ';

  @override
  String get walletNoTransactionsBody =>
      'ਤੁਹਾਡੀ ਕਮਾਈ ਅਤੇ ਨਿਕਾਸੀ ਇੱਥੇ ਦਿਖਾਈ ਦੇਣਗੀਆਂ।';

  @override
  String walletPlatformDues(String amount) {
    return 'ਪਲੇਟਫਾਰਮ ਬਕਾਇਆ: ₹$amount';
  }

  @override
  String get walletDuesBody =>
      'ਇਹ ਨਕਦ ਕੰਮਾਂ \'ਤੇ ਬਕਾਇਆ ਕਮਿਸ਼ਨ ਹੈ। ਇਸ ਨੂੰ ਚੁਕਾਉਣ ਲਈ ਆਪਣਾ ਵਾਲਿਟ ਟਾਪ-ਅੱਪ ਰੱਖੋ।';

  @override
  String timeMinutesAgo(int count) {
    return '$count ਮਿੰਟ ਪਹਿਲਾਂ';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count ਘੰਟੇ ਪਹਿਲਾਂ';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count ਦਿਨ ਪਹਿਲਾਂ';
  }

  @override
  String get commonChooseGallery => 'ਗੈਲਰੀ ਤੋਂ ਚੁਣੋ';

  @override
  String get commonTakePhoto => 'ਫ਼ੋਟੋ ਲਵੋ';

  @override
  String get profileStatusNotSelected => 'ਚੁਣਿਆ ਨਹੀਂ ਗਿਆ';

  @override
  String get profileStatusUnderReview => 'ਸਮੀਖਿਆ ਅਧੀਨ';

  @override
  String get profileApplied => 'ਅਰਜ਼ੀ ਦਿੱਤੀ';

  @override
  String get profileStepDecision => 'ਫ਼ੈਸਲਾ';

  @override
  String get profileYourBid => 'ਤੁਹਾਡੀ ਬੋਲੀ';

  @override
  String get profileTaskBudget => 'ਕੰਮ ਬਜਟ';

  @override
  String get profileYouEarn => 'ਤੁਹਾਡੀ ਕਮਾਈ';

  @override
  String get profileStartTask => 'ਕੰਮ ਸ਼ੁਰੂ ਕਰੋ';

  @override
  String profileAppliedAgo(String time) {
    return '$time ਅਰਜ਼ੀ ਦਿੱਤੀ';
  }

  @override
  String get profileMyProfile => 'ਮੇਰੀ ਪ੍ਰੋਫਾਈਲ';

  @override
  String profileReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ਸਮੀਖਿਆਵਾਂ',
      one: '1 ਸਮੀਖਿਆ',
    );
    return '$_temp0';
  }

  @override
  String get profileTasksDone => 'ਪੂਰੇ ਕੀਤੇ ਕੰਮ';

  @override
  String get profileEarned => 'ਕਮਾਏ';

  @override
  String get profileAvailableForTasks => 'ਕੰਮਾਂ ਲਈ ਉਪਲਬਧ';

  @override
  String get profileNotAvailable => 'ਉਪਲਬਧ ਨਹੀਂ';

  @override
  String get profileVisibleToCustomers => 'ਤੁਸੀਂ ਗਾਹਕਾਂ ਨੂੰ ਦਿਖ ਰਹੇ ਹੋ';

  @override
  String get profileWontReceiveTasks => 'ਤੁਹਾਨੂੰ ਨਵੇਂ ਕੰਮ ਨਹੀਂ ਮਿਲਣਗੇ';

  @override
  String get profileCompletion => 'ਪੂਰਨਤਾ';

  @override
  String get profileAvgResponse => 'ਔਸਤ ਜਵਾਬ';

  @override
  String get profileMemberSince => 'ਮੈਂਬਰ ਬਣੇ';

  @override
  String get profileAboutMe => 'ਮੇਰੇ ਬਾਰੇ';

  @override
  String get profileEdit => 'ਸੋਧੋ';

  @override
  String get profileMySkills => 'ਮੇਰੇ ਹੁਨਰ';

  @override
  String get profileMyWork => 'ਮੇਰਾ ਕੰਮ';

  @override
  String get profileAdd => 'ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get profileViewAll => 'ਸਾਰੇ ਵੇਖੋ';

  @override
  String get profileSecAccount => 'ਖਾਤਾ';

  @override
  String get profileSecWork => 'ਕੰਮ';

  @override
  String get profileSecSupportLegal => 'ਸਹਾਇਤਾ ਅਤੇ ਕਾਨੂੰਨੀ';

  @override
  String get profileEditProfile => 'ਪ੍ਰੋਫਾਈਲ ਸੋਧੋ';

  @override
  String get profileVerificationDocuments => 'ਤਸਦੀਕ ਅਤੇ ਦਸਤਾਵੇਜ਼';

  @override
  String get profileBankPayment => 'ਬੈਂਕ ਅਤੇ ਭੁਗਤਾਨ';

  @override
  String get profileSetWorkingHours => 'ਆਪਣੇ ਕੰਮ ਦੇ ਘੰਟੇ ਤੈਅ ਕਰੋ';

  @override
  String get profileWorkPortfolio => 'ਕੰਮ ਪੋਰਟਫੋਲੀਓ';

  @override
  String get profileShowcaseWork => 'ਆਪਣਾ ਵਧੀਆ ਕੰਮ ਦਿਖਾਓ';

  @override
  String profilePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ਫ਼ੋਟੋਆਂ',
      one: '1 ਫ਼ੋਟੋ',
    );
    return '$_temp0';
  }

  @override
  String get profileCompletedTasks => 'ਪੂਰੇ ਕੀਤੇ ਕੰਮ';

  @override
  String get profileMyReviews => 'ਮੇਰੀਆਂ ਸਮੀਖਿਆਵਾਂ';

  @override
  String get profileEarningsPayouts => 'ਕਮਾਈ ਅਤੇ ਭੁਗਤਾਨ';

  @override
  String get profileHelpSupport => 'ਸਹਾਇਤਾ ਅਤੇ ਸਮਰਥਨ';

  @override
  String get profileTerms => 'ਨਿਯਮ ਅਤੇ ਸ਼ਰਤਾਂ';

  @override
  String get profilePrivacy => 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ';

  @override
  String get profileRateUs => 'ਪਲੇ ਸਟੋਰ \'ਤੇ ਸਾਨੂੰ ਰੇਟ ਕਰੋ';

  @override
  String get profileReferEarn => 'ਰੈਫ਼ਰ ਕਰੋ ਅਤੇ ₹200 ਕਮਾਓ';

  @override
  String get profileSignOut => 'ਸਾਈਨ ਆਊਟ';

  @override
  String profileVersion(String version) {
    return 'ਵਰਜਨ $version';
  }

  @override
  String get profileRedirectTitle => 'ਬਾਹਰੀ ਲਿੰਕ \'ਤੇ ਰੀਡਾਇਰੈਕਟ';

  @override
  String profileRedirectBody(String url) {
    return 'ਤੁਹਾਨੂੰ ਇੱਕ ਬਾਹਰੀ ਵੈੱਬਸਾਈਟ \'ਤੇ ਰੀਡਾਇਰੈਕਟ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ:\n\n$url\n\nਕੀ ਤੁਸੀਂ ਜਾਰੀ ਰੱਖਣਾ ਚਾਹੁੰਦੇ ਹੋ?';
  }

  @override
  String get profileCouldNotOpenLink => 'ਲਿੰਕ ਨਹੀਂ ਖੋਲ੍ਹ ਸਕੇ';

  @override
  String get profileUploadingPhoto => 'ਫ਼ੋਟੋ ਅਪਲੋਡ ਹੋ ਰਹੀ ਹੈ…';

  @override
  String get profilePictureUpdated => 'ਪ੍ਰੋਫਾਈਲ ਫ਼ੋਟੋ ਅੱਪਡੇਟ ਹੋਈ';

  @override
  String get profileUpdatePicture => 'ਪ੍ਰੋਫਾਈਲ ਫ਼ੋਟੋ ਅੱਪਡੇਟ ਕਰੋ';

  @override
  String get profileEditAboutMe => 'ਮੇਰੇ ਬਾਰੇ ਸੋਧੋ';

  @override
  String get profileWriteAboutYourself => 'ਆਪਣੇ ਬਾਰੇ ਲਿਖੋ...';

  @override
  String get profileBioUpdated => 'ਬਾਇਓ ਅੱਪਡੇਟ ਹੋਇਆ';

  @override
  String get profileEditSkills => 'ਹੁਨਰ ਸੋਧੋ';

  @override
  String get profileSaveSkills => 'ਹੁਨਰ ਸੰਭਾਲੋ';

  @override
  String get profileSkillsUpdated => 'ਹੁਨਰ ਅੱਪਡੇਟ ਹੋਏ';

  @override
  String get profileNoCoins => 'ਕੋਈ TaskCoins ਨਹੀਂ';

  @override
  String get profileNoCoinsBody =>
      'ਤੁਹਾਡੇ ਵਾਲਿਟ ਵਿੱਚ ਭੁਨਾਉਣ ਲਈ 0 TaskCoins ਹਨ।';

  @override
  String get profileRedeemCoins => 'TaskCoins ਭੁਨਾਓ';

  @override
  String profileCoinsValue(int coins) {
    return '$coins ਸਿੱਕੇ = ₹$coins';
  }

  @override
  String get profileCoinsCredited =>
      'ਸਿੱਕੇ ਤੁਹਾਡੇ ਡਿਫੌਲਟ ਭੁਗਤਾਨ ਤਰੀਕੇ ਵਿੱਚ ਜਮ੍ਹਾਂ ਕੀਤੇ ਜਾਣਗੇ।';

  @override
  String profileCoinsWillCredit(int amount) {
    return '₹$amount ਤੁਹਾਡੇ ਖਾਤੇ ਵਿੱਚ ਜਮ੍ਹਾਂ ਕੀਤੇ ਜਾਣਗੇ';
  }

  @override
  String get profileRedeemAll => 'ਸਾਰੇ ਭੁਨਾਓ';

  @override
  String get profileAddPhotosWork => 'ਆਪਣੇ ਕੰਮ ਦੀਆਂ ਫ਼ੋਟੋਆਂ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get profilePortfolioHelps =>
      'ਇੱਕ ਮਜ਼ਬੂਤ ਪੋਰਟਫੋਲੀਓ ਤੁਹਾਨੂੰ ਵੱਧ ਕੰਮ ਦਿਵਾਉਣ ਵਿੱਚ ਮਦਦ ਕਰਦਾ ਹੈ';

  @override
  String get profileNotSet => 'ਤੈਅ ਨਹੀਂ';

  @override
  String get profileEveryDay => 'ਹਰ ਦਿਨ';

  @override
  String get profileHoursVary => 'ਘੰਟੇ ਵੱਖ-ਵੱਖ';

  @override
  String get walletWithdrawMoney => 'ਪੈਸੇ ਕਢਵਾਓ';

  @override
  String get walletAmount => 'ਰਕਮ';

  @override
  String walletAvailableBalance(String amount) {
    return 'ਉਪਲਬਧ: ₹$amount';
  }

  @override
  String get walletEnterValidAmount => 'ਕਿਰਪਾ ਕਰਕੇ ਵੈਧ ਰਕਮ ਦਰਜ ਕਰੋ';

  @override
  String get walletInsufficientBalance => 'ਨਾਕਾਫ਼ੀ ਬਕਾਇਆ';

  @override
  String walletWithdrawalRequested(String amount) {
    return '₹$amount ਦੀ ਨਿਕਾਸੀ ਦੀ ਬੇਨਤੀ ਕੀਤੀ ਗਈ!';
  }

  @override
  String get walletNoEarnings7Days => 'ਪਿਛਲੇ 7 ਦਿਨਾਂ ਵਿੱਚ ਕੋਈ ਕਮਾਈ ਨਹੀਂ';

  @override
  String get walletEarningsLast7 => 'ਕਮਾਈ - ਪਿਛਲੇ 7 ਦਿਨ';

  @override
  String get walletTotalEarned => 'ਕੁੱਲ ਕਮਾਈ';

  @override
  String get walletJobsCompleted => 'ਪੂਰੇ ਕੀਤੇ ਕੰਮ';

  @override
  String get walletAvgPerJob => 'ਪ੍ਰਤੀ ਕੰਮ ਔਸਤ';

  @override
  String get verifTitle => 'ਤਸਦੀਕ ਅਤੇ ਦਸਤਾਵੇਜ਼';

  @override
  String get verifProgress => 'ਤਸਦੀਕ ਪ੍ਰਗਤੀ';

  @override
  String verifDocsVerified(int verified, int total) {
    return '$total ਵਿੱਚੋਂ $verified ਦਸਤਾਵੇਜ਼ ਤਸਦੀਕ ਹੋਏ';
  }

  @override
  String get verifDocuments => 'ਦਸਤਾਵੇਜ਼';

  @override
  String get verifAadhaar => 'ਆਧਾਰ ਕਾਰਡ';

  @override
  String get verifAadhaarUpload => 'ਪਛਾਣ ਤਸਦੀਕ ਲਈ ਆਧਾਰ ਅਪਲੋਡ ਕਰੋ';

  @override
  String get verifPan => 'ਪੈਨ ਕਾਰਡ';

  @override
  String get verifPanUpload => 'ਟੈਕਸ ਮਕਸਦਾਂ ਲਈ ਪੈਨ ਅਪਲੋਡ ਕਰੋ';

  @override
  String get verifUnderReview => 'ਸਮੀਖਿਆ ਅਧੀਨ';

  @override
  String get verifAddressProof => 'ਪਤੇ ਦਾ ਸਬੂਤ';

  @override
  String get verifAddressVerified => 'ਪਤਾ ਸਫਲਤਾਪੂਰਵਕ ਤਸਦੀਕ ਹੋਇਆ';

  @override
  String get verifAddressUpload => 'ਬਿਜਲੀ ਬਿੱਲ ਜਾਂ ਕਿਰਾਇਆ ਸਮਝੌਤਾ ਅਪਲੋਡ ਕਰੋ';

  @override
  String get verifSelfie => 'ਸੈਲਫ਼ੀ ਤਸਦੀਕ';

  @override
  String get verifIdentityConfirmed => 'ਪਛਾਣ ਦੀ ਪੁਸ਼ਟੀ ਹੋਈ';

  @override
  String get verifSelfieUpload => 'ਪਛਾਣ ਦੀ ਪੁਸ਼ਟੀ ਲਈ ਸੈਲਫ਼ੀ ਲਵੋ';

  @override
  String get verifUnlockPremium =>
      'ਪ੍ਰੀਮੀਅਮ ਕੰਮ ਅਤੇ ਵੱਧ ਭੁਗਤਾਨ ਅਨਲੌਕ ਕਰਨ ਲਈ ਸਾਰੇ ਤਸਦੀਕ ਪੂਰੇ ਕਰੋ।';

  @override
  String get verifStatusVerified => 'ਤਸਦੀਕ ਹੋਇਆ';

  @override
  String get verifStatusPending => 'ਬਕਾਇਆ';

  @override
  String get verifStatusRejected => 'ਰੱਦ';

  @override
  String get verifStatusUpload => 'ਅਪਲੋਡ';

  @override
  String verifAlreadyVerified(String title) {
    return '$title ਪਹਿਲਾਂ ਹੀ ਤਸਦੀਕ ਹੈ!';
  }

  @override
  String verifUploadTitle(String title) {
    return '$title ਅਪਲੋਡ ਕਰੋ';
  }

  @override
  String verifUploading(String title) {
    return '$title ਅਪਲੋਡ ਹੋ ਰਿਹਾ ਹੈ…';
  }

  @override
  String verifSubmitted(String title) {
    return '$title ਜਮ੍ਹਾਂ ਕੀਤਾ ਗਿਆ। ਸਾਡੀ ਟੀਮ ਜਲਦੀ ਇਸ ਦੀ ਸਮੀਖਿਆ ਕਰੇਗੀ।';
  }

  @override
  String get availSaveSchedule => 'ਸਮਾਂ-ਸਾਰਣੀ ਸੰਭਾਲੋ';

  @override
  String get availSaved => 'ਉਪਲਬਧਤਾ ਸੰਭਾਲੀ ਗਈ';

  @override
  String get availEndAfterStart =>
      'ਸਮਾਪਤੀ ਸਮਾਂ ਸ਼ੁਰੂ ਸਮੇਂ ਤੋਂ ਬਾਅਦ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ';

  @override
  String get availStartTime => 'ਸ਼ੁਰੂ ਸਮਾਂ';

  @override
  String get availEndTime => 'ਸਮਾਪਤੀ ਸਮਾਂ';

  @override
  String get availYourWeeklyHours => 'ਤੁਹਾਡੇ ਹਫ਼ਤਾਵਾਰੀ ਘੰਟੇ';

  @override
  String get availNotSetTap => 'ਤੈਅ ਨਹੀਂ - ਕੰਮ ਦੇ ਘੰਟੇ ਜੋੜਨ ਲਈ ਟੈਪ ਕਰੋ';

  @override
  String get availStart => 'ਸ਼ੁਰੂ';

  @override
  String get availEnd => 'ਸਮਾਪਤ';

  @override
  String get availAvailableDay => 'ਉਪਲਬਧ';

  @override
  String get availOff => 'ਬੰਦ';

  @override
  String get dayMonday => 'ਸੋਮਵਾਰ';

  @override
  String get dayTuesday => 'ਮੰਗਲਵਾਰ';

  @override
  String get dayWednesday => 'ਬੁੱਧਵਾਰ';

  @override
  String get dayThursday => 'ਵੀਰਵਾਰ';

  @override
  String get dayFriday => 'ਸ਼ੁੱਕਰਵਾਰ';

  @override
  String get daySaturday => 'ਸ਼ਨੀਵਾਰ';

  @override
  String get daySunday => 'ਐਤਵਾਰ';

  @override
  String timeWeeksAgo(int count) {
    return '$count ਹਫ਼ਤੇ ਪਹਿਲਾਂ';
  }

  @override
  String get msgSearchChats => 'ਚੈਟ ਖੋਜੋ…';

  @override
  String get msgNoResults => 'ਕੋਈ ਨਤੀਜਾ ਨਹੀਂ ਮਿਲਿਆ';

  @override
  String get msgNoConversations => 'ਹਾਲੇ ਕੋਈ ਗੱਲਬਾਤ ਨਹੀਂ';

  @override
  String get msgTryDifferentSearch => 'ਕੋਈ ਹੋਰ ਖੋਜ ਸ਼ਬਦ ਅਜ਼ਮਾਓ';

  @override
  String get msgChatsWillAppear =>
      'ਜਦੋਂ ਤੁਸੀਂ ਕੋਈ ਕੰਮ ਸ਼ੁਰੂ ਕਰੋਗੇ,\nਤਾਂ ਤੁਹਾਡੀਆਂ ਚੈਟਾਂ ਇੱਥੇ ਦਿਖਣਗੀਆਂ।';

  @override
  String get msgTapToOpen => 'ਚੈਟ ਖੋਲ੍ਹਣ ਲਈ ਟੈਪ ਕਰੋ';

  @override
  String get msgYesterday => 'ਕੱਲ੍ਹ';

  @override
  String get msgSayHello => 'ਹੈਲੋ ਕਹੋ!';

  @override
  String get msgStartConversation => 'ਗੱਲਬਾਤ ਸ਼ੁਰੂ ਕਰੋ ਅਤੇ\nਕੰਮ ਅੱਗੇ ਵਧਾਓ।';

  @override
  String get msgTakePhoto => 'ਫ਼ੋਟੋ ਲਵੋ';

  @override
  String msgErrorSelectingImage(String error) {
    return 'ਇਮੇਜ ਚੁਣਨ ਵਿੱਚ ਗਲਤੀ: $error';
  }

  @override
  String get msgCouldNotSend => 'ਸੁਨੇਹਾ ਨਹੀਂ ਭੇਜ ਸਕੇ';

  @override
  String get msgMessageCopied => 'ਸੁਨੇਹਾ ਕਾਪੀ ਹੋਇਆ';

  @override
  String get msgTypeMessage => 'ਸੁਨੇਹਾ ਲਿਖੋ…';

  @override
  String get notifTitle => 'ਸੂਚਨਾਵਾਂ';

  @override
  String notifUnreadCount(int count) {
    return '$count ਅਣਪੜ੍ਹੀਆਂ';
  }

  @override
  String get notifAllCaughtUp => 'ਸਭ ਵੇਖ ਲਿਆ';

  @override
  String get notifMarkAll => 'ਸਾਰੀਆਂ ਪੜ੍ਹੀਆਂ ਕਰੋ';

  @override
  String get notifNoNotifications => 'ਹਾਲੇ ਕੋਈ ਸੂਚਨਾ ਨਹੀਂ';

  @override
  String get notifEmptyBody => 'ਜੌਬ ਲੀਡ, ਬੁਕਿੰਗ ਅਤੇ ਭੁਗਤਾਨ ਇੱਥੇ ਦਿਖਣਗੇ';

  @override
  String get notifSomethingWrong => 'ਕੁਝ ਗਲਤ ਹੋ ਗਿਆ';

  @override
  String get notifJustNow => 'ਹੁਣੇ';

  @override
  String get editProfileUpdated => 'ਪ੍ਰੋਫਾਈਲ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਹੋਈ';

  @override
  String editProfileFailed(String error) {
    return 'ਪ੍ਰੋਫਾਈਲ ਅੱਪਡੇਟ ਕਰਨ ਵਿੱਚ ਅਸਫਲ: $error';
  }

  @override
  String get editFullName => 'ਪੂਰਾ ਨਾਮ';

  @override
  String get editFullNameHint => 'ਆਪਣਾ ਪੂਰਾ ਨਾਮ ਦਰਜ ਕਰੋ';

  @override
  String get editNameRequired => 'ਨਾਮ ਲੋੜੀਂਦਾ ਹੈ';

  @override
  String get editEmail => 'ਈਮੇਲ';

  @override
  String get editEmailHint => 'ਆਪਣੀ ਈਮੇਲ ਦਰਜ ਕਰੋ';

  @override
  String get editEmailRequired => 'ਈਮੇਲ ਲੋੜੀਂਦੀ ਹੈ';

  @override
  String get editEmailInvalid => 'ਇੱਕ ਵੈਧ ਈਮੇਲ ਦਰਜ ਕਰੋ';

  @override
  String get editPhone => 'ਫ਼ੋਨ ਨੰਬਰ';

  @override
  String get editPhoneHint => 'ਆਪਣਾ ਫ਼ੋਨ ਨੰਬਰ ਦਰਜ ਕਰੋ';

  @override
  String get editPhoneRequired => 'ਫ਼ੋਨ ਲੋੜੀਂਦਾ ਹੈ';

  @override
  String get editCity => 'ਸ਼ਹਿਰ / ਟਿਕਾਣਾ';

  @override
  String get editCityHint => 'ਆਪਣਾ ਸ਼ਹਿਰ ਦਰਜ ਕਰੋ';

  @override
  String get editCityRequired => 'ਸ਼ਹਿਰ ਲੋੜੀਂਦਾ ਹੈ';

  @override
  String get editSaveChanges => 'ਤਬਦੀਲੀਆਂ ਸੰਭਾਲੋ';

  @override
  String get splashPreparing => 'TaskTeddy ਤਿਆਰ ਹੋ ਰਿਹਾ ਹੈ';

  @override
  String get splashGettingReady => 'ਸਭ ਕੁਝ ਤਿਆਰ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ...';

  @override
  String get splashGettingThingsReady => 'ਚੀਜ਼ਾਂ ਤਿਆਰ ਕੀਤੀਆਂ ਜਾ ਰਹੀਆਂ ਹਨ...';

  @override
  String get splashLocationOff => 'ਲੋਕੇਸ਼ਨ ਬੰਦ ਹੈ। ਜਾਰੀ ਹੈ...';

  @override
  String get splashLocationSkipped => 'ਲੋਕੇਸ਼ਨ ਇਜਾਜ਼ਤ ਛੱਡੀ ਗਈ। ਜਾਰੀ ਹੈ...';

  @override
  String splashLocationLocked(String label) {
    return 'ਲੋਕੇਸ਼ਨ ਤੈਅ ਹੋਈ: $label';
  }

  @override
  String get splashLocationFailed => 'ਲੋਕੇਸ਼ਨ ਨਹੀਂ ਮਿਲ ਸਕੀ। ਜਾਰੀ ਹੈ...';

  @override
  String get commonRemove => 'ਹਟਾਓ';

  @override
  String get completedEmptyBody =>
      'ਹਾਲੇ ਤੱਕ ਕੋਈ ਪੂਰਾ ਕੰਮ ਨਹੀਂ।\nਤੁਹਾਡਾ ਪੂਰਾ ਕੀਤਾ ਕੰਮ ਇੱਥੇ ਦਿਖੇਗਾ।';

  @override
  String get reviewsRecent => 'ਤਾਜ਼ਾ ਸਮੀਖਿਆਵਾਂ';

  @override
  String get reviewsNone => 'ਹਾਲੇ ਕੋਈ ਸਮੀਖਿਆ ਨਹੀਂ';

  @override
  String portfolioFull(int max) {
    return 'ਪੋਰਟਫੋਲੀਓ ਭਰ ਗਿਆ (ਵੱਧ ਤੋਂ ਵੱਧ $max ਫ਼ੋਟੋਆਂ)';
  }

  @override
  String get portfolioAddCaption => 'ਇੱਕ ਕੈਪਸ਼ਨ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get portfolioCaptionHint => 'ਵਿਕਲਪਿਕ - ਜਿਵੇਂ ਰਸੋਈ ਦੀ ਡੂੰਘੀ ਸਫ਼ਾਈ';

  @override
  String get portfolioSkip => 'ਛੱਡੋ';

  @override
  String get portfolioPhotoAdded => 'ਫ਼ੋਟੋ ਪੋਰਟਫੋਲੀਓ ਵਿੱਚ ਸ਼ਾਮਲ ਕੀਤੀ ਗਈ';

  @override
  String get portfolioAddWorkPhoto => 'ਕੰਮ ਦੀ ਫ਼ੋਟੋ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get portfolioRemovePhoto => 'ਫ਼ੋਟੋ ਹਟਾਓ';

  @override
  String get portfolioRemoveConfirm =>
      'ਕੀ ਇਸ ਫ਼ੋਟੋ ਨੂੰ ਆਪਣੇ ਪੋਰਟਫੋਲੀਓ ਤੋਂ ਹਟਾਉਣਾ ਹੈ?';

  @override
  String get portfolioPhotoRemoved => 'ਫ਼ੋਟੋ ਹਟਾਈ ਗਈ';

  @override
  String get portfolioUploading => 'ਅਪਲੋਡ ਹੋ ਰਿਹਾ ਹੈ...';

  @override
  String get portfolioAddPhoto => 'ਫ਼ੋਟੋ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get portfolioEmpty => 'ਹਾਲੇ ਕੋਈ ਪੋਰਟਫੋਲੀਓ ਫ਼ੋਟੋ ਨਹੀਂ';

  @override
  String get portfolioEmptyBody => 'ਵੱਧ ਕੰਮ ਲੈਣ ਲਈ ਆਪਣਾ ਵਧੀਆ ਕੰਮ ਦਿਖਾਓ।';

  @override
  String get portfolioUntitled => 'ਬਿਨਾਂ ਸਿਰਲੇਖ';

  @override
  String get referTitle => 'ਰੈਫ਼ਰ ਕਰੋ ਅਤੇ ਕਮਾਓ';

  @override
  String get referEarnHero => 'ਹਰ ਰੈਫ਼ਰਲ \'ਤੇ ₹200 ਕਮਾਓ!';

  @override
  String get referInviteFriends =>
      'ਦੋਸਤਾਂ ਨੂੰ TaskTeddy \'ਤੇ ਸੱਦੋ ਅਤੇ ਇਕੱਠੇ ਇਨਾਮ ਕਮਾਓ।';

  @override
  String get referHowItWorks => 'ਇਹ ਕਿਵੇਂ ਕੰਮ ਕਰਦਾ ਹੈ';

  @override
  String get referStep1 => 'ਆਪਣਾ ਰੈਫ਼ਰਲ ਕੋਡ ਦੋਸਤਾਂ ਨਾਲ ਸਾਂਝਾ ਕਰੋ';

  @override
  String get referStep2 =>
      'ਤੁਹਾਡਾ ਦੋਸਤ ਸਾਈਨ ਅੱਪ ਕਰਦਾ ਹੈ ਅਤੇ ਪਹਿਲਾ ਕੰਮ ਪੂਰਾ ਕਰਦਾ ਹੈ';

  @override
  String get referStep3 => 'ਤੁਸੀਂ ਦੋਵੇਂ ₹200 TaskCoins ਵਿੱਚ ਕਮਾਉਂਦੇ ਹੋ!';

  @override
  String get referYourCode => 'ਤੁਹਾਡਾ ਰੈਫ਼ਰਲ ਕੋਡ';

  @override
  String get referCodeCopied => 'ਕੋਡ ਕਾਪੀ ਹੋਇਆ!';

  @override
  String get referShareWhatsApp => 'WhatsApp \'ਤੇ ਸਾਂਝਾ ਕਰੋ';

  @override
  String get referShareDialogOpened => 'ਸਾਂਝਾ ਕਰਨ ਦਾ ਡਾਇਲੌਗ ਖੁੱਲ੍ਹਿਆ!';

  @override
  String get referYourReferrals => 'ਤੁਹਾਡੇ ਰੈਫ਼ਰਲ';

  @override
  String get referTotalReferrals => 'ਕੁੱਲ ਰੈਫ਼ਰਲ';

  @override
  String get referEarningsFrom => 'ਰੈਫ਼ਰਲ ਤੋਂ ਕਮਾਈ';

  @override
  String referStep(int number) {
    return 'ਕਦਮ $number';
  }

  @override
  String referShareMessage(String code) {
    return 'ਮੇਰੇ ਰੈਫ਼ਰਲ ਕੋਡ $code ਦੀ ਵਰਤੋਂ ਕਰਕੇ TaskTeddy ਜੋਇਨ ਕਰੋ ਅਤੇ ₹200 ਕਮਾਓ! ਹੁਣੇ ਡਾਊਨਲੋਡ ਕਰੋ: https://taskteddy.app';
  }

  @override
  String bankRemoveConfirmTitle(String name) {
    return '$name ਹਟਾਓ?';
  }

  @override
  String get bankRemoveConfirmBody =>
      'ਇਹ ਭੁਗਤਾਨ ਤਰੀਕਾ ਤੁਹਾਡੇ ਖਾਤੇ ਤੋਂ ਹਟਾ ਦਿੱਤਾ ਜਾਵੇਗਾ।';

  @override
  String bankMethodRemoved(String name) {
    return '$name ਹਟਾਇਆ ਗਿਆ';
  }

  @override
  String get bankBankAccount => 'ਬੈਂਕ ਖਾਤਾ';

  @override
  String get bankBankAccountSub => 'ਬੱਚਤ ਜਾਂ ਚਾਲੂ ਖਾਤਾ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get bankUpiId => 'UPI ID';

  @override
  String get bankUpiSub => 'ਆਪਣਾ UPI ਪਤਾ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get bankAddBankAccount => 'ਬੈਂਕ ਖਾਤਾ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get bankAccountHolderName => 'ਖਾਤਾਧਾਰਕ ਦਾ ਨਾਮ';

  @override
  String get bankAccountNumber => 'ਖਾਤਾ ਨੰਬਰ';

  @override
  String get bankIfscCode => 'IFSC ਕੋਡ';

  @override
  String get bankFillAllFields => 'ਕਿਰਪਾ ਕਰਕੇ ਸਾਰੇ ਖਾਨੇ ਭਰੋ';

  @override
  String bankSavingsMask(String last4) {
    return 'ਬੱਚਤ ਖਾਤਾ •••• $last4';
  }

  @override
  String get bankAccountAdded => 'ਬੈਂਕ ਖਾਤਾ ਸਫਲਤਾਪੂਰਵਕ ਸ਼ਾਮਲ ਕੀਤਾ ਗਿਆ';

  @override
  String get bankAddUpiId => 'UPI ID ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get bankUpiHint => 'ਜਿਵੇਂ name@upi';

  @override
  String get bankEnterValidUpi => 'ਕਿਰਪਾ ਕਰਕੇ ਵੈਧ UPI ID ਦਰਜ ਕਰੋ';

  @override
  String get bankUpiAdded => 'UPI ID ਸਫਲਤਾਪੂਰਵਕ ਸ਼ਾਮਲ ਕੀਤੀ ਗਈ';

  @override
  String get bankPayoutInfo => 'ਭੁਗਤਾਨ ਜਾਣਕਾਰੀ';

  @override
  String get bankProcessingTime => 'ਪ੍ਰੋਸੈਸਿੰਗ ਸਮਾਂ';

  @override
  String get bankProcessingTimeVal => 'ਕੰਮ ਪੂਰਾ ਹੋਣ ਦੇ 24 ਘੰਟੇ ਬਾਅਦ';

  @override
  String get bankMinWithdrawal => 'ਘੱਟੋ-ਘੱਟ ਨਿਕਾਸੀ';

  @override
  String get bankPlatformFee => 'ਪਲੇਟਫਾਰਮ ਫੀਸ';

  @override
  String get bankPlatformFeeVal => 'ਪ੍ਰਤੀ ਕੰਮ 15%';

  @override
  String get bankPaymentCycle => 'ਭੁਗਤਾਨ ਚੱਕਰ';

  @override
  String get bankPaymentCycleVal => 'ਡਿਫੌਲਟ ਤਰੀਕੇ ਵਿੱਚ ਤੁਰੰਤ';

  @override
  String get bankDefault => 'ਡਿਫੌਲਟ';

  @override
  String get bankSetDefault => 'ਡਿਫੌਲਟ ਸੈੱਟ ਕਰੋ';

  @override
  String get helpMyTicketsTooltip => 'ਮੇਰੇ ਟਿਕਟ';

  @override
  String get helpMessageSupport => 'ਸਪੋਰਟ ਨੂੰ ਸੁਨੇਹਾ ਭੇਜੋ';

  @override
  String get helpRespond24 =>
      'ਅਸੀਂ ਆਮ ਤੌਰ \'ਤੇ 24 ਘੰਟਿਆਂ ਦੇ ਅੰਦਰ ਜਵਾਬ ਦਿੰਦੇ ਹਾਂ।';

  @override
  String get helpSubject => 'ਵਿਸ਼ਾ';

  @override
  String get helpDescribeIssue => 'ਆਪਣੀ ਸਮੱਸਿਆ ਦੱਸੋ…';

  @override
  String get helpAddSubjectDesc =>
      'ਕਿਰਪਾ ਕਰਕੇ ਇੱਕ ਵਿਸ਼ਾ ਅਤੇ ਇੱਕ ਸੰਖੇਪ ਵੇਰਵਾ ਸ਼ਾਮਲ ਕਰੋ।';

  @override
  String get helpTicketSent => 'ਟਿਕਟ ਭੇਜਿਆ ਗਿਆ! ਅਸੀਂ ਐਪ ਵਿੱਚ ਜਵਾਬ ਦੇਵਾਂਗੇ।';

  @override
  String get helpSend => 'ਭੇਜੋ';

  @override
  String get helpNoTickets => 'ਹਾਲੇ ਕੋਈ ਸਪੋਰਟ ਟਿਕਟ ਨਹੀਂ';

  @override
  String get helpResolved => 'ਹੱਲ ਹੋਇਆ';

  @override
  String get helpOpen => 'ਖੁੱਲ੍ਹਾ';

  @override
  String helpSupportReply(String reply) {
    return 'ਸਪੋਰਟ: $reply';
  }

  @override
  String helpReachOut(String phone, String email) {
    return 'ਪਾਰਟਨਰ ਸਪੋਰਟ ਨਾਲ ਸੰਪਰਕ ਕਰੋ\n$phone  •  $email';
  }

  @override
  String get helpCallUs => 'ਸਾਨੂੰ ਕਾਲ ਕਰੋ';

  @override
  String get helpEmailUs => 'ਸਾਨੂੰ ਈਮੇਲ ਕਰੋ';

  @override
  String get helpCouldNotDial => 'ਇਸ ਡਿਵਾਈਸ \'ਤੇ ਡਾਇਲਰ ਨਹੀਂ ਖੋਲ੍ਹ ਸਕੇ।';

  @override
  String get helpCouldNotEmail => 'ਇਸ ਡਿਵਾਈਸ \'ਤੇ ਈਮੇਲ ਐਪ ਨਹੀਂ ਖੋਲ੍ਹ ਸਕੇ।';

  @override
  String get helpNeedQuickHelp => 'ਤੁਰੰਤ ਮਦਦ ਚਾਹੀਦੀ ਹੈ?';

  @override
  String get helpFindAnswers =>
      'ਤੁਰੰਤ ਜਵਾਬ ਲੱਭੋ ਜਾਂ ਕਿਸੇ ਵੀ ਵੇਲੇ ਸਪੋਰਟ ਨਾਲ ਸੰਪਰਕ ਕਰੋ।';

  @override
  String get helpMyDisputes => 'ਮੇਰੇ ਭੁਗਤਾਨ ਵਿਵਾਦ';

  @override
  String get helpNoDisputes => 'ਤੁਹਾਡੇ ਕੋਲ ਕੋਈ ਸਰਗਰਮ ਵਿਵਾਦ ਨਹੀਂ ਹੈ।';

  @override
  String get helpBrowseTopics => 'ਸਾਰੇ ਸਹਾਇਤਾ ਵਿਸ਼ੇ ਵੇਖੋ';

  @override
  String helpRelatedTo(String topic) {
    return '$topic ਨਾਲ ਸਬੰਧਤ ਸਹਾਇਤਾ';
  }

  @override
  String get helpCantFind => 'ਆਪਣਾ ਜਵਾਬ ਨਹੀਂ ਲੱਭ ਰਿਹਾ?';

  @override
  String get helpTeamHere => 'ਸਾਡੀ ਸਪੋਰਟ ਟੀਮ ਮਦਦ ਲਈ ਇੱਥੇ ਹੈ';

  @override
  String get helpT1Title => 'ਕੰਮ ਅਤੇ ਅਰਜ਼ੀਆਂ';

  @override
  String get helpT1Sub =>
      'ਅਰਜ਼ੀਆਂ, ਬੋਲੀਆਂ, ਸਲਾਟ ਵੇਰਵੇ ਅਤੇ ਕਵਰ ਲੈਟਰ ਪ੍ਰਬੰਧਿਤ ਕਰੋ';

  @override
  String get helpT1Q1 => 'ਮੈਂ ਕਿਸੇ ਕੰਮ ਲਈ ਅਰਜ਼ੀ ਕਿਵੇਂ ਦੇਵਾਂ?';

  @override
  String get helpT1A1 =>
      'ਖੋਜੋ ਟੈਬ ਵਿੱਚ ਉਪਲਬਧ ਕੰਮ ਵੇਖੋ, ਆਪਣੀ ਮੁਹਾਰਤ ਨਾਲ ਮੇਲ ਖਾਂਦਾ ਕੰਮ ਚੁਣੋ, ਆਪਣੀ ਬੋਲੀ ਰਕਮ ਤੈਅ ਕਰੋ, ਆਪਣੇ ਤਜਰਬੇ ਦਾ ਸੰਖੇਪ ਕਵਰ ਲੈਟਰ ਲਿਖੋ, ਅਤੇ ਅਰਜ਼ੀ ਦਿਓ \'ਤੇ ਟੈਪ ਕਰੋ।';

  @override
  String get helpT1Q2 => 'ਕੀ ਮੈਂ ਆਪਣੀ ਅਰਜ਼ੀ ਰੱਦ ਜਾਂ ਵਾਪਸ ਲੈ ਸਕਦਾ ਹਾਂ?';

  @override
  String get helpT1A2 =>
      'ਹਾਂ। ਪ੍ਰੋਫਾਈਲ ਟੈਬ \'ਤੇ ਮੇਰੀਆਂ ਅਰਜ਼ੀਆਂ ਵਿੱਚ ਜਾਓ, ਜਿਸ ਬਕਾਇਆ ਅਰਜ਼ੀ ਨੂੰ ਵਾਪਸ ਲੈਣਾ ਹੈ ਉਸ ਨੂੰ ਚੁਣੋ, ਅਤੇ ਆਪਣੀ ਬੋਲੀ ਹਟਾਉਣ ਲਈ ਵਾਪਸ ਲਵੋ ਵਿਕਲਪ \'ਤੇ ਟੈਪ ਕਰੋ।';

  @override
  String get helpT1Q3 => 'ਮੇਰੀ ਅਰਜ਼ੀ ਸਵੀਕਾਰ ਹੋਣ \'ਤੇ ਕੀ ਹੁੰਦਾ ਹੈ?';

  @override
  String get helpT1A3 =>
      'ਤੁਹਾਨੂੰ ਤੁਰੰਤ ਇੱਕ ਸੂਚਨਾ ਮਿਲੇਗੀ, ਅਤੇ ਕੰਮ ਤੁਹਾਡੇ \"ਮੇਰੇ ਸਰਗਰਮ ਕੰਮ\" ਵਿੱਚ ਚਲਾ ਜਾਵੇਗਾ। ਗਾਹਕ ਵੇਰਵੇ ਅਤੇ ਟਿਕਾਣਾ ਵੇਖਣ ਲਈ ਤੁਸੀਂ ਕੰਮ ਖੋਲ੍ਹ ਸਕਦੇ ਹੋ।';

  @override
  String get helpT1Q4 => 'ਕੰਮ ਪੂਰਾ ਹੋਣ ਦਾ OTP ਕੀ ਹੈ?';

  @override
  String get helpT1A4 =>
      'ਕੰਮ ਸਫਲਤਾਪੂਰਵਕ ਪੂਰਾ ਕਰਨ \'ਤੇ, ਗਾਹਕ ਤੋਂ 4-ਅੰਕਾਂ ਦਾ ਤਸਦੀਕ OTP ਮੰਗੋ। ਇਸ ਨੂੰ ਸਰਗਰਮ ਕੰਮ ਵਿੰਡੋ ਵਿੱਚ ਦਰਜ ਕਰੋ ਤਾਂ ਜੋ ਇਹ ਪੂਰਾ ਹੋਵੇ ਅਤੇ ਤੁਹਾਡਾ ਭੁਗਤਾਨ ਜਾਰੀ ਹੋਵੇ।';

  @override
  String get helpT1Q5 =>
      'ਮੇਰੇ ਪਹੁੰਚਣ ਤੋਂ ਬਾਅਦ ਗਾਹਕ ਕੰਮ ਰੱਦ ਕਰ ਦੇਵੇ ਤਾਂ ਕੀ ਹੋਵੇਗਾ?';

  @override
  String get helpT1A5 =>
      'ਜੇ ਤੁਹਾਡੇ ਪਹੁੰਚਣ ਜਾਂ ਟਿਕਾਣੇ ਵੱਲ ਸਫ਼ਰ ਸ਼ੁਰੂ ਕਰਨ ਤੋਂ ਬਾਅਦ ਗਾਹਕ ਰੱਦ ਕਰਦਾ ਹੈ, ਤਾਂ ਤੈਅ ਕੀਤੀ ਦੂਰੀ ਦੇ ਆਧਾਰ \'ਤੇ ਤੁਸੀਂ ₹50-₹150 ਦੇ ਰੱਦੀਕਰਨ ਮੁਆਵਜ਼ੇ ਦੇ ਹੱਕਦਾਰ ਹੋ ਸਕਦੇ ਹੋ। ਸਰਗਰਮ ਬੁਕਿੰਗ ਸਕ੍ਰੀਨ ਰਾਹੀਂ ਸਪੋਰਟ ਨਾਲ ਸੰਪਰਕ ਕਰੋ।';

  @override
  String get helpT1Q6 => 'ਕੰਮ ਦੀਆਂ ਰੇਟਿੰਗਾਂ ਦੀ ਗਣਨਾ ਕਿਵੇਂ ਹੁੰਦੀ ਹੈ?';

  @override
  String get helpT1A6 =>
      'ਤੁਹਾਡੀ ਸਮੁੱਚੀ ਰੇਟਿੰਗ ਕੰਮ ਪੂਰਾ ਹੋਣ \'ਤੇ ਗਾਹਕਾਂ ਵੱਲੋਂ ਦਿੱਤੀਆਂ ਰੇਟਿੰਗਾਂ ਦਾ ਔਸਤ ਹੈ। ਉੱਚੀਆਂ ਰੇਟਿੰਗਾਂ (4.5+) ਤੁਹਾਡੀ ਦਿੱਖ ਵਧਾਉਂਦੀਆਂ ਹਨ ਅਤੇ ਉੱਚ-ਮੁੱਲ ਕੰਮਾਂ ਤੱਕ ਜਲਦੀ ਪਹੁੰਚ ਦਿੰਦੀਆਂ ਹਨ।';

  @override
  String get helpT2Title => 'ਕਮਾਈ ਅਤੇ ਭੁਗਤਾਨ';

  @override
  String get helpT2Sub => 'ਪਲੇਟਫਾਰਮ ਫੀਸਾਂ, ਬੈਂਕ ਨਿਕਾਸੀਆਂ ਅਤੇ ਲੈਜਰ ਭੁਗਤਾਨ';

  @override
  String get helpT2Q1 => 'ਮੈਂ ਆਪਣੀ ਕਮਾਈ ਕਿਵੇਂ ਕਢਵਾਵਾਂ?';

  @override
  String get helpT2A1 =>
      'ਆਪਣੀ ਪ੍ਰੋਫਾਈਲ ਤੋਂ ਕਮਾਈ ਅਤੇ ਭੁਗਤਾਨ ਵਿੱਚ ਜਾਓ, ਕਢਵਾਓ \'ਤੇ ਟੈਪ ਕਰੋ, ਰਕਮ ਦਰਜ ਕਰੋ (ਘੱਟੋ-ਘੱਟ ₹100), ਅਤੇ ਰਕਮ ਤੁਰੰਤ ਤੁਹਾਡੇ ਡਿਫੌਲਟ ਭੁਗਤਾਨ ਟੀਚੇ ਵਿੱਚ ਟ੍ਰਾਂਸਫਰ ਹੋ ਜਾਂਦੀ ਹੈ।';

  @override
  String get helpT2Q2 => 'ਪਲੇਟਫਾਰਮ ਸੇਵਾ ਫੀਸ ਕੀ ਹੈ?';

  @override
  String get helpT2A2 =>
      'TaskTeddy ਬੀਮਾ, ਮਾਰਕੀਟਿੰਗ ਅਤੇ ਸੰਚਾਲਨ ਦੇ ਭੁਗਤਾਨ ਵਿੱਚ ਮਦਦ ਲਈ ਸਫਲ ਕੰਮ ਪੂਰਤੀਆਂ \'ਤੇ ਇੱਕਸਾਰ 15% ਪਲੇਟਫਾਰਮ ਸੇਵਾ ਫੀਸ ਲੈਂਦਾ ਹੈ।';

  @override
  String get helpT2Q3 => 'ਬੈਂਕ ਭੁਗਤਾਨ ਨਿਕਾਸੀ ਵਿੱਚ ਕਿੰਨਾ ਸਮਾਂ ਲੱਗਦਾ ਹੈ?';

  @override
  String get helpT2A3 =>
      'ਭੁਗਤਾਨ ਟ੍ਰਾਂਸਫਰ ਤੁਰੰਤ ਸ਼ੁਰੂ ਕੀਤੇ ਜਾਂਦੇ ਹਨ। ਤੁਹਾਡੇ ਬੈਂਕ ਦੀ IMPS ਪ੍ਰੋਸੈਸਿੰਗ ਗਤੀ ਦੇ ਆਧਾਰ \'ਤੇ, ਭੁਗਤਾਨ ਆਮ ਤੌਰ \'ਤੇ ਕੁਝ ਹੀ ਮਿੰਟਾਂ ਵਿੱਚ ਤੁਹਾਡੇ ਬੈਂਕ ਖਾਤੇ ਜਾਂ UPI ਵਿੱਚ ਦਿਖਦੇ ਹਨ।';

  @override
  String get helpT2Q4 => 'ਮੇਰਾ ਭੁਗਤਾਨ ਬਕਾਇਆ ਸਥਿਤੀ ਵਿੱਚ ਕਿਉਂ ਫਸਿਆ ਹੈ?';

  @override
  String get helpT2A4 =>
      'ਜੇ ਤੁਹਾਡਾ ਭੁਗਤਾਨ ਬਕਾਇਆ ਹੈ, ਤਾਂ ਇਹ ਆਮ ਤੌਰ \'ਤੇ ਬੈਂਕਿੰਗ ਨੈੱਟਵਰਕ ਦੇਰੀ ਜਾਂ ਤਸਦੀਕ ਜਾਂਚ ਕਾਰਨ ਹੁੰਦਾ ਹੈ। ਜ਼ਿਆਦਾਤਰ ਬਕਾਇਆ ਭੁਗਤਾਨ 2-4 ਘੰਟਿਆਂ ਵਿੱਚ ਆਪਣੇ ਆਪ ਹੱਲ ਹੋ ਜਾਂਦੇ ਹਨ। ਜੇ ਵੱਧ ਸਮਾਂ ਲੱਗੇ, ਤਾਂ Payout ID ਨਾਲ ਸੰਪਰਕ ਕਰੋ।';

  @override
  String get helpT2Q5 => 'ਕੀ ਮੈਂ ਆਪਣਾ ਡਿਫੌਲਟ ਭੁਗਤਾਨ ਬੈਂਕ ਖਾਤਾ ਬਦਲ ਸਕਦਾ ਹਾਂ?';

  @override
  String get helpT2A5 =>
      'ਹਾਂ, ਤੁਸੀਂ ਆਪਣੀ ਪ੍ਰੋਫਾਈਲ ਟੈਬ \'ਤੇ ਬੈਂਕ ਅਤੇ ਭੁਗਤਾਨ ਸਕ੍ਰੀਨ ਰਾਹੀਂ ਕਿਸੇ ਵੀ ਵੇਲੇ ਬੈਂਕ ਖਾਤੇ ਅਤੇ UPI ID ਸੋਧ ਜਾਂ ਸ਼ਾਮਲ ਕਰ ਸਕਦੇ ਹੋ। ਬਸ ਇੱਕ ਨਵਾਂ ਤਰੀਕਾ ਸ਼ਾਮਲ ਕਰੋ ਅਤੇ ਸਟਾਰ \'ਤੇ ਟੈਪ ਕਰੋ ਜਾਂ ਡਿਫੌਲਟ ਵਜੋਂ ਸੈੱਟ ਕਰੋ।';

  @override
  String get helpT3Title => 'ਤਸਦੀਕ ਅਤੇ ਪ੍ਰੋਫਾਈਲ';

  @override
  String get helpT3Sub => 'ਆਧਾਰ ਜਾਂਚਾਂ, ਪੈਨ ਤਸਦੀਕ ਅਤੇ ਪ੍ਰੋਫਾਈਲ ਫ਼ੋਟੋ ਸੈਟਿੰਗਾਂ';

  @override
  String get helpT3Q1 => 'ਦਸਤਾਵੇਜ਼ ਤਸਦੀਕ ਵਿੱਚ ਕਿੰਨਾ ਸਮਾਂ ਲੱਗਦਾ ਹੈ?';

  @override
  String get helpT3A1 =>
      'ਸਵੈਚਲਿਤ ਬੈਕਗ੍ਰਾਊਂਡ ਜਾਂਚਾਂ ਤੁਰੰਤ ਤਸਦੀਕ ਹੁੰਦੀਆਂ ਹਨ। ਮੈਨੂਅਲ ਸਮੀਖਿਆ ਵਾਲੇ ਮਾਮਲਿਆਂ ਵਿੱਚ, ਮਨਜ਼ੂਰੀ ਵਿੱਚ 24 ਘੰਟੇ ਤੱਕ ਲੱਗ ਸਕਦੇ ਹਨ। ਤੁਹਾਡਾ ਪ੍ਰਗਤੀ ਬਾਰ ਆਪਣੇ ਆਪ ਅੱਪਡੇਟ ਹੁੰਦਾ ਹੈ।';

  @override
  String get helpT3Q2 => 'ਕਿਹੜੇ ਪਤੇ ਦੇ ਸਬੂਤ ਸਵੀਕਾਰ ਹਨ?';

  @override
  String get helpT3A2 =>
      'ਅਸੀਂ 3 ਮਹੀਨਿਆਂ ਤੋਂ ਪੁਰਾਣੇ ਨਾ ਹੋਣ ਵਾਲੇ ਮਿਆਰੀ ਯੂਟਿਲਿਟੀ ਬਿੱਲ (ਬਿਜਲੀ, ਪਾਈਪਲਾਈਨ ਗੈਸ, ਜਾਂ ਪਾਣੀ ਦਾ ਬਿੱਲ), ਰਜਿਸਟਰਡ ਕਿਰਾਇਆ ਸਮਝੌਤੇ, ਜਾਂ ਤੁਹਾਡੇ ਨਾਮ ਦੇ ਸਰਕਾਰੀ ਸਰਟੀਫਿਕੇਟ ਸਵੀਕਾਰ ਕਰਦੇ ਹਾਂ।';

  @override
  String get helpT3Q3 => 'ਮੇਰਾ ਪੈਨ ਕਾਰਡ ਅਪਲੋਡ ਕਿਉਂ ਰੱਦ ਹੋਇਆ?';

  @override
  String get helpT3A3 =>
      'ਯਕੀਨੀ ਬਣਾਓ ਕਿ ਫ਼ੋਟੋ ਸਪੱਸ਼ਟ ਹੈ, ਸਾਰੇ ਕਿਨਾਰੇ ਦਿਖ ਰਹੇ ਹਨ, ਕੋਈ ਫ਼ਲੈਸ਼ ਪ੍ਰਤੀਬਿੰਬ ਨਹੀਂ ਹੈ, ਅਤੇ ਨਾਮ ਤੁਹਾਡੇ ਸਰਕਾਰੀ ID ਵੇਰਵਿਆਂ ਨਾਲ ਮੇਲ ਖਾਂਦਾ ਹੈ।';

  @override
  String get helpT3Q4 =>
      'ਤਸਦੀਕ ਤੋਂ ਬਾਅਦ ਮੈਂ ਆਪਣੇ ਪ੍ਰੋਫਾਈਲ ਵੇਰਵੇ ਕਿਵੇਂ ਅੱਪਡੇਟ ਕਰਾਂ?';

  @override
  String get helpT3A4 =>
      'ਇੱਕ ਵਾਰ ਤੁਹਾਡੀ ਪਛਾਣ ਤਸਦੀਕ ਹੋ ਜਾਣ \'ਤੇ, ਤੁਹਾਡੇ ਕਾਨੂੰਨੀ ਨਾਮ ਅਤੇ ਸਰਕਾਰੀ ID ਵਰਗੇ ਮੁੱਖ ਖਾਨੇ ਸਿੱਧੇ ਸੋਧੇ ਨਹੀਂ ਜਾ ਸਕਦੇ। ਆਪਣਾ ਰਜਿਸਟਰਡ ਫ਼ੋਨ ਨੰਬਰ ਬਦਲਣ ਜਾਂ ਨਾਮ ਦੀ ਗਲਤੀ ਠੀਕ ਕਰਨ ਲਈ, ਸਹਾਇਕ ਦਸਤਾਵੇਜ਼ਾਂ ਨਾਲ ਪਾਰਟਨਰ ਸਪੋਰਟ ਨਾਲ ਸੰਪਰਕ ਕਰੋ।';

  @override
  String get helpT3Q5 =>
      'ਜੇ ਮੇਰਾ ਦਸਤਾਵੇਜ਼ ਤਸਦੀਕ ਅਸਫਲ ਹੋਵੇ ਤਾਂ ਮੈਨੂੰ ਕੀ ਕਰਨਾ ਚਾਹੀਦਾ ਹੈ?';

  @override
  String get helpT3A5 =>
      'ਜੇ ਤੁਹਾਡਾ ਆਧਾਰ ਜਾਂ ਪੈਨ ਰੱਦ ਹੁੰਦਾ ਹੈ, ਤਾਂ ਤੁਹਾਨੂੰ ਕਾਰਨ ਦੱਸਦੀ ਇੱਕ ਸੂਚਨਾ ਮਿਲੇਗੀ। ਦੁਬਾਰਾ ਜਮ੍ਹਾਂ ਕਰਨ ਤੋਂ ਪਹਿਲਾਂ ਯਕੀਨੀ ਬਣਾਓ ਕਿ ਤੁਹਾਡਾ ਅਪਲੋਡ ਉੱਚ ਗੁਣਵੱਤਾ ਵਾਲਾ ਹੈ, ਧੁੰਦਲਾ ਨਹੀਂ ਹੈ, ਅਤੇ ਤੁਹਾਡੇ ਰਜਿਸਟਰਡ ਪ੍ਰੋਫਾਈਲ ਨਾਮ ਨਾਲ ਮੇਲ ਖਾਂਦਾ ਹੈ।';

  @override
  String get helpT4Title => 'ਸੁਰੱਖਿਆ ਅਤੇ ਆਚਾਰ ਸੰਹਿਤਾ';

  @override
  String get helpT4Sub => 'ਐਮਰਜੈਂਸੀ ਸਹਾਇਤਾ, ਟਿਕਾਣਾ ਟਰੈਕਿੰਗ ਅਤੇ ਨਿਯਮ';

  @override
  String get helpT4Q1 => 'ਕੰਮ ਦੌਰਾਨ ਮੈਨੂੰ ਅਸੁਰੱਖਿਅਤ ਲੱਗੇ - ਮੈਂ ਕੀ ਕਰਾਂ?';

  @override
  String get helpT4A1 =>
      'ਸੁਰੱਖਿਆ ਸਾਡੀ ਸਭ ਤੋਂ ਵੱਡੀ ਤਰਜੀਹ ਹੈ। ਤੁਰੰਤ ਉਸ ਟਿਕਾਣੇ ਨੂੰ ਛੱਡ ਕੇ ਕਿਸੇ ਜਨਤਕ ਥਾਂ \'ਤੇ ਜਾਓ ਅਤੇ ਸਪੋਰਟ ਨੂੰ ਕਾਲ ਕਰੋ। ਕਿਸੇ ਵੀ ਐਮਰਜੈਂਸੀ ਵਿੱਚ, ਪਹਿਲਾਂ ਸਥਾਨਕ ਪੁਲਿਸ (100/112) ਨੂੰ ਡਾਇਲ ਕਰੋ।';

  @override
  String get helpT4Q2 => 'ਕੀ ਮੈਂ ਗਾਹਕਾਂ ਤੋਂ ਸਿੱਧੇ ਭੁਗਤਾਨ ਸਵੀਕਾਰ ਕਰ ਸਕਦਾ ਹਾਂ?';

  @override
  String get helpT4A2 =>
      'ਨਹੀਂ। ਗਾਹਕਾਂ ਤੋਂ ਆਫਲਾਈਨ ਜਾਂ ਸਿੱਧੇ ਕੈਸ਼/UPI ਟ੍ਰਾਂਸਫਰ ਮੰਗਣਾ ਪਾਰਟਨਰ ਦਿਸ਼ਾ-ਨਿਰਦੇਸ਼ਾਂ ਦੀ ਉਲੰਘਣਾ ਹੈ ਅਤੇ ਇਸ ਨਾਲ ਤੁਹਾਡੇ TaskTeddy ਖਾਤੇ ਦਾ ਪੱਕਾ ਮੁਅੱਤਲੀ ਹੁੰਦੀ ਹੈ।';

  @override
  String get helpT4Q3 =>
      'ਜੇ ਟਿਕਾਣੇ \'ਤੇ ਕੰਮ ਦਾ ਦਾਇਰਾ ਬਦਲ ਜਾਵੇ ਤਾਂ ਮੈਨੂੰ ਕੀ ਕਰਨਾ ਚਾਹੀਦਾ ਹੈ?';

  @override
  String get helpT4A3 =>
      'ਜੇ ਕੋਈ ਗਾਹਕ ਤੁਹਾਨੂੰ ਮੂਲ ਕੰਮ ਵੇਰਵੇ ਵਿੱਚ ਨਾ ਦੱਸਿਆ ਵਾਧੂ ਕੰਮ ਕਰਨ ਲਈ ਕਹੇ, ਤਾਂ ਨਿਮਰਤਾ ਨਾਲ ਉਨ੍ਹਾਂ ਨੂੰ ਐਪ ਵਿੱਚ ਕੰਮ ਅੱਪਡੇਟ ਕਰਨ ਜਾਂ ਮਿਆਰੀ ਦਰਾਂ ਦਾ ਭੁਗਤਾਨ ਕਰਨ ਲਈ ਕਹੋ। ਸਪੋਰਟ ਨੂੰ ਸੂਚਿਤ ਕੀਤੇ ਬਿਨਾਂ ਆਫਲਾਈਨ ਭੁਗਤਾਨ ਸਮਾਯੋਜਨ ਸਵੀਕਾਰ ਨਾ ਕਰੋ।';

  @override
  String get helpT4Q4 => 'ਸਰਗਰਮ ਕੰਮਾਂ ਦੌਰਾਨ ਮੇਰਾ ਟਿਕਾਣਾ ਕਿਵੇਂ ਟਰੈਕ ਹੁੰਦਾ ਹੈ?';

  @override
  String get helpT4A4 =>
      'ਅਸੀਂ ਤੁਹਾਡਾ ਟਿਕਾਣਾ ਬੈਕਗ੍ਰਾਊਂਡ ਵਿੱਚ ਸਿਰਫ਼ ਉਦੋਂ ਟਰੈਕ ਕਰਦੇ ਹਾਂ ਜਦੋਂ ਤੁਸੀਂ ਕਿਸੇ ਕੰਮ ਵੱਲ ਸਫ਼ਰ ਕਰ ਰਹੇ ਹੋ ਜਾਂ ਸਰਗਰਮੀ ਨਾਲ ਕੋਈ ਸੇਵਾ ਪੂਰੀ ਕਰ ਰਹੇ ਹੋ, ਤਾਂ ਜੋ ਪਾਰਟਨਰ ਸੁਰੱਖਿਆ ਯਕੀਨੀ ਹੋਵੇ ਅਤੇ ਗਾਹਕਾਂ ਨੂੰ ਲਾਈਵ ETA ਮਿਲੇ।';

  @override
  String get setWeeklyHours => 'ਹਫ਼ਤਾਵਾਰੀ ਘੰਟੇ';

  @override
  String get setNotifications => 'ਸੂਚਨਾਵਾਂ';

  @override
  String get setPushNotif => 'ਪੁਸ਼ ਸੂਚਨਾਵਾਂ';

  @override
  String get setPushNotifSub => 'ਕੰਮ ਅਲਰਟ ਅਤੇ ਅੱਪਡੇਟ ਪ੍ਰਾਪਤ ਕਰੋ';

  @override
  String get setEmailNotif => 'ਈਮੇਲ ਸੂਚਨਾਵਾਂ';

  @override
  String get setEmailNotifSub => 'ਹਫ਼ਤਾਵਾਰੀ ਸਾਰ ਅਤੇ ਪ੍ਰਚਾਰ';

  @override
  String get setSmsNotif => 'SMS ਸੂਚਨਾਵਾਂ';

  @override
  String get setSmsNotifSub => 'ਸਿਰਫ਼ OTP ਅਤੇ ਜ਼ਰੂਰੀ ਅਲਰਟ';

  @override
  String get setAppearance => 'ਦਿੱਖ';

  @override
  String get setDarkMode => 'ਡਾਰਕ ਮੋਡ';

  @override
  String get setComingSoon => 'ਜਲਦੀ ਆ ਰਿਹਾ ਹੈ';

  @override
  String get setDataStorage => 'ਡਾਟਾ ਅਤੇ ਸਟੋਰੇਜ';

  @override
  String get setClearCache => 'ਕੈਸ਼ ਸਾਫ਼ ਕਰੋ';

  @override
  String get setCacheCleared => 'ਕੈਸ਼ ਸਾਫ਼ ਹੋਇਆ';

  @override
  String get setDownloadData => 'ਮੇਰਾ ਡਾਟਾ ਡਾਊਨਲੋਡ ਕਰੋ';

  @override
  String get setDataExportEmailed => 'ਡਾਟਾ ਨਿਰਯਾਤ ਤੁਹਾਨੂੰ ਈਮੇਲ ਕੀਤਾ ਜਾਵੇਗਾ';

  @override
  String get setDangerZone => 'ਖ਼ਤਰਨਾਕ ਖੇਤਰ';

  @override
  String get setDeleteAccount => 'ਖਾਤਾ ਹਟਾਓ';

  @override
  String get setDeleteAccountTitle => 'ਖਾਤਾ ਹਟਾਓ?';

  @override
  String get setDeleteAccountBody =>
      'ਇਹ ਕਾਰਵਾਈ ਨਾ-ਵਾਪਸੀਯੋਗ ਹੈ। ਤੁਹਾਡਾ ਸਾਰਾ ਡਾਟਾ, ਕਮਾਈ ਅਤੇ ਸਮੀਖਿਆਵਾਂ ਪੱਕੇ ਤੌਰ \'ਤੇ ਹਟਾ ਦਿੱਤੀਆਂ ਜਾਣਗੀਆਂ।';

  @override
  String get setDelete => 'ਹਟਾਓ';

  @override
  String get setDeletionSubmitted => 'ਖਾਤਾ ਹਟਾਉਣ ਦੀ ਬੇਨਤੀ ਜਮ੍ਹਾਂ ਕੀਤੀ ਗਈ';

  @override
  String get reportThisUser => 'ਇਸ ਉਪਭੋਗਤਾ';

  @override
  String reportUserTitle(String name) {
    return '$name ਦੀ ਰਿਪੋਰਟ ਕਰੋ';
  }

  @override
  String get reportChooseReason => 'ਇੱਕ ਕਾਰਨ ਚੁਣੋ। ਰਿਪੋਰਟਾਂ ਗੁਪਤ ਹਨ।';

  @override
  String get reportDetailsOptional => 'ਵੇਰਵੇ (ਵਿਕਲਪਿਕ)';

  @override
  String get reportDetailHint =>
      'ਜੋ ਹੋਇਆ ਉਸ ਨੂੰ ਸਮਝਣ ਵਿੱਚ ਮਦਦ ਕਰਨ ਵਾਲੀ ਕੋਈ ਵੀ ਗੱਲ ਸ਼ਾਮਲ ਕਰੋ…';

  @override
  String get reportSubmit => 'ਰਿਪੋਰਟ ਜਮ੍ਹਾਂ ਕਰੋ';

  @override
  String get reportSubmitted =>
      'ਰਿਪੋਰਟ ਜਮ੍ਹਾਂ ਹੋਈ। ਸਾਡੀ ਟੀਮ ਇਸ ਦੀ ਸਮੀਖਿਆ ਕਰੇਗੀ।';

  @override
  String get reportReasonInappropriate => 'ਗਲਤ ਵਿਵਹਾਰ';

  @override
  String get reportReasonNoShow => 'ਨਹੀਂ ਆਇਆ';

  @override
  String get reportReasonSafety => 'ਸੁਰੱਖਿਆ ਚਿੰਤਾ';

  @override
  String get reportReasonFraud => 'ਧੋਖਾਧੜੀ ਜਾਂ ਘੁਟਾਲਾ';

  @override
  String get reportReasonPoorQuality => 'ਮਾੜੀ ਗੁਣਵੱਤਾ';

  @override
  String get reportReasonSpam => 'ਸਪੈਮ';

  @override
  String get reportReasonOther => 'ਹੋਰ';

  @override
  String blockConfirmTitle(String name) {
    return '$name ਨੂੰ ਬਲੌਕ ਕਰੋ?';
  }

  @override
  String get blockConfirmBody =>
      'ਉਹ ਹੁਣ ਤੁਹਾਨੂੰ ਸੁਨੇਹਾ ਨਹੀਂ ਭੇਜ ਸਕਣਗੇ ਜਾਂ ਤੁਹਾਡੇ ਕੰਮਾਂ ਨਾਲ ਮੇਲ ਨਹੀਂ ਖਾ ਸਕਣਗੇ। ਤੁਸੀਂ ਉਨ੍ਹਾਂ ਨੂੰ ਸੈਟਿੰਗਾਂ ਤੋਂ ਕਿਸੇ ਵੀ ਵੇਲੇ ਅਨਬਲੌਕ ਕਰ ਸਕਦੇ ਹੋ।';

  @override
  String blockedSuccess(String name) {
    return '$name ਨੂੰ ਬਲੌਕ ਕਰ ਦਿੱਤਾ ਗਿਆ';
  }

  @override
  String get blockedUserFallback => 'ਉਪਭੋਗਤਾ';

  @override
  String get unblockAction => 'ਅਨਬਲੌਕ ਕਰੋ';

  @override
  String unblockedSuccess(String name) {
    return '$name ਅਨਬਲੌਕ ਹੋਇਆ';
  }

  @override
  String get blockedEmptyBody => 'ਤੁਹਾਡੇ ਵੱਲੋਂ ਬਲੌਕ ਕੀਤੇ ਲੋਕ ਇੱਥੇ ਦਿਖਣਗੇ।';

  @override
  String loginSendingOtp(String phone) {
    return '$phone \'ਤੇ OTP ਭੇਜਿਆ ਜਾ ਰਿਹਾ ਹੈ';
  }

  @override
  String loginOtpSent(String phone) {
    return '$phone \'ਤੇ OTP ਭੇਜਿਆ ਗਿਆ';
  }

  @override
  String get loginEnterOtpSent => 'ਆਪਣੇ ਨੰਬਰ \'ਤੇ ਭੇਜਿਆ OTP ਦਰਜ ਕਰੋ';

  @override
  String get loginErrConnect =>
      'ਕਨੈਕਟ ਨਹੀਂ ਹੋ ਸਕਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਇੰਟਰਨੈੱਟ ਜਾਂਚੋ ਅਤੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get loginErrServer =>
      'ਸਰਵਰ ਤੱਕ ਨਹੀਂ ਪਹੁੰਚ ਸਕੇ। ਕਿਰਪਾ ਕਰਕੇ ਬਾਅਦ ਵਿੱਚ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get loginErrInvalidOtp =>
      'ਅਵੈਧ OTP। ਕਿਰਪਾ ਕਰਕੇ ਜਾਂਚੋ ਅਤੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get loginErrExpiredOtp =>
      'OTP ਮਿਆਦ ਪੁੱਗ ਗਈ। ਕਿਰਪਾ ਕਰਕੇ ਨਵਾਂ ਬੇਨਤੀ ਕਰੋ।';

  @override
  String get loginErrTooMany =>
      'ਬਹੁਤ ਜ਼ਿਆਦਾ ਕੋਸ਼ਿਸ਼ਾਂ। ਕਿਰਪਾ ਕਰਕੇ ਥੋੜ੍ਹੀ ਦੇਰ ਰੁਕੋ ਅਤੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get loginErrGeneric =>
      'ਕੁਝ ਗਲਤ ਹੋ ਗਿਆ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get loginTermsPrefix => 'ਜਾਰੀ ਰੱਖੋ \'ਤੇ ਕਲਿੱਕ ਕਰਕੇ, ਤੁਸੀਂ ਸਾਡੀਆਂ ';

  @override
  String get loginAnd => ' ਅਤੇ ';

  @override
  String get loginTermsSuffix => ' ਸਵੀਕਾਰ ਕਰਦੇ ਹੋ।';

  @override
  String get dashLoading => 'ਤੁਹਾਡਾ ਡੈਸ਼ਬੋਰਡ ਲੋਡ ਹੋ ਰਿਹਾ ਹੈ…';

  @override
  String get dashLocationPicker => 'ਲੋਕੇਸ਼ਨ ਪਿਕਰ ਖੁੱਲ੍ਹਿਆ...';

  @override
  String dashAssigned(int count) {
    return '$count ਸੌਂਪੇ ਗਏ';
  }

  @override
  String dashAvailable(int count) {
    return '$count ਉਪਲਬਧ';
  }

  @override
  String dashOngoing(int count) {
    return '$count ਚੱਲ ਰਹੇ';
  }

  @override
  String get dashUseAppliedTab => 'ਹੇਠਾਂ ਨੈਵੀਗੇਸ਼ਨ ਵਿੱਚ ਅਰਜ਼ੀਆਂ ਟੈਬ ਵਰਤੋ';

  @override
  String get dashCheckBackSoon =>
      'ਜਲਦੀ ਫਿਰ ਵੇਖੋ — ਨਵੇਂ ਕੰਮ ਰੋਜ਼ ਪੋਸਟ ਹੁੰਦੇ ਹਨ!';

  @override
  String get dashBrowseStartEarning => 'ਉਪਲਬਧ ਕੰਮ ਵੇਖੋ ਅਤੇ ਕਮਾਈ ਸ਼ੁਰੂ ਕਰੋ!';

  @override
  String get dashSpecialOffer => 'ਖਾਸ ਪੇਸ਼ਕਸ਼!';

  @override
  String get dashBonusRewards => 'ਬੋਨਸ ਇਨਾਮ ਕਮਾਉਣ ਲਈ ਕੰਮ ਪੂਰੇ ਕਰੋ';

  @override
  String get dashCompleteBooking => 'ਬੁਕਿੰਗ ਪੂਰੀ ਕਰੋ';

  @override
  String dashBookingOtpPrompt(String service) {
    return '\"$service\" ਲਈ ਗਾਹਕ ਤੋਂ ਪੂਰਤੀ OTP ਮੰਗੋ ਅਤੇ ਇਸ ਨੂੰ ਹੇਠਾਂ ਦਰਜ ਕਰੋ।';
  }

  @override
  String get dashComplete => 'ਪੂਰਾ ਕਰੋ';

  @override
  String get dashBookingComplete => 'ਬੁਕਿੰਗ ਪੂਰੀ ਵਜੋਂ ਨਿਸ਼ਾਨਬੱਧ!';

  @override
  String get dashThisBooking => 'ਇਸ ਬੁਕਿੰਗ';

  @override
  String get dashMarkComplete => 'ਪੂਰਾ ਨਿਸ਼ਾਨਬੱਧ ਕਰੋ';

  @override
  String get dashScheduled => 'ਨਿਰਧਾਰਿਤ';

  @override
  String get dashServiceFallback => 'ਸੇਵਾ';

  @override
  String get dashCustomerFallback => 'ਗਾਹਕ';

  @override
  String get dashOverdue => 'ਸਮਾਂ ਬੀਤਿਆ';

  @override
  String dashMinLeft(int count) {
    return '$count ਮਿੰਟ ਬਾਕੀ';
  }

  @override
  String dashHrLeft(int count) {
    return '$count ਘੰਟੇ ਬਾਕੀ';
  }

  @override
  String dashDayLeft(int count) {
    return '$count ਦਿਨ ਬਾਕੀ';
  }

  @override
  String dashApplied(int count) {
    return '$count ਨੇ ਅਰਜ਼ੀ ਦਿੱਤੀ';
  }

  @override
  String get dashStatusPending => 'ਬਕਾਇਆ';

  @override
  String get dashStatusConfirmed => 'ਪੁਸ਼ਟੀ ਹੋਈ';

  @override
  String get dashStatusCompleted => 'ਪੂਰਾ';

  @override
  String get dashStatusCancelled => 'ਰੱਦ';

  @override
  String get dashTip1 => 'ਗੋਲਡ ਸਥਿਤੀ ਤੱਕ ਪਹੁੰਚਣ ਲਈ ਇਸ ਹਫ਼ਤੇ 3 ਹੋਰ ਕੰਮ ਪੂਰੇ ਕਰੋ';

  @override
  String get dashTip2 => 'ਤੇਜ਼ ਜਵਾਬ ਵਾਲੇ ਕੰਮਾਂ ਨੂੰ 2x ਵੱਧ ਬੁਕਿੰਗਾਂ ਮਿਲਦੀਆਂ ਹਨ';

  @override
  String get dashTip3 => 'ਤਰਜੀਹੀ ਸੂਚੀ ਲਈ ਆਪਣੀ ਪ੍ਰੋਫਾਈਲ 100% ਪੂਰੀ ਰੱਖੋ';

  @override
  String get dashTip4 =>
      'ਪ੍ਰੀਮੀਅਮ ਕੰਮ ਪਹੁੰਚ ਅਨਲੌਕ ਕਰਨ ਲਈ 4.8+ ਰੇਟਿੰਗ ਬਣਾਈ ਰੱਖੋ';

  @override
  String get dashTip5 => 'ਆਪਣੇ ਖੇਤਰ ਵਿੱਚ ਬਿਹਤਰ ਕੰਮ ਮੇਲ ਲਈ ਲੋਕੇਸ਼ਨ ਯੋਗ ਕਰੋ';

  @override
  String get browseNotNow => 'ਹੁਣੇ ਨਹੀਂ';

  @override
  String get browseTaskCompleted => 'ਕੰਮ ਪੂਰਾ ਹੋਇਆ';

  @override
  String browseCollectedCash(String amount) {
    return 'ਤੁਸੀਂ ਗਾਹਕ ਤੋਂ ₹$amount ਨਕਦ ਇਕੱਠੇ ਕੀਤੇ।';
  }

  @override
  String get browseCashCollected => 'ਨਕਦ ਇਕੱਠਾ ਕੀਤਾ';

  @override
  String browsePlatformFeeMethod(String method) {
    return 'ਪਲੇਟਫਾਰਮ ਫੀਸ ($method)';
  }

  @override
  String get browseNetEarning => 'ਸ਼ੁੱਧ ਕਮਾਈ';

  @override
  String browseFeeDeducted(String amount) {
    return '₹$amount ਪਲੇਟਫਾਰਮ ਫੀਸ ਤੁਹਾਡੇ ਵਾਲਿਟ ਤੋਂ ਕੱਟੀ ਗਈ। ਬਕਾਏ ਤੋਂ ਬਚਣ ਲਈ ਆਪਣਾ ਵਾਲਿਟ ਟਾਪ-ਅੱਪ ਰੱਖੋ।';
  }

  @override
  String get browseDone => 'ਹੋ ਗਿਆ';

  @override
  String get browseLeadDismissed => 'ਲੀਡ ਹਟਾਈ ਗਈ';

  @override
  String get browseUndo => 'ਵਾਪਸ ਕਰੋ';

  @override
  String get browseGpsPinging => 'GPS ਸੈਟੇਲਾਈਟ ਨੂੰ ਪਿੰਗ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ...';

  @override
  String get browseGpsResolving => 'ਕੋਆਰਡੀਨੇਟ ਹੱਲ ਕੀਤੇ ਜਾ ਰਹੇ ਹਨ...';

  @override
  String get browseGpsFetching => 'ਨੇੜਲੇ ਕੰਮ ਲਿਆਏ ਜਾ ਰਹੇ ਹਨ...';

  @override
  String browseLocationDetected(String city) {
    return 'ਲੋਕੇਸ਼ਨ $city \'ਤੇ ਆਪਣੇ ਆਪ ਪਛਾਣੀ ਗਈ! ਨੇੜਲੇ ਕੰਮ ਲੋਡ ਹੋਏ।';
  }

  @override
  String get browseSelectLocation => 'ਟਿਕਾਣਾ ਚੁਣੋ';

  @override
  String get browseSelectLocationSub =>
      'ਆਪਣੇ ਪਸੰਦੀਦਾ ਸ਼ਹਿਰ ਵਿੱਚ ਨੇੜਲੇ ਖੁੱਲ੍ਹੇ ਕੰਮ ਵੇਖੋ';

  @override
  String get browseAutoDetect => 'ਮੇਰੀ ਲੋਕੇਸ਼ਨ ਆਪਣੇ ਆਪ ਪਛਾਣੋ';

  @override
  String get browseAccessingGps => 'ਉੱਚ-ਸ਼ੁੱਧ GPS ਕੋਆਰਡੀਨੇਟ ਐਕਸੈਸ ਹੋ ਰਹੇ ਹਨ';

  @override
  String get browseSimulateGps => 'ਉੱਚ-ਸ਼ੁੱਧ GPS ਜਾਂਚ ਦਾ ਨਕਲ';

  @override
  String get browsePopularCities => 'ਪ੍ਰਸਿੱਧ ਸ਼ਹਿਰ';

  @override
  String browseBrowsingNearest(String city) {
    return '$city ਦੇ ਸਭ ਤੋਂ ਨੇੜਲੇ ਕੰਮ ਵੇਖੇ ਜਾ ਰਹੇ ਹਨ।';
  }

  @override
  String get browseReset => 'ਰੀਸੈੱਟ';

  @override
  String get browsePresetAll => 'ਸਾਰੇ';

  @override
  String get browsePresetUnder500 => '₹500 ਤੋਂ ਘੱਟ';

  @override
  String get browsePreset500to2000 => '₹500-₹2000';

  @override
  String get browsePresetAbove2000 => '₹2000 ਤੋਂ ਵੱਧ';

  @override
  String get browseMinBudget => 'ਘੱਟੋ-ਘੱਟ ਬਜਟ (₹)';

  @override
  String get browseMaxBudget => 'ਵੱਧ ਤੋਂ ਵੱਧ ਬਜਟ (₹)';

  @override
  String get browseHintAny => 'ਕੋਈ ਵੀ';

  @override
  String get browseFailedLoad => 'ਕੰਮ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਫਲ';

  @override
  String get browseRefresh => 'ਰਿਫਰੈਸ਼ ਕਰੋ';

  @override
  String get browseCatAll => 'ਸਾਰੇ';

  @override
  String browseOpenTasks(int count) {
    return '$count ਖੁੱਲ੍ਹੇ ਕੰਮ';
  }

  @override
  String browseSortLabel(String label) {
    return 'ਕ੍ਰਮ: $label';
  }

  @override
  String get browseSortLatest => 'ਨਵੀਨਤਮ';

  @override
  String get browseSortBudget => 'ਬਜਟ';

  @override
  String get browseSortDeadline => 'ਸਮਾਂ-ਸੀਮਾ';

  @override
  String get browseSortLeastBids => 'ਘੱਟ ਬੋਲੀਆਂ';

  @override
  String browsePosted(String ago) {
    return '$ago ਪੋਸਟ ਕੀਤਾ';
  }

  @override
  String get browseJustNow => 'ਹੁਣੇ';

  @override
  String browsePostedBy(String name) {
    return '$name ਵੱਲੋਂ ਪੋਸਟ ਕੀਤਾ';
  }

  @override
  String get browseBudgetSmall => 'ਬਜਟ';

  @override
  String get browseUrgent => 'ਜ਼ਰੂਰੀ';

  @override
  String get browseDueToday => '· ਅੱਜ ਦੇਣਯੋਗ!';

  @override
  String get browseDueTomorrow => '· ਕੱਲ੍ਹ ਦੇਣਯੋਗ';

  @override
  String browseDueInDays(int days) {
    return '· $days ਦਿਨਾਂ ਵਿੱਚ ਦੇਣਯੋਗ';
  }

  @override
  String browseDue(String date) {
    return 'ਦੇਣਯੋਗ $date';
  }

  @override
  String browseBids(int count) {
    return '$count ਬੋਲੀਆਂ';
  }

  @override
  String get browseDismiss => 'ਹਟਾਓ';

  @override
  String browseBidLower(String amount) {
    return 'ਤੁਹਾਡੀ ਬੋਲੀ ₹$amount ਘੱਟ ਹੈ — ਬਿਹਤਰ ਮੌਕਾ!';
  }

  @override
  String get browseBidAbove => 'ਬਜਟ ਤੋਂ ਵੱਧ — ਆਪਣੇ ਕਵਰ ਲੈਟਰ ਵਿੱਚ ਮੁੱਲ ਸਮਝਾਓ';

  @override
  String get browseBidMatches => 'ਤੁਹਾਡੀ ਬੋਲੀ ਬਜਟ ਨਾਲ ਮੇਲ ਖਾਂਦੀ ਹੈ';

  @override
  String browseCompBelow(String pct) {
    return 'ਤੁਸੀਂ ਔਸਤ ਬੋਲੀਆਂ ਤੋਂ $pct% ਘੱਟ ਹੋ';
  }

  @override
  String browseCompAbove(String pct) {
    return 'ਤੁਸੀਂ ਔਸਤ ਬੋਲੀਆਂ ਤੋਂ $pct% ਵੱਧ ਹੋ';
  }

  @override
  String get browseCompMatches => 'ਤੁਹਾਡੀ ਬੋਲੀ ਔਸਤ ਨਾਲ ਮੇਲ ਖਾਂਦੀ ਹੈ';

  @override
  String get browseYourBidAmount => 'ਤੁਹਾਡੀ ਬੋਲੀ ਰਕਮ (₹)';

  @override
  String get browseCompetitiveAnalysis => 'ਮੁਕਾਬਲੇਬਾਜ਼ ਵਿਸ਼ਲੇਸ਼ਣ';

  @override
  String get browseAvgBid => 'ਔਸਤ ਬੋਲੀ';

  @override
  String get browseEstTakeHome => 'ਅਨੁਮਾਨਿਤ ਸ਼ੁੱਧ ਰਕਮ';

  @override
  String get browseAfterFee => '10% ਪਲੇਟਫਾਰਮ ਫੀਸ ਤੋਂ ਬਾਅਦ';

  @override
  String get browseCoverLetter => 'ਕਵਰ ਲੈਟਰ *';

  @override
  String get browseCoverLetterOptional => 'ਕਵਰ ਲੈਟਰ (ਵਿਕਲਪਿਕ)';

  @override
  String get browseCoverHint =>
      'ਆਪਣਾ ਪਰਿਚੈ ਦਿਓ। ਤੁਸੀਂ ਸਭ ਤੋਂ ਢੁਕਵੇਂ ਕਿਉਂ ਹੋ? ਆਪਣਾ ਤਜਰਬਾ ਅਤੇ ਉਪਲਬਧਤਾ ਦੱਸੋ...';

  @override
  String get browseCoverTip => 'ਵਧੀਆ ਕਵਰ ਲੈਟਰ ਚੋਣ ਦੀ ਸੰਭਾਵਨਾ 70% ਵਧਾਉਂਦੇ ਹਨ';

  @override
  String get browseFeeNote =>
      'TaskTeddy ਸਿਰਫ਼ ਕੰਮ ਪੂਰਾ ਹੋਣ \'ਤੇ 10% ਪਲੇਟਫਾਰਮ ਫੀਸ ਲੈਂਦਾ ਹੈ।';

  @override
  String get browseSubmitApplication => 'ਅਰਜ਼ੀ ਜਮ੍ਹਾਂ ਕਰੋ';

  @override
  String get browseTaskRefMissing => 'ਕੰਮ ਹਵਾਲਾ ਗੁੰਮ';

  @override
  String get browseCustomerNotifiedSharing =>
      'ਗਾਹਕ ਨੂੰ ਸੂਚਿਤ ਕੀਤਾ ਗਿਆ। ਤੁਹਾਡੀ ਲੋਕੇਸ਼ਨ ਸਾਂਝੀ ਹੋ ਰਹੀ ਹੈ।';

  @override
  String get browseBackedOut => 'ਤੁਸੀਂ ਪਿੱਛੇ ਹਟ ਗਏ। ਕੰਮ ਫਿਰ ਖੁੱਲ੍ਹਾ ਹੈ।';

  @override
  String get browseInvalidOtp => 'ਅਵੈਧ OTP';

  @override
  String get browseActiveTask => 'ਸਰਗਰਮ ਕੰਮ';

  @override
  String browseYouEarnAmt(String amount) {
    return 'ਤੁਹਾਡੀ ਕਮਾਈ: ₹$amount';
  }

  @override
  String get browseFailedOpenChat => 'ਚੈਟ ਨਹੀਂ ਖੋਲ੍ਹ ਸਕੇ';

  @override
  String get browseChat => 'ਚੈਟ';

  @override
  String browseRatingLabel(String rating) {
    return '$rating ਰੇਟਿੰਗ';
  }

  @override
  String get browseHeadingToCustomer => 'ਗਾਹਕ ਵੱਲ ਜਾ ਰਹੇ ਹਾਂ';

  @override
  String get browseOtwActiveBody =>
      'ਗਾਹਕ ਨੂੰ ਸੂਚਿਤ ਕੀਤਾ ਗਿਆ। ਜਦੋਂ ਤੱਕ ਇਹ ਸਕ੍ਰੀਨ ਖੁੱਲ੍ਹੀ ਹੈ, ਤੁਹਾਡੀ ਲਾਈਵ ਲੋਕੇਸ਼ਨ ਸਾਂਝੀ ਹੋ ਰਹੀ ਹੈ।';

  @override
  String get browseOtwIdleBody =>
      'ਗਾਹਕ ਨੂੰ ਦੱਸੋ ਕਿ ਤੁਸੀਂ ਰਸਤੇ ਵਿੱਚ ਹੋ। ਅਸੀਂ ਤੁਹਾਡੀ ਲਾਈਵ ਲੋਕੇਸ਼ਨ ਸਾਂਝੀ ਕਰਾਂਗੇ ਤਾਂ ਜੋ ਉਹ ਤੁਹਾਡੀ ਪਹੁੰਚ ਨੂੰ ਟਰੈਕ ਕਰ ਸਕਣ।';

  @override
  String get browseCustomerNotified => 'ਗਾਹਕ ਨੂੰ ਸੂਚਿਤ ਕੀਤਾ ਗਿਆ';

  @override
  String get browseNotifying => 'ਸੂਚਿਤ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ...';

  @override
  String get browseCancelling => 'ਰੱਦ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ...';

  @override
  String get browseCancelJob => 'ਕੰਮ ਰੱਦ ਕਰੋ';

  @override
  String get browseEnterCompletionOtp => 'ਪੂਰਤੀ OTP ਦਰਜ ਕਰੋ';

  @override
  String get browseOtpPrompt =>
      'ਕੰਮ ਪੂਰਾ ਕਰਨ ਅਤੇ ਭੁਗਤਾਨ ਲੈਣ ਲਈ ਗਾਹਕ ਦੀ ਸਕ੍ਰੀਨ ਤੇ ਦਿਖ ਰਿਹਾ OTP ਮੰਗੋ।';

  @override
  String get browseVerifyComplete => 'ਤਸਦੀਕ ਕਰੋ ਅਤੇ ਕੰਮ ਪੂਰਾ ਕਰੋ';

  @override
  String get browseReasonEmergency => 'ਐਮਰਜੈਂਸੀ';

  @override
  String get browseReasonTooFar => 'ਬਹੁਤ ਦੂਰ';

  @override
  String get browseReasonSchedule => 'ਸਮਾਂ-ਸਾਰਣੀ ਟਕਰਾਅ';

  @override
  String get browseReasonOther => 'ਹੋਰ';

  @override
  String get browseBackOutTitle => 'ਇਸ ਕੰਮ ਤੋਂ ਪਿੱਛੇ ਹਟੋ?';

  @override
  String get browseBackOutWarning =>
      'ਇਸ ਨਾਲ ਕੰਮ ਹੋਰ ਟਾਸਕਰਾਂ ਲਈ ਫਿਰ ਖੁੱਲ੍ਹ ਜਾਂਦਾ ਹੈ। ਵਾਰ-ਵਾਰ ਰੱਦ ਕਰਨਾ ਤੁਹਾਡੇ ਭਰੋਸੇਯੋਗਤਾ ਸਕੋਰ ਨੂੰ ਨੁਕਸਾਨ ਪਹੁੰਚਾਉਂਦਾ ਹੈ।';

  @override
  String get browseReason => 'ਕਾਰਨ';

  @override
  String get browseAddNote => 'ਇੱਕ ਨੋਟ ਸ਼ਾਮਲ ਕਰੋ (ਵਿਕਲਪਿਕ)';

  @override
  String get browseKeepJob => 'ਕੰਮ ਰੱਖੋ';

  @override
  String get browseThanksRating => 'ਗਾਹਕ ਨੂੰ ਰੇਟਿੰਗ ਦੇਣ ਲਈ ਧੰਨਵਾਦ।';

  @override
  String browseRateCustomer(String name) {
    return '$name ਨੂੰ ਰੇਟ ਕਰੋ';
  }

  @override
  String get browseRateExperience =>
      'ਇਸ ਗਾਹਕ ਨਾਲ ਕੰਮ ਕਰਨ ਦਾ ਤੁਹਾਡਾ ਤਜਰਬਾ ਕਿਵੇਂ ਰਿਹਾ?';

  @override
  String get browseAddComment => 'ਇੱਕ ਟਿੱਪਣੀ ਸ਼ਾਮਲ ਕਰੋ (ਵਿਕਲਪਿਕ)';

  @override
  String get browseSubmitRating => 'ਰੇਟਿੰਗ ਜਮ੍ਹਾਂ ਕਰੋ';

  @override
  String get browseAppSubmitted => 'ਅਰਜ਼ੀ ਜਮ੍ਹਾਂ ਹੋਈ!';

  @override
  String browseAppSubmittedBody(String title) {
    return '\"$title\"\nਗਾਹਕ ਸਮੀਖਿਆ ਕਰਕੇ ਸਭ ਤੋਂ ਵਧੀਆ ਬੋਲੀ ਸਵੀਕਾਰ ਕਰੇਗਾ।';
  }

  @override
  String get browseAppSubmittedNote =>
      'ਸਵੀਕਾਰ ਹੋਣ \'ਤੇ ਤੁਹਾਨੂੰ ਸੂਚਨਾ ਮਿਲੇਗੀ। ਹੋਰ ਕੰਮਾਂ ਲਈ ਅਰਜ਼ੀ ਦਿੰਦੇ ਰਹੋ!';

  @override
  String get browseViewMyApps => 'ਮੇਰੀਆਂ ਅਰਜ਼ੀਆਂ ਵੇਖੋ';

  @override
  String get browseBrowseMore => 'ਹੋਰ ਕੰਮ ਵੇਖੋ';

  @override
  String get browsePhotos => 'ਫ਼ੋਟੋ';

  @override
  String get reputationYourLevel => 'ਤੁਹਾਡਾ ਪੱਧਰ';

  @override
  String get reputationReliability => 'ਭਰੋਸੇਯੋਗਤਾ';

  @override
  String reputationJobsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ਕੰਮ ਪੂਰੇ',
      one: '1 ਕੰਮ ਪੂਰਾ',
    );
    return '$_temp0';
  }

  @override
  String reputationJobsToNext(int completed, int next, String tier) {
    return '$tier ਤੱਕ $completed/$next ਕੰਮ';
  }

  @override
  String get reputationTopLevel => 'ਸਿਖਰਲਾ ਪੱਧਰ';

  @override
  String get reputationExplainer =>
      'ਪੱਧਰ ਵਧਾਉਣ ਲਈ ਕੰਮ ਪੂਰੇ ਕਰੋ ਅਤੇ ਰੇਟਿੰਗ ਉੱਚੀ ਰੱਖੋ।';

  @override
  String get reputationLevelNew => 'ਨਵਾਂ';

  @override
  String get reputationLevelBronze => 'ਬ੍ਰੌਂਜ਼';

  @override
  String get reputationLevelSilver => 'ਸਿਲਵਰ';

  @override
  String get reputationLevelGold => 'ਗੋਲਡ';

  @override
  String get reputationLevelPro => 'ਪ੍ਰੋ';
}
