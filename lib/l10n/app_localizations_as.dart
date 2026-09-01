// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Assamese (`as`).
class AppLocalizationsAs extends AppLocalizations {
  AppLocalizationsAs([String locale = 'as']) : super(locale);

  @override
  String get appName => 'কগনিকেয়াৰ';

  @override
  String get appTagline => 'আপোনাৰ স্মৃতিৰ সঙ্গী';

  @override
  String get selectYourRole => 'আপোনাৰ ভূমিকা বাছক';

  @override
  String get patientLabel => 'ৰোগী';

  @override
  String get caregiverLabel => 'পৰিচৰ্যাকাৰী';

  @override
  String get enterPin => 'PIN দিয়ক';

  @override
  String get loginButton => 'লগইন';

  @override
  String get wrongPin => 'ভুল PIN। পুনৰ চেষ্টা কৰক।';

  @override
  String get selectRole => 'প্ৰথমে আপোনাৰ ভূমিকা বাছক।';

  @override
  String get startButton => 'আৰম্ভ কৰক';

  @override
  String get nextButton => 'পৰৱৰ্তী';

  @override
  String get finishButton => 'শেষ কৰক';

  @override
  String get tryAgainButton => 'পুনৰ চেষ্টা কৰক';

  @override
  String get backButton => 'পিছলৈ';

  @override
  String get saveButton => 'সংৰক্ষণ কৰক';

  @override
  String get cancelButton => 'বাতিল কৰক';

  @override
  String get doneButton => 'হৈছে';

  @override
  String get okButton => 'ঠিক আছে';

  @override
  String get retryButton => 'পুনৰ চেষ্টা কৰক';

  @override
  String get goodMorning => 'শুভ পুৱা';

  @override
  String get goodAfternoon => 'শুভ দুপৰীয়া';

  @override
  String get goodEvening => 'শুভ সন্ধিয়া';

  @override
  String get todaysTasks => 'আজিৰ কাম';

  @override
  String get noTasksToday => 'আজিৰ বাবে কোনো কাম নাই। আপোনাৰ দিনটো উপভোগ কৰক!';

  @override
  String get allTasksDone => 'আপুনি আজিৰ সকলো কাম শেষ কৰিছে!';

  @override
  String get taskStatusDone => 'সম্পন্ন';

  @override
  String get taskStatusMissed => 'হেৰাই গৈছে';

  @override
  String get taskStatusUpcoming => 'আহিব';

  @override
  String get gamesTitle => 'মেমৰি গেমছ';

  @override
  String get gamesSubtitle => 'প্ৰতিদিন আপোনাৰ মগজু সক্ৰিয় ৰাখক';

  @override
  String get readMemorizeTitle => 'পঢ়ক, মনত ৰাখক আৰু ক\'ব';

  @override
  String get readMemorizeSubtitle =>
      'এটি অনুচ্ছেদ পঢ়ক, মনত ৰাখক আৰু জোৰে ক\'ব';

  @override
  String get pictureMatchTitle => 'ছবি মিলাওক';

  @override
  String get pictureMatchSubtitle => 'উত্তৰ-পূৱৰ সাংস্কৃতিক প্ৰতীকৰ যোৰ মিলাওক';

  @override
  String get routineRecallTitle => 'দৈনিক ৰুটিন মনত ৰাখক';

  @override
  String get routineRecallSubtitle => 'দৈনন্দিন কামবোৰ সঠিক ক্ৰমত সজাওক';

  @override
  String get patternRecognitionTitle => 'আৰ্হি চিনাক্ত কৰক';

  @override
  String get patternRecognitionSubtitle =>
      'পৰম্পৰাগত বয়নৰ আৰ্হি চিনাক্ত কৰক আৰু সম্পূৰ্ণ কৰক';

  @override
  String get selectCategory => 'শ্ৰেণী বাছক';

  @override
  String get selectLanguage => 'ভাষা বাছক';

  @override
  String get selectLength => 'দৈৰ্ঘ্য বাছক';

