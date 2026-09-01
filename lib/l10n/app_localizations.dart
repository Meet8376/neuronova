import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_as.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ne.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('as'),
    Locale('bn'),
    Locale('en'),
    Locale('hi'),
    Locale('ne')
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'NeuroNova'**
  String get appName;

  /// Shown on splash screen
  ///
  /// In en, this message translates to:
  /// **'Your memory companion'**
  String get appTagline;

  /// No description provided for @selectYourRole.
  ///
  /// In en, this message translates to:
  /// **'Select Your Role'**
  String get selectYourRole;

  /// No description provided for @patientLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientLabel;

  /// No description provided for @caregiverLabel.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get caregiverLabel;

  /// No description provided for @enterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enterPin;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @wrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN. Please try again.'**
  String get wrongPin;

  /// No description provided for @selectRole.
  ///
  /// In en, this message translates to:
  /// **'Please select your role first.'**
  String get selectRole;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextButton;

  /// No description provided for @finishButton.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finishButton;

  /// No description provided for @tryAgainButton.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgainButton;

  /// No description provided for @backButton.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backButton;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @okButton.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okButton;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// Greeting for morning
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @todaysTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Tasks'**
  String get todaysTasks;

  /// No description provided for @noTasksToday.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today. Enjoy your day!'**
  String get noTasksToday;

  /// No description provided for @allTasksDone.
  ///
  /// In en, this message translates to:
  /// **'You finished all tasks today!'**
  String get allTasksDone;

  /// No description provided for @taskStatusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get taskStatusDone;

  /// No description provided for @taskStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get taskStatusMissed;

  /// No description provided for @taskStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get taskStatusUpcoming;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get taskStatusInProgress;

  /// No description provided for @passageHiddenTitle.
  ///
  /// In en, this message translates to:
  /// **'The passage is hidden now.'**
  String get passageHiddenTitle;

  /// No description provided for @passageHiddenHint.
  ///
  /// In en, this message translates to:
  /// **'Speak what you remember!'**
  String get passageHiddenHint;

  /// No description provided for @listeningLabel2.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listeningLabel2;

  /// No description provided for @whatIHeard.
  ///
  /// In en, this message translates to:
  /// **'What I heard:'**
  String get whatIHeard;

  /// No description provided for @tapMicToStart.
  ///
  /// In en, this message translates to:
  /// **'Tap mic to start speaking'**
  String get tapMicToStart;

  /// No description provided for @tapMicToAdd.
  ///
  /// In en, this message translates to:
  /// **'Tap mic to add more'**
  String get tapMicToAdd;

  /// No description provided for @listeningTapStop.
  ///
  /// In en, this message translates to:
  /// **'Listening… tap ■ to stop'**
  String get listeningTapStop;

  /// No description provided for @finishEditingFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish editing before speaking again'**
  String get finishEditingFirst;

  /// No description provided for @speakNow.
  ///
  /// In en, this message translates to:
  /// **'Speak now…'**
  String get speakNow;

  /// No description provided for @tapMicAndSpeak.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic below and start speaking'**
  String get tapMicAndSpeak;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @typeInstead.
  ///
  /// In en, this message translates to:
  /// **'Type instead'**
  String get typeInstead;

  /// No description provided for @useMicInstead.
  ///
  /// In en, this message translates to:
  /// **'Use microphone instead'**
  String get useMicInstead;

  /// No description provided for @checkMyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Check My Answer'**
  String get checkMyAnswer;

  /// No description provided for @typeWhatYouRemember.
  ///
  /// In en, this message translates to:
  /// **'Type what you remember…'**
  String get typeWhatYouRemember;

  /// No description provided for @noContentFound.
  ///
  /// In en, this message translates to:
  /// **'No content found for this selection. Try a different combination.'**
  String get noContentFound;

  /// No description provided for @readyToSpeakButton.
  ///
  /// In en, this message translates to:
  /// **'I\'m Ready to Speak!'**
  String get readyToSpeakButton;

  /// No description provided for @textWillDisappear.
  ///
  /// In en, this message translates to:
  /// **'The text will disappear. Speak from memory.'**
  String get textWillDisappear;

  /// No description provided for @sayWhatYouRemember.
  ///
  /// In en, this message translates to:
  /// **'Say What You Remember'**
  String get sayWhatYouRemember;

  /// No description provided for @gamesTitle.
  ///
  /// In en, this message translates to:
  /// **'Memory Games'**
  String get gamesTitle;

  /// No description provided for @gamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise your mind every day'**
  String get gamesSubtitle;

  /// No description provided for @readMemorizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Read, Memorize & Speak'**
  String get readMemorizeTitle;

  /// No description provided for @readMemorizeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read a passage, remember it, and speak aloud'**
  String get readMemorizeSubtitle;

  /// No description provided for @pictureMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'Picture Match'**
  String get pictureMatchTitle;

  /// No description provided for @pictureMatchSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Match pairs of North Eastern cultural symbols'**
  String get pictureMatchSubtitle;

  /// No description provided for @routineRecallTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Routine Recall'**
  String get routineRecallTitle;

  /// No description provided for @routineRecallSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Arrange everyday activities in the correct time sequence'**
  String get routineRecallSubtitle;

  /// No description provided for @patternRecognitionTitle.
  ///
  /// In en, this message translates to:
  /// **'Pattern Recognition'**
  String get patternRecognitionTitle;

  /// No description provided for @patternRecognitionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Identify and complete traditional weaving patterns'**
  String get patternRecognitionSubtitle;

  /// No description provided for @selectCategory.
  ///
  /// In en, this message translates to:
  /// **'Select Category'**
  String get selectCategory;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectLength.
  ///
  /// In en, this message translates to:
  /// **'Select Length'**
  String get selectLength;

  /// No description provided for @categoryConversation.
  ///
  /// In en, this message translates to:
  /// **'Daily Conversation'**
  String get categoryConversation;

  /// No description provided for @categoryStories.
  ///
  /// In en, this message translates to:
  /// **'Stories'**
  String get categoryStories;

  /// No description provided for @categoryWisdom.
  ///
  /// In en, this message translates to:
  /// **'Wisdom'**
  String get categoryWisdom;

  /// No description provided for @lengthShort.
  ///
  /// In en, this message translates to:
  /// **'Short'**
  String get lengthShort;

  /// No description provided for @lengthMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get lengthMedium;

  /// No description provided for @lengthLong.
  ///
  /// In en, this message translates to:
  /// **'Long'**
  String get lengthLong;

  /// No description provided for @readPhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Read & Memorize'**
  String get readPhaseTitle;

  /// No description provided for @readPhaseHint.
  ///
  /// In en, this message translates to:
  /// **'Read the passage carefully. Take as long as you need.'**
  String get readPhaseHint;

  /// No description provided for @listenButton.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get listenButton;

  /// No description provided for @readyToSpeak.
  ///
  /// In en, this message translates to:
  /// **'I\'m Ready to Speak! 🎙️'**
  String get readyToSpeak;

  /// No description provided for @speakPhaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Speak from Memory'**
  String get speakPhaseTitle;

  /// No description provided for @speakPhaseHint.
  ///
  /// In en, this message translates to:
  /// **'The text is hidden now. Say what you remember!'**
  String get speakPhaseHint;

  /// No description provided for @tapToRecord.
  ///
  /// In en, this message translates to:
  /// **'Tap the mic to start recording'**
  String get tapToRecord;

  /// No description provided for @tapToStop.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop recording'**
  String get tapToStop;

  /// No description provided for @listeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Listening...'**
  String get listeningLabel;

  /// No description provided for @resultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Well Done!'**
  String get resultsTitle;

  /// No description provided for @wordsRecalled.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} words recalled'**
  String wordsRecalled(int count, int total);

  /// No description provided for @star1Message.
  ///
  /// In en, this message translates to:
  /// **'That\'s okay! Every attempt helps your memory!'**
  String get star1Message;

  /// No description provided for @star2Message.
  ///
  /// In en, this message translates to:
  /// **'Good effort! Keep practicing!'**
  String get star2Message;

  /// No description provided for @star3Message.
  ///
  /// In en, this message translates to:
  /// **'Wonderful! You remembered so well!'**
  String get star3Message;

  /// No description provided for @ttsNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Audio not available for this language'**
  String get ttsNotSupported;

  /// No description provided for @careplanTitle.
  ///
  /// In en, this message translates to:
  /// **'Care Plan'**
  String get careplanTitle;

  /// No description provided for @addTaskButton.
  ///
  /// In en, this message translates to:
  /// **'+ Add Task'**
  String get addTaskButton;

  /// No description provided for @addReminderButton.
  ///
  /// In en, this message translates to:
  /// **'+ Add Reminder'**
  String get addReminderButton;

  /// No description provided for @taskNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter task name...'**
  String get taskNameHint;

  /// No description provided for @setTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Set Time'**
  String get setTimeLabel;

  /// No description provided for @medicineTab.
  ///
  /// In en, this message translates to:
  /// **'Medicine'**
  String get medicineTab;

  /// No description provided for @hydrationTab.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydrationTab;

  /// No description provided for @remindersTab.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTab;

  /// No description provided for @noRemindersYet.
  ///
  /// In en, this message translates to:
  /// **'No reminders set yet.'**
  String get noRemindersYet;

  /// No description provided for @noMedicinesYet.
  ///
  /// In en, this message translates to:
  /// **'No medicines scheduled yet.'**
  String get noMedicinesYet;

  /// No description provided for @progressTitle.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progressTitle;

  /// No description provided for @sessionsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Sessions This Week'**
  String get sessionsThisWeek;

  /// No description provided for @noSessionsYet.
  ///
  /// In en, this message translates to:
  /// **'No sessions played yet. Start a game!'**
  String get noSessionsYet;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @patientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Patient Name'**
  String get patientNameLabel;

  /// No description provided for @caregiverNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Caregiver Name'**
  String get caregiverNameLabel;

  /// No description provided for @emergencyContactLabel.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contact'**
  String get emergencyContactLabel;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettingsTitle;

  /// No description provided for @primaryLanguageLabel.
  ///
  /// In en, this message translates to:
  /// **'Primary Language'**
  String get primaryLanguageLabel;

  /// No description provided for @additionalLanguagesLabel.
  ///
  /// In en, this message translates to:
  /// **'Play games in:'**
  String get additionalLanguagesLabel;

  /// No description provided for @textSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSizeLabel;

  /// No description provided for @ttsSpeedLabel.
  ///
  /// In en, this message translates to:
  /// **'Speaking Speed'**
  String get ttsSpeedLabel;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get logoutButton;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirm;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langHindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी (Hindi)'**
  String get langHindi;

  /// No description provided for @langBengali.
  ///
  /// In en, this message translates to:
  /// **'বাংলা (Bengali)'**
  String get langBengali;

  /// No description provided for @langAssamese.
  ///
  /// In en, this message translates to:
  /// **'অসমীয়া (Assamese)'**
  String get langAssamese;

  /// No description provided for @langNepali.
  ///
  /// In en, this message translates to:
  /// **'नेपाली (Nepali)'**
  String get langNepali;

  /// No description provided for @adminDashTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get adminDashTitle;

  /// No description provided for @patientsTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get patientsTabLabel;

  /// No description provided for @overviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewLabel;

  /// No description provided for @cognitiveIndexLabel.
  ///
  /// In en, this message translates to:
  /// **'Cognitive Index'**
  String get cognitiveIndexLabel;

  /// No description provided for @lastActiveLabel.
  ///
  /// In en, this message translates to:
  /// **'Last Active'**
  String get lastActiveLabel;

  /// No description provided for @syncButton.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncButton;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete!'**
  String get syncComplete;

  /// No description provided for @attentionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Needs Attention'**
  String get attentionNeeded;

  /// No description provided for @stableStatus.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get stableStatus;

  /// No description provided for @emergencyCallButton.
  ///
  /// In en, this message translates to:
  /// **'Emergency Call'**
  String get emergencyCallButton;

  /// No description provided for @emergencyConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Call'**
  String get emergencyConfirmTitle;

  /// No description provided for @emergencyConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Call your caregiver now?'**
  String get emergencyConfirmBody;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @medicineAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Medicine Reminder'**
  String get medicineAlarmTitle;

  /// No description provided for @hydrationAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Hydration Reminder'**
  String get hydrationAlarmTitle;

  /// No description provided for @taskAlarmTitle.
  ///
  /// In en, this message translates to:
  /// **'Task Reminder'**
  String get taskAlarmTitle;

  /// No description provided for @loadingLabel.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingLabel;

  /// No description provided for @translatingContent.
  ///
  /// In en, this message translates to:
  /// **'Setting up {language} content...'**
  String translatingContent(String language);

  /// No description provided for @needsInternetForSetup.
  ///
  /// In en, this message translates to:
  /// **'Internet needed to set up {language} for the first time. Will complete when connected.'**
  String needsInternetForSetup(String language);

  /// No description provided for @translationComplete.
  ///
  /// In en, this message translates to:
  /// **'{language} content is ready!'**
  String translationComplete(String language);

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @downloadingModel.
  ///
  /// In en, this message translates to:
  /// **'Downloading {language} language model (one-time, needs Wi-Fi)...'**
  String downloadingModel(String language);

  /// No description provided for @modelReady.
  ///
  /// In en, this message translates to:
  /// **'{language} model ready — works offline from now on!'**
  String modelReady(String language);

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get enterUsername;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @wrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Wrong username or password.'**
  String get wrongCredentials;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get navHealth;

  /// No description provided for @navGames.
  ///
  /// In en, this message translates to:
  /// **'Games'**
  String get navGames;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @seeAllTasks.
  ///
  /// In en, this message translates to:
  /// **'See all tasks'**
  String get seeAllTasks;

  /// No description provided for @deleteTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete task?'**
  String get deleteTaskTitle;

  /// No description provided for @yesDelete.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete'**
  String get yesDelete;

  /// No description provided for @brainGames.
  ///
  /// In en, this message translates to:
  /// **'Brain Games'**
  String get brainGames;

  /// No description provided for @brainGamesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Exercise your mind every day'**
  String get brainGamesSubtitle;

  /// No description provided for @viewPracticeHistory.
  ///
  /// In en, this message translates to:
  /// **'View practice history'**
  String get viewPracticeHistory;

  /// No description provided for @newTask.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get newTask;

  /// No description provided for @quickPick.
  ///
  /// In en, this message translates to:
  /// **'Quick pick'**
  String get quickPick;

  /// No description provided for @choosePracticeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose practice language'**
  String get choosePracticeLanguage;

  /// No description provided for @gameLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Your app language is pre-selected. Change just for this game.'**
  String get gameLanguageHint;

  /// No description provided for @healthTitle.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthTitle;

  /// No description provided for @noTasksHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add Task\" to get started'**
  String get noTasksHint;

  /// No description provided for @medicines.
  ///
  /// In en, this message translates to:
  /// **'Medicines'**
  String get medicines;

  /// No description provided for @hydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydration;

  /// No description provided for @noMedicinesScheduled.
  ///
  /// In en, this message translates to:
  /// **'No medicines scheduled for today'**
  String get noMedicinesScheduled;

  /// No description provided for @askCaregiverMedicine.
  ///
  /// In en, this message translates to:
  /// **'Ask your caregiver to set up your medicine schedule'**
  String get askCaregiverMedicine;

  /// No description provided for @takenButton.
  ///
  /// In en, this message translates to:
  /// **'Taken'**
  String get takenButton;

  /// No description provided for @doneMark.
  ///
  /// In en, this message translates to:
  /// **'Done ✓'**
  String get doneMark;

  /// No description provided for @hydrationGreat.
  ///
  /// In en, this message translates to:
  /// **'Great job! 🎉'**
  String get hydrationGreat;

  /// No description provided for @hydrationKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'Keep drinking water!'**
  String get hydrationKeepGoing;

  /// No description provided for @glassesOfDay.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total} glasses today'**
  String glassesOfDay(int count, int total);

  /// No description provided for @drankGlass.
  ///
  /// In en, this message translates to:
  /// **'I drank a glass of water'**
  String get drankGlass;

  /// No description provided for @dailyGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Daily water goal reached!'**
  String get dailyGoalReached;

  /// No description provided for @byCaregiver.
  ///
  /// In en, this message translates to:
  /// **'By caregiver'**
  String get byCaregiver;

  /// No description provided for @byYou.
  ///
  /// In en, this message translates to:
  /// **'By you'**
  String get byYou;

  /// No description provided for @markAsDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as Done'**
  String get markAsDone;

  /// No description provided for @imStartingNow.
  ///
  /// In en, this message translates to:
  /// **'I\'m Starting Now'**
  String get imStartingNow;

  /// No description provided for @remindMeLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Me Later'**
  String get remindMeLater;

  /// No description provided for @editTask.
  ///
  /// In en, this message translates to:
  /// **'Edit task'**
  String get editTask;

  /// No description provided for @practiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice ✨'**
  String get practiceTitle;

  /// No description provided for @whatYouPractised.
  ///
  /// In en, this message translates to:
  /// **'What you practised'**
  String get whatYouPractised;

  /// No description provided for @todayLabel.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get todayLabel;

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalLabel;

  /// No description provided for @readyToBegin.
  ///
  /// In en, this message translates to:
  /// **'Ready to begin?'**
  String get readyToBegin;

  /// No description provided for @practiseMemoryHint.
  ///
  /// In en, this message translates to:
  /// **'Practise your memory — every session helps your brain stay sharp!'**
  String get practiseMemoryHint;

  /// No description provided for @practiceAgain.
  ///
  /// In en, this message translates to:
  /// **'Practice Again'**
  String get practiceAgain;

  /// No description provided for @startPractising.
  ///
  /// In en, this message translates to:
  /// **'Start Practising'**
  String get startPractising;

  /// No description provided for @warmMessage3Stars.
  ///
  /// In en, this message translates to:
  /// **'Wonderful practice!'**
  String get warmMessage3Stars;

  /// No description provided for @warmMessage2Stars.
  ///
  /// In en, this message translates to:
  /// **'Great effort today!'**
  String get warmMessage2Stars;

  /// No description provided for @warmMessage1Star.
  ///
  /// In en, this message translates to:
  /// **'Every practice helps! ❤️'**
  String get warmMessage1Star;

  /// No description provided for @originalPassageLabel.
  ///
  /// In en, this message translates to:
  /// **'The original passage:'**
  String get originalPassageLabel;

  /// No description provided for @whatYouSaidLabel.
  ///
  /// In en, this message translates to:
  /// **'What you said:'**
  String get whatYouSaidLabel;

  /// No description provided for @nothingRecorded.
  ///
  /// In en, this message translates to:
  /// **'(Nothing was recorded)'**
  String get nothingRecorded;

  /// No description provided for @tryAgainGame.
  ///
  /// In en, this message translates to:
  /// **'Try Again 💪'**
  String get tryAgainGame;

  /// No description provided for @saveAndFinish.
  ///
  /// In en, this message translates to:
  /// **'Save & Finish 🏁'**
  String get saveAndFinish;

  /// No description provided for @wonderfulJob.
  ///
  /// In en, this message translates to:
  /// **'Wonderful Job!'**
  String get wonderfulJob;

  /// No description provided for @backToGames.
  ///
  /// In en, this message translates to:
  /// **'Back to Games'**
  String get backToGames;

  /// No description provided for @greatSequence.
  ///
  /// In en, this message translates to:
  /// **'Great Sequence!'**
  String get greatSequence;

  /// No description provided for @goodEffortLabel.
  ///
  /// In en, this message translates to:
  /// **'Good Effort!'**
  String get goodEffortLabel;

  /// No description provided for @patternCompleted.
  ///
  /// In en, this message translates to:
  /// **'Pattern Completed!'**
  String get patternCompleted;

  /// No description provided for @orderYourRoutine.
  ///
  /// In en, this message translates to:
  /// **'Order Your Daily Routine'**
  String get orderYourRoutine;

  /// No description provided for @dragReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag and reorder the cards from earliest to latest in the day.'**
  String get dragReorderHint;

  /// No description provided for @checkRoutineSequence.
  ///
  /// In en, this message translates to:
  /// **'Check Routine Sequence'**
  String get checkRoutineSequence;

  /// No description provided for @lookAtPattern.
  ///
  /// In en, this message translates to:
  /// **'Look at the pattern below. Which motif comes next?'**
  String get lookAtPattern;

  /// No description provided for @selectCorrectMotif.
  ///
  /// In en, this message translates to:
  /// **'Select the correct motif:'**
  String get selectCorrectMotif;

  /// No description provided for @movesLabel.
  ///
  /// In en, this message translates to:
  /// **'Moves: {count}'**
  String movesLabel(int count);

  /// No description provided for @timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time: {seconds}s'**
  String timeLabel(int seconds);

  /// No description provided for @pairsLabel.
  ///
  /// In en, this message translates to:
  /// **'Pairs: {found}/{total}'**
  String pairsLabel(int found, int total);

  /// No description provided for @questionLabel.
  ///
  /// In en, this message translates to:
  /// **'Question {current}/{total}'**
  String questionLabel(int current, int total);

  /// No description provided for @youMatchedAll.
  ///
  /// In en, this message translates to:
  /// **'You matched all {pairs} pairs in {moves} moves and {seconds} seconds!'**
  String youMatchedAll(int pairs, int moves, int seconds);

  /// No description provided for @youPlaced.
  ///
  /// In en, this message translates to:
  /// **'You placed {correct} out of {total} activities in the correct order in {seconds}s.'**
  String youPlaced(int correct, int total, int seconds);

  /// No description provided for @youSolved.
  ///
  /// In en, this message translates to:
  /// **'You solved {correct} out of {total} pattern sequences correctly in {seconds}s!'**
  String youSolved(int correct, int total, int seconds);

  /// No description provided for @warmResultGreat.
  ///
  /// In en, this message translates to:
  /// **'Wonderful! You remembered so well! 🌟'**
  String get warmResultGreat;

  /// No description provided for @subResultGreat.
  ///
  /// In en, this message translates to:
  /// **'Your memory is doing amazing work today.'**
  String get subResultGreat;

  /// No description provided for @subResultGood.
  ///
  /// In en, this message translates to:
  /// **'You\'re improving with every try — keep it up!'**
  String get subResultGood;

  /// No description provided for @subResultOkay.
  ///
  /// In en, this message translates to:
  /// **'Want to try again? The text will come back for you.'**
  String get subResultOkay;

  /// No description provided for @whoAmIBanner.
  ///
  /// In en, this message translates to:
  /// **'👤 Who Am I? · Tap for your story'**
  String get whoAmIBanner;

  /// No description provided for @whoAmIQuick.
  ///
  /// In en, this message translates to:
  /// **'Who Am I?'**
  String get whoAmIQuick;

  /// No description provided for @safeZoneQuick.
  ///
  /// In en, this message translates to:
  /// **'Safe Zone'**
  String get safeZoneQuick;

  /// No description provided for @memoriesQuick.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get memoriesQuick;

  /// No description provided for @readTasksQuick.
  ///
  /// In en, this message translates to:
  /// **'Read tasks'**
  String get readTasksQuick;

  /// No description provided for @stopQuick.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopQuick;

  /// No description provided for @hydrationQuick.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get hydrationQuick;

  /// No description provided for @calmBreatheQuick.
  ///
  /// In en, this message translates to:
  /// **'Calm Breathe'**
  String get calmBreatheQuick;

  /// No description provided for @allClear.
  ///
  /// In en, this message translates to:
  /// **'All clear!'**
  String get allClear;

  /// No description provided for @noTasksForTodayTapPlus.
  ///
  /// In en, this message translates to:
  /// **'No tasks for today — tap + to add one'**
  String get noTasksForTodayTapPlus;

  /// No description provided for @sos.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sos;

  /// No description provided for @returnToLogin.
  ///
  /// In en, this message translates to:
  /// **'Return to the login screen'**
  String get returnToLogin;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @resetAppSetup.
  ///
  /// In en, this message translates to:
  /// **'Reset App Setup'**
  String get resetAppSetup;

  /// No description provided for @clearNamesSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Clear names and setup — keeps game history'**
  String get clearNamesSetupHint;

  /// No description provided for @caregiverViewBadge.
  ///
  /// In en, this message translates to:
  /// **'Caregiver View'**
  String get caregiverViewBadge;

  /// No description provided for @patientViewBadge.
  ///
  /// In en, this message translates to:
  /// **'Patient View'**
  String get patientViewBadge;

  /// No description provided for @accountSection.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountSection;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @phoneHelper.
  ///
  /// In en, this message translates to:
  /// **'Patients use this for the \"Call for Help\" button'**
  String get phoneHelper;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @resetAppConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will erase all names and setup. Task and game history will be kept.'**
  String get resetAppConfirm;

  /// No description provided for @resetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset App?'**
  String get resetTitle;

  /// No description provided for @addReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {type} Reminder'**
  String addReminderTitle(String type);

  /// No description provided for @reminderName.
  ///
  /// In en, this message translates to:
  /// **'Reminder name'**
  String get reminderName;

  /// No description provided for @reminderNameHelper.
  ///
  /// In en, this message translates to:
  /// **'What should it say on the alarm?'**
  String get reminderNameHelper;

  /// No description provided for @scheduleType.
  ///
  /// In en, this message translates to:
  /// **'Schedule type'**
  String get scheduleType;

  /// No description provided for @atSpecificTimes.
  ///
  /// In en, this message translates to:
  /// **'At specific times'**
  String get atSpecificTimes;

  /// No description provided for @everyFewHours.
  ///
  /// In en, this message translates to:
  /// **'Every few hours'**
  String get everyFewHours;

  /// No description provided for @dailyGoalMode.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get dailyGoalMode;

  /// No description provided for @timesSection.
  ///
  /// In en, this message translates to:
  /// **'Times'**
  String get timesSection;

  /// No description provided for @addTime.
  ///
  /// In en, this message translates to:
  /// **'Add time'**
  String get addTime;

  /// No description provided for @saveReminder.
  ///
  /// In en, this message translates to:
  /// **'Save Reminder'**
  String get saveReminder;

  /// No description provided for @remindEveryHours.
  ///
  /// In en, this message translates to:
  /// **'Remind every {hours} hours'**
  String remindEveryHours(String hours);

  /// No description provided for @fromLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// No description provided for @untilLabel.
  ///
  /// In en, this message translates to:
  /// **'Until'**
  String get untilLabel;

  /// No description provided for @unitLabel.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// No description provided for @breakfastLabel.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get breakfastLabel;

  /// No description provided for @lunchLabel.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get lunchLabel;

  /// No description provided for @dinnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get dinnerLabel;

  /// No description provided for @morningWalkLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning walk'**
  String get morningWalkLabel;

  /// No description provided for @bedtimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get bedtimeLabel;

  /// No description provided for @eveningCallLabel.
  ///
  /// In en, this message translates to:
  /// **'Evening call'**
  String get eveningCallLabel;

  /// No description provided for @morningRoutineLabel.
  ///
  /// In en, this message translates to:
  /// **'Morning routine'**
  String get morningRoutineLabel;

  /// No description provided for @goodMorningGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get goodMorningGreeting;

  /// No description provided for @goodAfternoonGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get goodAfternoonGreeting;

  /// No description provided for @goodEveningGreeting.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get goodEveningGreeting;
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
      <String>['as', 'bn', 'en', 'hi', 'ne'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'as':
      return AppLocalizationsAs();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'ne':
      return AppLocalizationsNe();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
