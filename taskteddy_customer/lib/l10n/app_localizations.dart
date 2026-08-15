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

  /// Bottom navigation label for the Home tab
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation label for the Tasks tab
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// Bottom navigation label for the central Post tab
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get navPost;

  /// Bottom navigation label for the Bookings tab
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get navBookings;

  /// Bottom nav label for the active tasks tab
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get navActive;

  /// Bottom navigation label for the Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Home greeting shown before noon
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorning;

  /// Home greeting shown in the afternoon
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoon;

  /// Home greeting shown in the evening
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEvening;

  /// Title of the home hero post-a-task card
  ///
  /// In en, this message translates to:
  /// **'Get anything done'**
  String get heroTitle;

  /// Subtitle of the home hero post-a-task card
  ///
  /// In en, this message translates to:
  /// **'Post a task and get offers from trusted taskers near you.'**
  String get heroSubtitle;

  /// Section header for the how-it-works steps
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// How it works step 1 title
  ///
  /// In en, this message translates to:
  /// **'Post your task'**
  String get howStep1Title;

  /// How it works step 1 caption
  ///
  /// In en, this message translates to:
  /// **'Describe what you need done'**
  String get howStep1Caption;

  /// How it works step 2 title
  ///
  /// In en, this message translates to:
  /// **'Get offers from taskers'**
  String get howStep2Title;

  /// How it works step 2 caption
  ///
  /// In en, this message translates to:
  /// **'Compare prices and reviews'**
  String get howStep2Caption;

  /// How it works step 3 title
  ///
  /// In en, this message translates to:
  /// **'Hire and get it done'**
  String get howStep3Title;

  /// How it works step 3 caption
  ///
  /// In en, this message translates to:
  /// **'Pay securely when complete'**
  String get howStep3Caption;

  /// Section header above the task categories
  ///
  /// In en, this message translates to:
  /// **'What do you need help with?'**
  String get whatDoYouNeedHelp;

  /// Category tile for an unlisted task type
  ///
  /// In en, this message translates to:
  /// **'Something else'**
  String get somethingElse;

  /// Section header shown when the user has no tasks
  ///
  /// In en, this message translates to:
  /// **'Your tasks'**
  String get yourTasks;

  /// Section header for the recent tasks list
  ///
  /// In en, this message translates to:
  /// **'Your recent tasks'**
  String get yourRecentTasks;

  /// Action to open the full list from a section header
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get viewAll;

  /// Empty state title on the home tasks section
  ///
  /// In en, this message translates to:
  /// **'You haven\'t posted a task yet'**
  String get noTasksYet;

  /// Empty state subtitle on the home tasks section
  ///
  /// In en, this message translates to:
  /// **'Post your first task and start getting offers.'**
  String get postFirstTask;

  /// Trust strip label (two lines)
  ///
  /// In en, this message translates to:
  /// **'Verified\ntaskers'**
  String get trustVerifiedTaskers;

  /// Trust strip label (two lines)
  ///
  /// In en, this message translates to:
  /// **'Top rated\nservice'**
  String get trustTopRated;

  /// Trust strip label (two lines)
  ///
  /// In en, this message translates to:
  /// **'Secure\npayments'**
  String get trustSecurePayments;

  /// Shared primary action to start posting a task
  ///
  /// In en, this message translates to:
  /// **'Post a Task'**
  String get postATask;

  /// Shared action: apply
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Shared action: accept
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Shared action: decline
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// Shared action: cancel
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Shared action: save
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Shared action: retry
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Shared action: continue
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Shared action: submit
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Shared action: OK / acknowledge
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Shared action: yes
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Shared action: no
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Shared action: close
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Shared action: report
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// Shared action: block
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// Shared action / tooltip: go back
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Tagline under the logo on the auth screen
  ///
  /// In en, this message translates to:
  /// **'Get professional house help in minutes!'**
  String get authTagline;

  /// Header of the auth footer card
  ///
  /// In en, this message translates to:
  /// **'Log in or Sign up'**
  String get authLoginOrSignup;

  /// Button to edit the entered phone number
  ///
  /// In en, this message translates to:
  /// **'Change number'**
  String get authChangeNumber;

  /// Button to resend the OTP
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get authResendOtp;

  /// Countdown shown before OTP can be resent
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String authResendIn(int seconds);

  /// Hint text for the phone number field
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get authMobileNumber;

  /// Leading text of the terms acceptance line
  ///
  /// In en, this message translates to:
  /// **'By clicking continue, you accept our '**
  String get authTermsIntro;

  /// Terms & Conditions link text
  ///
  /// In en, this message translates to:
  /// **'Terms & Conditions'**
  String get authTerms;

  /// Conjunction between Terms and Privacy links
  ///
  /// In en, this message translates to:
  /// **' and '**
  String get authAnd;

  /// Privacy Policy link text
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get authPrivacy;

  /// Profile/settings row that opens the language chooser
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Title of the language chooser sheet
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// Option to follow the device language
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Language name: English (native)
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language name: Hindi (native)
  ///
  /// In en, this message translates to:
  /// **'हिन्दी (Hindi)'**
  String get languageHindi;

  /// Language name: Punjabi (native)
  ///
  /// In en, this message translates to:
  /// **'ਪੰਜਾਬੀ (Punjabi)'**
  String get languagePunjabi;

  /// No description provided for @verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// No description provided for @safetyMoreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get safetyMoreOptions;

  /// No description provided for @safetyBlockUser.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get safetyBlockUser;

  /// No description provided for @safetyBlockBody.
  ///
  /// In en, this message translates to:
  /// **'Block {name}? You will no longer see their offers or content, and they cannot contact you.'**
  String safetyBlockBody(String name);

  /// No description provided for @safetyUserBlocked.
  ///
  /// In en, this message translates to:
  /// **'{name} has been blocked'**
  String safetyUserBlocked(String name);

  /// No description provided for @safetyThisUser.
  ///
  /// In en, this message translates to:
  /// **'this user'**
  String get safetyThisUser;

  /// No description provided for @safetyReportUser.
  ///
  /// In en, this message translates to:
  /// **'Report user'**
  String get safetyReportUser;

  /// No description provided for @safetyReportUserNamed.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String safetyReportUserNamed(String name);

  /// No description provided for @safetyReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tell us what went wrong. Reports are confidential.'**
  String get safetyReportSubtitle;

  /// No description provided for @safetyReportDetailHint.
  ///
  /// In en, this message translates to:
  /// **'Add any details (optional)'**
  String get safetyReportDetailHint;

  /// No description provided for @safetySubmitReport.
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get safetySubmitReport;

  /// No description provided for @safetyReportThanks.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Thank you for keeping TaskTeddy safe.'**
  String get safetyReportThanks;

  /// No description provided for @reasonInappropriate.
  ///
  /// In en, this message translates to:
  /// **'Inappropriate behaviour'**
  String get reasonInappropriate;

  /// No description provided for @reasonNoShow.
  ///
  /// In en, this message translates to:
  /// **'No show'**
  String get reasonNoShow;

  /// No description provided for @reasonSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety concern'**
  String get reasonSafety;

  /// No description provided for @reasonFraud.
  ///
  /// In en, this message translates to:
  /// **'Fraud or scam'**
  String get reasonFraud;

  /// No description provided for @reasonPoorQuality.
  ///
  /// In en, this message translates to:
  /// **'Poor quality'**
  String get reasonPoorQuality;

  /// No description provided for @reasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reasonSpam;

  /// No description provided for @reasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reasonOther;

  /// No description provided for @blockedUsersTitle.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersTitle;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @unblockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} unblocked'**
  String unblockedSuccess(String name);

  /// No description provided for @userLabel.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get userLabel;

  /// No description provided for @noBlockedUsers.
  ///
  /// In en, this message translates to:
  /// **'No blocked users'**
  String get noBlockedUsers;

  /// No description provided for @blockedUsersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'People you block will appear here. You can unblock them any time.'**
  String get blockedUsersEmptyBody;

  /// No description provided for @blockedUsersError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load blocked users.'**
  String get blockedUsersError;

  /// No description provided for @tasksMyTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get tasksMyTasks;

  /// No description provided for @statusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statusOpen;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @tasksLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your tasks.'**
  String get tasksLoadError;

  /// No description provided for @tasksTotalTasks.
  ///
  /// In en, this message translates to:
  /// **'Total tasks'**
  String get tasksTotalTasks;

  /// No description provided for @tasksAcrossStatuses.
  ///
  /// In en, this message translates to:
  /// **'across all statuses'**
  String get tasksAcrossStatuses;

  /// No description provided for @tasksWithBids.
  ///
  /// In en, this message translates to:
  /// **'With bids'**
  String get tasksWithBids;

  /// No description provided for @tasksReadyForReview.
  ///
  /// In en, this message translates to:
  /// **'ready for review'**
  String get tasksReadyForReview;

  /// No description provided for @tasksUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tasksUpcoming;

  /// No description provided for @tasksNotPastDeadline.
  ///
  /// In en, this message translates to:
  /// **'not past deadline'**
  String get tasksNotPastDeadline;

  /// No description provided for @tasksSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search task title, location or category'**
  String get tasksSearchHint;

  /// No description provided for @tasksOnlyWithBids.
  ///
  /// In en, this message translates to:
  /// **'Only tasks with bids'**
  String get tasksOnlyWithBids;

  /// Splash status shown while the app boots
  ///
  /// In en, this message translates to:
  /// **'Preparing TaskTeddy'**
  String get splashPreparing;

  /// No description provided for @splashLoadingWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Loading your workspace'**
  String get splashLoadingWorkspace;

  /// No description provided for @splashGettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting things ready...'**
  String get splashGettingReady;

  /// No description provided for @splashAlmostThere.
  ///
  /// In en, this message translates to:
  /// **'Almost there...'**
  String get splashAlmostThere;

  /// No description provided for @splashLocationOff.
  ///
  /// In en, this message translates to:
  /// **'Location is off. You can set it from home.'**
  String get splashLocationOff;

  /// No description provided for @splashLocationSkipped.
  ///
  /// In en, this message translates to:
  /// **'Location permission skipped. Continuing...'**
  String get splashLocationSkipped;

  /// No description provided for @splashUsingDefaultLocation.
  ///
  /// In en, this message translates to:
  /// **'Using default location.'**
  String get splashUsingDefaultLocation;

  /// Splash status once the location is resolved
  ///
  /// In en, this message translates to:
  /// **'Location locked: {label}'**
  String splashLocationLocked(String label);

  /// No description provided for @splashLocationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch location. Continuing...'**
  String get splashLocationFailed;

  /// Title of the Saved (favorites) screen
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get favSaved;

  /// No description provided for @favTabServices.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get favTabServices;

  /// No description provided for @favTabTaskers.
  ///
  /// In en, this message translates to:
  /// **'Taskers'**
  String get favTabTaskers;

  /// No description provided for @favNoServices.
  ///
  /// In en, this message translates to:
  /// **'No saved services yet'**
  String get favNoServices;

  /// No description provided for @favNoServicesBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the heart on any service to save it here.'**
  String get favNoServicesBody;

  /// No description provided for @favNoTaskers.
  ///
  /// In en, this message translates to:
  /// **'No saved taskers yet'**
  String get favNoTaskers;

  /// No description provided for @favNoTaskersBody.
  ///
  /// In en, this message translates to:
  /// **'Save a tasker to quickly find them again.'**
  String get favNoTaskersBody;

  /// No description provided for @favLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your saved items.'**
  String get favLoadError;

  /// Count of reviews shown next to a rating
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 review} other{{count} reviews}}'**
  String reviewsCount(int count);

  /// No description provided for @portfolioTitle.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioTitle;

  /// No description provided for @weeklyAvailability.
  ///
  /// In en, this message translates to:
  /// **'Weekly availability'**
  String get weeklyAvailability;

  /// No description provided for @recentReviews.
  ///
  /// In en, this message translates to:
  /// **'Recent reviews'**
  String get recentReviews;

  /// Stat label: tasker average rating
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get profileStatRating;

  /// Stat label: tasker completed jobs
  ///
  /// In en, this message translates to:
  /// **'Jobs done'**
  String get profileStatJobs;

  /// Stat label: tasker reliability percentage
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get profileStatReliability;

  /// Label for the tasker's bid amount in the profile sheet
  ///
  /// In en, this message translates to:
  /// **'Their offer'**
  String get taskTheirOffer;

  /// No description provided for @noReviewsYet.
  ///
  /// In en, this message translates to:
  /// **'No reviews yet.'**
  String get noReviewsYet;

  /// No description provided for @availabilityNotSet.
  ///
  /// In en, this message translates to:
  /// **'Availability not set.'**
  String get availabilityNotSet;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @reviewerCustomer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get reviewerCustomer;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @sdSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get sdSavedAddresses;

  /// No description provided for @sdDefault.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get sdDefault;

  /// No description provided for @sdConfirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get sdConfirmBooking;

  /// No description provided for @sdServicePrice.
  ///
  /// In en, this message translates to:
  /// **'Service price'**
  String get sdServicePrice;

  /// No description provided for @sdDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get sdDiscount;

  /// No description provided for @sdTotalFromWallet.
  ///
  /// In en, this message translates to:
  /// **'Total (from wallet)'**
  String get sdTotalFromWallet;

  /// No description provided for @sdTotalPayAfter.
  ///
  /// In en, this message translates to:
  /// **'Total (pay after service)'**
  String get sdTotalPayAfter;

  /// No description provided for @sdPaymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get sdPaymentMethod;

  /// No description provided for @sdPayAfterService.
  ///
  /// In en, this message translates to:
  /// **'Pay after service'**
  String get sdPayAfterService;

  /// No description provided for @sdPayAfterServiceSub.
  ///
  /// In en, this message translates to:
  /// **'Cash / UPI on completion'**
  String get sdPayAfterServiceSub;

  /// No description provided for @sdWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get sdWallet;

  /// No description provided for @sdWalletAvailable.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} available'**
  String sdWalletAvailable(int amount);

  /// No description provided for @sdWalletLow.
  ///
  /// In en, this message translates to:
  /// **'Low balance: ₹{amount}'**
  String sdWalletLow(int amount);

  /// No description provided for @sdConfirmAndBook.
  ///
  /// In en, this message translates to:
  /// **'Confirm & Book  •  ₹{amount}'**
  String sdConfirmAndBook(int amount);

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @sdBookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed!'**
  String get sdBookingConfirmed;

  /// No description provided for @sdPaidFromWallet.
  ///
  /// In en, this message translates to:
  /// **'₹{amount} paid from wallet'**
  String sdPaidFromWallet(int amount);

  /// No description provided for @sdBookingId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID: {ref}'**
  String sdBookingId(String ref);

  /// No description provided for @sdViewMyBookings.
  ///
  /// In en, this message translates to:
  /// **'View My Bookings'**
  String get sdViewMyBookings;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @sdPickTimeSlotError.
  ///
  /// In en, this message translates to:
  /// **'Please pick a time slot'**
  String get sdPickTimeSlotError;

  /// No description provided for @sdEnterAddressError.
  ///
  /// In en, this message translates to:
  /// **'Please enter your address'**
  String get sdEnterAddressError;

  /// No description provided for @sdRemoveFromSaved.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get sdRemoveFromSaved;

  /// No description provided for @badgeHot.
  ///
  /// In en, this message translates to:
  /// **'HOT'**
  String get badgeHot;

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get badgeNew;

  /// No description provided for @percentOff.
  ///
  /// In en, this message translates to:
  /// **'{percent}% OFF'**
  String percentOff(int percent);

  /// No description provided for @sdDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get sdDescription;

  /// No description provided for @sdWhatsIncluded.
  ///
  /// In en, this message translates to:
  /// **'What\'s Included'**
  String get sdWhatsIncluded;

  /// No description provided for @sdPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a Date'**
  String get sdPickDate;

  /// No description provided for @dateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateToday;

  /// No description provided for @dateTomorrowShort.
  ///
  /// In en, this message translates to:
  /// **'Tmrw'**
  String get dateTomorrowShort;

  /// No description provided for @sdPickTimeSlot.
  ///
  /// In en, this message translates to:
  /// **'Pick a Time Slot'**
  String get sdPickTimeSlot;

  /// No description provided for @sdAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get sdAddress;

  /// No description provided for @sdUseSaved.
  ///
  /// In en, this message translates to:
  /// **'Use saved'**
  String get sdUseSaved;

  /// No description provided for @sdAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your full address'**
  String get sdAddressHint;

  /// No description provided for @sdNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Notes (Optional)'**
  String get sdNotesOptional;

  /// No description provided for @sdNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Any special instructions?'**
  String get sdNotesHint;

  /// No description provided for @sdBookNow.
  ///
  /// In en, this message translates to:
  /// **'Book Now  •  ₹{amount}'**
  String sdBookNow(int amount);

  /// No description provided for @bookingCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking?'**
  String get bookingCancelTitle;

  /// No description provided for @bookingCancelBody.
  ///
  /// In en, this message translates to:
  /// **'{service} on {when} will be cancelled.'**
  String bookingCancelBody(String service, String when);

  /// No description provided for @bookingKeepIt.
  ///
  /// In en, this message translates to:
  /// **'Keep it'**
  String get bookingKeepIt;

  /// No description provided for @bookingCancelConfirm.
  ///
  /// In en, this message translates to:
  /// **'Cancel booking'**
  String get bookingCancelConfirm;

  /// No description provided for @bookingCancelled.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled'**
  String get bookingCancelled;

  /// No description provided for @bookingCancelledRefund.
  ///
  /// In en, this message translates to:
  /// **'Booking cancelled • ₹{amount} refunded to wallet'**
  String bookingCancelledRefund(int amount);

  /// No description provided for @bookingRescheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule {service}'**
  String bookingRescheduleTitle(String service);

  /// No description provided for @bookingConfirmNewTime.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Time'**
  String get bookingConfirmNewTime;

  /// No description provided for @bookingRescheduledTo.
  ///
  /// In en, this message translates to:
  /// **'Rescheduled to {when}'**
  String bookingRescheduledTo(String when);

  /// No description provided for @bookingsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Bookings'**
  String get bookingsTitle;

  /// No description provided for @bookingsTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bookingsTabUpcoming;

  /// No description provided for @bookingsTabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingsTabCompleted;

  /// No description provided for @bookingsTabCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingsTabCancelled;

  /// No description provided for @bookingsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet'**
  String get bookingsEmptyTitle;

  /// No description provided for @bookingsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Your scheduled services will appear here.'**
  String get bookingsEmptyBody;

  /// No description provided for @bookingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get bookingStatusPending;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'CONFIRMED'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'CANCELLED'**
  String get bookingStatusCancelled;

  /// No description provided for @bookingDetailId.
  ///
  /// In en, this message translates to:
  /// **'Booking ID'**
  String get bookingDetailId;

  /// No description provided for @bookingDetailScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get bookingDetailScheduled;

  /// No description provided for @bookingDetailAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get bookingDetailAddress;

  /// No description provided for @bookingDetailNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get bookingDetailNotes;

  /// No description provided for @bookingDetailAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get bookingDetailAmount;

  /// No description provided for @bookingDetailPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get bookingDetailPayment;

  /// No description provided for @bookingPaidFromWallet.
  ///
  /// In en, this message translates to:
  /// **'Paid from wallet'**
  String get bookingPaidFromWallet;

  /// No description provided for @bookingBookAgain.
  ///
  /// In en, this message translates to:
  /// **'Book again'**
  String get bookingBookAgain;

  /// No description provided for @bookingReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get bookingReschedule;

  /// No description provided for @notificationFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationFallbackTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'New updates about your bookings and\ntasks will show up here.'**
  String get notificationsEmptyBody;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String timeDaysAgo(int days);

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @messagesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search chats…'**
  String get messagesSearchHint;

  /// No description provided for @messagesNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get messagesNoResults;

  /// No description provided for @messagesNoConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get messagesNoConversations;

  /// No description provided for @messagesTryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get messagesTryDifferentSearch;

  /// No description provided for @messagesBookToChat.
  ///
  /// In en, this message translates to:
  /// **'Book a task to start chatting\nwith your tasker!'**
  String get messagesBookToChat;

  /// No description provided for @messagesTapToOpen.
  ///
  /// In en, this message translates to:
  /// **'Tap to open chat'**
  String get messagesTapToOpen;

  /// No description provided for @messagesCouldNotSend.
  ///
  /// In en, this message translates to:
  /// **'Could not send message'**
  String get messagesCouldNotSend;

  /// No description provided for @messagesCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get messagesCopied;

  /// No description provided for @messagesOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get messagesOnline;

  /// No description provided for @messagesSayHello.
  ///
  /// In en, this message translates to:
  /// **'Say hello!'**
  String get messagesSayHello;

  /// No description provided for @messagesStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with\n{name}'**
  String messagesStartConversation(String name);

  /// No description provided for @messagesTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Type a message…'**
  String get messagesTypeHint;

  /// No description provided for @messagesTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get messagesTakePhoto;

  /// No description provided for @messagesChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get messagesChooseGallery;

  /// No description provided for @messagesCouldNotSendImage.
  ///
  /// In en, this message translates to:
  /// **'Could not send image'**
  String get messagesCouldNotSendImage;

  /// No description provided for @messagesErrorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image: {error}'**
  String messagesErrorSelectingImage(String error);

  /// No description provided for @msgTimeNow.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get msgTimeNow;

  /// No description provided for @msgTimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String msgTimeMinutes(int minutes);

  /// No description provided for @msgTimeHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String msgTimeHours(int hours);

  /// No description provided for @msgTimeDays.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String msgTimeDays(int days);

  /// No description provided for @dateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateYesterday;

  /// No description provided for @weekdayFullMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayFullMonday;

  /// No description provided for @weekdayFullTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayFullTuesday;

  /// No description provided for @weekdayFullWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayFullWednesday;

  /// No description provided for @weekdayFullThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayFullThursday;

  /// No description provided for @weekdayFullFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFullFriday;

  /// No description provided for @weekdayFullSaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdayFullSaturday;

  /// No description provided for @weekdayFullSunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdayFullSunday;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @profileAddPhone.
  ///
  /// In en, this message translates to:
  /// **'Add phone number'**
  String get profileAddPhone;

  /// No description provided for @profileCouldNotOpen.
  ///
  /// In en, this message translates to:
  /// **'Could not open {url}'**
  String profileCouldNotOpen(String url);

  /// No description provided for @profileOpenExternalTitle.
  ///
  /// In en, this message translates to:
  /// **'Open {title}?'**
  String profileOpenExternalTitle(String title);

  /// No description provided for @profileOpenExternalBody.
  ///
  /// In en, this message translates to:
  /// **'You are about to open an external website.'**
  String get profileOpenExternalBody;

  /// No description provided for @profileUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccess;

  /// No description provided for @profileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'TaskTeddy User'**
  String get profileDefaultName;

  /// No description provided for @profileEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileEditProfile;

  /// No description provided for @profileAddressBookReady.
  ///
  /// In en, this message translates to:
  /// **'Address book ready for faster checkout'**
  String get profileAddressBookReady;

  /// No description provided for @profileManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get profileManage;

  /// No description provided for @profileQuickAccess.
  ///
  /// In en, this message translates to:
  /// **'Quick access'**
  String get profileQuickAccess;

  /// No description provided for @profileTrackManage.
  ///
  /// In en, this message translates to:
  /// **'Track & manage'**
  String get profileTrackManage;

  /// No description provided for @profileAddresses.
  ///
  /// In en, this message translates to:
  /// **'Addresses'**
  String get profileAddresses;

  /// No description provided for @profileSaveForCheckout.
  ///
  /// In en, this message translates to:
  /// **'Save for checkout'**
  String get profileSaveForCheckout;

  /// No description provided for @profileHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get profileHelp;

  /// No description provided for @profile24x7.
  ///
  /// In en, this message translates to:
  /// **'24x7 support'**
  String get profile24x7;

  /// No description provided for @profileReferEarn.
  ///
  /// In en, this message translates to:
  /// **'Refer & earn'**
  String get profileReferEarn;

  /// No description provided for @profileInviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite friends and get rewarded'**
  String get profileInviteFriends;

  /// No description provided for @profileUpTo100.
  ///
  /// In en, this message translates to:
  /// **'Up to ₹100'**
  String get profileUpTo100;

  /// No description provided for @profileSavedServicesTaskers.
  ///
  /// In en, this message translates to:
  /// **'Saved services & taskers'**
  String get profileSavedServicesTaskers;

  /// No description provided for @profileSavedAddresses.
  ///
  /// In en, this message translates to:
  /// **'Saved addresses'**
  String get profileSavedAddresses;

  /// No description provided for @profileAboutUs.
  ///
  /// In en, this message translates to:
  /// **'About us'**
  String get profileAboutUs;

  /// No description provided for @profileTermsConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms & conditions'**
  String get profileTermsConditions;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileLogout;

  /// No description provided for @profileAccountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account settings'**
  String get profileAccountSettings;

  /// No description provided for @profileAppVersion.
  ///
  /// In en, this message translates to:
  /// **'APP VERSION: {version}'**
  String profileAppVersion(String version);

  /// No description provided for @profileErrFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter first name'**
  String get profileErrFirstName;

  /// No description provided for @profileErrPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone number is not valid'**
  String get profileErrPhone;

  /// No description provided for @profileErrValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get profileErrValidEmail;

  /// No description provided for @profileChangeEmail.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get profileChangeEmail;

  /// No description provided for @profileChangeEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Update email before verification. A fresh OTP will be sent to the new email.'**
  String get profileChangeEmailBody;

  /// No description provided for @profileEnterNewEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter new email'**
  String get profileEnterNewEmail;

  /// No description provided for @profileUseThisEmail.
  ///
  /// In en, this message translates to:
  /// **'Use this email'**
  String get profileUseThisEmail;

  /// No description provided for @profileAddEmailFirst.
  ///
  /// In en, this message translates to:
  /// **'Please add your email first'**
  String get profileAddEmailFirst;

  /// No description provided for @profileVerifCodeSent.
  ///
  /// In en, this message translates to:
  /// **'Verification code sent to {email}'**
  String profileVerifCodeSent(String email);

  /// No description provided for @profileErrValidEmailShort.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get profileErrValidEmailShort;

  /// No description provided for @profileEnterFullOtp.
  ///
  /// In en, this message translates to:
  /// **'Please enter full 6-digit OTP code'**
  String get profileEnterFullOtp;

  /// No description provided for @profileEmailVerified.
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully'**
  String get profileEmailVerified;

  /// No description provided for @profileEmailLocked.
  ///
  /// In en, this message translates to:
  /// **'Email is verified. Contact {email} to change your email.'**
  String profileEmailLocked(String email);

  /// No description provided for @profileUpdateDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your details'**
  String get profileUpdateDetails;

  /// No description provided for @profileUpdateDetailsBody.
  ///
  /// In en, this message translates to:
  /// **'Keep your profile and contact details accurate for smoother bookings.'**
  String get profileUpdateDetailsBody;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get profileTitle;

  /// No description provided for @profileBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get profileBasicInfo;

  /// No description provided for @profileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get profileFirstName;

  /// No description provided for @profileFirstNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter first name'**
  String get profileFirstNameHint;

  /// No description provided for @profileLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get profileLastName;

  /// No description provided for @profileLastNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter last name'**
  String get profileLastNameHint;

  /// No description provided for @profileContactVerification.
  ///
  /// In en, this message translates to:
  /// **'Contact & Verification'**
  String get profileContactVerification;

  /// No description provided for @profileMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get profileMobile;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get profileVerify;

  /// No description provided for @profileSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get profileSaveChanges;

  /// No description provided for @profileVerifyEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify email'**
  String get profileVerifyEmail;

  /// No description provided for @profileVerifyEmailBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit verification code sent to {email}. Need to update email? Tap Change email.'**
  String profileVerifyEmailBody(String email);

  /// No description provided for @walletNoTransactions.
  ///
  /// In en, this message translates to:
  /// **'No recent transactions yet'**
  String get walletNoTransactions;

  /// No description provided for @walletTransaction.
  ///
  /// In en, this message translates to:
  /// **'Wallet transaction'**
  String get walletTransaction;

  /// No description provided for @walletMinAmount.
  ///
  /// In en, this message translates to:
  /// **'Minimum add amount is ₹100'**
  String get walletMinAmount;

  /// No description provided for @walletHelpHint.
  ///
  /// In en, this message translates to:
  /// **'Add money to use faster checkout on bookings.'**
  String get walletHelpHint;

  /// No description provided for @walletCardLabel.
  ///
  /// In en, this message translates to:
  /// **'WALLET'**
  String get walletCardLabel;

  /// No description provided for @walletBalance.
  ///
  /// In en, this message translates to:
  /// **'Wallet Balance'**
  String get walletBalance;

  /// No description provided for @walletBalanceLow.
  ///
  /// In en, this message translates to:
  /// **'Your balance is low. Add money to continue booking smoothly.'**
  String get walletBalanceLow;

  /// No description provided for @walletBalanceUse.
  ///
  /// In en, this message translates to:
  /// **'Use wallet credits for faster checkout and instant offer benefits.'**
  String get walletBalanceUse;

  /// No description provided for @walletGet5Extra.
  ///
  /// In en, this message translates to:
  /// **'Get 5% Extra!'**
  String get walletGet5Extra;

  /// No description provided for @walletOnAdding250.
  ///
  /// In en, this message translates to:
  /// **'On adding ₹250 or more'**
  String get walletOnAdding250;

  /// No description provided for @walletAddMoney.
  ///
  /// In en, this message translates to:
  /// **'Add money'**
  String get walletAddMoney;

  /// No description provided for @walletEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get walletEnterAmount;

  /// No description provided for @walletCashback.
  ///
  /// In en, this message translates to:
  /// **'Get {amount} cashback'**
  String walletCashback(String amount);

  /// No description provided for @walletYouWillGet.
  ///
  /// In en, this message translates to:
  /// **'You will get {amount} in the wallet'**
  String walletYouWillGet(String amount);

  /// No description provided for @walletAddToWallet.
  ///
  /// In en, this message translates to:
  /// **'Add {amount} to wallet'**
  String walletAddToWallet(String amount);

  /// No description provided for @walletRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get walletRecentTransactions;

  /// No description provided for @walletAddedBonus.
  ///
  /// In en, this message translates to:
  /// **'Added {added} + bonus {bonus}. Wallet credited {credited}.'**
  String walletAddedBonus(String added, String bonus, String credited);

  /// No description provided for @walletAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {amount} to your wallet.'**
  String walletAdded(String amount);

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

  /// No description provided for @helpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & support'**
  String get helpTitle;

  /// No description provided for @helpReachOut.
  ///
  /// In en, this message translates to:
  /// **'Reach out to customer support\n{phone}  •  {email}'**
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

  /// No description provided for @helpMyRefunds.
  ///
  /// In en, this message translates to:
  /// **'My refunds'**
  String get helpMyRefunds;

  /// No description provided for @helpNoRefunds.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any refunds yet.'**
  String get helpNoRefunds;

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

  /// No description provided for @helpCantFindAnswer.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find your answer?'**
  String get helpCantFindAnswer;

  /// No description provided for @helpSupportHere.
  ///
  /// In en, this message translates to:
  /// **'Our support team is here to help'**
  String get helpSupportHere;

  /// No description provided for @helpTopicBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking'**
  String get helpTopicBooking;

  /// No description provided for @helpTopicBookingSub.
  ///
  /// In en, this message translates to:
  /// **'Manage bookings, cancellations, and schedules'**
  String get helpTopicBookingSub;

  /// No description provided for @helpTopicAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get helpTopicAccount;

  /// No description provided for @helpTopicAccountSub.
  ///
  /// In en, this message translates to:
  /// **'Profile, login, and account settings'**
  String get helpTopicAccountSub;

  /// No description provided for @helpTopicPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get helpTopicPayments;

  /// No description provided for @helpTopicPaymentsSub.
  ///
  /// In en, this message translates to:
  /// **'Billing, refunds, and transactions'**
  String get helpTopicPaymentsSub;

  /// No description provided for @helpTopicServiceQuality.
  ///
  /// In en, this message translates to:
  /// **'Service quality'**
  String get helpTopicServiceQuality;

  /// No description provided for @helpTopicServiceQualitySub.
  ///
  /// In en, this message translates to:
  /// **'Feedback, issues, and service standards'**
  String get helpTopicServiceQualitySub;

  /// No description provided for @helpTopicSafety.
  ///
  /// In en, this message translates to:
  /// **'Safety'**
  String get helpTopicSafety;

  /// No description provided for @helpTopicSafetySub.
  ///
  /// In en, this message translates to:
  /// **'Security and safety-related concerns'**
  String get helpTopicSafetySub;

  /// No description provided for @faqBookingRecurringQ.
  ///
  /// In en, this message translates to:
  /// **'Can I book a recurring service?'**
  String get faqBookingRecurringQ;

  /// No description provided for @faqBookingRecurringA.
  ///
  /// In en, this message translates to:
  /// **'Yes. You can book a recurring service by choosing your preferred frequency while confirming the slot. We support weekly and bi-weekly repeats in most cities.'**
  String get faqBookingRecurringA;

  /// No description provided for @faqBookingEquipmentQ.
  ///
  /// In en, this message translates to:
  /// **'Do I need to provide all the cleaning equipment?'**
  String get faqBookingEquipmentQ;

  /// No description provided for @faqBookingEquipmentA.
  ///
  /// In en, this message translates to:
  /// **'Basic supplies should be available at your location. For selected premium plans, partners may carry service essentials as listed on the service detail page.'**
  String get faqBookingEquipmentA;

  /// No description provided for @faqBookingRescheduleQ.
  ///
  /// In en, this message translates to:
  /// **'How do I reschedule or cancel a booking?'**
  String get faqBookingRescheduleQ;

  /// No description provided for @faqBookingRescheduleA.
  ///
  /// In en, this message translates to:
  /// **'Open My Bookings, choose the booking, and select reschedule or cancel. Cancellation fees depend on how close you are to the service time.'**
  String get faqBookingRescheduleA;

  /// No description provided for @faqBookingIssueQ.
  ///
  /// In en, this message translates to:
  /// **'What if there is a service issue?'**
  String get faqBookingIssueQ;

  /// No description provided for @faqBookingIssueA.
  ///
  /// In en, this message translates to:
  /// **'Raise a support request from this page with booking details. Our team reviews quality issues and helps with resolution or compensation where applicable.'**
  String get faqBookingIssueA;

  /// No description provided for @faqBookingPriceQ.
  ///
  /// In en, this message translates to:
  /// **'How is service price calculated?'**
  String get faqBookingPriceQ;

  /// No description provided for @faqBookingPriceA.
  ///
  /// In en, this message translates to:
  /// **'Price is based on service type, duration, location, and add-ons. You always see the final amount before payment confirmation.'**
  String get faqBookingPriceA;

  /// No description provided for @faqAccountUpdateAddressQ.
  ///
  /// In en, this message translates to:
  /// **'How do I update a saved address?'**
  String get faqAccountUpdateAddressQ;

  /// No description provided for @faqAccountUpdateAddressA.
  ///
  /// In en, this message translates to:
  /// **'Go to Profile > Saved addresses. Select the address card and update the details, then save.'**
  String get faqAccountUpdateAddressA;

  /// No description provided for @faqAccountAddAddressQ.
  ///
  /// In en, this message translates to:
  /// **'How do I add a new address?'**
  String get faqAccountAddAddressQ;

  /// No description provided for @faqAccountAddAddressA.
  ///
  /// In en, this message translates to:
  /// **'From Saved addresses, tap Add addresses and enter your complete address with landmark and pin code.'**
  String get faqAccountAddAddressA;

  /// No description provided for @faqAccountContactQ.
  ///
  /// In en, this message translates to:
  /// **'How do I contact support?'**
  String get faqAccountContactQ;

  /// No description provided for @faqAccountContactA.
  ///
  /// In en, this message translates to:
  /// **'Use the Call us button on the Help & support page. You can also open a category here and tap the support card at the bottom.'**
  String get faqAccountContactA;

  /// No description provided for @faqPaymentsFailedQ.
  ///
  /// In en, this message translates to:
  /// **'My payment failed but the money left my account'**
  String get faqPaymentsFailedQ;

  /// No description provided for @faqPaymentsFailedA.
  ///
  /// In en, this message translates to:
  /// **'If payment is pending, it usually auto-reverses within bank timelines. If not reversed, share payment ID with support and we will help track it.'**
  String get faqPaymentsFailedA;

  /// No description provided for @faqPaymentsCouponQ.
  ///
  /// In en, this message translates to:
  /// **'How do I use a coupon or offer?'**
  String get faqPaymentsCouponQ;

  /// No description provided for @faqPaymentsCouponA.
  ///
  /// In en, this message translates to:
  /// **'Apply coupon codes during checkout on the payment screen. Valid offers are reflected instantly before you place the booking.'**
  String get faqPaymentsCouponA;

  /// No description provided for @faqPaymentsRefundQ.
  ///
  /// In en, this message translates to:
  /// **'Will I get a refund if I cancel?'**
  String get faqPaymentsRefundQ;

  /// No description provided for @faqPaymentsRefundA.
  ///
  /// In en, this message translates to:
  /// **'Refund eligibility depends on cancellation timing and service terms. The exact policy is shown before you confirm cancellation.'**
  String get faqPaymentsRefundA;

  /// No description provided for @faqQualityDamageQ.
  ///
  /// In en, this message translates to:
  /// **'Is there a damage policy for service?'**
  String get faqQualityDamageQ;

  /// No description provided for @faqQualityDamageA.
  ///
  /// In en, this message translates to:
  /// **'Yes. Report damage within 24 hours with photos and booking details. Claims are reviewed as per policy and partner verification.'**
  String get faqQualityDamageA;

  /// No description provided for @faqQualityRateQ.
  ///
  /// In en, this message translates to:
  /// **'How do I rate my partner?'**
  String get faqQualityRateQ;

  /// No description provided for @faqQualityRateA.
  ///
  /// In en, this message translates to:
  /// **'After service completion, open the booking and submit a rating with comments. Your feedback helps us maintain quality standards.'**
  String get faqQualityRateA;

  /// No description provided for @faqSafetyTrustQ.
  ///
  /// In en, this message translates to:
  /// **'How can I trust your service?'**
  String get faqSafetyTrustQ;

  /// No description provided for @faqSafetyTrustA.
  ///
  /// In en, this message translates to:
  /// **'TaskTeddy verifies partners, tracks bookings, and monitors quality reports. We also offer in-app support for issue escalation.'**
  String get faqSafetyTrustA;

  /// No description provided for @faqSafetyVerifiedQ.
  ///
  /// In en, this message translates to:
  /// **'Are TaskTeddy partners verified?'**
  String get faqSafetyVerifiedQ;

  /// No description provided for @faqSafetyVerifiedA.
  ///
  /// In en, this message translates to:
  /// **'Yes, we run onboarding checks including identity verification and basic service screening before activation.'**
  String get faqSafetyVerifiedA;

  /// No description provided for @faqSafetyShareQ.
  ///
  /// In en, this message translates to:
  /// **'What does TaskTeddy share with partners about me?'**
  String get faqSafetyShareQ;

  /// No description provided for @faqSafetyShareA.
  ///
  /// In en, this message translates to:
  /// **'Partners see only the details needed for service fulfillment, such as name, location, slot, and service notes.'**
  String get faqSafetyShareA;

  /// No description provided for @faqSafetyUnsafeQ.
  ///
  /// In en, this message translates to:
  /// **'I feel unsafe during a booking - what do I do?'**
  String get faqSafetyUnsafeQ;

  /// No description provided for @faqSafetyUnsafeA.
  ///
  /// In en, this message translates to:
  /// **'End the interaction immediately, move to a safe space, and call support from this page. In emergencies, contact local authorities first.'**
  String get faqSafetyUnsafeA;

  /// No description provided for @referCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Referral code copied'**
  String get referCodeCopied;

  /// No description provided for @referLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Invite link copied. Share it with your friends.'**
  String get referLinkCopied;

  /// No description provided for @referCouldNotOpenTerms.
  ///
  /// In en, this message translates to:
  /// **'Could not open terms link'**
  String get referCouldNotOpenTerms;

  /// No description provided for @referShareLink.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get referShareLink;

  /// No description provided for @referCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy referral code'**
  String get referCopyCode;

  /// No description provided for @referTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer a friend to TaskTeddy'**
  String get referTitle;

  /// No description provided for @referGet100.
  ///
  /// In en, this message translates to:
  /// **'Get ₹100'**
  String get referGet100;

  /// No description provided for @referFriendGets.
  ///
  /// In en, this message translates to:
  /// **'Your friend gets flat ₹50 off on their first TaskTeddy service.'**
  String get referFriendGets;

  /// No description provided for @referStep1.
  ///
  /// In en, this message translates to:
  /// **'Share the link with your friend'**
  String get referStep1;

  /// No description provided for @referStep2.
  ///
  /// In en, this message translates to:
  /// **'Your friend downloads the app with your link'**
  String get referStep2;

  /// No description provided for @referStep3.
  ///
  /// In en, this message translates to:
  /// **'They get ₹50 and you get ₹100 after their first completed booking'**
  String get referStep3;

  /// No description provided for @referReadTerms.
  ///
  /// In en, this message translates to:
  /// **'Read our T&Cs to know more.'**
  String get referReadTerms;

  /// No description provided for @addrDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete address?'**
  String get addrDeleteTitle;

  /// No description provided for @addrDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'This saved address will be removed.'**
  String get addrDeleteBody;

  /// No description provided for @addrDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get addrDelete;

  /// No description provided for @addrMyAddresses.
  ///
  /// In en, this message translates to:
  /// **'My Addresses'**
  String get addrMyAddresses;

  /// No description provided for @addrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your delivery addresses for faster checkout. The default is used automatically.'**
  String get addrSubtitle;

  /// No description provided for @addrSaveNew.
  ///
  /// In en, this message translates to:
  /// **'Save new address'**
  String get addrSaveNew;

  /// No description provided for @addrEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved addresses yet. Save one to speed up checkout.'**
  String get addrEmpty;

  /// No description provided for @addrLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark: {landmark}'**
  String addrLandmark(String landmark);

  /// No description provided for @addrSetAsDefault.
  ///
  /// In en, this message translates to:
  /// **'Set as default'**
  String get addrSetAsDefault;

  /// No description provided for @addrLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your addresses.'**
  String get addrLoadError;

  /// No description provided for @addrLabelHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get addrLabelHome;

  /// No description provided for @addrLabelWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get addrLabelWork;

  /// No description provided for @addrLabelOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get addrLabelOther;

  /// No description provided for @addrErrLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to detect your address.'**
  String get addrErrLocationServices;

  /// No description provided for @addrErrPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission is needed to detect your address.'**
  String get addrErrPermissionNeeded;

  /// No description provided for @addrErrEnablePermission.
  ///
  /// In en, this message translates to:
  /// **'Enable location permission from app settings.'**
  String get addrErrEnablePermission;

  /// No description provided for @addrErrMockLocation.
  ///
  /// In en, this message translates to:
  /// **'Mock location detected. Please use real device GPS.'**
  String get addrErrMockLocation;

  /// No description provided for @addrSelectedLocation.
  ///
  /// In en, this message translates to:
  /// **'Selected location'**
  String get addrSelectedLocation;

  /// No description provided for @addrAddressDetected.
  ///
  /// In en, this message translates to:
  /// **'Address detected'**
  String get addrAddressDetected;

  /// No description provided for @addrExactCoords.
  ///
  /// In en, this message translates to:
  /// **'Exact coordinates selected'**
  String get addrExactCoords;

  /// No description provided for @addrLocationDetected.
  ///
  /// In en, this message translates to:
  /// **'Location detected'**
  String get addrLocationDetected;

  /// No description provided for @addrPickExact.
  ///
  /// In en, this message translates to:
  /// **'Pick exact location'**
  String get addrPickExact;

  /// No description provided for @addrUseCurrent.
  ///
  /// In en, this message translates to:
  /// **'Use current'**
  String get addrUseCurrent;

  /// No description provided for @addrUseThisLocation.
  ///
  /// In en, this message translates to:
  /// **'Use this location'**
  String get addrUseThisLocation;

  /// No description provided for @addrErrEnterDetails.
  ///
  /// In en, this message translates to:
  /// **'Please enter your address details.'**
  String get addrErrEnterDetails;

  /// No description provided for @addrErrPincode.
  ///
  /// In en, this message translates to:
  /// **'Pincode must be exactly 6 digits.'**
  String get addrErrPincode;

  /// No description provided for @addrEditorAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Address Details'**
  String get addrEditorAddTitle;

  /// No description provided for @addrEditorEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Address Details'**
  String get addrEditorEditTitle;

  /// No description provided for @addrSaveAddress.
  ///
  /// In en, this message translates to:
  /// **'SAVE ADDRESS'**
  String get addrSaveAddress;

  /// No description provided for @addrLocateOnMap.
  ///
  /// In en, this message translates to:
  /// **'Locate on map'**
  String get addrLocateOnMap;

  /// No description provided for @addrLocateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use current location or tap the map pin.'**
  String get addrLocateSubtitle;

  /// No description provided for @addrChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get addrChange;

  /// No description provided for @addrUseCurrentLocation.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get addrUseCurrentLocation;

  /// No description provided for @addrAddAddress.
  ///
  /// In en, this message translates to:
  /// **'Add address'**
  String get addrAddAddress;

  /// No description provided for @addrHouseLabel.
  ///
  /// In en, this message translates to:
  /// **'House No. & Floor *'**
  String get addrHouseLabel;

  /// No description provided for @addrHouseHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 216, B-14'**
  String get addrHouseHint;

  /// No description provided for @addrBuildingLabel.
  ///
  /// In en, this message translates to:
  /// **'Building & Block No. (Optional)'**
  String get addrBuildingLabel;

  /// No description provided for @addrBuildingHint.
  ///
  /// In en, this message translates to:
  /// **'Tower, block, wing, etc.'**
  String get addrBuildingHint;

  /// No description provided for @addrStreetLabel.
  ///
  /// In en, this message translates to:
  /// **'Street / Area *'**
  String get addrStreetLabel;

  /// No description provided for @addrStreetHint.
  ///
  /// In en, this message translates to:
  /// **'Street, locality or sector'**
  String get addrStreetHint;

  /// No description provided for @addrCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City *'**
  String get addrCityLabel;

  /// No description provided for @addrCityHint.
  ///
  /// In en, this message translates to:
  /// **'Your city'**
  String get addrCityHint;

  /// No description provided for @addrLandmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Landmark & Area Name (Optional)'**
  String get addrLandmarkLabel;

  /// No description provided for @addrLandmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Nearby known place'**
  String get addrLandmarkHint;

  /// No description provided for @addrPincodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Pincode *'**
  String get addrPincodeLabel;

  /// No description provided for @addrPincodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit PIN'**
  String get addrPincodeHint;

  /// No description provided for @addrAddLabel.
  ///
  /// In en, this message translates to:
  /// **'Add address label'**
  String get addrAddLabel;

  /// No description provided for @addrSetDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Set as default address'**
  String get addrSetDefaultTitle;

  /// No description provided for @addrSetDefaultSub.
  ///
  /// In en, this message translates to:
  /// **'Used automatically at checkout.'**
  String get addrSetDefaultSub;

  /// No description provided for @tasksSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get tasksSortNewest;

  /// No description provided for @tasksSortDueSoon.
  ///
  /// In en, this message translates to:
  /// **'Due soon'**
  String get tasksSortDueSoon;

  /// No description provided for @tasksSortBudgetHigh.
  ///
  /// In en, this message translates to:
  /// **'Budget high'**
  String get tasksSortBudgetHigh;

  /// No description provided for @tasksNoTasksFound.
  ///
  /// In en, this message translates to:
  /// **'No tasks found'**
  String get tasksNoTasksFound;

  /// Subtitle under the empty-state on the tasks list
  ///
  /// In en, this message translates to:
  /// **'Post a task and taskers nearby will send you offers.'**
  String get tasksEmptySubtitle;

  /// No description provided for @taskBudgetFixed.
  ///
  /// In en, this message translates to:
  /// **'Fixed Price'**
  String get taskBudgetFixed;

  /// No description provided for @taskBudgetHourly.
  ///
  /// In en, this message translates to:
  /// **'Hourly Rate'**
  String get taskBudgetHourly;

  /// No description provided for @taskBudgetFixedHelper.
  ///
  /// In en, this message translates to:
  /// **'One final budget for the complete task'**
  String get taskBudgetFixedHelper;

  /// No description provided for @taskBudgetHourlyHelper.
  ///
  /// In en, this message translates to:
  /// **'Rate per hour, then add expected hours'**
  String get taskBudgetHourlyHelper;

  /// No description provided for @taskUrgencyStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get taskUrgencyStandard;

  /// No description provided for @taskUrgencyPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get taskUrgencyPriority;

  /// No description provided for @taskUrgencyUrgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get taskUrgencyUrgent;

  /// No description provided for @taskUrgencyStandardSub.
  ///
  /// In en, this message translates to:
  /// **'Within normal timeline'**
  String get taskUrgencyStandardSub;

  /// No description provided for @taskUrgencyPrioritySub.
  ///
  /// In en, this message translates to:
  /// **'Need faster responses'**
  String get taskUrgencyPrioritySub;

  /// No description provided for @taskUrgencyUrgentSub.
  ///
  /// In en, this message translates to:
  /// **'Immediate attention needed'**
  String get taskUrgencyUrgentSub;

  /// No description provided for @taskReviewThanks.
  ///
  /// In en, this message translates to:
  /// **'Thanks for your review!'**
  String get taskReviewThanks;

  /// No description provided for @taskAcceptOffer.
  ///
  /// In en, this message translates to:
  /// **'Accept offer'**
  String get taskAcceptOffer;

  /// No description provided for @taskAcceptOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Assign this task to {name} for ₹{amount}?\n\nOther offers will be automatically declined.'**
  String taskAcceptOfferBody(String name, int amount);

  /// No description provided for @taskOfferAccepted.
  ///
  /// In en, this message translates to:
  /// **'Offer accepted successfully!'**
  String get taskOfferAccepted;

  /// No description provided for @taskOfferDeclined.
  ///
  /// In en, this message translates to:
  /// **'Offer declined'**
  String get taskOfferDeclined;

  /// No description provided for @taskCancelledSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task cancelled successfully'**
  String get taskCancelledSuccess;

  /// No description provided for @taskYourTasker.
  ///
  /// In en, this message translates to:
  /// **'Your tasker'**
  String get taskYourTasker;

  /// No description provided for @taskJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get taskJustNow;

  /// No description provided for @taskMinutesAgoFull.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 minute ago} other{{count} minutes ago}}'**
  String taskMinutesAgoFull(int count);

  /// No description provided for @taskHoursAgoFull.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour ago} other{{count} hours ago}}'**
  String taskHoursAgoFull(int count);

  /// No description provided for @taskDaysAgoFull.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String taskDaysAgoFull(int count);

  /// No description provided for @taskOnTheWay.
  ///
  /// In en, this message translates to:
  /// **'Tasker on the way'**
  String get taskOnTheWay;

  /// No description provided for @taskLive.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get taskLive;

  /// No description provided for @taskOnTheWaySince.
  ///
  /// In en, this message translates to:
  /// **'On the way since {time}'**
  String taskOnTheWaySince(String time);

  /// No description provided for @taskLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Location updated {time}'**
  String taskLocationUpdated(String time);

  /// No description provided for @taskWaitingLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a location update'**
  String get taskWaitingLocation;

  /// No description provided for @taskMetersAway.
  ///
  /// In en, this message translates to:
  /// **'{meters} m away'**
  String taskMetersAway(int meters);

  /// No description provided for @taskKmAway.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String taskKmAway(String km);

  /// No description provided for @taskDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Details'**
  String get taskDetailsTitle;

  /// No description provided for @taskBidsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bid} other{{count} bids}}'**
  String taskBidsCount(int count);

  /// No description provided for @taskLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get taskLocationLabel;

  /// No description provided for @taskOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get taskOffers;

  /// No description provided for @taskOffersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 offer} other{{count} offers}}'**
  String taskOffersCount(int count);

  /// No description provided for @taskNoOffers.
  ///
  /// In en, this message translates to:
  /// **'No offers yet — taskers will send offers soon'**
  String get taskNoOffers;

  /// No description provided for @taskCompletionOtp.
  ///
  /// In en, this message translates to:
  /// **'Completion OTP'**
  String get taskCompletionOtp;

  /// No description provided for @taskCompletionOtpHint.
  ///
  /// In en, this message translates to:
  /// **'Share this OTP with the tasker when they complete the task'**
  String get taskCompletionOtpHint;

  /// No description provided for @taskEditTask.
  ///
  /// In en, this message translates to:
  /// **'Edit Task'**
  String get taskEditTask;

  /// No description provided for @taskCancelTask.
  ///
  /// In en, this message translates to:
  /// **'Cancel Task'**
  String get taskCancelTask;

  /// No description provided for @taskRateName.
  ///
  /// In en, this message translates to:
  /// **'Rate {name}'**
  String taskRateName(String name);

  /// No description provided for @cancelReasonNoLongerNeeded.
  ///
  /// In en, this message translates to:
  /// **'No longer needed'**
  String get cancelReasonNoLongerNeeded;

  /// No description provided for @cancelReasonPostedByMistake.
  ///
  /// In en, this message translates to:
  /// **'Posted by mistake'**
  String get cancelReasonPostedByMistake;

  /// No description provided for @cancelReasonFoundElsewhere.
  ///
  /// In en, this message translates to:
  /// **'Found help elsewhere'**
  String get cancelReasonFoundElsewhere;

  /// No description provided for @taskCancelTaskSheet.
  ///
  /// In en, this message translates to:
  /// **'Cancel task'**
  String get taskCancelTaskSheet;

  /// No description provided for @taskCancelWhy.
  ///
  /// In en, this message translates to:
  /// **'Why are you cancelling \"{title}\"?'**
  String taskCancelWhy(String title);

  /// No description provided for @taskCancelAssignedWarning.
  ///
  /// In en, this message translates to:
  /// **'This task is assigned. The tasker will be notified that you cancelled.'**
  String get taskCancelAssignedWarning;

  /// No description provided for @taskAddNoteOptional.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get taskAddNoteOptional;

  /// No description provided for @taskKeepTask.
  ///
  /// In en, this message translates to:
  /// **'Keep task'**
  String get taskKeepTask;

  /// No description provided for @taskReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Share a few words (optional)'**
  String get taskReviewHint;

  /// No description provided for @taskSubmitReview.
  ///
  /// In en, this message translates to:
  /// **'Submit review'**
  String get taskSubmitReview;

  /// No description provided for @taskFailedOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Failed to open chat'**
  String get taskFailedOpenChat;

  /// Banner shown in a chat whose task is finished
  ///
  /// In en, this message translates to:
  /// **'This chat is closed — the task is complete.'**
  String get chatClosed;

  /// No description provided for @taskChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get taskChat;

  /// No description provided for @taskStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get taskStatusAccepted;

  /// No description provided for @taskStatusRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get taskStatusRejected;

  /// No description provided for @taskReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get taskReject;

  /// No description provided for @taskAcceptBid.
  ///
  /// In en, this message translates to:
  /// **'Accept Bid'**
  String get taskAcceptBid;

  /// No description provided for @taskBidAmount.
  ///
  /// In en, this message translates to:
  /// **'Bid: ₹{amount}'**
  String taskBidAmount(int amount);

  /// No description provided for @taskLocationUpdatedPosition.
  ///
  /// In en, this message translates to:
  /// **'Location updated from your current position'**
  String get taskLocationUpdatedPosition;

  /// No description provided for @taskMaxPhotos.
  ///
  /// In en, this message translates to:
  /// **'You can add up to 6 photos'**
  String get taskMaxPhotos;

  /// No description provided for @taskTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get taskTakePhoto;

  /// No description provided for @taskChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get taskChooseGallery;

  /// No description provided for @taskCameraError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open camera right now'**
  String get taskCameraError;

  /// No description provided for @taskOnlyFirstPhotos.
  ///
  /// In en, this message translates to:
  /// **'Only first {count} photo(s) were added'**
  String taskOnlyFirstPhotos(int count);

  /// No description provided for @taskGalleryError.
  ///
  /// In en, this message translates to:
  /// **'Unable to open gallery right now'**
  String get taskGalleryError;

  /// No description provided for @taskFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required'**
  String taskFieldRequired(String field);

  /// No description provided for @taskFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get taskFieldTitle;

  /// No description provided for @taskFieldDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get taskFieldDescription;

  /// No description provided for @taskFieldBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get taskFieldBudget;

  /// No description provided for @taskFieldLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get taskFieldLocation;

  /// No description provided for @taskTitleMin.
  ///
  /// In en, this message translates to:
  /// **'Title should be at least 8 characters'**
  String get taskTitleMin;

  /// No description provided for @taskDescMin.
  ///
  /// In en, this message translates to:
  /// **'Add more details so taskers can quote correctly'**
  String get taskDescMin;

  /// No description provided for @taskBudgetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid budget amount'**
  String get taskBudgetInvalid;

  /// No description provided for @taskBudgetInsightPrompt.
  ///
  /// In en, this message translates to:
  /// **'Enter budget and location to check market range'**
  String get taskBudgetInsightPrompt;

  /// No description provided for @taskBudgetSuggested.
  ///
  /// In en, this message translates to:
  /// **'Suggested: ₹{amount}'**
  String taskBudgetSuggested(String amount);

  /// No description provided for @taskBudgetRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended in your area: ₹{min} - ₹{max}'**
  String taskBudgetRecommended(String min, String max);

  /// No description provided for @taskBudgetInsightOk.
  ///
  /// In en, this message translates to:
  /// **'Budget insight fetched successfully'**
  String get taskBudgetInsightOk;

  /// No description provided for @taskBudgetInsightUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Market insight is currently unavailable. You can still post your task.'**
  String get taskBudgetInsightUnavailable;

  /// No description provided for @taskCompleteRequired.
  ///
  /// In en, this message translates to:
  /// **'Please complete the required fields'**
  String get taskCompleteRequired;

  /// No description provided for @taskPhotosUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Photos could not be uploaded — posting without them.'**
  String get taskPhotosUploadFailed;

  /// No description provided for @taskBriefTagline.
  ///
  /// In en, this message translates to:
  /// **'Write a clear brief to get better bids from verified taskers'**
  String get taskBriefTagline;

  /// No description provided for @taskGoodBriefs.
  ///
  /// In en, this message translates to:
  /// **'Good briefs close faster. Include scope, access details, and a realistic budget.'**
  String get taskGoodBriefs;

  /// No description provided for @taskSecBasics.
  ///
  /// In en, this message translates to:
  /// **'Task Basics'**
  String get taskSecBasics;

  /// No description provided for @taskSecBasicsSub.
  ///
  /// In en, this message translates to:
  /// **'Category and task description'**
  String get taskSecBasicsSub;

  /// No description provided for @taskCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get taskCategoryLabel;

  /// No description provided for @taskTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Task Title *'**
  String get taskTitleLabel;

  /// No description provided for @taskTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Deep clean 2BHK apartment'**
  String get taskTitleHint;

  /// No description provided for @taskDescLabel.
  ///
  /// In en, this message translates to:
  /// **'Description *'**
  String get taskDescLabel;

  /// No description provided for @taskDescHint.
  ///
  /// In en, this message translates to:
  /// **'Mention size, floors, tools needed, and anything taskers should know before accepting.'**
  String get taskDescHint;

  /// No description provided for @taskSecPhotos.
  ///
  /// In en, this message translates to:
  /// **'Task Photos'**
  String get taskSecPhotos;

  /// No description provided for @taskSecPhotosSub.
  ///
  /// In en, this message translates to:
  /// **'Add up to 6 real photos to improve trust and faster bids'**
  String get taskSecPhotosSub;

  /// No description provided for @taskNoPhotos.
  ///
  /// In en, this message translates to:
  /// **'No photos added yet'**
  String get taskNoPhotos;

  /// No description provided for @taskPhotosAdded.
  ///
  /// In en, this message translates to:
  /// **'{count}/6 photo(s) added'**
  String taskPhotosAdded(int count);

  /// No description provided for @taskAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get taskAddPhotos;

  /// No description provided for @taskPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Show task area, tools/materials, and current condition.'**
  String get taskPhotoHint;

  /// No description provided for @taskSecBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget & Priority'**
  String get taskSecBudget;

  /// No description provided for @taskSecBudgetSub.
  ///
  /// In en, this message translates to:
  /// **'Set the price format and urgency'**
  String get taskSecBudgetSub;

  /// No description provided for @taskBudgetFormat.
  ///
  /// In en, this message translates to:
  /// **'Budget Format'**
  String get taskBudgetFormat;

  /// No description provided for @taskTotalBudget.
  ///
  /// In en, this message translates to:
  /// **'Total Budget (₹) *'**
  String get taskTotalBudget;

  /// No description provided for @taskHourlyBudget.
  ///
  /// In en, this message translates to:
  /// **'Hourly Budget (₹) *'**
  String get taskHourlyBudget;

  /// No description provided for @taskHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours *'**
  String get taskHoursLabel;

  /// No description provided for @taskRequiredShort.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get taskRequiredShort;

  /// No description provided for @taskCheckMarket.
  ///
  /// In en, this message translates to:
  /// **'Check Market Range'**
  String get taskCheckMarket;

  /// No description provided for @taskUrgencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get taskUrgencyLabel;

  /// No description provided for @taskSecLocation.
  ///
  /// In en, this message translates to:
  /// **'Location & Schedule'**
  String get taskSecLocation;

  /// No description provided for @taskSecLocationSub.
  ///
  /// In en, this message translates to:
  /// **'Where and when the task should happen'**
  String get taskSecLocationSub;

  /// No description provided for @taskLocationMatchHint.
  ///
  /// In en, this message translates to:
  /// **'Use your current phone location for faster task matching.'**
  String get taskLocationMatchHint;

  /// No description provided for @taskGps.
  ///
  /// In en, this message translates to:
  /// **'GPS: {lat}, {lng}'**
  String taskGps(String lat, String lng);

  /// No description provided for @taskServiceLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Location *'**
  String get taskServiceLocationLabel;

  /// No description provided for @taskLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Area, City'**
  String get taskLocationHint;

  /// No description provided for @taskLandmarkLabel2.
  ///
  /// In en, this message translates to:
  /// **'Landmark (Optional)'**
  String get taskLandmarkLabel2;

  /// No description provided for @taskLandmarkHint2.
  ///
  /// In en, this message translates to:
  /// **'Nearby mall, metro station, gate number...'**
  String get taskLandmarkHint2;

  /// No description provided for @taskDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline Date *'**
  String get taskDeadlineLabel;

  /// No description provided for @taskPreferredTime.
  ///
  /// In en, this message translates to:
  /// **'Preferred Time'**
  String get taskPreferredTime;

  /// No description provided for @taskAnytime.
  ///
  /// In en, this message translates to:
  /// **'Anytime'**
  String get taskAnytime;

  /// No description provided for @taskSecNotes.
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get taskSecNotes;

  /// No description provided for @taskSecNotesSub.
  ///
  /// In en, this message translates to:
  /// **'Optional details that can help taskers prepare'**
  String get taskSecNotesSub;

  /// No description provided for @taskNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Parking info, entry rules, tools available, preferred communication...'**
  String get taskNotesHint;

  /// No description provided for @taskSecSummary.
  ///
  /// In en, this message translates to:
  /// **'Live Summary'**
  String get taskSecSummary;

  /// No description provided for @taskSecSummarySub.
  ///
  /// In en, this message translates to:
  /// **'Preview how your posting will look'**
  String get taskSecSummarySub;

  /// No description provided for @taskUntitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled Task'**
  String get taskUntitled;

  /// No description provided for @taskSetBudget.
  ///
  /// In en, this message translates to:
  /// **'Set budget'**
  String get taskSetBudget;

  /// No description provided for @taskLocationPending.
  ///
  /// In en, this message translates to:
  /// **'Location pending'**
  String get taskLocationPending;

  /// No description provided for @taskNoPhotosShort.
  ///
  /// In en, this message translates to:
  /// **'No photos'**
  String get taskNoPhotosShort;

  /// No description provided for @taskPhotosCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String taskPhotosCount(int count);

  /// No description provided for @taskUploadingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Uploading Photos...'**
  String get taskUploadingPhotos;

  /// No description provided for @taskPostTask.
  ///
  /// In en, this message translates to:
  /// **'Post Task'**
  String get taskPostTask;

  /// No description provided for @taskStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get taskStatusOpen;

  /// No description provided for @taskStatusAssigned.
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get taskStatusAssigned;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get taskStatusInProgress;

  /// No description provided for @taskStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskStatusCompleted;

  /// No description provided for @taskStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskStatusCancelled;

  /// No description provided for @taskStatusUnderReview.
  ///
  /// In en, this message translates to:
  /// **'Under Review'**
  String get taskStatusUnderReview;

  /// No description provided for @taskStatusNotApproved.
  ///
  /// In en, this message translates to:
  /// **'Not Approved'**
  String get taskStatusNotApproved;

  /// No description provided for @taskUnderReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Under review'**
  String get taskUnderReviewTitle;

  /// No description provided for @taskUnderReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Our team is reviewing this task — it usually goes live within 5 minutes.'**
  String get taskUnderReviewNote;

  /// No description provided for @taskNotApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get taskNotApprovedTitle;

  /// No description provided for @taskNotApprovedNote.
  ///
  /// In en, this message translates to:
  /// **'This task wasn\'t approved during review.'**
  String get taskNotApprovedNote;

  /// No description provided for @taskRejectedReason.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String taskRejectedReason(String reason);

  /// No description provided for @taskPostAgain.
  ///
  /// In en, this message translates to:
  /// **'Post again'**
  String get taskPostAgain;

  /// No description provided for @taskPostedTitle.
  ///
  /// In en, this message translates to:
  /// **'Task submitted for review'**
  String get taskPostedTitle;

  /// No description provided for @taskPostedBody.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\"'**
  String taskPostedBody(String title);

  /// No description provided for @taskPostedReviewNote.
  ///
  /// In en, this message translates to:
  /// **'Our team reviews every task for quality and safety — usually approved within 5 minutes. You\'ll be notified when it goes live.'**
  String get taskPostedReviewNote;

  /// No description provided for @taskViewMyTasks.
  ///
  /// In en, this message translates to:
  /// **'View My Tasks'**
  String get taskViewMyTasks;

  /// No description provided for @taskPostAnother.
  ///
  /// In en, this message translates to:
  /// **'Post Another Task'**
  String get taskPostAnother;

  /// No description provided for @taskUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Task updated successfully'**
  String get taskUpdatedSuccess;

  /// No description provided for @taskEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Title'**
  String get taskEditTitle;

  /// No description provided for @taskEditTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Fix leaking tap'**
  String get taskEditTitleHint;

  /// No description provided for @taskEditTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get taskEditTitleRequired;

  /// No description provided for @taskEditDescHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue...'**
  String get taskEditDescHint;

  /// No description provided for @taskEditDescRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get taskEditDescRequired;

  /// No description provided for @taskEditDescMin.
  ///
  /// In en, this message translates to:
  /// **'Add more details'**
  String get taskEditDescMin;

  /// No description provided for @taskEditLocHint.
  ///
  /// In en, this message translates to:
  /// **'Where should this be done?'**
  String get taskEditLocHint;

  /// No description provided for @taskEditLocRequired.
  ///
  /// In en, this message translates to:
  /// **'Location is required'**
  String get taskEditLocRequired;

  /// No description provided for @taskEditBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget (₹)'**
  String get taskEditBudgetLabel;

  /// No description provided for @taskEditBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 500'**
  String get taskEditBudgetHint;

  /// No description provided for @taskEditBudgetRequired.
  ///
  /// In en, this message translates to:
  /// **'Budget is required'**
  String get taskEditBudgetRequired;

  /// No description provided for @taskEditBudgetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount'**
  String get taskEditBudgetInvalid;

  /// No description provided for @taskSaveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get taskSaveChanges;

  /// No description provided for @taskDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String taskDue(String date);

  /// No description provided for @commonChooseGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get commonChooseGallery;

  /// No description provided for @commonTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get commonTakePhoto;

  /// No description provided for @profileChangePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get profileChangePhoto;

  /// No description provided for @profilePhotoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated'**
  String get profilePhotoUpdated;

  /// No description provided for @reputationSummary.
  ///
  /// In en, this message translates to:
  /// **'{jobs} jobs • {reliability}% reliable'**
  String reputationSummary(int jobs, int reliability);

  /// No description provided for @taskTaskerCancelledReview.
  ///
  /// In en, this message translates to:
  /// **'Your tasker cancelled — please choose another offer.'**
  String get taskTaskerCancelledReview;
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