  @override
  String get categoryConversation => 'দৈনিক কথা-বতৰা';

  @override
  String get categoryStories => 'কাহিনী';

  @override
  String get categoryWisdom => 'জ্ঞান';

  @override
  String get lengthShort => 'চুটি';

  @override
  String get lengthMedium => 'মধ্যম';

  @override
  String get lengthLong => 'দীঘল';

  @override
  String get readPhaseTitle => 'পঢ়ক আৰু মনত ৰাখক';

  @override
  String get readPhaseHint => 'অনুচ্ছেদটো মনোযোগেৰে পঢ়ক। যিমান সময় লাগে লওক।';

  @override
  String get listenButton => 'শুনক';

  @override
  String get readyToSpeak => 'মই ক\'বলৈ সাজু! 🎙️';

  @override
  String get speakPhaseTitle => 'মনৰ পৰা কওক';

  @override
  String get speakPhaseHint => 'লিখাটো এতিয়া লুকাই আছে। মনত যি আছে কওক!';

  @override
  String get tapToRecord => 'ৰেকৰ্ড কৰিবলৈ মাইকত চাপক';

  @override
  String get tapToStop => 'ৰুকিবলৈ চাপক';

  @override
  String get listeningLabel => 'শুনিছোঁ...';

  @override
  String get resultsTitle => 'বাহ, অতিশয় ভাল!';

  @override
  String wordsRecalled(int count, int total) {
    return '$total টিৰ মধ্যত $count টি শব্দ মনত পেলাইছে';
  }

  @override
  String get star1Message =>
      'ঠিকেই আছে! প্ৰতিটো প্ৰচেষ্টাই আপোনাৰ স্মৃতিশক্তিত সহায় কৰে!';

  @override
  String get star2Message => 'ভাল প্ৰচেষ্টা! অনুশীলন কৰি যাওক!';

  @override
  String get star3Message => 'অপূৰ্ব! আপুনি ইমান ভালকৈ মনত ৰাখিছে!';

  @override
  String get ttsNotSupported => 'এই ভাষাৰ বাবে অডিঅ\' উপলব্ধ নহয়';

  @override
  String get careplanTitle => 'পৰিচৰ্যা পৰিকল্পনা';

  @override
  String get addTaskButton => '+ কাম যোগ কৰক';

  @override
  String get addReminderButton => '+ সোঁৱৰণী যোগ কৰক';

  @override
  String get taskNameHint => 'কামৰ নাম দিয়ক...';

  @override
  String get setTimeLabel => 'সময় নিৰ্ধাৰণ কৰক';

  @override
  String get medicineTab => 'দৰব';

  @override
  String get hydrationTab => 'পানী';

  @override
  String get remindersTab => 'সোঁৱৰণী';

  @override
  String get noRemindersYet => 'এতিয়ালৈকে কোনো সোঁৱৰণী নাই।';

  @override
  String get noMedicinesYet => 'এতিয়ালৈকে কোনো দৰব নিৰ্ধাৰণ কৰা হোৱা নাই।';

  @override
  String get progressTitle => 'অগ্ৰগতি';

  @override
  String get sessionsThisWeek => 'এই সপ্তাহৰ অধিবেশন';

  @override
  String get noSessionsYet =>
      'এতিয়ালৈকে কোনো অধিবেশন খেলা হোৱা নাই। এটা গেম আৰম্ভ কৰক!';

  @override
  String get profileTitle => 'প্ৰফাইল';

  @override
  String get patientNameLabel => 'ৰোগীৰ নাম';

  @override
  String get caregiverNameLabel => 'পৰিচৰ্যাকাৰীৰ নাম';

  @override
  String get emergencyContactLabel => 'জৰুৰীকালীন যোগাযোগ';

  @override
  String get languageSettingsTitle => 'ভাষাৰ ছেটিং';

  @override
  String get primaryLanguageLabel => 'মূখ্য ভাষা';

