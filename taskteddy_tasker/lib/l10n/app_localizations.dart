import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
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
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n? of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n);
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

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
    Locale('hi'),
    Locale('pa')
  ];

  /// No description provided for @walletDuesSettled.
  ///
  /// In en, this message translates to:
  /// **'Dues settled — you can browse again.'**
  String get walletDuesSettled;

  /// Cash-dues pause screen title
  ///
  /// In en, this message translates to:
  /// **'Browsing paused'**
  String get browseDuesTitle;

  /// Cash-dues pause screen body
  ///
  /// In en, this message translates to:
  /// **'You have unsettled platform fees from cash jobs. Settle your wallet to continue browsing tasks.'**
  String get browseDuesBody;

  /// No description provided for @browseDuesAmount.
  ///
  /// In en, this message translates to:
  /// **'Dues: ₹{amount}'**
  String browseDuesAmount(String amount);

  /// Settle dues button
  ///
  /// In en, this message translates to:
  /// **'Settle now'**
  String get browseSettleNow;

  /// Login screen tagline under the wordmark
  ///
  /// In en, this message translates to:
  /// **'Find tasks & earn money on your schedule!'**
  String get appTagline;

  /// Bottom nav label for the dashboard tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom nav label for the browse tasks tab
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get navBrowse;

  /// Bottom nav label for the applications tab
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get navApplied;

  /// Bottom nav label for the wallet/earnings tab
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get navEarnings;

  /// Bottom nav label for the profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Dashboard greeting before noon
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// Dashboard greeting in the afternoon
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// Dashboard greeting in the evening
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// Availability chip when the tasker is available
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// Availability chip when the tasker is unavailable
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get statusOffline;

  /// Availability bar subtitle when the tasker is online
  ///
  /// In en, this message translates to:
  /// **'Available for new tasks'**
  String get dashAvailableForWork;

  /// Availability bar subtitle when the tasker is offline
  ///
  /// In en, this message translates to:
  /// **'Tap to go online and receive tasks'**
  String get dashTapToGoOnline;

  /// Stat chip label for the reliability percentage
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get dashStatReliability;

  /// Stat chip label for the tasker reputation level
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get dashStatLevel;

  /// Default reputation level label when none is set
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get dashLevelNew;

  /// Dashboard earnings card title
  ///
  /// In en, this message translates to:
  /// **'Earnings Overview'**
  String get earningsOverview;

  /// Wallet label / button
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// Earnings period: today
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Earnings period: this week
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// Earnings period: this month
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// Stat tile label for rating
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get statRating;

  /// Stat tile label for tasks completed
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get statTasks;

  /// Stat tile label for rank
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get statRank;

  /// Stat tile label for TaskCoins
  ///
  /// In en, this message translates to:
  /// **'Coins'**
  String get statCoins;

  /// Quick action / browse header
  ///
  /// In en, this message translates to:
  /// **'Browse Tasks'**
  String get qaBrowseTasks;

  /// Quick action for applications
  ///
  /// In en, this message translates to:
  /// **'Applications'**
  String get qaApplications;

  /// Quick action for completed tasks
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get qaCompleted;

  /// Quick action for messages
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get qaMessages;

  /// Dashboard section header for nearby tasks
  ///
  /// In en, this message translates to:
  /// **'Tasks Near You'**
  String get tasksNearYou;

  /// Dashboard section header for active jobs
  ///
  /// In en, this message translates to:
  /// **'My Active Jobs'**
  String get myActiveJobs;

  /// Dashboard section header for bookings
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get myBookings;

  /// Link to open the full list
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// Empty state when no tasks are available
  ///
  /// In en, this message translates to:
  /// **'No tasks available right now'**
  String get noTasksAvailable;

  /// Empty state when there are no active jobs
  ///
  /// In en, this message translates to:
  /// **'No active jobs'**
  String get noActiveJobs;

  /// Browse search field placeholder
  ///
  /// In en, this message translates to:
  /// **'Search tasks, location...'**
  String get searchTasksHint;

  /// Browse filter sheet title
  ///
  /// In en, this message translates to:
  /// **'Filter Tasks'**
  String get filterTasks;

  /// Browse filter section: budget range
  ///
  /// In en, this message translates to:
  /// **'Budget Range'**
  String get budgetRange;

  /// Button that applies the selected filters
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// Label for a task budget
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// Button to quickly apply to a task
  ///
  /// In en, this message translates to:
  /// **'Quick Apply'**
  String get quickApply;

  /// Button shown to unverified taskers on a task card
  ///
  /// In en, this message translates to:
  /// **'Get verified to apply'**
  String get getVerifiedToApply;

  /// Title of the KYC required dialog
  ///
  /// In en, this message translates to:
  /// **'Verification required'**
  String get verificationRequired;

  /// Body of the KYC required dialog
  ///
  /// In en, this message translates to:
  /// **'Complete your KYC verification to start applying to tasks.'**
  String get completeKyc;

  /// Button to open verification
  ///
  /// In en, this message translates to:
  /// **'Get verified'**
  String get getVerified;

  /// Empty state for browse results
  ///
  /// In en, this message translates to:
  /// **'No tasks found'**
  String get noTasksFound;

  /// Hint under the browse empty state
  ///
  /// In en, this message translates to:
  /// **'Try adjusting filters or search'**
  String get tryAdjustingFilters;

  /// Heading on the login sheet
  ///
  /// In en, this message translates to:
  /// **'Log in or Sign up'**
  String get loginOrSignup;

  /// Phone field placeholder
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// Validation error for the phone field
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 10-digit mobile number'**
  String get enterValidMobile;

  /// Validation error for the OTP field
  ///
  /// In en, this message translates to:
  /// **'Please enter full 6-digit OTP'**
  String get enterFullOtp;

  /// Button to change the phone number after OTP is sent
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get changeNumber;

  /// Button to resend the OTP
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// Countdown label before the OTP can be resent
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String resendInSeconds(int seconds);

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Settings row that opens the language chooser
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Title of the language chooser sheet
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// Language name: English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// Language name: Hindi
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get langHindi;

  /// Language name: Punjabi
  ///
  /// In en, this message translates to:
  /// **'ਪੰਜਾਬੀ (Punjabi)'**
  String get langPunjabi;

  /// Settings section title for safety
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get safety;

  /// Settings row / screen title for blocked users
  ///
  /// In en, this message translates to:
  /// **'Blocked Users'**
  String get blockedUsers;

  /// Trailing label meaning manage
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// Empty state for the blocked users screen
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// Settings section header
  ///
  /// In en, this message translates to:
  /// **'WORK PREFERENCES'**
  String get workPreferences;

  /// Settings row for availability
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// Common action: apply
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get actionApply;

  /// Common action: accept
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get actionAccept;

  /// Common action: decline
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get actionDecline;

  /// Common action: cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// Common action: save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// Common action: retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// Common action: continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Common action: submit
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get actionSubmit;

  /// Common action: OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get actionOk;

  /// Common action: yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get actionYes;

  /// Common action: no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get actionNo;

  /// Common action: close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// Common action: report
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get actionReport;

  /// Common action: block
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get actionBlock;

  /// Common action: on my way
  ///
  /// In en, this message translates to:
  /// **'On my way'**
  String get actionOnMyWay;

  /// No description provided for @bankTitle.
  ///
  /// In en, this message translates to:
  /// **'Bank & Payments'**
  String get bankTitle;

  /// No description provided for @bankPayoutMethods.
  ///
  /// In en, this message translates to:
  /// **'Payout Methods'**
  String get bankPayoutMethods;

  /// No description provided for @bankNoMethods.
  ///
  /// In en, this message translates to:
  /// **'No payout methods added yet.'**
  String get bankNoMethods;

  /// No description provided for @bankSetDefaultSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} set as default payout method'**
  String bankSetDefaultSuccess(String name);

  /// No description provided for @bankAddPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Add Payment Method'**
  String get bankAddPaymentMethod;

  /// No description provided for @profileMyApplications.
  ///
  /// In en, this message translates to:
  /// **'My Applications'**
  String get profileMyApplications;

  /// No description provided for @profileTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get profileTotal;

  /// No description provided for @profilePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get profilePending;

  /// No description provided for @profileAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get profileAccepted;

  /// Applications tab: completed jobs
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get profileCompleted;

  /// No description provided for @profileRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get profileRejected;

  /// No description provided for @profileAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get profileAll;

  /// No description provided for @profileNothingHere.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get profileNothingHere;

  /// No description provided for @profileBrowseTasksStart.
  ///
  /// In en, this message translates to:
  /// **'Browse tasks to get started'**
  String get profileBrowseTasksStart;

  /// No description provided for @profileWithdrawBid.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Bid'**
  String get profileWithdrawBid;

  /// No description provided for @profileWithdrawBidConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to withdraw this bid?'**
  String get profileWithdrawBidConfirm;

  /// No description provided for @profileWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get profileWithdraw;

  /// No description provided for @profileBidWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Bid withdrawn'**
  String get profileBidWithdrawn;

  /// No description provided for @profileCompleteTask.
  ///
  /// In en, this message translates to:
  /// **'Complete Task'**
  String get profileCompleteTask;

  /// No description provided for @profileCompleteTaskOtpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter the OTP shared by the customer to complete this task.'**
  String get profileCompleteTaskOtpPrompt;

  /// No description provided for @profileOtp.
  ///
  /// In en, this message translates to:
  /// **'OTP'**
  String get profileOtp;

  /// No description provided for @profileEnterOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP'**
  String get profileEnterOtp;

  /// Banner in a chat whose task is finished
  ///
  /// In en, this message translates to:
  /// **'This chat is closed — the task is finished.'**
  String get chatClosed;

  /// No description provided for @walletMyWallet.
  ///
  /// In en, this message translates to:
  /// **'My Wallet'**
  String get walletMyWallet;

  /// No description provided for @walletTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total Balance'**
  String get walletTotalBalance;

  /// No description provided for @walletAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get walletAvailable;

  /// No description provided for @walletEarnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get walletEarnings;

  /// No description provided for @walletTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get walletTransactions;

  /// No description provided for @walletWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get walletWithdraw;

  /// No description provided for @walletTasksDone.
  ///
  /// In en, this message translates to:
  /// **'Tasks Done'**
  String get walletTasksDone;

  /// Empty-state title on the wallet transactions tab
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get walletNoTransactions;

  /// Empty-state body on the wallet transactions tab
  ///
  /// In en, this message translates to:
  /// **'Your earnings and withdrawals will appear here.'**
  String get walletNoTransactionsBody;

  /// No description provided for @walletPlatformDues.
  ///
  /// In en, this message translates to:
  /// **'Platform dues: ₹{amount}'**
  String walletPlatformDues(String amount);

  /// No description provided for @walletDuesBody.
  ///
  /// In en, this message translates to:
  /// **'This is the commission owed on cash jobs. Keep your wallet topped up to clear it.'**
  String get walletDuesBody;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @commonChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get commonChooseGallery;

  /// No description provided for @commonTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get commonTakePhoto;

  /// No description provided for @profileStatusNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not Selected'**
  String get profileStatusNotSelected;

  /// No description provided for @profileStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get profileStatusUnderReview;

  /// No description provided for @profileApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get profileApplied;

  /// No description provided for @profileStepDecision.
  ///
  /// In en, this message translates to:
  /// **'Decision'**
  String get profileStepDecision;

  /// No description provided for @profileYourBid.
  ///
  /// In en, this message translates to:
  /// **'Your Bid'**
  String get profileYourBid;

  /// No description provided for @profileTaskBudget.
  ///
  /// In en, this message translates to:
  /// **'Task Budget'**
  String get profileTaskBudget;

  /// No description provided for @profileYouEarn.
  ///
  /// In en, this message translates to:
  /// **'You Earn'**
  String get profileYouEarn;

  /// No description provided for @profileStartTask.
  ///
  /// In en, this message translates to:
  /// **'Start Task'**
  String get profileStartTask;

  /// No description provided for @profileAppliedAgo.
  ///
  /// In en, this message translates to:
  /// **'Applied {time}'**
  String profileAppliedAgo(String time);

  /// No description provided for @profileMyProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get profileMyProfile;

  /// No description provided for @profileReviewsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String profileReviewsCount(int count);

  /// No description provided for @profileTasksDone.
  ///
  /// In en, this message translates to:
  /// **'Tasks Done'**
  String get profileTasksDone;

  /// No description provided for @profileEarned.
  ///
  /// In en, this message translates to:
  /// **'Earned'**
  String get profileEarned;

  /// No description provided for @profileAvailableForTasks.
  ///
  /// In en, this message translates to:
  /// **'Available for Tasks'**
  String get profileAvailableForTasks;

  /// No description provided for @profileNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not Available'**
  String get profileNotAvailable;

  /// No description provided for @profileVisibleToCustomers.
  ///
  /// In en, this message translates to:
  /// **'You\'re visible to customers'**
  String get profileVisibleToCustomers;

  /// No description provided for @profileWontReceiveTasks.
  ///
  /// In en, this message translates to:
  /// **'You won\'t receive new tasks'**
  String get profileWontReceiveTasks;

  /// No description provided for @profileCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get profileCompletion;

  /// No description provided for @profileAvgResponse.
  ///
  /// In en, this message translates to:
  /// **'Avg Response'**
  String get profileAvgResponse;

  /// No description provided for @profileMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get profileMemberSince;

  /// No description provided for @profileAboutMe.
  ///
  /// In en, this message translates to:
  /// **'About Me'**
  String get profileAboutMe;

  /// No description provided for @profileEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profileEdit;

  /// No description provided for @profileMySkills.
  ///
  /// In en, this message translates to:
  /// **'My Skills'**
  String get profileMySkills;

  /// No description provided for @profileMyWork.
  ///
  /// In en, this message translates to:
  /// **'My Work'**
  String get profileMyWork;

  /// No description provided for @profileAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get profileAdd;

  /// No description provided for @profileViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get profileViewAll;

  /// No description provided for @profileSecAccount.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get profileSecAccount;

  /// No description provided for @profileSecWork.
  ///
  /// In en, this message translates to:
  /// **'WORK'**
  String get profileSecWork;

  /// No description provided for @profileSecSupportLegal.
  ///
  /// In en, this message translates to:
  /// **'SUPPORT & LEGAL'**
  String get profileSecSupportLegal;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get profileEditProfile;

  /// No description provided for @profileVerificationDocuments.
  ///
  /// In en, this message translates to:
  /// **'Verification & Documents'**
  String get profileVerificationDocuments;

  /// No description provided for @profileBankPayment.
  ///
  /// In en, this message translates to:
  /// **'Bank & Payment'**
  String get profileBankPayment;

  /// No description provided for @profileSetWorkingHours.
  ///
  /// In en, this message translates to:
  /// **'Set your working hours'**
  String get profileSetWorkingHours;

  /// No description provided for @profileWorkPortfolio.
  ///
  /// In en, this message translates to:
  /// **'Work Portfolio'**
  String get profileWorkPortfolio;

  /// No description provided for @profileShowcaseWork.
  ///
  /// In en, this message translates to:
  /// **'Showcase your best work'**
  String get profileShowcaseWork;

  /// No description provided for @profilePhotoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String profilePhotoCount(int count);

  /// No description provided for @profileCompletedTasks.
  ///
  /// In en, this message translates to:
  /// **'Completed Tasks'**
  String get profileCompletedTasks;

  /// No description provided for @profileMyReviews.
  ///
  /// In en, this message translates to:
  /// **'My Reviews'**
  String get profileMyReviews;

  /// No description provided for @profileEarningsPayouts.
  ///
  /// In en, this message translates to:
  /// **'Earnings & Payouts'**
  String get profileEarningsPayouts;

  /// No description provided for @profileHelpSupport.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get profileHelpSupport;

  /// No description provided for @profileTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get profileTerms;

  /// No description provided for @profilePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get profilePrivacy;

  /// No description provided for @profileRateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us on Play Store'**
  String get profileRateUs;

  /// No description provided for @profileReferEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn ₹200'**
  String get profileReferEarn;

  /// No description provided for @profileSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get profileSignOut;

  /// No description provided for @profileVersion.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String profileVersion(String version);

  /// No description provided for @profileRedirectTitle.
  ///
  /// In en, this message translates to:
  /// **'Redirect to External Link'**
  String get profileRedirectTitle;

  /// No description provided for @profileRedirectBody.
  ///
  /// In en, this message translates to:
  /// **'You are being redirected to an external website:\n\n{url}\n\nDo you want to continue?'**
  String profileRedirectBody(String url);

  /// No description provided for @profileCouldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get profileCouldNotOpenLink;

  /// No description provided for @profileUploadingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo…'**
  String get profileUploadingPhoto;

  /// No description provided for @profilePictureUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated'**
  String get profilePictureUpdated;

  /// No description provided for @profileUpdatePicture.
  ///
  /// In en, this message translates to:
  /// **'Update Profile Picture'**
  String get profileUpdatePicture;

  /// No description provided for @profileEditAboutMe.
  ///
  /// In en, this message translates to:
  /// **'Edit About Me'**
  String get profileEditAboutMe;

  /// No description provided for @profileWriteAboutYourself.
  ///
  /// In en, this message translates to:
  /// **'Write about yourself...'**
  String get profileWriteAboutYourself;

  /// No description provided for @profileBioUpdated.
  ///
  /// In en, this message translates to:
  /// **'Bio updated'**
  String get profileBioUpdated;

  /// No description provided for @profileEditSkills.
  ///
  /// In en, this message translates to:
  /// **'Edit Skills'**
  String get profileEditSkills;

  /// No description provided for @profileSaveSkills.
  ///
  /// In en, this message translates to:
  /// **'Save Skills'**
  String get profileSaveSkills;

  /// No description provided for @profileSkillsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Skills updated'**
  String get profileSkillsUpdated;

  /// No description provided for @profileNoCoins.
  ///
  /// In en, this message translates to:
  /// **'No TaskCoins'**
  String get profileNoCoins;

  /// No description provided for @profileNoCoinsBody.
  ///
  /// In en, this message translates to:
  /// **'You have 0 TaskCoins in your wallet to redeem.'**
  String get profileNoCoinsBody;

  /// No description provided for @profileRedeemCoins.
  ///
  /// In en, this message translates to:
  /// **'Redeem TaskCoins'**
  String get profileRedeemCoins;

  /// No description provided for @profileCoinsValue.
  ///
  /// In en, this message translates to:
  /// **'{coins} Coins = ₹{coins}'**
  String profileCoinsValue(int coins);

  /// No description provided for @profileCoinsCredited.
  ///
  /// In en, this message translates to:
  /// **'Coins will be credited to your default payout method.'**
  String get profileCoinsCredited;

  /// No description provided for @profileCoinsWillCredit.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} will be credited to your account'**
  String profileCoinsWillCredit(int amount);

  /// No description provided for @profileRedeemAll.
  ///
  /// In en, this message translates to:
  /// **'Redeem All'**
  String get profileRedeemAll;

  /// No description provided for @profileAddPhotosWork.
  ///
  /// In en, this message translates to:
  /// **'Add photos of your work'**
  String get profileAddPhotosWork;

  /// No description provided for @profilePortfolioHelps.
  ///
  /// In en, this message translates to:
  /// **'A strong portfolio helps you win more jobs'**
  String get profilePortfolioHelps;

  /// No description provided for @profileNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get profileNotSet;

  /// No description provided for @profileEveryDay.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get profileEveryDay;

  /// No description provided for @profileHoursVary.
  ///
  /// In en, this message translates to:
  /// **'hours vary'**
  String get profileHoursVary;

  /// No description provided for @walletWithdrawMoney.
  ///
  /// In en, this message translates to:
  /// **'Withdraw Money'**
  String get walletWithdrawMoney;

  /// No description provided for @walletAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get walletAmount;

  /// No description provided for @walletAvailableBalance.
  ///
  /// In en, this message translates to:
  /// **'Available: ₹{amount}'**
  String walletAvailableBalance(String amount);

  /// No description provided for @walletEnterValidAmount.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid amount'**
  String get walletEnterValidAmount;

  /// No description provided for @walletInsufficientBalance.
  ///
  /// In en, this message translates to:
  /// **'Insufficient balance'**
  String get walletInsufficientBalance;

  /// No description provided for @walletWithdrawalRequested.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal of ₹{amount} requested!'**
  String walletWithdrawalRequested(String amount);

  /// No description provided for @walletNoEarnings7Days.
  ///
  /// In en, this message translates to:
  /// **'No earnings in the last 7 days'**
  String get walletNoEarnings7Days;

  /// No description provided for @walletEarningsLast7.
  ///
  /// In en, this message translates to:
  /// **'Earnings - Last 7 Days'**
  String get walletEarningsLast7;

  /// No description provided for @walletTotalEarned.
  ///
  /// In en, this message translates to:
  /// **'Total Earned'**
  String get walletTotalEarned;

  /// No description provided for @walletJobsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Jobs Completed'**
  String get walletJobsCompleted;

  /// No description provided for @walletAvgPerJob.
  ///
  /// In en, this message translates to:
  /// **'Average per Job'**
  String get walletAvgPerJob;

  /// No description provided for @verifTitle.
  ///
  /// In en, this message translates to:
  /// **'Verification & Documents'**
  String get verifTitle;

  /// No description provided for @verifProgress.
  ///
  /// In en, this message translates to:
  /// **'Verification Progress'**
  String get verifProgress;

  /// No description provided for @verifDocsVerified.
  ///
  /// In en, this message translates to:
  /// **'{verified} of {total} documents verified'**
  String verifDocsVerified(int verified, int total);

  /// No description provided for @verifDocuments.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENTS'**
  String get verifDocuments;

  /// No description provided for @verifAadhaar.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Card'**
  String get verifAadhaar;

  /// No description provided for @verifAadhaarUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload Aadhaar for identity verification'**
  String get verifAadhaarUpload;

  /// No description provided for @verifPan.
  ///
  /// In en, this message translates to:
  /// **'PAN Card'**
  String get verifPan;

  /// No description provided for @verifPanUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload PAN for tax purposes'**
  String get verifPanUpload;

  /// No description provided for @verifUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get verifUnderReview;

  /// No description provided for @verifAddressProof.
  ///
  /// In en, this message translates to:
  /// **'Address Proof'**
  String get verifAddressProof;

  /// No description provided for @verifAddressVerified.
  ///
  /// In en, this message translates to:
  /// **'Address verified successfully'**
  String get verifAddressVerified;

  /// No description provided for @verifAddressUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload electricity bill or rent agreement'**
  String get verifAddressUpload;

  /// No description provided for @verifSelfie.
  ///
  /// In en, this message translates to:
  /// **'Selfie Verification'**
  String get verifSelfie;

  /// No description provided for @verifIdentityConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Identity confirmed'**
  String get verifIdentityConfirmed;

  /// No description provided for @verifSelfieUpload.
  ///
  /// In en, this message translates to:
  /// **'Capture a selfie to confirm identity'**
  String get verifSelfieUpload;

  /// No description provided for @verifUnlockPremium.
  ///
  /// In en, this message translates to:
  /// **'Complete all verifications to unlock premium tasks and higher payouts.'**
  String get verifUnlockPremium;

  /// No description provided for @verifStatusVerified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verifStatusVerified;

  /// No description provided for @verifStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get verifStatusPending;

  /// No description provided for @verifStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get verifStatusRejected;

  /// No description provided for @verifStatusUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get verifStatusUpload;

  /// No description provided for @verifAlreadyVerified.
  ///
  /// In en, this message translates to:
  /// **'{title} is already verified!'**
  String verifAlreadyVerified(String title);

  /// No description provided for @verifUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload {title}'**
  String verifUploadTitle(String title);

  /// No description provided for @verifUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading {title}…'**
  String verifUploading(String title);

  /// No description provided for @verifSubmitted.
  ///
  /// In en, this message translates to:
  /// **'{title} submitted. Our team will review it shortly.'**
  String verifSubmitted(String title);

  /// No description provided for @availSaveSchedule.
  ///
  /// In en, this message translates to:
  /// **'Save Schedule'**
  String get availSaveSchedule;

  /// No description provided for @availSaved.
  ///
  /// In en, this message translates to:
  /// **'Availability saved'**
  String get availSaved;

  /// No description provided for @availEndAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get availEndAfterStart;

  /// No description provided for @availStartTime.
  ///
  /// In en, this message translates to:
  /// **'Start time'**
  String get availStartTime;

  /// No description provided for @availEndTime.
  ///
  /// In en, this message translates to:
  /// **'End time'**
  String get availEndTime;

  /// No description provided for @availYourWeeklyHours.
  ///
  /// In en, this message translates to:
  /// **'Your weekly hours'**
  String get availYourWeeklyHours;

  /// No description provided for @availNotSetTap.
  ///
  /// In en, this message translates to:
  /// **'Not set - tap to add working hours'**
  String get availNotSetTap;

  /// No description provided for @availStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get availStart;

  /// No description provided for @availEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get availEnd;

  /// No description provided for @availAvailableDay.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get availAvailableDay;

  /// No description provided for @availOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get availOff;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String timeWeeksAgo(int count);

  /// No description provided for @msgSearchChats.
  ///
  /// In en, this message translates to:
  /// **'Search chats…'**
  String get msgSearchChats;

  /// No description provided for @msgNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get msgNoResults;

  /// No description provided for @msgNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get msgNoConversations;

  /// No description provided for @msgTryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get msgTryDifferentSearch;

  /// No description provided for @msgChatsWillAppear.
  ///
  /// In en, this message translates to:
  /// **'When you start a task,\nyour chats will appear here.'**
  String get msgChatsWillAppear;

  /// No description provided for @msgTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open chat'**
  String get msgTapToOpen;

  /// No description provided for @msgYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get msgYesterday;

  /// No description provided for @msgSayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello!'**
  String get msgSayHello;

  /// No description provided for @msgStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation and\nget things moving.'**
  String get msgStartConversation;

  /// No description provided for @msgTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get msgTakePhoto;

  /// No description provided for @msgErrorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image: {error}'**
  String msgErrorSelectingImage(String error);

  /// No description provided for @msgCouldNotSend.
  ///
  /// In en, this message translates to:
  /// **'Could not send message'**
  String get msgCouldNotSend;

  /// No description provided for @msgMessageCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get msgMessageCopied;

  /// No description provided for @msgTypeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get msgTypeMessage;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifTitle;

  /// No description provided for @notifUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notifUnreadCount(int count);

  /// No description provided for @notifAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get notifAllCaughtUp;

  /// No description provided for @notifMarkAll.
  ///
  /// In en, this message translates to:
  /// **'Mark all'**
  String get notifMarkAll;

  /// No description provided for @notifNoNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get notifNoNotifications;

  /// No description provided for @notifEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Job leads, bookings and payouts show up here'**
  String get notifEmptyBody;

  /// No description provided for @notifSomethingWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get notifSomethingWrong;

  /// No description provided for @notifJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notifJustNow;

  /// No description provided for @editProfileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get editProfileUpdated;

  /// No description provided for @editProfileFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile: {error}'**
  String editProfileFailed(String error);

  /// No description provided for @editFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get editFullName;

  /// No description provided for @editFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get editFullNameHint;

  /// No description provided for @editNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get editNameRequired;

  /// No description provided for @editEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editEmail;

  /// No description provided for @editEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get editEmailHint;

  /// No description provided for @editEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get editEmailRequired;

  /// No description provided for @editEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email'**
  String get editEmailInvalid;

  /// No description provided for @editPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get editPhone;

  /// No description provided for @editPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number'**
  String get editPhoneHint;

  /// No description provided for @editPhoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone is required'**
  String get editPhoneRequired;

  /// No description provided for @editCity.
  ///
  /// In en, this message translates to:
  /// **'City / Location'**
  String get editCity;

  /// No description provided for @editCityHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your city'**
  String get editCityHint;

  /// No description provided for @editCityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get editCityRequired;

  /// No description provided for @editSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get editSaveChanges;

  /// No description provided for @splashPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing TaskTeddy'**
  String get splashPreparing;

  /// No description provided for @splashGettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting everything ready...'**
  String get splashGettingReady;

  /// No description provided for @splashGettingThingsReady.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready...'**
  String get splashGettingThingsReady;

  /// No description provided for @splashLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off. Continuing...'**
  String get splashLocationOff;

  /// No description provided for @splashLocationSkipped.
  ///
  /// In en, this message translates to:
  /// **'Location permission skipped. Continuing...'**
  String get splashLocationSkipped;

  /// No description provided for @splashLocationLocked.
  ///
  /// In en, this message translates to:
  /// **'Location locked: {label}'**
  String splashLocationLocked(String label);

  /// No description provided for @splashLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch location. Continuing...'**
  String get splashLocationFailed;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @completedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'No completed tasks yet.\nYour finished work will appear here.'**
  String get completedEmptyBody;

  /// No description provided for @reviewsRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent Reviews'**
  String get reviewsRecent;

  /// No description provided for @reviewsNone.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet'**
  String get reviewsNone;

  /// No description provided for @portfolioFull.
  ///
  /// In en, this message translates to:
  /// **'Portfolio is full ({max} photos max)'**
  String portfolioFull(int max);

  /// No description provided for @portfolioAddCaption.
  ///
  /// In en, this message translates to:
  /// **'Add a caption'**
  String get portfolioAddCaption;

  /// No description provided for @portfolioCaptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional - e.g. Kitchen deep clean'**
  String get portfolioCaptionHint;

  /// No description provided for @portfolioSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get portfolioSkip;

  /// No description provided for @portfolioPhotoAdded.
  ///
  /// In en, this message translates to:
  /// **'Photo added to portfolio'**
  String get portfolioPhotoAdded;

  /// No description provided for @portfolioAddWorkPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Work Photo'**
  String get portfolioAddWorkPhoto;

  /// No description provided for @portfolioRemovePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get portfolioRemovePhoto;

  /// No description provided for @portfolioRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this photo from your portfolio?'**
  String get portfolioRemoveConfirm;

  /// No description provided for @portfolioPhotoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get portfolioPhotoRemoved;

  /// No description provided for @portfolioUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get portfolioUploading;

  /// No description provided for @portfolioAddPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Photo'**
  String get portfolioAddPhoto;

  /// No description provided for @portfolioEmpty.
  ///
  /// In en, this message translates to:
  /// **'No portfolio photos yet'**
  String get portfolioEmpty;

  /// No description provided for @portfolioEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Showcase your best work to win more jobs.'**
  String get portfolioEmptyBody;

  /// No description provided for @portfolioUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get portfolioUntitled;

  /// No description provided for @referTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer & Earn'**
  String get referTitle;

  /// No description provided for @referEarnHero.
  ///
  /// In en, this message translates to:
  /// **'Earn ₹200 for every referral!'**
  String get referEarnHero;

  /// No description provided for @referInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends to TaskTeddy and earn rewards together.'**
  String get referInviteFriends;

  /// No description provided for @referHowItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get referHowItWorks;

  /// No description provided for @referStep1.
  ///
  /// In en, this message translates to:
  /// **'Share your referral code with friends'**
  String get referStep1;

  /// No description provided for @referStep2.
  ///
  /// In en, this message translates to:
  /// **'Your friend signs up & completes first task'**
  String get referStep2;

  /// No description provided for @referStep3.
  ///
  /// In en, this message translates to:
  /// **'Both of you earn ₹200 in TaskCoins!'**
  String get referStep3;

  /// No description provided for @referYourCode.
  ///
  /// In en, this message translates to:
  /// **'Your Referral Code'**
  String get referYourCode;

  /// No description provided for @referCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get referCodeCopied;

  /// No description provided for @referShareWhatsApp.
  ///
  /// In en, this message translates to:
  /// **'Share via WhatsApp'**
  String get referShareWhatsApp;

  /// No description provided for @referShareDialogOpened.
  ///
  /// In en, this message translates to:
  /// **'Share dialog opened!'**
  String get referShareDialogOpened;

  /// No description provided for @referYourReferrals.
  ///
  /// In en, this message translates to:
  /// **'Your Referrals'**
  String get referYourReferrals;

  /// No description provided for @referTotalReferrals.
  ///
  /// In en, this message translates to:
  /// **'Total Referrals'**
  String get referTotalReferrals;

  /// No description provided for @referEarningsFrom.
  ///
  /// In en, this message translates to:
  /// **'Earnings from Referrals'**
  String get referEarningsFrom;

  /// No description provided for @referStep.
  ///
  /// In en, this message translates to:
  /// **'Step {number}'**
  String referStep(int number);

  /// No description provided for @referShareMessage.
  ///
  /// In en, this message translates to:
  /// **'Join TaskTeddy using my referral code {code} and earn ₹200! Download now: https://taskteddy.app'**
  String referShareMessage(String code);

  /// No description provided for @bankRemoveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String bankRemoveConfirmTitle(String name);

  /// No description provided for @bankRemoveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This payment method will be removed from your account.'**
  String get bankRemoveConfirmBody;

  /// No description provided for @bankMethodRemoved.
  ///
  /// In en, this message translates to:
  /// **'{name} removed'**
  String bankMethodRemoved(String name);

  /// No description provided for @bankBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get bankBankAccount;

  /// No description provided for @bankBankAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Add savings or current account'**
  String get bankBankAccountSub;

  /// No description provided for @bankUpiId.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get bankUpiId;

  /// No description provided for @bankUpiSub.
  ///
  /// In en, this message translates to:
  /// **'Add your UPI address'**
  String get bankUpiSub;

  /// No description provided for @bankAddBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Add Bank Account'**
  String get bankAddBankAccount;

  /// No description provided for @bankAccountHolderName.
  ///
  /// In en, this message translates to:
  /// **'Account Holder Name'**
  String get bankAccountHolderName;

  /// No description provided for @bankAccountNumber.
  ///
  /// In en, this message translates to:
  /// **'Account Number'**
  String get bankAccountNumber;

  /// No description provided for @bankIfscCode.
  ///
  /// In en, this message translates to:
  /// **'IFSC Code'**
  String get bankIfscCode;

  /// No description provided for @bankFillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Please fill all fields'**
  String get bankFillAllFields;

  /// No description provided for @bankSavingsMask.
  ///
  /// In en, this message translates to:
  /// **'Savings Account •••• {last4}'**
  String bankSavingsMask(String last4);

  /// No description provided for @bankAccountAdded.
  ///
  /// In en, this message translates to:
  /// **'Bank account added successfully'**
  String get bankAccountAdded;

  /// No description provided for @bankAddUpiId.
  ///
  /// In en, this message translates to:
  /// **'Add UPI ID'**
  String get bankAddUpiId;

  /// No description provided for @bankUpiHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. name@upi'**
  String get bankUpiHint;

  /// No description provided for @bankEnterValidUpi.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid UPI ID'**
  String get bankEnterValidUpi;

  /// No description provided for @bankUpiAdded.
  ///
  /// In en, this message translates to:
  /// **'UPI ID added successfully'**
  String get bankUpiAdded;

  /// No description provided for @bankPayoutInfo.
  ///
  /// In en, this message translates to:
  /// **'Payout Information'**
  String get bankPayoutInfo;

  /// No description provided for @bankProcessingTime.
  ///
  /// In en, this message translates to:
  /// **'Processing Time'**
  String get bankProcessingTime;

  /// No description provided for @bankProcessingTimeVal.
  ///
  /// In en, this message translates to:
  /// **'24 hours after task completion'**
  String get bankProcessingTimeVal;

  /// No description provided for @bankMinWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Minimum Withdrawal'**
  String get bankMinWithdrawal;

  /// No description provided for @bankPlatformFee.
  ///
  /// In en, this message translates to:
  /// **'Platform Fee'**
  String get bankPlatformFee;

  /// No description provided for @bankPlatformFeeVal.
  ///
  /// In en, this message translates to:
  /// **'15% per task'**
  String get bankPlatformFeeVal;

  /// No description provided for @bankPaymentCycle.
  ///
  /// In en, this message translates to:
  /// **'Payment Cycle'**
  String get bankPaymentCycle;

  /// No description provided for @bankPaymentCycleVal.
  ///
  /// In en, this message translates to:
  /// **'Instant to default method'**
  String get bankPaymentCycleVal;

  /// No description provided for @bankDefault.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get bankDefault;

  /// No description provided for @bankSetDefault.
  ///
  /// In en, this message translates to:
  /// **'Set Default'**
  String get bankSetDefault;

  /// No description provided for @helpMyTicketsTooltip.
  ///
  /// In en, this message translates to:
  /// **'My tickets'**
  String get helpMyTicketsTooltip;

  /// No description provided for @helpMessageSupport.
  ///
  /// In en, this message translates to:
  /// **'Message support'**
  String get helpMessageSupport;

  /// No description provided for @helpRespond24.
  ///
  /// In en, this message translates to:
  /// **'We usually respond within 24 hours.'**
  String get helpRespond24;

  /// No description provided for @helpSubject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get helpSubject;

  /// No description provided for @helpDescribeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue…'**
  String get helpDescribeIssue;

  /// No description provided for @helpAddSubjectDesc.
  ///
  /// In en, this message translates to:
  /// **'Please add a subject and a short description.'**
  String get helpAddSubjectDesc;

  /// No description provided for @helpTicketSent.
  ///
  /// In en, this message translates to:
  /// **'Ticket sent! We will reply in-app.'**
  String get helpTicketSent;

  /// No description provided for @helpSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get helpSend;

  /// No description provided for @helpNoTickets.
  ///
  /// In en, this message translates to:
  /// **'No support tickets yet'**
  String get helpNoTickets;

  /// No description provided for @helpResolved.
  ///
  /// In en, this message translates to:
  /// **'RESOLVED'**
  String get helpResolved;

  /// No description provided for @helpOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get helpOpen;

  /// No description provided for @helpSupportReply.
  ///
  /// In en, this message translates to:
  /// **'Support: {reply}'**
  String helpSupportReply(String reply);

  /// No description provided for @helpReachOut.
  ///
  /// In en, this message translates to:
  /// **'Reach out to partner support\n{phone}  •  {email}'**
  String helpReachOut(String phone, String email);

  /// No description provided for @helpCallUs.
  ///
  /// In en, this message translates to:
  /// **'Call us'**
  String get helpCallUs;

  /// No description provided for @helpEmailUs.
  ///
  /// In en, this message translates to:
  /// **'Email us'**
  String get helpEmailUs;

  /// No description provided for @helpCouldNotDial.
  ///
  /// In en, this message translates to:
  /// **'Could not open dialer on this device.'**
  String get helpCouldNotDial;

  /// No description provided for @helpCouldNotEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app on this device.'**
  String get helpCouldNotEmail;

  /// No description provided for @helpNeedQuickHelp.
  ///
  /// In en, this message translates to:
  /// **'Need quick help?'**
  String get helpNeedQuickHelp;

  /// No description provided for @helpFindAnswers.
  ///
  /// In en, this message translates to:
  /// **'Find answers instantly or contact support anytime.'**
  String get helpFindAnswers;

  /// No description provided for @helpMyDisputes.
  ///
  /// In en, this message translates to:
  /// **'My Payout disputes'**
  String get helpMyDisputes;

  /// No description provided for @helpNoDisputes.
  ///
  /// In en, this message translates to:
  /// **'You don’t have any active disputes.'**
  String get helpNoDisputes;

  /// No description provided for @helpBrowseTopics.
  ///
  /// In en, this message translates to:
  /// **'Browse all help topics'**
  String get helpBrowseTopics;

  /// No description provided for @helpRelatedTo.
  ///
  /// In en, this message translates to:
  /// **'Help related to {topic}'**
  String helpRelatedTo(String topic);

  /// No description provided for @helpCantFind.
  ///
  /// In en, this message translates to:
  /// **'Can’t find your answer?'**
  String get helpCantFind;

  /// No description provided for @helpTeamHere.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here to help'**
  String get helpTeamHere;

  /// No description provided for @helpT1Title.
  ///
  /// In en, this message translates to:
  /// **'Tasks & Applications'**
  String get helpT1Title;

  /// No description provided for @helpT1Sub.
  ///
  /// In en, this message translates to:
  /// **'Manage applications, bids, slot details, and cover letters'**
  String get helpT1Sub;

  /// No description provided for @helpT1Q1.
  ///
  /// In en, this message translates to:
  /// **'How do I apply for a task?'**
  String get helpT1Q1;

  /// No description provided for @helpT1A1.
  ///
  /// In en, this message translates to:
  /// **'Browse available tasks in the Browse tab, select a task that matches your expertise, choose your bid amount, write a brief cover letter describing your experience, and tap Apply.'**
  String get helpT1A1;

  /// No description provided for @helpT1Q2.
  ///
  /// In en, this message translates to:
  /// **'Can I cancel or withdraw my application?'**
  String get helpT1Q2;

  /// No description provided for @helpT1A2.
  ///
  /// In en, this message translates to:
  /// **'Yes. Go to My Applications on the Profile tab, choose the pending application you want to withdraw, and tap the Withdraw option to remove your bid.'**
  String get helpT1A2;

  /// No description provided for @helpT1Q3.
  ///
  /// In en, this message translates to:
  /// **'What happens when my application is accepted?'**
  String get helpT1Q3;

  /// No description provided for @helpT1A3.
  ///
  /// In en, this message translates to:
  /// **'You will receive an instant notification, and the task moves to your \"My Active Tasks\" shelf. You can open the task to view customer details and coordinates.'**
  String get helpT1A3;

  /// No description provided for @helpT1Q4.
  ///
  /// In en, this message translates to:
  /// **'What is the task completion OTP?'**
  String get helpT1Q4;

  /// No description provided for @helpT1A4.
  ///
  /// In en, this message translates to:
  /// **'Upon successfully completing the task, ask the customer for the 4-digit verification OTP. Enter it in the active task window to mark it completed and release your payout.'**
  String get helpT1A4;

  /// No description provided for @helpT1Q5.
  ///
  /// In en, this message translates to:
  /// **'What happens if a customer cancels a task after I arrive?'**
  String get helpT1Q5;

  /// No description provided for @helpT1A5.
  ///
  /// In en, this message translates to:
  /// **'If a customer cancels after you have arrived or started traveling to the location, you may be eligible for a cancellation compensation of ₹50-₹150 depending on the distance traveled. Contact support via the active booking screen.'**
  String get helpT1A5;

  /// No description provided for @helpT1Q6.
  ///
  /// In en, this message translates to:
  /// **'How are task ratings calculated?'**
  String get helpT1Q6;

  /// No description provided for @helpT1A6.
  ///
  /// In en, this message translates to:
  /// **'Your overall rating is the average of ratings given by customers upon task completion. High ratings (4.5+) increase your visibility and give you early access to high-value tasks.'**
  String get helpT1A6;

  /// No description provided for @helpT2Title.
  ///
  /// In en, this message translates to:
  /// **'Earnings & Payouts'**
  String get helpT2Title;

  /// No description provided for @helpT2Sub.
  ///
  /// In en, this message translates to:
  /// **'Platform fees, bank withdrawals, and ledger payments'**
  String get helpT2Sub;

  /// No description provided for @helpT2Q1.
  ///
  /// In en, this message translates to:
  /// **'How do I withdraw my earnings?'**
  String get helpT2Q1;

  /// No description provided for @helpT2A1.
  ///
  /// In en, this message translates to:
  /// **'Go to Earnings & Payouts from your Profile, tap Withdraw, enter the amount (min ₹100), and the funds are instantly transferred to your default payout target.'**
  String get helpT2A1;

  /// No description provided for @helpT2Q2.
  ///
  /// In en, this message translates to:
  /// **'What is the platform service fee?'**
  String get helpT2Q2;

  /// No description provided for @helpT2A2.
  ///
  /// In en, this message translates to:
  /// **'TaskTeddy charges a flat 15% platform service fee on successful task completions to help pay for insurance, marketing, and operations.'**
  String get helpT2A2;

  /// No description provided for @helpT2Q3.
  ///
  /// In en, this message translates to:
  /// **'How long does a withdrawal bank payout take?'**
  String get helpT2Q3;

  /// No description provided for @helpT2A3.
  ///
  /// In en, this message translates to:
  /// **'Payout transfers are initiated instantly. Depending on your bank\'s IMPS processing speeds, payouts usually reflect in your bank account or UPI within a few minutes.'**
  String get helpT2A3;

  /// No description provided for @helpT2Q4.
  ///
  /// In en, this message translates to:
  /// **'Why is my payout stuck in pending status?'**
  String get helpT2Q4;

  /// No description provided for @helpT2A4.
  ///
  /// In en, this message translates to:
  /// **'If your payout is pending, it\'s usually due to a banking network delay or verification check. Most pending payouts resolve automatically within 2-4 hours. If it takes longer, reach out with the Payout ID.'**
  String get helpT2A4;

  /// No description provided for @helpT2Q5.
  ///
  /// In en, this message translates to:
  /// **'Can I change my default payout bank account?'**
  String get helpT2Q5;

  /// No description provided for @helpT2A5.
  ///
  /// In en, this message translates to:
  /// **'Yes, you can edit or add bank accounts and UPI IDs anytime via the Bank & Payout screen on your Profile tab. Simply add a new method and tap the star or set as default.'**
  String get helpT2A5;

  /// No description provided for @helpT3Title.
  ///
  /// In en, this message translates to:
  /// **'Verification & Profile'**
  String get helpT3Title;

  /// No description provided for @helpT3Sub.
  ///
  /// In en, this message translates to:
  /// **'Aadhaar checks, PAN verification, and profile picture settings'**
  String get helpT3Sub;

  /// No description provided for @helpT3Q1.
  ///
  /// In en, this message translates to:
  /// **'How long does document verification take?'**
  String get helpT3Q1;

  /// No description provided for @helpT3A1.
  ///
  /// In en, this message translates to:
  /// **'Automated background checks are verified instantly. In cases requiring manual reviews, approval can take up to 24 hours. Your progress bar updates automatically.'**
  String get helpT3A1;

  /// No description provided for @helpT3Q2.
  ///
  /// In en, this message translates to:
  /// **'What address proofs are acceptable?'**
  String get helpT3Q2;

  /// No description provided for @helpT3A2.
  ///
  /// In en, this message translates to:
  /// **'We accept standard utility bills (electricity, pipeline gas, or water bill) not older than 3 months, registered rent agreements, or government certificates in your name.'**
  String get helpT3A2;

  /// No description provided for @helpT3Q3.
  ///
  /// In en, this message translates to:
  /// **'Why was my PAN card upload rejected?'**
  String get helpT3Q3;

  /// No description provided for @helpT3A3.
  ///
  /// In en, this message translates to:
  /// **'Ensure that the photo is clear, all edges are visible, there is no flash reflection, and the name matches your government ID details.'**
  String get helpT3A3;

  /// No description provided for @helpT3Q4.
  ///
  /// In en, this message translates to:
  /// **'How do I update my profile details after verification?'**
  String get helpT3Q4;

  /// No description provided for @helpT3A4.
  ///
  /// In en, this message translates to:
  /// **'Once your identity is verified, major fields like your legal name and government ID cannot be edited directly. To change your registered phone number or correct a name error, contact partner support with supporting documents.'**
  String get helpT3A4;

  /// No description provided for @helpT3Q5.
  ///
  /// In en, this message translates to:
  /// **'What should I do if my document verification fails?'**
  String get helpT3Q5;

  /// No description provided for @helpT3A5.
  ///
  /// In en, this message translates to:
  /// **'If your Aadhaar or PAN is rejected, you will receive a notification stating the reason. Make sure your upload is high-quality, not blurred, and matches your registered profile name before submitting again.'**
  String get helpT3A5;

  /// No description provided for @helpT4Title.
  ///
  /// In en, this message translates to:
  /// **'Safety & Code of Conduct'**
  String get helpT4Title;

  /// No description provided for @helpT4Sub.
  ///
  /// In en, this message translates to:
  /// **'Emergency support, coordinates tracking, and rules'**
  String get helpT4Sub;

  /// No description provided for @helpT4Q1.
  ///
  /// In en, this message translates to:
  /// **'I feel unsafe during a task - what do I do?'**
  String get helpT4Q1;

  /// No description provided for @helpT4A1.
  ///
  /// In en, this message translates to:
  /// **'Safety is our top priority. Leave the location immediately to a public space and call support. In any emergency, dial local police (100/112) first.'**
  String get helpT4A1;

  /// No description provided for @helpT4Q2.
  ///
  /// In en, this message translates to:
  /// **'Can I accept payments directly from customers?'**
  String get helpT4Q2;

  /// No description provided for @helpT4A2.
  ///
  /// In en, this message translates to:
  /// **'No. Asking customers for offline or direct cash/UPI transfers violates partner guidelines and leads to permanent suspension of your TaskTeddy account.'**
  String get helpT4A2;

  /// No description provided for @helpT4Q3.
  ///
  /// In en, this message translates to:
  /// **'What should I do if the task scope changes at the location?'**
  String get helpT4Q3;

  /// No description provided for @helpT4A3.
  ///
  /// In en, this message translates to:
  /// **'If a customer asks you to do additional work not mentioned in the original task description, politely ask them to update the task in the app or pay standard rates. Do not accept offline payment adjustments without informing support.'**
  String get helpT4A3;

  /// No description provided for @helpT4Q4.
  ///
  /// In en, this message translates to:
  /// **'How is my location tracked during active tasks?'**
  String get helpT4Q4;

  /// No description provided for @helpT4A4.
  ///
  /// In en, this message translates to:
  /// **'We track your location in the background only when you are traveling to a task or actively completing a service, to ensure partner safety and provide customers with live ETAs.'**
  String get helpT4A4;

  /// No description provided for @setWeeklyHours.
  ///
  /// In en, this message translates to:
  /// **'Weekly hours'**
  String get setWeeklyHours;

  /// No description provided for @setNotifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get setNotifications;

  /// No description provided for @setPushNotif.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get setPushNotif;

  /// No description provided for @setPushNotifSub.
  ///
  /// In en, this message translates to:
  /// **'Receive task alerts & updates'**
  String get setPushNotifSub;

  /// No description provided for @setEmailNotif.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get setEmailNotif;

  /// No description provided for @setEmailNotifSub.
  ///
  /// In en, this message translates to:
  /// **'Weekly summary & promotions'**
  String get setEmailNotifSub;

  /// No description provided for @setSmsNotif.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get setSmsNotif;

  /// No description provided for @setSmsNotifSub.
  ///
  /// In en, this message translates to:
  /// **'OTP & critical alerts only'**
  String get setSmsNotifSub;

  /// No description provided for @setAppearance.
  ///
  /// In en, this message translates to:
  /// **'APPEARANCE'**
  String get setAppearance;

  /// No description provided for @setDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get setDarkMode;

  /// No description provided for @setComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get setComingSoon;

  /// No description provided for @setDataStorage.
  ///
  /// In en, this message translates to:
  /// **'DATA & STORAGE'**
  String get setDataStorage;

  /// No description provided for @setClearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get setClearCache;

  /// No description provided for @setCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared'**
  String get setCacheCleared;

  /// No description provided for @setDownloadData.
  ///
  /// In en, this message translates to:
  /// **'Download My Data'**
  String get setDownloadData;

  /// No description provided for @setDataExportEmailed.
  ///
  /// In en, this message translates to:
  /// **'Data export will be emailed to you'**
  String get setDataExportEmailed;

  /// No description provided for @setDangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get setDangerZone;

  /// No description provided for @setDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get setDeleteAccount;

  /// No description provided for @setDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account?'**
  String get setDeleteAccountTitle;

  /// No description provided for @setDeleteAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. All your data, earnings, and reviews will be permanently deleted.'**
  String get setDeleteAccountBody;

  /// No description provided for @setDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get setDelete;

  /// No description provided for @setDeletionSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Account deletion request submitted'**
  String get setDeletionSubmitted;

  /// No description provided for @reportThisUser.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get reportThisUser;

  /// No description provided for @reportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportUserTitle(String name);

  /// No description provided for @reportChooseReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason. Reports are confidential.'**
  String get reportChooseReason;

  /// No description provided for @reportDetailsOptional.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetailsOptional;

  /// No description provided for @reportDetailHint.
  ///
  /// In en, this message translates to:
  /// **'Add anything that helps us understand what happened…'**
  String get reportDetailHint;

  /// No description provided for @reportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get reportSubmit;

  /// No description provided for @reportSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Our team will review it.'**
  String get reportSubmitted;

  /// No description provided for @reportReasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate behaviour'**
  String get reportReasonInappropriate;

  /// No description provided for @reportReasonNoShow.
  ///
  /// In en, this message translates to:
  /// **'No show'**
  String get reportReasonNoShow;

  /// No description provided for @reportReasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get reportReasonSafety;

  /// No description provided for @reportReasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud or scam'**
  String get reportReasonFraud;

  /// No description provided for @reportReasonPoorQuality.
  ///
  /// In en, this message translates to:
  /// **'Poor quality'**
  String get reportReasonPoorQuality;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @blockConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockConfirmTitle(String name);

  /// No description provided for @blockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They will no longer be able to message you or match with your tasks. You can unblock them anytime from Settings.'**
  String get blockConfirmBody;

  /// No description provided for @blockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} has been blocked'**
  String blockedSuccess(String name);

  /// No description provided for @blockedUserFallback.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get blockedUserFallback;

  /// No description provided for @unblockAction.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockAction;

  /// No description provided for @unblockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} unblocked'**
  String unblockedSuccess(String name);

  /// No description provided for @blockedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'People you block will appear here.'**
  String get blockedEmptyBody;

  /// No description provided for @loginSendingOtp.
  ///
  /// In en, this message translates to:
  /// **'Sending OTP to {phone}'**
  String loginSendingOtp(String phone);

  /// No description provided for @loginOtpSent.
  ///
  /// In en, this message translates to:
  /// **'OTP sent to {phone}'**
  String loginOtpSent(String phone);

  /// No description provided for @loginEnterOtpSent.
  ///
  /// In en, this message translates to:
  /// **'Enter OTP sent to your number'**
  String get loginEnterOtpSent;

  /// No description provided for @loginErrConnect.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Please check your internet and try again.'**
  String get loginErrConnect;

  /// No description provided for @loginErrServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach server. Please try again later.'**
  String get loginErrServer;

  /// No description provided for @loginErrInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please check and try again.'**
  String get loginErrInvalidOtp;

  /// No description provided for @loginErrExpiredOtp.
  ///
  /// In en, this message translates to:
  /// **'OTP expired. Please request a new one.'**
  String get loginErrExpiredOtp;

  /// No description provided for @loginErrTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get loginErrTooMany;

  /// No description provided for @loginErrGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get loginErrGeneric;

  /// No description provided for @loginTermsPrefix.
  ///
  /// In en, this message translates to:
  /// **'By clicking continue, you accept our '**
  String get loginTermsPrefix;

  /// No description provided for @loginAnd.
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get loginAnd;

  /// No description provided for @loginTermsSuffix.
  ///
  /// In en, this message translates to:
  /// **'.'**
  String get loginTermsSuffix;

  /// No description provided for @dashLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading your dashboard…'**
  String get dashLoading;

  /// No description provided for @dashLocationPicker.
  ///
  /// In en, this message translates to:
  /// **'Location picker opened...'**
  String get dashLocationPicker;

  /// No description provided for @dashAssigned.
  ///
  /// In en, this message translates to:
  /// **'{count} assigned'**
  String dashAssigned(int count);

  /// No description provided for @dashAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} available'**
  String dashAvailable(int count);

  /// No description provided for @dashOngoing.
  ///
  /// In en, this message translates to:
  /// **'{count} ongoing'**
  String dashOngoing(int count);

  /// No description provided for @dashUseAppliedTab.
  ///
  /// In en, this message translates to:
  /// **'Use the Applied tab in bottom navigation'**
  String get dashUseAppliedTab;

  /// No description provided for @dashCheckBackSoon.
  ///
  /// In en, this message translates to:
  /// **'Check back soon — new tasks are posted daily!'**
  String get dashCheckBackSoon;

  /// No description provided for @dashBrowseStartEarning.
  ///
  /// In en, this message translates to:
  /// **'Browse available tasks and start earning!'**
  String get dashBrowseStartEarning;

  /// No description provided for @dashSpecialOffer.
  ///
  /// In en, this message translates to:
  /// **'Special Offer!'**
  String get dashSpecialOffer;

  /// No description provided for @dashBonusRewards.
  ///
  /// In en, this message translates to:
  /// **'Complete tasks to earn bonus rewards'**
  String get dashBonusRewards;

  /// No description provided for @dashCompleteBooking.
  ///
  /// In en, this message translates to:
  /// **'Complete Booking'**
  String get dashCompleteBooking;

  /// No description provided for @dashBookingOtpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask the customer for their completion OTP for \"{service}\" and enter it below.'**
  String dashBookingOtpPrompt(String service);

  /// No description provided for @dashComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get dashComplete;

  /// No description provided for @dashBookingComplete.
  ///
  /// In en, this message translates to:
  /// **'Booking marked complete!'**
  String get dashBookingComplete;

  /// No description provided for @dashThisBooking.
  ///
  /// In en, this message translates to:
  /// **'this booking'**
  String get dashThisBooking;

  /// No description provided for @dashMarkComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark Complete'**
  String get dashMarkComplete;

  /// No description provided for @dashScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get dashScheduled;

  /// No description provided for @dashServiceFallback.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get dashServiceFallback;

  /// No description provided for @dashCustomerFallback.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get dashCustomerFallback;

  /// No description provided for @dashOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dashOverdue;

  /// No description provided for @dashMinLeft.
  ///
  /// In en, this message translates to:
  /// **'{count}m left'**
  String dashMinLeft(int count);

  /// No description provided for @dashHrLeft.
  ///
  /// In en, this message translates to:
  /// **'{count}h left'**
  String dashHrLeft(int count);

  /// No description provided for @dashDayLeft.
  ///
  /// In en, this message translates to:
  /// **'{count}d left'**
  String dashDayLeft(int count);

  /// No description provided for @dashApplied.
  ///
  /// In en, this message translates to:
  /// **'{count} applied'**
  String dashApplied(int count);

  /// No description provided for @dashStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get dashStatusPending;

  /// No description provided for @dashStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get dashStatusConfirmed;

  /// No description provided for @dashStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get dashStatusCompleted;

  /// No description provided for @dashStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get dashStatusCancelled;

  /// No description provided for @dashTip1.
  ///
  /// In en, this message translates to:
  /// **'Complete 3 more tasks this week to reach Gold status'**
  String get dashTip1;

  /// No description provided for @dashTip2.
  ///
  /// In en, this message translates to:
  /// **'Tasks with a quick response get 2x more bookings'**
  String get dashTip2;

  /// No description provided for @dashTip3.
  ///
  /// In en, this message translates to:
  /// **'Keep your profile 100% complete for priority listing'**
  String get dashTip3;

  /// No description provided for @dashTip4.
  ///
  /// In en, this message translates to:
  /// **'Maintain a 4.8+ rating to unlock premium task access'**
  String get dashTip4;

  /// No description provided for @dashTip5.
  ///
  /// In en, this message translates to:
  /// **'Enable location for better task matching in your area'**
  String get dashTip5;

  /// No description provided for @browseNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get browseNotNow;

  /// No description provided for @browseTaskCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get browseTaskCompleted;

  /// No description provided for @browseCollectedCash.
  ///
  /// In en, this message translates to:
  /// **'You collected ₹{amount} in cash from the customer.'**
  String browseCollectedCash(String amount);

  /// No description provided for @browseCashCollected.
  ///
  /// In en, this message translates to:
  /// **'Cash collected'**
  String get browseCashCollected;

  /// No description provided for @browsePlatformFeeMethod.
  ///
  /// In en, this message translates to:
  /// **'Platform fee ({method})'**
  String browsePlatformFeeMethod(String method);

  /// No description provided for @browseNetEarning.
  ///
  /// In en, this message translates to:
  /// **'Net earning'**
  String get browseNetEarning;

  /// No description provided for @browseFeeDeducted.
  ///
  /// In en, this message translates to:
  /// **'The ₹{amount} platform fee was deducted from your wallet. Keep your wallet topped up to avoid dues.'**
  String browseFeeDeducted(String amount);

  /// No description provided for @browseDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get browseDone;

  /// No description provided for @browseLeadDismissed.
  ///
  /// In en, this message translates to:
  /// **'Lead dismissed'**
  String get browseLeadDismissed;

  /// No description provided for @browseUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get browseUndo;

  /// No description provided for @browseGpsPinging.
  ///
  /// In en, this message translates to:
  /// **'Pinging GPS Satellites...'**
  String get browseGpsPinging;

  /// No description provided for @browseGpsResolving.
  ///
  /// In en, this message translates to:
  /// **'Resolving coordinates...'**
  String get browseGpsResolving;

  /// No description provided for @browseGpsFetching.
  ///
  /// In en, this message translates to:
  /// **'Fetching nearest tasks...'**
  String get browseGpsFetching;

  /// No description provided for @browseLocationDetected.
  ///
  /// In en, this message translates to:
  /// **'Location auto-detected to {city}! Nearest tasks loaded.'**
  String browseLocationDetected(String city);

  /// No description provided for @browseSelectLocation.
  ///
  /// In en, this message translates to:
  /// **'Select Location'**
  String get browseSelectLocation;

  /// No description provided for @browseSelectLocationSub.
  ///
  /// In en, this message translates to:
  /// **'Browse nearby open tasks in your preferred city'**
  String get browseSelectLocationSub;

  /// No description provided for @browseAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto-Detect My Location'**
  String get browseAutoDetect;

  /// No description provided for @browseAccessingGps.
  ///
  /// In en, this message translates to:
  /// **'Accessing high-accuracy GPS coordinates'**
  String get browseAccessingGps;

  /// No description provided for @browseSimulateGps.
  ///
  /// In en, this message translates to:
  /// **'Simulate high-accuracy GPS check'**
  String get browseSimulateGps;

  /// No description provided for @browsePopularCities.
  ///
  /// In en, this message translates to:
  /// **'POPULAR CITIES'**
  String get browsePopularCities;

  /// No description provided for @browseBrowsingNearest.
  ///
  /// In en, this message translates to:
  /// **'Browsing tasks nearest to {city}.'**
  String browseBrowsingNearest(String city);

  /// No description provided for @browseReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get browseReset;

  /// No description provided for @browsePresetAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get browsePresetAll;

  /// No description provided for @browsePresetUnder500.
  ///
  /// In en, this message translates to:
  /// **'Under ₹500'**
  String get browsePresetUnder500;

  /// No description provided for @browsePreset500to2000.
  ///
  /// In en, this message translates to:
  /// **'₹500-₹2000'**
  String get browsePreset500to2000;

  /// No description provided for @browsePresetAbove2000.
  ///
  /// In en, this message translates to:
  /// **'Above ₹2000'**
  String get browsePresetAbove2000;

  /// No description provided for @browseMinBudget.
  ///
  /// In en, this message translates to:
  /// **'Min Budget (₹)'**
  String get browseMinBudget;

  /// No description provided for @browseMaxBudget.
  ///
  /// In en, this message translates to:
  /// **'Max Budget (₹)'**
  String get browseMaxBudget;

  /// No description provided for @browseHintAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get browseHintAny;

  /// No description provided for @browseFailedLoad.
  ///
  /// In en, this message translates to:
  /// **'Failed to load tasks'**
  String get browseFailedLoad;

  /// No description provided for @browseRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get browseRefresh;

  /// No description provided for @browseCatAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get browseCatAll;

  /// No description provided for @browseOpenTasks.
  ///
  /// In en, this message translates to:
  /// **'{count} open tasks'**
  String browseOpenTasks(int count);

  /// No description provided for @browseSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort: {label}'**
  String browseSortLabel(String label);

  /// Sort option: newest posted tasks first
  ///
  /// In en, this message translates to:
  /// **'latest'**
  String get browseSortLatest;

  /// No description provided for @browseSortBudget.
  ///
  /// In en, this message translates to:
  /// **'budget'**
  String get browseSortBudget;

  /// No description provided for @browseSortDeadline.
  ///
  /// In en, this message translates to:
  /// **'deadline'**
  String get browseSortDeadline;

  /// No description provided for @browseSortLeastBids.
  ///
  /// In en, this message translates to:
  /// **'least bids'**
  String get browseSortLeastBids;

  /// Timestamp on a task card, e.g. 'Posted 3h ago'
  ///
  /// In en, this message translates to:
  /// **'Posted {ago}'**
  String browsePosted(String ago);

  /// Relative time for a task posted less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get browseJustNow;

  /// No description provided for @browsePostedBy.
  ///
  /// In en, this message translates to:
  /// **'Posted by {name}'**
  String browsePostedBy(String name);

  /// No description provided for @browseBudgetSmall.
  ///
  /// In en, this message translates to:
  /// **'budget'**
  String get browseBudgetSmall;

  /// No description provided for @browseUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get browseUrgent;

  /// No description provided for @browseDueToday.
  ///
  /// In en, this message translates to:
  /// **'· Due today!'**
  String get browseDueToday;

  /// No description provided for @browseDueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'· Due tomorrow'**
  String get browseDueTomorrow;

  /// No description provided for @browseDueInDays.
  ///
  /// In en, this message translates to:
  /// **'· Due in {days} days'**
  String browseDueInDays(int days);

  /// No description provided for @browseDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String browseDue(String date);

  /// No description provided for @browseBids.
  ///
  /// In en, this message translates to:
  /// **'{count} bids'**
  String browseBids(int count);

  /// No description provided for @browseDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get browseDismiss;

  /// No description provided for @browseBidLower.
  ///
  /// In en, this message translates to:
  /// **'Your bid is ₹{amount} lower — better chance!'**
  String browseBidLower(String amount);

  /// No description provided for @browseBidAbove.
  ///
  /// In en, this message translates to:
  /// **'Above budget — explain the value in your cover letter'**
  String get browseBidAbove;

  /// No description provided for @browseBidMatches.
  ///
  /// In en, this message translates to:
  /// **'Your bid matches the budget'**
  String get browseBidMatches;

  /// No description provided for @browseCompBelow.
  ///
  /// In en, this message translates to:
  /// **'You\'re {pct}% below average bids'**
  String browseCompBelow(String pct);

  /// No description provided for @browseCompAbove.
  ///
  /// In en, this message translates to:
  /// **'You\'re {pct}% above average bids'**
  String browseCompAbove(String pct);

  /// No description provided for @browseCompMatches.
  ///
  /// In en, this message translates to:
  /// **'Your bid matches the average'**
  String get browseCompMatches;

  /// No description provided for @browseYourBidAmount.
  ///
  /// In en, this message translates to:
  /// **'Your Bid Amount (₹)'**
  String get browseYourBidAmount;

  /// No description provided for @browseCompetitiveAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Competitive Analysis'**
  String get browseCompetitiveAnalysis;

  /// No description provided for @browseAvgBid.
  ///
  /// In en, this message translates to:
  /// **'Avg Bid'**
  String get browseAvgBid;

  /// No description provided for @browseEstTakeHome.
  ///
  /// In en, this message translates to:
  /// **'Estimated Take-Home'**
  String get browseEstTakeHome;

  /// No description provided for @browseAfterFee.
  ///
  /// In en, this message translates to:
  /// **'after 10% platform fee'**
  String get browseAfterFee;

  /// No description provided for @browseCoverLetter.
  ///
  /// In en, this message translates to:
  /// **'Cover Letter *'**
  String get browseCoverLetter;

  /// No description provided for @browseCoverLetterOptional.
  ///
  /// In en, this message translates to:
  /// **'Cover letter (optional)'**
  String get browseCoverLetterOptional;

  /// No description provided for @browseCoverHint.
  ///
  /// In en, this message translates to:
  /// **'Introduce yourself. Why are you the best fit? Mention your experience and availability...'**
  String get browseCoverHint;

  /// No description provided for @browseCoverTip.
  ///
  /// In en, this message translates to:
  /// **'Good cover letters increase selection chance by 70%'**
  String get browseCoverTip;

  /// No description provided for @browseFeeNote.
  ///
  /// In en, this message translates to:
  /// **'TaskTeddy charges 10% platform fee only when a task is completed.'**
  String get browseFeeNote;

  /// No description provided for @browseSubmitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get browseSubmitApplication;

  /// No description provided for @browseTaskRefMissing.
  ///
  /// In en, this message translates to:
  /// **'Task reference missing'**
  String get browseTaskRefMissing;

  /// No description provided for @browseCustomerNotifiedSharing.
  ///
  /// In en, this message translates to:
  /// **'Customer notified. Sharing your location.'**
  String get browseCustomerNotifiedSharing;

  /// No description provided for @browseBackedOut.
  ///
  /// In en, this message translates to:
  /// **'You backed out. The job is open again.'**
  String get browseBackedOut;

  /// No description provided for @browseInvalidOtp.
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP'**
  String get browseInvalidOtp;

  /// No description provided for @browseActiveTask.
  ///
  /// In en, this message translates to:
  /// **'Active Task'**
  String get browseActiveTask;

  /// No description provided for @browseYouEarnAmt.
  ///
  /// In en, this message translates to:
  /// **'You earn: ₹{amount}'**
  String browseYouEarnAmt(String amount);

  /// No description provided for @browseFailedOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to open chat'**
  String get browseFailedOpenChat;

  /// No description provided for @browseChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get browseChat;

  /// No description provided for @browseRatingLabel.
  ///
  /// In en, this message translates to:
  /// **'{rating} rating'**
  String browseRatingLabel(String rating);

  /// No description provided for @browseHeadingToCustomer.
  ///
  /// In en, this message translates to:
  /// **'Heading to the customer'**
  String get browseHeadingToCustomer;

  /// No description provided for @browseOtwActiveBody.
  ///
  /// In en, this message translates to:
  /// **'Customer notified. Your live location is being shared while this screen is open.'**
  String get browseOtwActiveBody;

  /// No description provided for @browseOtwIdleBody.
  ///
  /// In en, this message translates to:
  /// **'Let the customer know you are on your way. We will share your live location so they can track your arrival.'**
  String get browseOtwIdleBody;

  /// No description provided for @browseCustomerNotified.
  ///
  /// In en, this message translates to:
  /// **'Customer notified'**
  String get browseCustomerNotified;

  /// No description provided for @browseNotifying.
  ///
  /// In en, this message translates to:
  /// **'Notifying...'**
  String get browseNotifying;

  /// No description provided for @browseCancelling.
  ///
  /// In en, this message translates to:
  /// **'Cancelling...'**
  String get browseCancelling;

  /// No description provided for @browseCancelJob.
  ///
  /// In en, this message translates to:
  /// **'Cancel job'**
  String get browseCancelJob;

  /// No description provided for @browseEnterCompletionOtp.
  ///
  /// In en, this message translates to:
  /// **'Enter Completion OTP'**
  String get browseEnterCompletionOtp;

  /// No description provided for @browseOtpPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask the customer for the 4-digit OTP to confirm task completion and receive payment.'**
  String get browseOtpPrompt;

  /// No description provided for @browseVerifyComplete.
  ///
  /// In en, this message translates to:
  /// **'Verify & Complete Task'**
  String get browseVerifyComplete;

  /// No description provided for @browseReasonEmergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get browseReasonEmergency;

  /// No description provided for @browseReasonTooFar.
  ///
  /// In en, this message translates to:
  /// **'Too far'**
  String get browseReasonTooFar;

  /// No description provided for @browseReasonSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule conflict'**
  String get browseReasonSchedule;

  /// No description provided for @browseReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get browseReasonOther;

  /// No description provided for @browseBackOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Back out of this job?'**
  String get browseBackOutTitle;

  /// No description provided for @browseBackOutWarning.
  ///
  /// In en, this message translates to:
  /// **'This reopens the task for other taskers. Repeated cancellations hurt your reliability score.'**
  String get browseBackOutWarning;

  /// No description provided for @browseReason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get browseReason;

  /// No description provided for @browseAddNote.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get browseAddNote;

  /// No description provided for @browseKeepJob.
  ///
  /// In en, this message translates to:
  /// **'Keep job'**
  String get browseKeepJob;

  /// No description provided for @browseThanksRating.
  ///
  /// In en, this message translates to:
  /// **'Thanks for rating the customer.'**
  String get browseThanksRating;

  /// No description provided for @browseRateCustomer.
  ///
  /// In en, this message translates to:
  /// **'Rate {name}'**
  String browseRateCustomer(String name);

  /// No description provided for @browseRateExperience.
  ///
  /// In en, this message translates to:
  /// **'How was your experience working with this customer?'**
  String get browseRateExperience;

  /// No description provided for @browseAddComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment (optional)'**
  String get browseAddComment;

  /// No description provided for @browseSubmitRating.
  ///
  /// In en, this message translates to:
  /// **'Submit rating'**
  String get browseSubmitRating;

  /// No description provided for @browseAppSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Application Submitted!'**
  String get browseAppSubmitted;

  /// No description provided for @browseAppSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\"\nThe customer will review and accept the best bid.'**
  String browseAppSubmittedBody(String title);

  /// No description provided for @browseAppSubmittedNote.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get a notification when accepted. Keep applying to more tasks!'**
  String get browseAppSubmittedNote;

  /// No description provided for @browseViewMyApps.
  ///
  /// In en, this message translates to:
  /// **'View My Applications'**
  String get browseViewMyApps;

  /// No description provided for @browseBrowseMore.
  ///
  /// In en, this message translates to:
  /// **'Browse More Tasks'**
  String get browseBrowseMore;

  /// No description provided for @browsePhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get browsePhotos;

  /// No description provided for @reputationYourLevel.
  ///
  /// In en, this message translates to:
  /// **'Your Level'**
  String get reputationYourLevel;

  /// No description provided for @reputationReliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get reputationReliability;

  /// No description provided for @reputationJobsDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 job done} other{{count} jobs done}}'**
  String reputationJobsDone(int count);

  /// No description provided for @reputationJobsToNext.
  ///
  /// In en, this message translates to:
  /// **'{completed}/{next} jobs to {tier}'**
  String reputationJobsToNext(int completed, int next, String tier);

  /// No description provided for @reputationTopLevel.
  ///
  /// In en, this message translates to:
  /// **'Top level'**
  String get reputationTopLevel;

  /// No description provided for @reputationExplainer.
  ///
  /// In en, this message translates to:
  /// **'Complete jobs and keep a high rating to level up.'**
  String get reputationExplainer;

  /// No description provided for @reputationLevelNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get reputationLevelNew;

  /// No description provided for @reputationLevelBronze.
  ///
  /// In en, this message translates to:
  /// **'Bronze'**
  String get reputationLevelBronze;

  /// No description provided for @reputationLevelSilver.
  ///
  /// In en, this message translates to:
  /// **'Silver'**
  String get reputationLevelSilver;

  /// No description provided for @reputationLevelGold.
  ///
  /// In en, this message translates to:
  /// **'Gold'**
  String get reputationLevelGold;

  /// No description provided for @reputationLevelPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get reputationLevelPro;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'pa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'hi':
      return AppL10nHi();
    case 'pa':
      return AppL10nPa();
  }

  throw FlutterError(
      'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
