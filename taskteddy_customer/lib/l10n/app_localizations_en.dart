// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get navHome => 'Home';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navPost => 'Post';

  @override
  String get navBookings => 'Bookings';

  @override
  String get navActive => 'Active';

  @override
  String get navProfile => 'Profile';

  @override
  String get goodMorning => 'Good Morning';

  @override
  String get goodAfternoon => 'Good Afternoon';

  @override
  String get goodEvening => 'Good Evening';

  @override
  String get heroTitle => 'Get anything done';

  @override
  String get heroSubtitle =>
      'Post a task and get offers from trusted taskers near you.';

  @override
  String get howItWorks => 'How it works';

  @override
  String get howStep1Title => 'Post your task';

  @override
  String get howStep1Caption => 'Describe what you need done';

  @override
  String get howStep2Title => 'Get offers from taskers';

  @override
  String get howStep2Caption => 'Compare prices and reviews';

  @override
  String get howStep3Title => 'Hire and get it done';

  @override
  String get howStep3Caption => 'Pay securely when complete';

  @override
  String get whatDoYouNeedHelp => 'What do you need help with?';

  @override
  String get somethingElse => 'Something else';

  @override
  String get yourTasks => 'Your tasks';

  @override
  String get yourRecentTasks => 'Your recent tasks';

  @override
  String get viewAll => 'View all';

  @override
  String get noTasksYet => 'You haven\'t posted a task yet';

  @override
  String get postFirstTask => 'Post your first task and start getting offers.';

  @override
  String get trustVerifiedTaskers => 'Verified\ntaskers';

  @override
  String get trustTopRated => 'Top rated\nservice';

  @override
  String get trustSecurePayments => 'Secure\npayments';

  @override
  String get postATask => 'Post a Task';

  @override
  String get apply => 'Apply';

  @override
  String get accept => 'Accept';

  @override
  String get decline => 'Decline';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get retry => 'Retry';

  @override
  String get continueLabel => 'Continue';

  @override
  String get submit => 'Submit';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get close => 'Close';

  @override
  String get report => 'Report';

  @override
  String get block => 'Block';

  @override
  String get back => 'Back';

  @override
  String get authTagline => 'Get professional house help in minutes!';

  @override
  String get authLoginOrSignup => 'Log in or Sign up';

  @override
  String get authChangeNumber => 'Change number';

  @override
  String get authResendOtp => 'Resend OTP';

  @override
  String authResendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get authMobileNumber => 'Mobile number';

  @override
  String get authTermsIntro => 'By clicking continue, you accept our ';

  @override
  String get authTerms => 'Terms & Conditions';

  @override
  String get authAnd => ' and ';

  @override
  String get authPrivacy => 'Privacy Policy';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHindi => 'हिन्दी (Hindi)';

  @override
  String get languagePunjabi => 'ਪੰਜਾਬੀ (Punjabi)';

  @override
  String get verified => 'Verified';

  @override
  String get safetyMoreOptions => 'More options';

  @override
  String get safetyBlockUser => 'Block user';

  @override
  String safetyBlockBody(String name) {
    return 'Block $name? You will no longer see their offers or content, and they cannot contact you.';
  }

  @override
  String safetyUserBlocked(String name) {
    return '$name has been blocked';
  }

  @override
  String get safetyThisUser => 'this user';

  @override
  String get safetyReportUser => 'Report user';

  @override
  String safetyReportUserNamed(String name) {
    return 'Report $name';
  }

  @override
  String get safetyReportSubtitle =>
      'Tell us what went wrong. Reports are confidential.';

  @override
  String get safetyReportDetailHint => 'Add any details (optional)';

  @override
  String get safetySubmitReport => 'Submit report';

  @override
  String get safetyReportThanks =>
      'Report submitted. Thank you for keeping TaskTeddy safe.';

  @override
  String get reasonInappropriate => 'Inappropriate behaviour';

  @override
  String get reasonNoShow => 'No show';

  @override
  String get reasonSafety => 'Safety concern';

  @override
  String get reasonFraud => 'Fraud or scam';

  @override
  String get reasonPoorQuality => 'Poor quality';

  @override
  String get reasonSpam => 'Spam';

  @override
  String get reasonOther => 'Other';

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get unblock => 'Unblock';

  @override
  String unblockedSuccess(String name) {
    return '$name unblocked';
  }

  @override
  String get userLabel => 'User';

  @override
  String get noBlockedUsers => 'No blocked users';

  @override
  String get blockedUsersEmptyBody =>
      'People you block will appear here. You can unblock them any time.';

  @override
  String get blockedUsersError => 'Couldn\'t load blocked users.';

  @override
  String get tasksMyTasks => 'My Tasks';

  @override
  String get statusOpen => 'Open';

  @override
  String get statusActive => 'Active';

  @override
  String get statusDone => 'Done';

  @override
  String get statusAll => 'All';

  @override
  String get tasksLoadError => 'Could not load your tasks.';

  @override
  String get tasksTotalTasks => 'Total tasks';

  @override
  String get tasksAcrossStatuses => 'across all statuses';

  @override
  String get tasksWithBids => 'With bids';

  @override
  String get tasksReadyForReview => 'ready for review';

  @override
  String get tasksUpcoming => 'Upcoming';

  @override
  String get tasksNotPastDeadline => 'not past deadline';

  @override
  String get tasksSearchHint => 'Search task title, location or category';

  @override
  String get tasksOnlyWithBids => 'Only tasks with bids';

  @override
  String get splashPreparing => 'Preparing TaskTeddy';

  @override
  String get splashLoadingWorkspace => 'Loading your workspace';

  @override
  String get splashGettingReady => 'Getting things ready...';

  @override
  String get splashAlmostThere => 'Almost there...';

  @override
  String get splashLocationOff => 'Location is off. You can set it from home.';

  @override
  String get splashLocationSkipped =>
      'Location permission skipped. Continuing...';

  @override
  String get splashUsingDefaultLocation => 'Using default location.';

  @override
  String splashLocationLocked(String label) {
    return 'Location locked: $label';
  }

  @override
  String get splashLocationFailed => 'Could not fetch location. Continuing...';

  @override
  String get favSaved => 'Saved';

  @override
  String get favTabServices => 'Services';

  @override
  String get favTabTaskers => 'Taskers';

  @override
  String get favNoServices => 'No saved services yet';

  @override
  String get favNoServicesBody =>
      'Tap the heart on any service to save it here.';

  @override
  String get favNoTaskers => 'No saved taskers yet';

  @override
  String get favNoTaskersBody => 'Save a tasker to quickly find them again.';

  @override
  String get favLoadError => 'Couldn\'t load your saved items.';

  @override
  String reviewsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reviews',
      one: '1 review',
    );
    return '$_temp0';
  }

  @override
  String get portfolioTitle => 'Portfolio';

  @override
  String get weeklyAvailability => 'Weekly availability';

  @override
  String get recentReviews => 'Recent reviews';

  @override
  String get profileStatRating => 'Rating';

  @override
  String get profileStatJobs => 'Jobs done';

  @override
  String get profileStatReliability => 'Reliability';

  @override
  String get taskTheirOffer => 'Their offer';

  @override
  String get noReviewsYet => 'No reviews yet.';

  @override
  String get availabilityNotSet => 'Availability not set.';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get reviewerCustomer => 'Customer';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get sdSavedAddresses => 'Saved addresses';

  @override
  String get sdDefault => 'DEFAULT';

  @override
  String get sdConfirmBooking => 'Confirm Booking';

  @override
  String get sdServicePrice => 'Service price';

  @override
  String get sdDiscount => 'Discount';

  @override
  String get sdTotalFromWallet => 'Total (from wallet)';

  @override
  String get sdTotalPayAfter => 'Total (pay after service)';

  @override
  String get sdPaymentMethod => 'Payment Method';

  @override
  String get sdPayAfterService => 'Pay after service';

  @override
  String get sdPayAfterServiceSub => 'Cash / UPI on completion';

  @override
  String get sdWallet => 'Wallet';

  @override
  String sdWalletAvailable(int amount) {
    return '₹$amount available';
  }

  @override
  String sdWalletLow(int amount) {
    return 'Low balance: ₹$amount';
  }

  @override
  String sdConfirmAndBook(int amount) {
    return 'Confirm & Book  •  ₹$amount';
  }

  @override
  String get sessionExpired => 'Session expired. Please log in again.';

  @override
  String get sdBookingConfirmed => 'Booking Confirmed!';

  @override
  String sdPaidFromWallet(int amount) {
    return '₹$amount paid from wallet';
  }

  @override
  String sdBookingId(String ref) {
    return 'Booking ID: $ref';
  }

  @override
  String get sdViewMyBookings => 'View My Bookings';

  @override
  String get done => 'Done';

  @override
  String get sdPickTimeSlotError => 'Please pick a time slot';

  @override
  String get sdEnterAddressError => 'Please enter your address';

  @override
  String get sdRemoveFromSaved => 'Remove from saved';

  @override
  String get badgeHot => 'HOT';

  @override
  String get badgeNew => 'NEW';

  @override
  String percentOff(int percent) {
    return '$percent% OFF';
  }

  @override
  String get sdDescription => 'Description';

  @override
  String get sdWhatsIncluded => 'What\'s Included';

  @override
  String get sdPickDate => 'Pick a Date';

  @override
  String get dateToday => 'Today';

  @override
  String get dateTomorrowShort => 'Tmrw';

  @override
  String get sdPickTimeSlot => 'Pick a Time Slot';

  @override
  String get sdAddress => 'Address';

  @override
  String get sdUseSaved => 'Use saved';

  @override
  String get sdAddressHint => 'Enter your full address';

  @override
  String get sdNotesOptional => 'Notes (Optional)';

  @override
  String get sdNotesHint => 'Any special instructions?';

  @override
  String sdBookNow(int amount) {
    return 'Book Now  •  ₹$amount';
  }

  @override
  String get bookingCancelTitle => 'Cancel booking?';

  @override
  String bookingCancelBody(String service, String when) {
    return '$service on $when will be cancelled.';
  }

  @override
  String get bookingKeepIt => 'Keep it';

  @override
  String get bookingCancelConfirm => 'Cancel booking';

  @override
  String get bookingCancelled => 'Booking cancelled';

  @override
  String bookingCancelledRefund(int amount) {
    return 'Booking cancelled • ₹$amount refunded to wallet';
  }

  @override
  String bookingRescheduleTitle(String service) {
    return 'Reschedule $service';
  }

  @override
  String get bookingConfirmNewTime => 'Confirm New Time';

  @override
  String bookingRescheduledTo(String when) {
    return 'Rescheduled to $when';
  }

  @override
  String get bookingsTitle => 'My Bookings';

  @override
  String get bookingsTabUpcoming => 'Upcoming';

  @override
  String get bookingsTabCompleted => 'Completed';

  @override
  String get bookingsTabCancelled => 'Cancelled';

  @override
  String get bookingsEmptyTitle => 'No bookings yet';

  @override
  String get bookingsEmptyBody => 'Your scheduled services will appear here.';

  @override
  String get bookingStatusPending => 'PENDING';

  @override
  String get bookingStatusConfirmed => 'CONFIRMED';

  @override
  String get bookingStatusCompleted => 'COMPLETED';

  @override
  String get bookingStatusCancelled => 'CANCELLED';

  @override
  String get bookingDetailId => 'Booking ID';

  @override
  String get bookingDetailScheduled => 'Scheduled';

  @override
  String get bookingDetailAddress => 'Address';

  @override
  String get bookingDetailNotes => 'Notes';

  @override
  String get bookingDetailAmount => 'Amount';

  @override
  String get bookingDetailPayment => 'Payment';

  @override
  String get bookingPaidFromWallet => 'Paid from wallet';

  @override
  String get bookingBookAgain => 'Book again';

  @override
  String get bookingReschedule => 'Reschedule';

  @override
  String get notificationFallbackTitle => 'Notification';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all read';

  @override
  String get notificationsEmptyTitle => 'You\'re all caught up';

  @override
  String get notificationsEmptyBody =>
      'New updates about your bookings and\ntasks will show up here.';

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String timeHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get messagesTitle => 'Messages';

  @override
  String get messagesSearchHint => 'Search chats…';

  @override
  String get messagesNoResults => 'No results found';

  @override
  String get messagesNoConversations => 'No conversations yet';

  @override
  String get messagesTryDifferentSearch => 'Try a different search term';

  @override
  String get messagesBookToChat =>
      'Book a task to start chatting\nwith your tasker!';

  @override
  String get messagesTapToOpen => 'Tap to open chat';

  @override
  String get messagesCouldNotSend => 'Could not send message';

  @override
  String get messagesCopied => 'Copied to clipboard';

  @override
  String get messagesOnline => 'Online';

  @override
  String get messagesSayHello => 'Say hello!';

  @override
  String messagesStartConversation(String name) {
    return 'Start a conversation with\n$name';
  }

  @override
  String get messagesTypeHint => 'Type a message…';

  @override
  String get messagesTakePhoto => 'Take Photo';

  @override
  String get messagesChooseGallery => 'Choose from Gallery';

  @override
  String get messagesCouldNotSendImage => 'Could not send image';

  @override
  String messagesErrorSelectingImage(String error) {
    return 'Error selecting image: $error';
  }

  @override
  String get msgTimeNow => 'now';

  @override
  String msgTimeMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String msgTimeHours(int hours) {
    return '${hours}h';
  }

  @override
  String msgTimeDays(int days) {
    return '${days}d';
  }

  @override
  String get dateYesterday => 'Yesterday';

  @override
  String get weekdayFullMonday => 'Monday';

  @override
  String get weekdayFullTuesday => 'Tuesday';

  @override
  String get weekdayFullWednesday => 'Wednesday';

  @override
  String get weekdayFullThursday => 'Thursday';

  @override
  String get weekdayFullFriday => 'Friday';

  @override
  String get weekdayFullSaturday => 'Saturday';

  @override
  String get weekdayFullSunday => 'Sunday';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get profileAddPhone => 'Add phone number';

  @override
  String profileCouldNotOpen(String url) {
    return 'Could not open $url';
  }

  @override
  String profileOpenExternalTitle(String title) {
    return 'Open $title?';
  }

  @override
  String get profileOpenExternalBody =>
      'You are about to open an external website.';

  @override
  String get profileUpdatedSuccess => 'Profile updated successfully';

  @override
  String get profileDefaultName => 'TaskTeddy User';

  @override
  String get profileEditProfile => 'Edit profile';

  @override
  String get profileAddressBookReady =>
      'Address book ready for faster checkout';

  @override
  String get profileManage => 'Manage';

  @override
  String get profileQuickAccess => 'Quick access';

  @override
  String get profileTrackManage => 'Track & manage';

  @override
  String get profileAddresses => 'Addresses';

  @override
  String get profileSaveForCheckout => 'Save for checkout';

  @override
  String get profileHelp => 'Help';

  @override
  String get profile24x7 => '24x7 support';

  @override
  String get profileReferEarn => 'Refer & earn';

  @override
  String get profileInviteFriends => 'Invite friends and get rewarded';

  @override
  String get profileUpTo100 => 'Up to ₹100';

  @override
  String get profileSavedServicesTaskers => 'Saved services & taskers';

  @override
  String get profileSavedAddresses => 'Saved addresses';

  @override
  String get profileAboutUs => 'About us';

  @override
  String get profileTermsConditions => 'Terms & conditions';

  @override
  String get profilePrivacyPolicy => 'Privacy policy';

  @override
  String get profileLogout => 'Log out';

  @override
  String get profileAccountSettings => 'Account settings';

  @override
  String profileAppVersion(String version) {
    return 'APP VERSION: $version';
  }

  @override
  String get profileErrFirstName => 'Please enter first name';

  @override
  String get profileErrPhone => 'Phone number is not valid';

  @override
  String get profileErrValidEmail => 'Please enter a valid email address';

  @override
  String get profileChangeEmail => 'Change email';

  @override
  String get profileChangeEmailBody =>
      'Update email before verification. A fresh OTP will be sent to the new email.';

  @override
  String get profileEnterNewEmail => 'Enter new email';

  @override
  String get profileUseThisEmail => 'Use this email';

  @override
  String get profileAddEmailFirst => 'Please add your email first';

  @override
  String profileVerifCodeSent(String email) {
    return 'Verification code sent to $email';
  }

  @override
  String get profileErrValidEmailShort => 'Please enter a valid email';

  @override
  String get profileEnterFullOtp => 'Please enter full 6-digit OTP code';

  @override
  String get profileEmailVerified => 'Email verified successfully';

  @override
  String profileEmailLocked(String email) {
    return 'Email is verified. Contact $email to change your email.';
  }

  @override
  String get profileUpdateDetails => 'Update your details';

  @override
  String get profileUpdateDetailsBody =>
      'Keep your profile and contact details accurate for smoother bookings.';

  @override
  String get profileTitle => 'Title';

  @override
  String get profileBasicInfo => 'Basic Information';

  @override
  String get profileFirstName => 'First name';

  @override
  String get profileFirstNameHint => 'Enter first name';

  @override
  String get profileLastName => 'Last name';

  @override
  String get profileLastNameHint => 'Enter last name';

  @override
  String get profileContactVerification => 'Contact & Verification';

  @override
  String get profileMobile => 'Mobile';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileVerify => 'Verify';

  @override
  String get profileSaveChanges => 'Save changes';

  @override
  String get profileVerifyEmail => 'Verify email';

  @override
  String profileVerifyEmailBody(String email) {
    return 'Enter the 6-digit verification code sent to $email. Need to update email? Tap Change email.';
  }

  @override
  String get walletNoTransactions => 'No recent transactions yet';

  @override
  String get walletTransaction => 'Wallet transaction';

  @override
  String get walletMinAmount => 'Minimum add amount is ₹100';

  @override
  String get walletHelpHint => 'Add money to use faster checkout on bookings.';

  @override
  String get walletCardLabel => 'WALLET';

  @override
  String get walletBalance => 'Wallet Balance';

  @override
  String get walletBalanceLow =>
      'Your balance is low. Add money to continue booking smoothly.';

  @override
  String get walletBalanceUse =>
      'Use wallet credits for faster checkout and instant offer benefits.';

  @override
  String get walletGet5Extra => 'Get 5% Extra!';

  @override
  String get walletOnAdding250 => 'On adding ₹250 or more';

  @override
  String get walletAddMoney => 'Add money';

  @override
  String get walletEnterAmount => 'Enter amount';

  @override
  String walletCashback(String amount) {
    return 'Get $amount cashback';
  }

  @override
  String walletYouWillGet(String amount) {
    return 'You will get $amount in the wallet';
  }

  @override
  String walletAddToWallet(String amount) {
    return 'Add $amount to wallet';
  }

  @override
  String get walletRecentTransactions => 'Recent transactions';

  @override
  String walletAddedBonus(String added, String bonus, String credited) {
    return 'Added $added + bonus $bonus. Wallet credited $credited.';
  }

  @override
  String walletAdded(String amount) {
    return 'Added $amount to your wallet.';
  }

  @override
  String get helpCouldNotDial => 'Could not open dialer on this device.';

  @override
  String get helpCouldNotEmail => 'Could not open email app on this device.';

  @override
  String get helpTitle => 'Help & support';

  @override
  String helpReachOut(String phone, String email) {
    return 'Reach out to customer support\n$phone  •  $email';
  }

  @override
  String get helpCallUs => 'Call us';

  @override
  String get helpEmailUs => 'Email us';

  @override
  String get helpNeedQuickHelp => 'Need quick help?';

  @override
  String get helpFindAnswers =>
      'Find answers instantly or contact support anytime.';

  @override
  String get helpMyRefunds => 'My refunds';

  @override
  String get helpNoRefunds => 'You don\'t have any refunds yet.';

  @override
  String get helpBrowseTopics => 'Browse all help topics';

  @override
  String helpRelatedTo(String topic) {
    return 'Help related to $topic';
  }

  @override
  String get helpCantFindAnswer => 'Can\'t find your answer?';

  @override
  String get helpSupportHere => 'Our support team is here to help';

  @override
  String get helpTopicBooking => 'Booking';

  @override
  String get helpTopicBookingSub =>
      'Manage bookings, cancellations, and schedules';

  @override
  String get helpTopicAccount => 'Account';

  @override
  String get helpTopicAccountSub => 'Profile, login, and account settings';

  @override
  String get helpTopicPayments => 'Payments';

  @override
  String get helpTopicPaymentsSub => 'Billing, refunds, and transactions';

  @override
  String get helpTopicServiceQuality => 'Service quality';

  @override
  String get helpTopicServiceQualitySub =>
      'Feedback, issues, and service standards';

  @override
  String get helpTopicSafety => 'Safety';

  @override
  String get helpTopicSafetySub => 'Security and safety-related concerns';

  @override
  String get faqBookingRecurringQ => 'Can I book a recurring service?';

  @override
  String get faqBookingRecurringA =>
      'Yes. You can book a recurring service by choosing your preferred frequency while confirming the slot. We support weekly and bi-weekly repeats in most cities.';

  @override
  String get faqBookingEquipmentQ =>
      'Do I need to provide all the cleaning equipment?';

  @override
  String get faqBookingEquipmentA =>
      'Basic supplies should be available at your location. For selected premium plans, partners may carry service essentials as listed on the service detail page.';

  @override
  String get faqBookingRescheduleQ =>
      'How do I reschedule or cancel a booking?';

  @override
  String get faqBookingRescheduleA =>
      'Open My Bookings, choose the booking, and select reschedule or cancel. Cancellation fees depend on how close you are to the service time.';

  @override
  String get faqBookingIssueQ => 'What if there is a service issue?';

  @override
  String get faqBookingIssueA =>
      'Raise a support request from this page with booking details. Our team reviews quality issues and helps with resolution or compensation where applicable.';

  @override
  String get faqBookingPriceQ => 'How is service price calculated?';

  @override
  String get faqBookingPriceA =>
      'Price is based on service type, duration, location, and add-ons. You always see the final amount before payment confirmation.';

  @override
  String get faqAccountUpdateAddressQ => 'How do I update a saved address?';

  @override
  String get faqAccountUpdateAddressA =>
      'Go to Profile > Saved addresses. Select the address card and update the details, then save.';

  @override
  String get faqAccountAddAddressQ => 'How do I add a new address?';

  @override
  String get faqAccountAddAddressA =>
      'From Saved addresses, tap Add addresses and enter your complete address with landmark and pin code.';

  @override
  String get faqAccountContactQ => 'How do I contact support?';

  @override
  String get faqAccountContactA =>
      'Use the Call us button on the Help & support page. You can also open a category here and tap the support card at the bottom.';

  @override
  String get faqPaymentsFailedQ =>
      'My payment failed but the money left my account';

  @override
  String get faqPaymentsFailedA =>
      'If payment is pending, it usually auto-reverses within bank timelines. If not reversed, share payment ID with support and we will help track it.';

  @override
  String get faqPaymentsCouponQ => 'How do I use a coupon or offer?';

  @override
  String get faqPaymentsCouponA =>
      'Apply coupon codes during checkout on the payment screen. Valid offers are reflected instantly before you place the booking.';

  @override
  String get faqPaymentsRefundQ => 'Will I get a refund if I cancel?';

  @override
  String get faqPaymentsRefundA =>
      'Refund eligibility depends on cancellation timing and service terms. The exact policy is shown before you confirm cancellation.';

  @override
  String get faqQualityDamageQ => 'Is there a damage policy for service?';

  @override
  String get faqQualityDamageA =>
      'Yes. Report damage within 24 hours with photos and booking details. Claims are reviewed as per policy and partner verification.';

  @override
  String get faqQualityRateQ => 'How do I rate my partner?';

  @override
  String get faqQualityRateA =>
      'After service completion, open the booking and submit a rating with comments. Your feedback helps us maintain quality standards.';

  @override
  String get faqSafetyTrustQ => 'How can I trust your service?';

  @override
  String get faqSafetyTrustA =>
      'TaskTeddy verifies partners, tracks bookings, and monitors quality reports. We also offer in-app support for issue escalation.';

  @override
  String get faqSafetyVerifiedQ => 'Are TaskTeddy partners verified?';

  @override
  String get faqSafetyVerifiedA =>
      'Yes, we run onboarding checks including identity verification and basic service screening before activation.';

  @override
  String get faqSafetyShareQ =>
      'What does TaskTeddy share with partners about me?';

  @override
  String get faqSafetyShareA =>
      'Partners see only the details needed for service fulfillment, such as name, location, slot, and service notes.';

  @override
  String get faqSafetyUnsafeQ =>
      'I feel unsafe during a booking - what do I do?';

  @override
  String get faqSafetyUnsafeA =>
      'End the interaction immediately, move to a safe space, and call support from this page. In emergencies, contact local authorities first.';

  @override
  String get referCodeCopied => 'Referral code copied';

  @override
  String get referLinkCopied =>
      'Invite link copied. Share it with your friends.';

  @override
  String get referCouldNotOpenTerms => 'Could not open terms link';

  @override
  String get referShareLink => 'Share invite link';

  @override
  String get referCopyCode => 'Copy referral code';

  @override
  String get referTitle => 'Refer a friend to TaskTeddy';

  @override
  String get referGet100 => 'Get ₹100';

  @override
  String get referFriendGets =>
      'Your friend gets flat ₹50 off on their first TaskTeddy service.';

  @override
  String get referStep1 => 'Share the link with your friend';

  @override
  String get referStep2 => 'Your friend downloads the app with your link';

  @override
  String get referStep3 =>
      'They get ₹50 and you get ₹100 after their first completed booking';

  @override
  String get referReadTerms => 'Read our T&Cs to know more.';

  @override
  String get addrDeleteTitle => 'Delete address?';

  @override
  String get addrDeleteBody => 'This saved address will be removed.';

  @override
  String get addrDelete => 'Delete';

  @override
  String get addrMyAddresses => 'My Addresses';

  @override
  String get addrSubtitle =>
      'Save your delivery addresses for faster checkout. The default is used automatically.';

  @override
  String get addrSaveNew => 'Save new address';

  @override
  String get addrEmpty =>
      'No saved addresses yet. Save one to speed up checkout.';

  @override
  String addrLandmark(String landmark) {
    return 'Landmark: $landmark';
  }

  @override
  String get addrSetAsDefault => 'Set as default';

  @override
  String get addrLoadError => 'Couldn\'t load your addresses.';

  @override
  String get addrLabelHome => 'Home';

  @override
  String get addrLabelWork => 'Work';

  @override
  String get addrLabelOther => 'Other';

  @override
  String get addrErrLocationServices =>
      'Turn on location services to detect your address.';

  @override
  String get addrErrPermissionNeeded =>
      'Location permission is needed to detect your address.';

  @override
  String get addrErrEnablePermission =>
      'Enable location permission from app settings.';

  @override
  String get addrErrMockLocation =>
      'Mock location detected. Please use real device GPS.';

  @override
  String get addrSelectedLocation => 'Selected location';

  @override
  String get addrAddressDetected => 'Address detected';

  @override
  String get addrExactCoords => 'Exact coordinates selected';

  @override
  String get addrLocationDetected => 'Location detected';

  @override
  String get addrPickExact => 'Pick exact location';

  @override
  String get addrUseCurrent => 'Use current';

  @override
  String get addrUseThisLocation => 'Use this location';

  @override
  String get addrErrEnterDetails => 'Please enter your address details.';

  @override
  String get addrErrPincode => 'Pincode must be exactly 6 digits.';

  @override
  String get addrEditorAddTitle => 'Add Address Details';

  @override
  String get addrEditorEditTitle => 'Edit Address Details';

  @override
  String get addrSaveAddress => 'SAVE ADDRESS';

  @override
  String get addrLocateOnMap => 'Locate on map';

  @override
  String get addrLocateSubtitle => 'Use current location or tap the map pin.';

  @override
  String get addrChange => 'Change';

  @override
  String get addrUseCurrentLocation => 'Use current location';

  @override
  String get addrAddAddress => 'Add address';

  @override
  String get addrHouseLabel => 'House No. & Floor *';

  @override
  String get addrHouseHint => 'e.g. 216, B-14';

  @override
  String get addrBuildingLabel => 'Building & Block No. (Optional)';

  @override
  String get addrBuildingHint => 'Tower, block, wing, etc.';

  @override
  String get addrStreetLabel => 'Street / Area *';

  @override
  String get addrStreetHint => 'Street, locality or sector';

  @override
  String get addrCityLabel => 'City *';

  @override
  String get addrCityHint => 'Your city';

  @override
  String get addrLandmarkLabel => 'Landmark & Area Name (Optional)';

  @override
  String get addrLandmarkHint => 'Nearby known place';

  @override
  String get addrPincodeLabel => 'Pincode *';

  @override
  String get addrPincodeHint => '6-digit PIN';

  @override
  String get addrAddLabel => 'Add address label';

  @override
  String get addrSetDefaultTitle => 'Set as default address';

  @override
  String get addrSetDefaultSub => 'Used automatically at checkout.';

  @override
  String get tasksSortNewest => 'Newest';

  @override
  String get tasksSortDueSoon => 'Due soon';

  @override
  String get tasksSortBudgetHigh => 'Budget high';

  @override
  String get tasksNoTasksFound => 'No tasks found';

  @override
  String get tasksEmptySubtitle =>
      'Post a task and taskers nearby will send you offers.';

  @override
  String get taskBudgetFixed => 'Fixed Price';

  @override
  String get taskBudgetHourly => 'Hourly Rate';

  @override
  String get taskBudgetFixedHelper => 'One final budget for the complete task';

  @override
  String get taskBudgetHourlyHelper => 'Rate per hour, then add expected hours';

  @override
  String get taskUrgencyStandard => 'Standard';

  @override
  String get taskUrgencyPriority => 'Priority';

  @override
  String get taskUrgencyUrgent => 'Urgent';

  @override
  String get taskUrgencyStandardSub => 'Within normal timeline';

  @override
  String get taskUrgencyPrioritySub => 'Need faster responses';

  @override
  String get taskUrgencyUrgentSub => 'Immediate attention needed';

  @override
  String get taskReviewThanks => 'Thanks for your review!';

  @override
  String get taskAcceptOffer => 'Accept offer';

  @override
  String taskAcceptOfferBody(String name, int amount) {
    return 'Assign this task to $name for ₹$amount?\n\nOther offers will be automatically declined.';
  }

  @override
  String get taskOfferAccepted => 'Offer accepted successfully!';

  @override
  String get taskOfferDeclined => 'Offer declined';

  @override
  String get taskCancelledSuccess => 'Task cancelled successfully';

  @override
  String get taskYourTasker => 'Your tasker';

  @override
  String get taskJustNow => 'just now';

  @override
  String taskMinutesAgoFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count minutes ago',
      one: '1 minute ago',
    );
    return '$_temp0';
  }

  @override
  String taskHoursAgoFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours ago',
      one: '1 hour ago',
    );
    return '$_temp0';
  }

  @override
  String taskDaysAgoFull(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String get taskOnTheWay => 'Tasker on the way';

  @override
  String get taskLive => 'LIVE';

  @override
  String taskOnTheWaySince(String time) {
    return 'On the way since $time';
  }

  @override
  String taskLocationUpdated(String time) {
    return 'Location updated $time';
  }

  @override
  String get taskWaitingLocation => 'Waiting for a location update';

  @override
  String taskMetersAway(int meters) {
    return '$meters m away';
  }

  @override
  String taskKmAway(String km) {
    return '$km km away';
  }

  @override
  String get taskDetailsTitle => 'Task Details';

  @override
  String taskBidsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bids',
      one: '1 bid',
    );
    return '$_temp0';
  }

  @override
  String get taskLocationLabel => 'Location';

  @override
  String get taskOffers => 'Offers';

  @override
  String taskOffersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count offers',
      one: '1 offer',
    );
    return '$_temp0';
  }

  @override
  String get taskNoOffers => 'No offers yet — taskers will send offers soon';

  @override
  String get taskCompletionOtp => 'Completion OTP';

  @override
  String get taskCompletionOtpHint =>
      'Share this OTP with the tasker when they complete the task';

  @override
  String get taskEditTask => 'Edit Task';

  @override
  String get taskCancelTask => 'Cancel Task';

  @override
  String taskRateName(String name) {
    return 'Rate $name';
  }

  @override
  String get cancelReasonNoLongerNeeded => 'No longer needed';

  @override
  String get cancelReasonPostedByMistake => 'Posted by mistake';

  @override
  String get cancelReasonFoundElsewhere => 'Found help elsewhere';

  @override
  String get taskCancelTaskSheet => 'Cancel task';

  @override
  String taskCancelWhy(String title) {
    return 'Why are you cancelling \"$title\"?';
  }

  @override
  String get taskCancelAssignedWarning =>
      'This task is assigned. The tasker will be notified that you cancelled.';

  @override
  String get taskAddNoteOptional => 'Add a note (optional)';

  @override
  String get taskKeepTask => 'Keep task';

  @override
  String get taskReviewHint => 'Share a few words (optional)';

  @override
  String get taskSubmitReview => 'Submit review';

  @override
  String get taskFailedOpenChat => 'Failed to open chat';

  @override
  String get chatClosed => 'This chat is closed — the task is complete.';

  @override
  String get taskChat => 'Chat';

  @override
  String get taskStatusAccepted => 'Accepted';

  @override
  String get taskStatusRejected => 'Rejected';

  @override
  String get taskReject => 'Reject';

  @override
  String get taskAcceptBid => 'Accept Bid';

  @override
  String taskBidAmount(int amount) {
    return 'Bid: ₹$amount';
  }

  @override
  String get taskLocationUpdatedPosition =>
      'Location updated from your current position';

  @override
  String get taskMaxPhotos => 'You can add up to 6 photos';

  @override
  String get taskTakePhoto => 'Take a photo';

  @override
  String get taskChooseGallery => 'Choose from gallery';

  @override
  String get taskCameraError => 'Unable to open camera right now';

  @override
  String taskOnlyFirstPhotos(int count) {
    return 'Only first $count photo(s) were added';
  }

  @override
  String get taskGalleryError => 'Unable to open gallery right now';

  @override
  String taskFieldRequired(String field) {
    return '$field is required';
  }

  @override
  String get taskFieldTitle => 'Task title';

  @override
  String get taskFieldDescription => 'Description';

  @override
  String get taskFieldBudget => 'Budget';

  @override
  String get taskFieldLocation => 'Location';

  @override
  String get taskTitleMin => 'Title should be at least 8 characters';

  @override
  String get taskDescMin => 'Add more details so taskers can quote correctly';

  @override
  String get taskBudgetInvalid => 'Enter a valid budget amount';

  @override
  String get taskBudgetInsightPrompt =>
      'Enter budget and location to check market range';

  @override
  String taskBudgetSuggested(String amount) {
    return 'Suggested: ₹$amount';
  }

  @override
  String taskBudgetRecommended(String min, String max) {
    return 'Recommended in your area: ₹$min - ₹$max';
  }

  @override
  String get taskBudgetInsightOk => 'Budget insight fetched successfully';

  @override
  String get taskBudgetInsightUnavailable =>
      'Market insight is currently unavailable. You can still post your task.';

  @override
  String get taskCompleteRequired => 'Please complete the required fields';

  @override
  String get taskPhotosUploadFailed =>
      'Photos could not be uploaded — posting without them.';

  @override
  String get taskBriefTagline =>
      'Write a clear brief to get better bids from verified taskers';

  @override
  String get taskGoodBriefs =>
      'Good briefs close faster. Include scope, access details, and a realistic budget.';

  @override
  String get taskSecBasics => 'Task Basics';

  @override
  String get taskSecBasicsSub => 'Category and task description';

  @override
  String get taskCategoryLabel => 'Category';

  @override
  String get taskTitleLabel => 'Task Title *';

  @override
  String get taskTitleHint => 'e.g. Deep clean 2BHK apartment';

  @override
  String get taskDescLabel => 'Description *';

  @override
  String get taskDescHint =>
      'Mention size, floors, tools needed, and anything taskers should know before accepting.';

  @override
  String get taskSecPhotos => 'Task Photos';

  @override
  String get taskSecPhotosSub =>
      'Add up to 6 real photos to improve trust and faster bids';

  @override
  String get taskNoPhotos => 'No photos added yet';

  @override
  String taskPhotosAdded(int count) {
    return '$count/6 photo(s) added';
  }

  @override
  String get taskAddPhotos => 'Add Photos';

  @override
  String get taskPhotoHint =>
      'Show task area, tools/materials, and current condition.';

  @override
  String get taskSecBudget => 'Budget & Priority';

  @override
  String get taskSecBudgetSub => 'Set the price format and urgency';

  @override
  String get taskBudgetFormat => 'Budget Format';

  @override
  String get taskTotalBudget => 'Total Budget (₹) *';

  @override
  String get taskHourlyBudget => 'Hourly Budget (₹) *';

  @override
  String get taskHoursLabel => 'Hours *';

  @override
  String get taskRequiredShort => 'Required';

  @override
  String get taskCheckMarket => 'Check Market Range';

  @override
  String get taskUrgencyLabel => 'Urgency';

  @override
  String get taskSecLocation => 'Location & Schedule';

  @override
  String get taskSecLocationSub => 'Where and when the task should happen';

  @override
  String get taskLocationMatchHint =>
      'Use your current phone location for faster task matching.';

  @override
  String taskGps(String lat, String lng) {
    return 'GPS: $lat, $lng';
  }

  @override
  String get taskServiceLocationLabel => 'Service Location *';

  @override
  String get taskLocationHint => 'Area, City';

  @override
  String get taskLandmarkLabel2 => 'Landmark (Optional)';

  @override
  String get taskLandmarkHint2 => 'Nearby mall, metro station, gate number...';

  @override
  String get taskDeadlineLabel => 'Deadline Date *';

  @override
  String get taskPreferredTime => 'Preferred Time';

  @override
  String get taskAnytime => 'Anytime';

  @override
  String get taskSecNotes => 'Additional Notes';

  @override
  String get taskSecNotesSub =>
      'Optional details that can help taskers prepare';

  @override
  String get taskNotesHint =>
      'Parking info, entry rules, tools available, preferred communication...';

  @override
  String get taskSecSummary => 'Live Summary';

  @override
  String get taskSecSummarySub => 'Preview how your posting will look';

  @override
  String get taskUntitled => 'Untitled Task';

  @override
  String get taskSetBudget => 'Set budget';

  @override
  String get taskLocationPending => 'Location pending';

  @override
  String get taskNoPhotosShort => 'No photos';

  @override
  String taskPhotosCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get taskUploadingPhotos => 'Uploading Photos...';

  @override
  String get taskPostTask => 'Post Task';

  @override
  String get taskStatusOpen => 'Open';

  @override
  String get taskStatusAssigned => 'Assigned';

  @override
  String get taskStatusInProgress => 'In Progress';

  @override
  String get taskStatusCompleted => 'Completed';

  @override
  String get taskStatusCancelled => 'Cancelled';

  @override
  String get taskStatusUnderReview => 'Under Review';

  @override
  String get taskStatusNotApproved => 'Not Approved';

  @override
  String get taskUnderReviewTitle => 'Under review';

  @override
  String get taskUnderReviewNote =>
      'Our team is reviewing this task — it usually goes live within 5 minutes.';

  @override
  String get taskNotApprovedTitle => 'Not approved';

  @override
  String get taskNotApprovedNote => 'This task wasn\'t approved during review.';

  @override
  String taskRejectedReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get taskPostAgain => 'Post again';

  @override
  String get taskPostedTitle => 'Task submitted for review';

  @override
  String taskPostedBody(String title) {
    return '\"$title\"';
  }

  @override
  String get taskPostedReviewNote =>
      'Our team reviews every task for quality and safety — usually approved within 5 minutes. You\'ll be notified when it goes live.';

  @override
  String get taskViewMyTasks => 'View My Tasks';

  @override
  String get taskPostAnother => 'Post Another Task';

  @override
  String get taskUpdatedSuccess => 'Task updated successfully';

  @override
  String get taskEditTitle => 'Task Title';

  @override
  String get taskEditTitleHint => 'e.g. Fix leaking tap';

  @override
  String get taskEditTitleRequired => 'Title is required';

  @override
  String get taskEditDescHint => 'Describe the issue...';

  @override
  String get taskEditDescRequired => 'Description is required';

  @override
  String get taskEditDescMin => 'Add more details';

  @override
  String get taskEditLocHint => 'Where should this be done?';

  @override
  String get taskEditLocRequired => 'Location is required';

  @override
  String get taskEditBudgetLabel => 'Budget (₹)';

  @override
  String get taskEditBudgetHint => 'e.g. 500';

  @override
  String get taskEditBudgetRequired => 'Budget is required';

  @override
  String get taskEditBudgetInvalid => 'Enter a valid amount';

  @override
  String get taskSaveChanges => 'Save Changes';

  @override
  String taskDue(String date) {
    return 'Due $date';
  }

  @override
  String get commonChooseGallery => 'Choose from gallery';

  @override
  String get commonTakePhoto => 'Take a photo';

  @override
  String get profileChangePhoto => 'Change photo';

  @override
  String get profilePhotoUpdated => 'Profile photo updated';

  @override
  String reputationSummary(int jobs, int reliability) {
    return '$jobs jobs • $reliability% reliable';
  }

  @override
  String get taskTaskerCancelledReview =>
      'Your tasker cancelled — please choose another offer.';
}