  @override
  String get additionalLanguagesLabel => 'গেম খেলক এইবোৰত:';

  @override
  String get textSizeLabel => 'আখৰৰ আকাৰ';

  @override
  String get ttsSpeedLabel => 'কথা কোৱাৰ গতি';

  @override
  String get logoutButton => 'লগ আউট';

  @override
  String get logoutConfirm => 'আপুনি সঁচাকৈ লগ আউট কৰিব বিচাৰেনে?';

  @override
  String get langEnglish => 'English';

  @override
  String get langHindi => 'हिंदी (Hindi)';

  @override
  String get langBengali => 'বাংলা (Bengali)';

  @override
  String get langAssamese => 'অসমীয়া (Assamese)';

  @override
  String get langNepali => 'नेपाली (Nepali)';

  @override
  String get adminDashTitle => 'ডেশ্বব\'ৰ্ড';

  @override
  String get patientsTabLabel => 'ৰোগী';

  @override
  String get overviewLabel => 'সাৰাংশ';

  @override
  String get cognitiveIndexLabel => 'জ্ঞানমূলক সূচক';

  @override
  String get lastActiveLabel => 'শেষবাৰ সক্ৰিয়';

  @override
  String get syncButton => 'এতিয়া ছিংক কৰক';

  @override
  String get syncComplete => 'ছিংক সম্পন্ন!';

  @override
  String get attentionNeeded => 'মনোযোগ প্ৰয়োজন';

  @override
  String get stableStatus => 'স্থিৰ';

  @override
  String get emergencyCallButton => 'জৰুৰীকালীন কল';

  @override
  String get emergencyConfirmTitle => 'জৰুৰীকালীন কল';

  @override
  String get emergencyConfirmBody => 'এতিয়া পৰিচৰ্যাকাৰীক কল কৰিবনে?';

  @override
  String get yes => 'হয়';

  @override
  String get no => 'নহয়';

  @override
  String get medicineAlarmTitle => 'দৰব খোৱাৰ সময়';

  @override
  String get hydrationAlarmTitle => 'পানী খোৱাৰ সময়';

  @override
  String get taskAlarmTitle => 'কামৰ সোঁৱৰণী';

  @override
  String get loadingLabel => 'লোড হৈ আছে...';

  @override
  String translatingContent(String language) {
    return '$language সামগ্ৰী প্ৰস্তুত হৈ আছে...';
  }

  @override
  String needsInternetForSetup(String language) {
    return '$language প্ৰথমবাৰৰ বাবে ছেট আপ কৰিবলৈ ইণ্টাৰনেট লাগিব। সংযুক্ত হ\'লে স্বয়ংক্ৰিয়ভাৱে সম্পন্ন হ\'ব।';
  }

  @override
  String translationComplete(String language) {
    return '$language সামগ্ৰী সাজু!';
  }

  @override
  String get somethingWentWrong => 'কিবা ভুল হৈছে। পুনৰ চেষ্টা কৰক।';

  @override
  String downloadingModel(String language) {
    return '$language ভাষা মডেল ডাউনলোড হৈ আছে (এবাৰ, Wi-Fi লাগিব)...';
  }

  @override
  String modelReady(String language) {
    return '$language মডেল সাজু — এতিয়া অফলাইনতো কাম কৰিব!';
  }

  @override
  String get welcomeBack => 'আপোনালৈ স্বাগতম';

  @override
  String get signInToContinue => 'চলি থকিবলৈ চাইন ইন কৰক';

  @override
  String get username => 'ব্যৱহাৰকাৰীৰ নাম';

  @override
  String get enterUsername => 'আপোনাৰ ব্যৱহাৰকাৰীৰ নাম দিয়ক';

  @override
  String get password => 'পাছৱৰ্ড';

  @override
  String get enterPassword => 'আপোনাৰ পাছৱৰ্ড দিয়ক';

  @override
  String get signInButton => 'চাইন ইন';

  @override
  String get wrongCredentials => 'ভুল ব্যৱহাৰকাৰীৰ নাম বা পাছৱৰ্ড।';

