// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get walletDuesSettled => 'Dues settled — you can browse again.';

  @override
  String get browseDuesTitle => 'Browsing paused';

  @override
  String get browseDuesBody =>
      'You have unsettled platform fees from cash jobs. Settle your wallet to continue browsing tasks.';

  @override
  String browseDuesAmount(String amount) {
    return 'Dues: ₹$amount';
  }

  @override
  String get browseSettleNow => 'Settle now';

  @override
  String get appTagline => 'Find tasks & earn money on your schedule!';

  @override
  String get navHome => 'Home';

  @override
  String get navBrowse => 'Browse';

  @override
  String get navApplied => 'Applied';

  @override
  String get navEarnings => 'Earnings';

  @override
  String get navProfile => 'Profile';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get statusOnline => 'Online';

  @override
  String get statusOffline => 'Offline';

  @override
  String get dashAvailableForWork => 'Available for new tasks';

  @override
  String get dashTapToGoOnline => 'Tap to go online and receive tasks';

  @override
  String get dashStatReliability => 'Reliability';

  @override
  String get dashStatLevel => 'Level';

  @override
  String get dashLevelNew => 'New';

  @override
  String get earningsOverview => 'Earnings Overview';

  @override
  String get wallet => 'Wallet';

  @override
  String get today => 'Today';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get statRating => 'Rating';

  @override
  String get statTasks => 'Tasks';

  @override
  String get statRank => 'Rank';

  @override
  String get statCoins => 'Coins';

  @override
  String get qaBrowseTasks => 'Browse Tasks';

  @override
  String get qaApplications => 'Applications';

  @override
  String get qaCompleted => 'Completed';

  @override
  String get qaMessages => 'Messages';

  @override
  String get tasksNearYou => 'Tasks Near You';

  @override
  String get myActiveJobs => 'My Active Jobs';

  @override
  String get myBookings => 'My Bookings';

  @override
  String get seeAll => 'See all';

  @override
  String get noTasksAvailable => 'No tasks available right now';

  @override
  String get noActiveJobs => 'No active jobs';

  @override
  String get searchTasksHint => 'Search tasks, location...';

  @override
  String get filterTasks => 'Filter Tasks';

  @override
  String get budgetRange => 'Budget Range';

  @override
  String get applyFilters => 'Apply Filters';

  @override
  String get budget => 'Budget';

  @override
  String get quickApply => 'Quick Apply';

  @override
  String get getVerifiedToApply => 'Get verified to apply';

  @override
  String get verificationRequired => 'Verification required';

  @override
  String get completeKyc =>
      'Complete your KYC verification to start applying to tasks.';

  @override
  String get getVerified => 'Get verified';

  @override
  String get noTasksFound => 'No tasks found';

  @override
  String get tryAdjustingFilters => 'Try adjusting filters or search';

  @override
  String get loginOrSignup => 'Log in or Sign up';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get enterValidMobile => 'Enter a valid 10-digit mobile number';

  @override
  String get enterFullOtp => 'Please enter full 6-digit OTP';

  @override
  String get changeNumber => 'Change number';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendInSeconds(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get langEnglish => 'English';

  @override
  String get langHindi => 'हिन्दी (Hindi)';

  @override
  String get langPunjabi => 'ਪੰਜਾਬੀ (Punjabi)';

  @override
  String get safety => 'Safety';

  @override
  String get blockedUsers => 'Blocked Users';

  @override
  String get manage => 'Manage';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get workPreferences => 'WORK PREFERENCES';

  @override
  String get availability => 'Availability';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionDecline => 'Decline';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionSubmit => 'Submit';

  @override
  String get actionOk => 'OK';

  @override
  String get actionYes => 'Yes';

  @override
  String get actionNo => 'No';

  @override
  String get actionClose => 'Close';

  @override
  String get actionReport => 'Report';

  @override
  String get actionBlock => 'Block';

  @override
  String get actionOnMyWay => 'On my way';

  @override
  String get bankTitle => 'Bank & Payments';

  @override
  String get bankPayoutMethods => 'Payout Methods';

  @override
  String get bankNoMethods => 'No payout methods added yet.';

  @override
  String bankSetDefaultSuccess(String name) {
    return '$name set as default payout method';
  }

  @override
  String get bankAddPaymentMethod => 'Add Payment Method';

  @override
  String get profileMyApplications => 'My Applications';

  @override
  String get profileTotal => 'Total';

  @override
  String get profilePending => 'Pending';

  @override
  String get profileAccepted => 'Accepted';

  @override
  String get profileCompleted => 'Completed';

  @override
  String get profileRejected => 'Rejected';

  @override
  String get profileAll => 'All';

  @override
  String get profileNothingHere => 'Nothing here yet';

  @override
  String get profileBrowseTasksStart => 'Browse tasks to get started';

  @override
  String get profileWithdrawBid => 'Withdraw Bid';

  @override
  String get profileWithdrawBidConfirm =>
      'Are you sure you want to withdraw this bid?';

  @override
  String get profileWithdraw => 'Withdraw';

  @override
  String get profileBidWithdrawn => 'Bid withdrawn';

  @override
  String get profileCompleteTask => 'Complete Task';

  @override
  String get profileCompleteTaskOtpPrompt =>
      'Enter the OTP shared by the customer to complete this task.';

  @override
  String get profileOtp => 'OTP';

  @override
  String get profileEnterOtp => 'Enter OTP';

  @override
  String get chatClosed => 'This chat is closed — the task is finished.';

  @override
  String get walletMyWallet => 'My Wallet';

  @override
  String get walletTotalBalance => 'Total Balance';

  @override
  String get walletAvailable => 'Available';

  @override
  String get walletEarnings => 'Earnings';

  @override
  String get walletTransactions => 'Transactions';

  @override
  String get walletWithdraw => 'Withdraw';

  @override
  String get walletTasksDone => 'Tasks Done';

  @override
  String get walletNoTransactions => 'No transactions yet';

  @override
  String get walletNoTransactionsBody =>
      'Your earnings and withdrawals will appear here.';

  @override
  String walletPlatformDues(String amount) {
    return 'Platform dues: ₹$amount';
  }

  @override
  String get walletDuesBody =>
      'This is the commission owed on cash jobs. Keep your wallet topped up to clear it.';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get commonChooseGallery => 'Choose from Gallery';

  @override
  String get commonTakePhoto => 'Take a Photo';

  @override
  String get profileStatusNotSelected => 'Not Selected';

  @override
  String get profileStatusUnderReview => 'Under Review';

  @override
  String get profileApplied => 'Applied';

  @override
  String get profileStepDecision => 'Decision';

  @override
  String get profileYourBid => 'Your Bid';

  @override
  String get profileTaskBudget => 'Task Budget';

  @override
  String get profileYouEarn => 'You Earn';

  @override
  String get profileStartTask => 'Start Task';

  @override
  String profileAppliedAgo(String time) {
    return 'Applied $time';
  }

  @override
  String get profileMyProfile => 'My Profile';

  @override
  String profileReviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get profileTasksDone => 'Tasks Done';

  @override
  String get profileEarned => 'Earned';

  @override
  String get profileAvailableForTasks => 'Available for Tasks';

  @override
  String get profileNotAvailable => 'Not Available';

  @override
  String get profileVisibleToCustomers => 'You\'re visible to customers';

  @override
  String get profileWontReceiveTasks => 'You won\'t receive new tasks';

  @override
  String get profileCompletion => 'Completion';

  @override
  String get profileAvgResponse => 'Avg Response';

  @override
  String get profileMemberSince => 'Member Since';

  @override
  String get profileAboutMe => 'About Me';

  @override
  String get profileEdit => 'Edit';

  @override
  String get profileMySkills => 'My Skills';

  @override
  String get profileMyWork => 'My Work';

  @override
  String get profileAdd => 'Add';

  @override
  String get profileViewAll => 'View all';

  @override
  String get profileSecAccount => 'ACCOUNT';

  @override
  String get profileSecWork => 'WORK';

  @override
  String get profileSecSupportLegal => 'SUPPORT & LEGAL';

  @override
  String get profileEditProfile => 'Edit Profile';

  @override
  String get profileVerificationDocuments => 'Verification & Documents';

  @override
  String get profileBankPayment => 'Bank & Payment';

  @override
  String get profileSetWorkingHours => 'Set your working hours';

  @override
  String get profileWorkPortfolio => 'Work Portfolio';

  @override
  String get profileShowcaseWork => 'Showcase your best work';

  @override
  String profilePhotoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get profileCompletedTasks => 'Completed Tasks';

  @override
  String get profileMyReviews => 'My Reviews';

  @override
  String get profileEarningsPayouts => 'Earnings & Payouts';

  @override
  String get profileHelpSupport => 'Help & Support';

  @override
  String get profileTerms => 'Terms & Conditions';

  @override
  String get profilePrivacy => 'Privacy Policy';

  @override
  String get profileRateUs => 'Rate Us on Play Store';

  @override
  String get profileReferEarn => 'Refer & Earn ₹200';

  @override
  String get profileSignOut => 'Sign Out';

  @override
  String profileVersion(String version) {
    return 'Version $version';
  }

  @override
  String get profileRedirectTitle => 'Redirect to External Link';

  @override
  String profileRedirectBody(String url) {
    return 'You are being redirected to an external website:\n\n$url\n\nDo you want to continue?';
  }

  @override
  String get profileCouldNotOpenLink => 'Could not open link';

  @override
  String get profileUploadingPhoto => 'Uploading photo…';

  @override
  String get profilePictureUpdated => 'Profile picture updated';

  @override
  String get profileUpdatePicture => 'Update Profile Picture';

  @override
  String get profileEditAboutMe => 'Edit About Me';

  @override
  String get profileWriteAboutYourself => 'Write about yourself...';

  @override
  String get profileBioUpdated => 'Bio updated';

  @override
  String get profileEditSkills => 'Edit Skills';

  @override
  String get profileSaveSkills => 'Save Skills';

  @override
  String get profileSkillsUpdated => 'Skills updated';

  @override
  String get profileNoCoins => 'No TaskCoins';

  @override
  String get profileNoCoinsBody =>
      'You have 0 TaskCoins in your wallet to redeem.';

  @override
  String get profileRedeemCoins => 'Redeem TaskCoins';

  @override
  String profileCoinsValue(int coins) {
    return '$coins Coins = ₹$coins';
  }

  @override
  String get profileCoinsCredited =>
      'Coins will be credited to your default payout method.';

  @override
  String profileCoinsWillCredit(int amount) {
    return '₹$amount will be credited to your account';
  }

  @override
  String get profileRedeemAll => 'Redeem All';

  @override
  String get profileAddPhotosWork => 'Add photos of your work';

  @override
  String get profilePortfolioHelps =>
      'A strong portfolio helps you win more jobs';

  @override
  String get profileNotSet => 'Not set';

  @override
  String get profileEveryDay => 'Every day';

  @override
  String get profileHoursVary => 'hours vary';

  @override
  String get walletWithdrawMoney => 'Withdraw Money';

  @override
  String get walletAmount => 'Amount';

  @override
  String walletAvailableBalance(String amount) {
    return 'Available: ₹$amount';
  }

  @override
  String get walletEnterValidAmount => 'Please enter a valid amount';

  @override
  String get walletInsufficientBalance => 'Insufficient balance';

  @override
  String walletWithdrawalRequested(String amount) {
    return 'Withdrawal of ₹$amount requested!';
  }

  @override
  String get walletNoEarnings7Days => 'No earnings in the last 7 days';

  @override
  String get walletEarningsLast7 => 'Earnings - Last 7 Days';

  @override
  String get walletTotalEarned => 'Total Earned';

  @override
  String get walletJobsCompleted => 'Jobs Completed';

  @override
  String get walletAvgPerJob => 'Average per Job';

  @override
  String get verifTitle => 'Verification & Documents';

  @override
  String get verifProgress => 'Verification Progress';

  @override
  String verifDocsVerified(int verified, int total) {
    return '$verified of $total documents verified';
  }

  @override
  String get verifDocuments => 'DOCUMENTS';

  @override
  String get verifAadhaar => 'Aadhaar Card';

  @override
  String get verifAadhaarUpload => 'Upload Aadhaar for identity verification';

  @override
  String get verifPan => 'PAN Card';

  @override
  String get verifPanUpload => 'Upload PAN for tax purposes';

  @override
  String get verifUnderReview => 'Under review';

  @override
  String get verifAddressProof => 'Address Proof';

  @override
  String get verifAddressVerified => 'Address verified successfully';

  @override
  String get verifAddressUpload => 'Upload electricity bill or rent agreement';

  @override
  String get verifSelfie => 'Selfie Verification';

  @override
  String get verifIdentityConfirmed => 'Identity confirmed';

  @override
  String get verifSelfieUpload => 'Capture a selfie to confirm identity';

  @override
  String get verifUnlockPremium =>
      'Complete all verifications to unlock premium tasks and higher payouts.';

  @override
  String get verifStatusVerified => 'Verified';

  @override
  String get verifStatusPending => 'Pending';

  @override
  String get verifStatusRejected => 'Rejected';

  @override
  String get verifStatusUpload => 'Upload';

  @override
  String verifAlreadyVerified(String title) {
    return '$title is already verified!';
  }

  @override
  String verifUploadTitle(String title) {
    return 'Upload $title';
  }

  @override
  String verifUploading(String title) {
    return 'Uploading $title…';
  }

  @override
  String verifSubmitted(String title) {
    return '$title submitted. Our team will review it shortly.';
  }

  @override
  String get availSaveSchedule => 'Save Schedule';

  @override
  String get availSaved => 'Availability saved';

  @override
  String get availEndAfterStart => 'End time must be after start time';

  @override
  String get availStartTime => 'Start time';

  @override
  String get availEndTime => 'End time';

  @override
  String get availYourWeeklyHours => 'Your weekly hours';

  @override
  String get availNotSetTap => 'Not set - tap to add working hours';

  @override
  String get availStart => 'Start';

  @override
  String get availEnd => 'End';

  @override
  String get availAvailableDay => 'Available';

  @override
  String get availOff => 'Off';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get daySunday => 'Sunday';

  @override
  String timeWeeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String get msgSearchChats => 'Search chats…';

  @override
  String get msgNoResults => 'No results found';

  @override
  String get msgNoConversations => 'No conversations yet';

  @override
  String get msgTryDifferentSearch => 'Try a different search term';

  @override
  String get msgChatsWillAppear =>
      'When you start a task,\nyour chats will appear here.';

  @override
  String get msgTapToOpen => 'Tap to open chat';

  @override
  String get msgYesterday => 'Yesterday';

  @override
  String get msgSayHello => 'Say hello!';

  @override
  String get msgStartConversation =>
      'Start a conversation and\nget things moving.';

  @override
  String get msgTakePhoto => 'Take Photo';

  @override
  String msgErrorSelectingImage(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String get msgCouldNotSend => 'Could not send message';

  @override
  String get msgMessageCopied => 'Message copied';

  @override
  String get msgTypeMessage => 'Type a message…';

  @override
  String get notifTitle => 'Notifications';

  @override
  String notifUnreadCount(int count) {
    return '$count unread';
  }

  @override
  String get notifAllCaughtUp => 'All caught up';

  @override
  String get notifMarkAll => 'Mark all';

  @override
  String get notifNoNotifications => 'No notifications yet';

  @override
  String get notifEmptyBody => 'Job leads, bookings and payouts show up here';

  @override
  String get notifSomethingWrong => 'Something went wrong';

  @override
  String get notifJustNow => 'Just now';

  @override
  String get editProfileUpdated => 'Profile updated successfully';

  @override
  String editProfileFailed(String error) {
    return 'Failed to update profile: $error';
  }

  @override
  String get editFullName => 'Full Name';

  @override
  String get editFullNameHint => 'Enter your full name';

  @override
  String get editNameRequired => 'Name is required';

  @override
  String get editEmail => 'Email';

  @override
  String get editEmailHint => 'Enter your email';

  @override
  String get editEmailRequired => 'Email is required';

  @override
  String get editEmailInvalid => 'Enter a valid email';

  @override
  String get editPhone => 'Phone Number';

  @override
  String get editPhoneHint => 'Enter your phone number';

  @override
  String get editPhoneRequired => 'Phone is required';

  @override
  String get editCity => 'City / Location';

  @override
  String get editCityHint => 'Enter your city';

  @override
  String get editCityRequired => 'City is required';

  @override
  String get editSaveChanges => 'Save Changes';

  @override
  String get splashPreparing => 'Preparing TaskTeddy';

  @override
  String get splashGettingReady => 'Getting everything ready...';

  @override
  String get splashGettingThingsReady => 'Getting things ready...';

  @override
  String get splashLocationOff => 'Location is off. Continuing...';

  @override
  String get splashLocationSkipped =>
      'Location permission skipped. Continuing...';

  @override
  String splashLocationLocked(String label) {
    return 'Location locked: $label';
  }

  @override
  String get splashLocationFailed => 'Could not fetch location. Continuing...';

  @override
  String get commonRemove => 'Remove';

  @override
  String get completedEmptyBody =>
      'No completed tasks yet.\nYour finished work will appear here.';

  @override
  String get reviewsRecent => 'Recent Reviews';

  @override
  String get reviewsNone => 'No reviews yet';

  @override
  String portfolioFull(int max) {
    return 'Portfolio is full ($max photos max)';
  }

  @override
  String get portfolioAddCaption => 'Add a caption';

  @override
  String get portfolioCaptionHint => 'Optional - e.g. Kitchen deep clean';

  @override
  String get portfolioSkip => 'Skip';

  @override
  String get portfolioPhotoAdded => 'Photo added to portfolio';

  @override
  String get portfolioAddWorkPhoto => 'Add Work Photo';

  @override
  String get portfolioRemovePhoto => 'Remove Photo';

  @override
  String get portfolioRemoveConfirm => 'Remove this photo from your portfolio?';

  @override
  String get portfolioPhotoRemoved => 'Photo removed';

  @override
  String get portfolioUploading => 'Uploading...';

  @override
  String get portfolioAddPhoto => 'Add Photo';

  @override
  String get portfolioEmpty => 'No portfolio photos yet';

  @override
  String get portfolioEmptyBody => 'Showcase your best work to win more jobs.';

  @override
  String get portfolioUntitled => 'Untitled';

  @override
  String get referTitle => 'Refer & Earn';

  @override
  String get referEarnHero => 'Earn ₹200 for every referral!';

  @override
  String get referInviteFriends =>
      'Invite friends to TaskTeddy and earn rewards together.';

  @override
  String get referHowItWorks => 'How it works';

  @override
  String get referStep1 => 'Share your referral code with friends';

  @override
  String get referStep2 => 'Your friend signs up & completes first task';

  @override
  String get referStep3 => 'Both of you earn ₹200 in TaskCoins!';

  @override
  String get referYourCode => 'Your Referral Code';

  @override
  String get referCodeCopied => 'Code copied!';

  @override
  String get referShareWhatsApp => 'Share via WhatsApp';

  @override
  String get referShareDialogOpened => 'Share dialog opened!';

  @override
  String get referYourReferrals => 'Your Referrals';

  @override
  String get referTotalReferrals => 'Total Referrals';

  @override
  String get referEarningsFrom => 'Earnings from Referrals';

  @override
  String referStep(int number) {
    return 'Step $number';
  }

  @override
  String referShareMessage(String code) {
    return 'Join TaskTeddy using my referral code $code and earn ₹200! Download now: https://taskteddy.app';
  }

  @override
  String bankRemoveConfirmTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get bankRemoveConfirmBody =>
      'This payment method will be removed from your account.';

  @override
  String bankMethodRemoved(String name) {
    return '$name removed';
  }

  @override
  String get bankBankAccount => 'Bank Account';

  @override
  String get bankBankAccountSub => 'Add savings or current account';

  @override
  String get bankUpiId => 'UPI ID';

  @override
  String get bankUpiSub => 'Add your UPI address';

  @override
  String get bankAddBankAccount => 'Add Bank Account';

  @override
  String get bankAccountHolderName => 'Account Holder Name';

  @override
  String get bankAccountNumber => 'Account Number';

  @override
  String get bankIfscCode => 'IFSC Code';

  @override
  String get bankFillAllFields => 'Please fill all fields';

  @override
  String bankSavingsMask(String last4) {
    return 'Savings Account •••• $last4';
  }

  @override
  String get bankAccountAdded => 'Bank account added successfully';

  @override
  String get bankAddUpiId => 'Add UPI ID';

  @override
  String get bankUpiHint => 'e.g. name@upi';

  @override
  String get bankEnterValidUpi => 'Please enter a valid UPI ID';

  @override
  String get bankUpiAdded => 'UPI ID added successfully';

  @override
  String get bankPayoutInfo => 'Payout Information';

  @override
  String get bankProcessingTime => 'Processing Time';

  @override
  String get bankProcessingTimeVal => '24 hours after task completion';

  @override
  String get bankMinWithdrawal => 'Minimum Withdrawal';

  @override
  String get bankPlatformFee => 'Platform Fee';

  @override
  String get bankPlatformFeeVal => '15% per task';

  @override
  String get bankPaymentCycle => 'Payment Cycle';

  @override
  String get bankPaymentCycleVal => 'Instant to default method';

  @override
  String get bankDefault => 'DEFAULT';

  @override
  String get bankSetDefault => 'Set Default';

  @override
  String get helpMyTicketsTooltip => 'My tickets';

  @override
  String get helpMessageSupport => 'Message support';

  @override
  String get helpRespond24 => 'We usually respond within 24 hours.';

  @override
  String get helpSubject => 'Subject';

  @override
  String get helpDescribeIssue => 'Describe your issue…';

  @override
  String get helpAddSubjectDesc =>
      'Please add a subject and a short description.';

  @override
  String get helpTicketSent => 'Ticket sent! We will reply in-app.';

  @override
  String get helpSend => 'Send';

  @override
  String get helpNoTickets => 'No support tickets yet';

  @override
  String get helpResolved => 'RESOLVED';

  @override
  String get helpOpen => 'OPEN';

  @override
  String helpSupportReply(String reply) {
    return 'Support: $reply';
  }

  @override
  String helpReachOut(String phone, String email) {
    return 'Reach out to partner support\n$phone  •  $email';
  }

  @override
  String get helpCallUs => 'Call us';

  @override
  String get helpEmailUs => 'Email us';

  @override
  String get helpCouldNotDial => 'Could not open dialer on this device.';

  @override
  String get helpCouldNotEmail => 'Could not open email app on this device.';

  @override
  String get helpNeedQuickHelp => 'Need quick help?';

  @override
  String get helpFindAnswers =>
      'Find answers instantly or contact support anytime.';

  @override
  String get helpMyDisputes => 'My Payout disputes';

  @override
  String get helpNoDisputes => 'You don’t have any active disputes.';

  @override
  String get helpBrowseTopics => 'Browse all help topics';

  @override
  String helpRelatedTo(String topic) {
    return 'Help related to $topic';
  }

  @override
  String get helpCantFind => 'Can’t find your answer?';

  @override
  String get helpTeamHere => 'Our support team is here to help';

  @override
  String get helpT1Title => 'Tasks & Applications';

  @override
  String get helpT1Sub =>
      'Manage applications, bids, slot details, and cover letters';

  @override
  String get helpT1Q1 => 'How do I apply for a task?';

  @override
  String get helpT1A1 =>
      'Browse available tasks in the Browse tab, select a task that matches your expertise, choose your bid amount, write a brief cover letter describing your experience, and tap Apply.';

  @override
  String get helpT1Q2 => 'Can I cancel or withdraw my application?';

  @override
  String get helpT1A2 =>
      'Yes. Go to My Applications on the Profile tab, choose the pending application you want to withdraw, and tap the Withdraw option to remove your bid.';

  @override
  String get helpT1Q3 => 'What happens when my application is accepted?';

  @override
  String get helpT1A3 =>
      'You will receive an instant notification, and the task moves to your \"My Active Tasks\" shelf. You can open the task to view customer details and coordinates.';

  @override
  String get helpT1Q4 => 'What is the task completion OTP?';

  @override
  String get helpT1A4 =>
      'Upon successfully completing the task, ask the customer for the 4-digit verification OTP. Enter it in the active task window to mark it completed and release your payout.';

  @override
  String get helpT1Q5 =>
      'What happens if a customer cancels a task after I arrive?';

  @override
  String get helpT1A5 =>
      'If a customer cancels after you have arrived or started traveling to the location, you may be eligible for a cancellation compensation of ₹50-₹150 depending on the distance traveled. Contact support via the active booking screen.';

  @override
  String get helpT1Q6 => 'How are task ratings calculated?';

  @override
  String get helpT1A6 =>
      'Your overall rating is the average of ratings given by customers upon task completion. High ratings (4.5+) increase your visibility and give you early access to high-value tasks.';

  @override
  String get helpT2Title => 'Earnings & Payouts';

  @override
  String get helpT2Sub =>
      'Platform fees, bank withdrawals, and ledger payments';

  @override
  String get helpT2Q1 => 'How do I withdraw my earnings?';

  @override
  String get helpT2A1 =>
      'Go to Earnings & Payouts from your Profile, tap Withdraw, enter the amount (min ₹100), and the funds are instantly transferred to your default payout target.';

  @override
  String get helpT2Q2 => 'What is the platform service fee?';

  @override
  String get helpT2A2 =>
      'TaskTeddy charges a flat 15% platform service fee on successful task completions to help pay for insurance, marketing, and operations.';

  @override
  String get helpT2Q3 => 'How long does a withdrawal bank payout take?';

  @override
  String get helpT2A3 =>
      'Payout transfers are initiated instantly. Depending on your bank\'s IMPS processing speeds, payouts usually reflect in your bank account or UPI within a few minutes.';

  @override
  String get helpT2Q4 => 'Why is my payout stuck in pending status?';

  @override
  String get helpT2A4 =>
      'If your payout is pending, it\'s usually due to a banking network delay or verification check. Most pending payouts resolve automatically within 2-4 hours. If it takes longer, reach out with the Payout ID.';

  @override
  String get helpT2Q5 => 'Can I change my default payout bank account?';

  @override
  String get helpT2A5 =>
      'Yes, you can edit or add bank accounts and UPI IDs anytime via the Bank & Payout screen on your Profile tab. Simply add a new method and tap the star or set as default.';

  @override
  String get helpT3Title => 'Verification & Profile';

  @override
  String get helpT3Sub =>
      'Aadhaar checks, PAN verification, and profile picture settings';

  @override
  String get helpT3Q1 => 'How long does document verification take?';

  @override
  String get helpT3A1 =>
      'Automated background checks are verified instantly. In cases requiring manual reviews, approval can take up to 24 hours. Your progress bar updates automatically.';

  @override
  String get helpT3Q2 => 'What address proofs are acceptable?';

  @override
  String get helpT3A2 =>
      'We accept standard utility bills (electricity, pipeline gas, or water bill) not older than 3 months, registered rent agreements, or government certificates in your name.';

  @override
  String get helpT3Q3 => 'Why was my PAN card upload rejected?';

  @override
  String get helpT3A3 =>
      'Ensure that the photo is clear, all edges are visible, there is no flash reflection, and the name matches your government ID details.';

  @override
  String get helpT3Q4 =>
      'How do I update my profile details after verification?';

  @override
  String get helpT3A4 =>
      'Once your identity is verified, major fields like your legal name and government ID cannot be edited directly. To change your registered phone number or correct a name error, contact partner support with supporting documents.';

  @override
  String get helpT3Q5 => 'What should I do if my document verification fails?';

  @override
  String get helpT3A5 =>
      'If your Aadhaar or PAN is rejected, you will receive a notification stating the reason. Make sure your upload is high-quality, not blurred, and matches your registered profile name before submitting again.';

  @override
  String get helpT4Title => 'Safety & Code of Conduct';

  @override
  String get helpT4Sub => 'Emergency support, coordinates tracking, and rules';

  @override
  String get helpT4Q1 => 'I feel unsafe during a task - what do I do?';

  @override
  String get helpT4A1 =>
      'Safety is our top priority. Leave the location immediately to a public space and call support. In any emergency, dial local police (100/112) first.';

  @override
  String get helpT4Q2 => 'Can I accept payments directly from customers?';

  @override
  String get helpT4A2 =>
      'No. Asking customers for offline or direct cash/UPI transfers violates partner guidelines and leads to permanent suspension of your TaskTeddy account.';

  @override
  String get helpT4Q3 =>
      'What should I do if the task scope changes at the location?';

  @override
  String get helpT4A3 =>
      'If a customer asks you to do additional work not mentioned in the original task description, politely ask them to update the task in the app or pay standard rates. Do not accept offline payment adjustments without informing support.';

  @override
  String get helpT4Q4 => 'How is my location tracked during active tasks?';

  @override
  String get helpT4A4 =>
      'We track your location in the background only when you are traveling to a task or actively completing a service, to ensure partner safety and provide customers with live ETAs.';

  @override
  String get setWeeklyHours => 'Weekly hours';

  @override
  String get setNotifications => 'NOTIFICATIONS';

  @override
  String get setPushNotif => 'Push Notifications';

  @override
  String get setPushNotifSub => 'Receive task alerts & updates';

  @override
  String get setEmailNotif => 'Email Notifications';

  @override
  String get setEmailNotifSub => 'Weekly summary & promotions';

  @override
  String get setSmsNotif => 'SMS Notifications';

  @override
  String get setSmsNotifSub => 'OTP & critical alerts only';

  @override
  String get setAppearance => 'APPEARANCE';

  @override
  String get setDarkMode => 'Dark Mode';

  @override
  String get setComingSoon => 'Coming soon';

  @override
  String get setDataStorage => 'DATA & STORAGE';

  @override
  String get setClearCache => 'Clear Cache';

  @override
  String get setCacheCleared => 'Cache cleared';

  @override
  String get setDownloadData => 'Download My Data';

  @override
  String get setDataExportEmailed => 'Data export will be emailed to you';

  @override
  String get setDangerZone => 'DANGER ZONE';

  @override
  String get setDeleteAccount => 'Delete Account';

  @override
  String get setDeleteAccountTitle => 'Delete Account?';

  @override
  String get setDeleteAccountBody =>
      'This action is irreversible. All your data, earnings, and reviews will be permanently deleted.';

  @override
  String get setDelete => 'Delete';

  @override
  String get setDeletionSubmitted => 'Account deletion request submitted';

  @override
  String get reportThisUser => 'this user';

  @override
  String reportUserTitle(String name) {
    return 'Report $name';
  }

  @override
  String get reportChooseReason => 'Choose a reason. Reports are confidential.';

  @override
  String get reportDetailsOptional => 'Details (optional)';

  @override
  String get reportDetailHint =>
      'Add anything that helps us understand what happened…';

  @override
  String get reportSubmit => 'Submit Report';

  @override
  String get reportSubmitted => 'Report submitted. Our team will review it.';

  @override
  String get reportReasonInappropriate => 'Inappropriate behaviour';

  @override
  String get reportReasonNoShow => 'No show';

  @override
  String get reportReasonSafety => 'Safety concern';

  @override
  String get reportReasonFraud => 'Fraud or scam';

  @override
  String get reportReasonPoorQuality => 'Poor quality';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonOther => 'Other';

  @override
  String blockConfirmTitle(String name) {
    return 'Block $name?';
  }

  @override
  String get blockConfirmBody =>
      'They will no longer be able to message you or match with your tasks. You can unblock them anytime from Settings.';

  @override
  String blockedSuccess(String name) {
    return '$name has been blocked';
  }

  @override
  String get blockedUserFallback => 'User';

  @override
  String get unblockAction => 'Unblock';

  @override
  String unblockedSuccess(String name) {
    return '$name unblocked';
  }

  @override
  String get blockedEmptyBody => 'People you block will appear here.';

  @override
  String loginSendingOtp(String phone) {
    return 'Sending OTP to $phone';
  }

  @override
  String loginOtpSent(String phone) {
    return 'OTP sent to $phone';
  }

  @override
  String get loginEnterOtpSent => 'Enter OTP sent to your number';

  @override
  String get loginErrConnect =>
      'Unable to connect. Please check your internet and try again.';

  @override
  String get loginErrServer => 'Cannot reach server. Please try again later.';

  @override
  String get loginErrInvalidOtp => 'Invalid OTP. Please check and try again.';

  @override
  String get loginErrExpiredOtp => 'OTP expired. Please request a new one.';

  @override
  String get loginErrTooMany =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get loginErrGeneric => 'Something went wrong. Please try again.';

  @override
  String get loginTermsPrefix => 'By clicking continue, you accept our ';

  @override
  String get loginAnd => ' and ';

  @override
  String get loginTermsSuffix => '.';

  @override
  String get dashLoading => 'Loading your dashboard…';

  @override
  String get dashLocationPicker => 'Location picker opened...';

  @override
  String dashAssigned(int count) {
    return '$count assigned';
  }

  @override
  String dashAvailable(int count) {
    return '$count available';
  }

  @override
  String dashOngoing(int count) {
    return '$count ongoing';
  }

  @override
  String get dashUseAppliedTab => 'Use the Applied tab in bottom navigation';

  @override
  String get dashCheckBackSoon =>
      'Check back soon — new tasks are posted daily!';

  @override
  String get dashBrowseStartEarning =>
      'Browse available tasks and start earning!';

  @override
  String get dashSpecialOffer => 'Special Offer!';

  @override
  String get dashBonusRewards => 'Complete tasks to earn bonus rewards';

  @override
  String get dashCompleteBooking => 'Complete Booking';

  @override
  String dashBookingOtpPrompt(String service) {
    return 'Ask the customer for their completion OTP for \"$service\" and enter it below.';
  }

  @override
  String get dashComplete => 'Complete';

  @override
  String get dashBookingComplete => 'Booking marked complete!';

  @override
  String get dashThisBooking => 'this booking';

  @override
  String get dashMarkComplete => 'Mark Complete';

  @override
  String get dashScheduled => 'Scheduled';

  @override
  String get dashServiceFallback => 'Service';

  @override
  String get dashCustomerFallback => 'Customer';

  @override
  String get dashOverdue => 'Overdue';

  @override
  String dashMinLeft(int count) {
    return '${count}m left';
  }

  @override
  String dashHrLeft(int count) {
    return '${count}h left';
  }

  @override
  String dashDayLeft(int count) {
    return '${count}d left';
  }

  @override
  String dashApplied(int count) {
    return '$count applied';
  }

  @override
  String get dashStatusPending => 'Pending';

  @override
  String get dashStatusConfirmed => 'Confirmed';

  @override
  String get dashStatusCompleted => 'Completed';

  @override
  String get dashStatusCancelled => 'Cancelled';

  @override
  String get dashTip1 => 'Complete 3 more tasks this week to reach Gold status';

  @override
  String get dashTip2 => 'Tasks with a quick response get 2x more bookings';

  @override
  String get dashTip3 => 'Keep your profile 100% complete for priority listing';

  @override
  String get dashTip4 => 'Maintain a 4.8+ rating to unlock premium task access';

  @override
  String get dashTip5 =>
      'Enable location for better task matching in your area';

  @override
  String get browseNotNow => 'Not now';

  @override
  String get browseTaskCompleted => 'Task completed';

  @override
  String browseCollectedCash(String amount) {
    return 'You collected ₹$amount in cash from the customer.';
  }

  @override
  String get browseCashCollected => 'Cash collected';

  @override
  String browsePlatformFeeMethod(String method) {
    return 'Platform fee ($method)';
  }

  @override
  String get browseNetEarning => 'Net earning';

  @override
  String browseFeeDeducted(String amount) {
    return 'The ₹$amount platform fee was deducted from your wallet. Keep your wallet topped up to avoid dues.';
  }

  @override
  String get browseDone => 'Done';

  @override
  String get browseLeadDismissed => 'Lead dismissed';

  @override
  String get browseUndo => 'Undo';

  @override
  String get browseGpsPinging => 'Pinging GPS Satellites...';

  @override
  String get browseGpsResolving => 'Resolving coordinates...';

  @override
  String get browseGpsFetching => 'Fetching nearest tasks...';

  @override
  String browseLocationDetected(String city) {
    return 'Location auto-detected to $city! Nearest tasks loaded.';
  }

  @override
  String get browseSelectLocation => 'Select Location';

  @override
  String get browseSelectLocationSub =>
      'Browse nearby open tasks in your preferred city';

  @override
  String get browseAutoDetect => 'Auto-Detect My Location';

  @override
  String get browseAccessingGps => 'Accessing high-accuracy GPS coordinates';

  @override
  String get browseSimulateGps => 'Simulate high-accuracy GPS check';

  @override
  String get browsePopularCities => 'POPULAR CITIES';

  @override
  String browseBrowsingNearest(String city) {
    return 'Browsing tasks nearest to $city.';
  }

  @override
  String get browseReset => 'Reset';

  @override
  String get browsePresetAll => 'All';

  @override
  String get browsePresetUnder500 => 'Under ₹500';

  @override
  String get browsePreset500to2000 => '₹500-₹2000';

  @override
  String get browsePresetAbove2000 => 'Above ₹2000';

  @override
  String get browseMinBudget => 'Min Budget (₹)';

  @override
  String get browseMaxBudget => 'Max Budget (₹)';

  @override
  String get browseHintAny => 'Any';

  @override
  String get browseFailedLoad => 'Failed to load tasks';

  @override
  String get browseRefresh => 'Refresh';

  @override
  String get browseCatAll => 'All';

  @override
  String browseOpenTasks(int count) {
    return '$count open tasks';
  }

  @override
  String browseSortLabel(String label) {
    return 'Sort: $label';
  }

  @override
  String get browseSortLatest => 'latest';

  @override
  String get browseSortBudget => 'budget';

  @override
  String get browseSortDeadline => 'deadline';

  @override
  String get browseSortLeastBids => 'least bids';

  @override
  String browsePosted(String ago) {
    return 'Posted $ago';
  }

  @override
  String get browseJustNow => 'just now';

  @override
  String browsePostedBy(String name) {
    return 'Posted by $name';
  }

  @override
  String get browseBudgetSmall => 'budget';

  @override
  String get browseUrgent => 'Urgent';

  @override
  String get browseDueToday => '· Due today!';

  @override
  String get browseDueTomorrow => '· Due tomorrow';

  @override
  String browseDueInDays(int days) {
    return '· Due in $days days';
  }

  @override
  String browseDue(String date) {
    return 'Due $date';
  }

  @override
  String browseBids(int count) {
    return '$count bids';
  }

  @override
  String get browseDismiss => 'Dismiss';

  @override
  String browseBidLower(String amount) {
    return 'Your bid is ₹$amount lower — better chance!';
  }

  @override
  String get browseBidAbove =>
      'Above budget — explain the value in your cover letter';

  @override
  String get browseBidMatches => 'Your bid matches the budget';

  @override
  String browseCompBelow(String pct) {
    return 'You\'re $pct% below average bids';
  }

  @override
  String browseCompAbove(String pct) {
    return 'You\'re $pct% above average bids';
  }

  @override
  String get browseCompMatches => 'Your bid matches the average';

  @override
  String get browseYourBidAmount => 'Your Bid Amount (₹)';

  @override
  String get browseCompetitiveAnalysis => 'Competitive Analysis';

  @override
  String get browseAvgBid => 'Avg Bid';

  @override
  String get browseEstTakeHome => 'Estimated Take-Home';

  @override
  String get browseAfterFee => 'after 10% platform fee';

  @override
  String get browseCoverLetter => 'Cover Letter *';

  @override
  String get browseCoverLetterOptional => 'Cover letter (optional)';

  @override
  String get browseCoverHint =>
      'Introduce yourself. Why are you the best fit? Mention your experience and availability...';

  @override
  String get browseCoverTip =>
      'Good cover letters increase selection chance by 70%';

  @override
  String get browseFeeNote =>
      'TaskTeddy charges 10% platform fee only when a task is completed.';

  @override
  String get browseSubmitApplication => 'Submit Application';

  @override
  String get browseTaskRefMissing => 'Task reference missing';

  @override
  String get browseCustomerNotifiedSharing =>
      'Customer notified. Sharing your location.';

  @override
  String get browseBackedOut => 'You backed out. The job is open again.';

  @override
  String get browseInvalidOtp => 'Invalid OTP';

  @override
  String get browseActiveTask => 'Active Task';

  @override
  String browseYouEarnAmt(String amount) {
    return 'You earn: ₹$amount';
  }

  @override
  String get browseFailedOpenChat => 'Failed to open chat';

  @override
  String get browseChat => 'Chat';

  @override
  String browseRatingLabel(String rating) {
    return '$rating rating';
  }

  @override
  String get browseHeadingToCustomer => 'Heading to the customer';

  @override
  String get browseOtwActiveBody =>
      'Customer notified. Your live location is being shared while this screen is open.';

  @override
  String get browseOtwIdleBody =>
      'Let the customer know you are on your way. We will share your live location so they can track your arrival.';

  @override
  String get browseCustomerNotified => 'Customer notified';

  @override
  String get browseNotifying => 'Notifying...';

  @override
  String get browseCancelling => 'Cancelling...';

  @override
  String get browseCancelJob => 'Cancel job';

  @override
  String get browseEnterCompletionOtp => 'Enter Completion OTP';

  @override
  String get browseOtpPrompt =>
      'Ask the customer for the 4-digit OTP to confirm task completion and receive payment.';

  @override
  String get browseVerifyComplete => 'Verify & Complete Task';

  @override
  String get browseReasonEmergency => 'Emergency';

  @override
  String get browseReasonTooFar => 'Too far';

  @override
  String get browseReasonSchedule => 'Schedule conflict';

  @override
  String get browseReasonOther => 'Other';

  @override
  String get browseBackOutTitle => 'Back out of this job?';

  @override
  String get browseBackOutWarning =>
      'This reopens the task for other taskers. Repeated cancellations hurt your reliability score.';

  @override
  String get browseReason => 'Reason';

  @override
  String get browseAddNote => 'Add a note (optional)';

  @override
  String get browseKeepJob => 'Keep job';

  @override
  String get browseThanksRating => 'Thanks for rating the customer.';

  @override
  String browseRateCustomer(String name) {
    return 'Rate $name';
  }

  @override
  String get browseRateExperience =>
      'How was your experience working with this customer?';

  @override
  String get browseAddComment => 'Add a comment (optional)';

  @override
  String get browseSubmitRating => 'Submit rating';

  @override
  String get browseAppSubmitted => 'Application Submitted!';

  @override
  String browseAppSubmittedBody(String title) {
    return '\"$title\"\nThe customer will review and accept the best bid.';
  }

  @override
  String get browseAppSubmittedNote =>
      'You\'ll get a notification when accepted. Keep applying to more tasks!';

  @override
  String get browseViewMyApps => 'View My Applications';

  @override
  String get browseBrowseMore => 'Browse More Tasks';

  @override
  String get browsePhotos => 'Photos';

  @override
  String get reputationYourLevel => 'Your Level';

  @override
  String get reputationReliability => 'Reliability';

  @override
  String reputationJobsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jobs done',
      one: '1 job done',
    );
    return '$_temp0';
  }

  @override
  String reputationJobsToNext(int completed, int next, String tier) {
    return '$completed/$next jobs to $tier';
  }

  @override
  String get reputationTopLevel => 'Top level';

  @override
  String get reputationExplainer =>
      'Complete jobs and keep a high rating to level up.';

  @override
  String get reputationLevelNew => 'New';

  @override
  String get reputationLevelBronze => 'Bronze';

  @override
  String get reputationLevelSilver => 'Silver';

  @override
  String get reputationLevelGold => 'Gold';

  @override
  String get reputationLevelPro => 'Pro';
}