  @override
  String get navHome => 'হোম';

  @override
  String get navHealth => 'স্বাস্থ্য';

  @override
  String get navGames => 'গেমছ';

  @override
  String get navProfile => 'প্ৰফাইল';

  @override
  String get addTask => 'কাম যোগ কৰক';

  @override
  String get seeAllTasks => 'সকলো কাম চাওক';

  @override
  String get deleteTaskTitle => 'কাম মচি দিয়ক?';

  @override
  String get yesDelete => 'হয়, মচক';

  @override
  String get brainGames => 'মগজুৰ গেমছ';

  @override
  String get brainGamesSubtitle => 'প্ৰতিদিন মগজু সক্ৰিয় ৰাখক';

  @override
  String get viewPracticeHistory => 'অনুশীলনৰ ইতিহাস চাওক';

  @override
  String get newTask => 'নতুন কাম';

  @override
  String get quickPick => 'দ্ৰুত বাছনি';

  @override
  String get choosePracticeLanguage => 'অনুশীলনৰ ভাষা বাছক';

  @override
  String get gameLanguageHint =>
      'আপোনাৰ এপৰ ভাষা আগতে বাছনি কৰা হৈছে। কেৱল এই গেমৰ বাবে সলনি কৰক।';

  @override
  String get healthTitle => 'স্বাস্থ্য';

  @override
  String get noTasksHint => 'আৰম্ভ কৰিবলৈ \"কাম যোগ কৰক\" টেপ কৰক';

  @override
  String get medicines => 'দৰব';

  @override
  String get hydration => 'পানী পান';

  @override
  String get noMedicinesScheduled => 'আজিৰ বাবে কোনো দৰব নিৰ্ধাৰিত নাই';

  @override
  String get askCaregiverMedicine => 'দৰবৰ সময় নিৰ্ধাৰণৰ বাবে যত্নকাৰীক কওক';

  @override
  String get takenButton => 'লোৱা হৈছে';

  @override
  String get doneMark => 'সম্পন্ন ✓';

  @override
  String get hydrationGreat => 'চমৎকাৰ! 🎉';

  @override
  String get hydrationKeepGoing => 'পানী পান কৰি থাকক!';

  @override
  String glassesOfDay(int count, int total) {
    return 'আজি $totalটাৰ মধ্যত $countটা গিলাচ';
  }

  @override
  String get drankGlass => 'মই এগিলাচ পানী খালোঁ';

  @override
  String get dailyGoalReached => 'আজিৰ পানী খোৱাৰ লক্ষ্য পূৰণ হৈছে!';

  @override
  String get byCaregiver => 'যত্নকাৰীৰ দ্বাৰা';

  @override
  String get byYou => 'আপোনাৰ দ্বাৰা';

  @override
  String get markAsDone => 'সম্পন্ন হিচাপে চিহ্নিত কৰক';

  @override
  String get imStartingNow => 'মই এতিয়া আৰম্ভ কৰিছোঁ';

  @override
  String get remindMeLater => 'পিছত মনে পেলাই দিব';

  @override
  String get editTask => 'সম্পাদনা কৰক';

  @override
  String get practiceTitle => 'অভ্যাস ✨';

  @override
  String get whatYouPractised => 'আপুনি কি অভ্যাস কৰিলে';

  @override
  String get todayLabel => 'আজি';

  @override
  String get totalLabel => 'মুঠ';

  @override
  String get readyToBegin => 'আৰম্ভ কৰিবলৈ প্ৰস্তুত?';

  @override
  String get practiseMemoryHint =>
      'আপোনাৰ স্মৃতি অভ্যাস কৰক — প্ৰতিটো সত্ৰই আপোনাৰ মগজ সতেজ ৰাখে!';

  @override
  String get practiceAgain => 'পুনৰায় অভ্যাস কৰক';

  @override
  String get startPractising => 'অভ্যাস আৰম্ভ কৰক';

  @override
  String get warmMessage3Stars => 'চমৎকাৰ অভ্যাস!';

  @override
  String get warmMessage2Stars => 'ভাল প্ৰচেষ্টা!';

  @override
  String get warmMessage1Star => 'প্ৰতিটো অভ্যাস সহায় কৰে! ❤️';

  @override
  String get originalPassageLabel => 'মূল অনুচ্ছেদ:';

  @override
  String get whatYouSaidLabel => 'আপুনি কি কৈছিল:';

  @override
  String get nothingRecorded => '(একো ৰেকৰ্ড হোৱা নাই)';

  @override
  String get tryAgainGame => 'পুনৰায় চেষ্টা কৰক 💪';

  @override
  String get saveAndFinish => 'সংৰক্ষণ কৰক আৰু শেষ কৰক 🏁';

  @override
  String get wonderfulJob => 'অসাধাৰণ কাম!';

  @override
  String get backToGames => 'খেলত উভতি যাওক';

  @override
  String get greatSequence => 'চমৎকাৰ ক্ৰম!';

  @override
  String get goodEffortLabel => 'ভাল প্ৰচেষ্টা!';

  @override
  String get patternCompleted => 'আৰ্হি সম্পন্ন হৈছে!';

  @override
  String get orderYourRoutine => 'আপোনাৰ দৈনন্দিন ৰুটিন সজাওক';

  @override
  String get dragReorderHint => 'কাৰ্ডবোৰ পুৱাৰ পৰা গধুলিলৈ ক্ৰমত সজাওক।';

  @override
  String get checkRoutineSequence => 'ৰুটিনৰ ক্ৰম পৰীক্ষা কৰক';

  @override
  String get lookAtPattern => 'তলৰ আৰ্হিটো চাওক। পিছৰটো কি হ\'ব?';

  @override
  String get selectCorrectMotif => 'সঠিক নকশা বাছক:';

  @override
  String movesLabel(int count) {
    return 'চাল: $count';
  }

  @override
  String timeLabel(int seconds) {
    return 'সময়: $secondsসে';
  }

  @override
  String pairsLabel(int found, int total) {
    return 'যোৰ: $found/$total';
  }

  @override
  String questionLabel(int current, int total) {
    return 'প্ৰশ্ন $current/$total';
  }

  @override
  String youMatchedAll(int pairs, int moves, int seconds) {
    return 'আপুনি $movesটা চালত আৰু $seconds ছেকেণ্ডত $pairsটা যোৰ মিলাইছে!';
  }

  @override
  String youPlaced(int correct, int total, int seconds) {
    return 'আপুনি $seconds ছেকেণ্ডত $totalটাৰ মধ্যত $correctটা কাৰ্যক্ৰম সঠিক ক্ৰমত ৰাখিলে।';
  }

  @override
  String youSolved(int correct, int total, int seconds) {
    return 'আপুনি $seconds ছেকেণ্ডত $totalটাৰ মধ্যত $correctটা আৰ্হি সঠিকভাৱে সমাধান কৰিলে!';
  }

  @override
  String get warmResultGreat => 'অসাধাৰণ! আপুনি ইমান ভালকৈ মনত ৰাখিলে! 🌟';

  @override
  String get warmResultGood => 'চমৎকাৰ প্ৰচেষ্টা! চলি থাকক! 💪';

  @override
  String get warmResultOkay =>
      'কোনো সমস্যা নাই! প্ৰতিটো অভ্যাসে স্মৃতিত সহায় কৰে! ❤️';

  @override
  String get subResultGreat => 'আপোনাৰ স্মৃতি আজি অসাধাৰণ কাম কৰিছে।';

  @override
  String get subResultGood => 'প্ৰতিটো প্ৰচেষ্টাত আপুনি উন্নতি কৰিছে!';

  @override
  String get subResultOkay => 'পুনৰায় চেষ্টা কৰিব বিচাৰেনে? পাঠটো উভতি আহিব।';
}
