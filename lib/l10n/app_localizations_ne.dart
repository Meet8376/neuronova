// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Nepali (`ne`).
class AppLocalizationsNe extends AppLocalizations {
  AppLocalizationsNe([String locale = 'ne']) : super(locale);

  @override
  String get appName => 'कग्निकेयर';

  @override
  String get appTagline => 'तपाईंको स्मृतिको साथी';

  @override
  String get selectYourRole => 'आफ्नो भूमिका छान्नुहोस्';

  @override
  String get patientLabel => 'बिरामी';

  @override
  String get caregiverLabel => 'हेरचाहकर्ता';

  @override
  String get enterPin => 'PIN हाल्नुहोस्';

  @override
  String get loginButton => 'लगइन';

  @override
  String get wrongPin => 'गलत PIN। फेरि प्रयास गर्नुहोस्।';

  @override
  String get selectRole => 'पहिले आफ्नो भूमिका छान्नुहोस्।';

  @override
  String get startButton => 'सुरु गर्नुहोस्';

  @override
  String get nextButton => 'अर्को';

  @override
  String get finishButton => 'सकिन्छ';

  @override
  String get tryAgainButton => 'फेरि प्रयास गर्नुहोस्';

  @override
  String get backButton => 'पछाडि';

  @override
  String get saveButton => 'बचत गर्नुहोस्';

  @override
  String get cancelButton => 'रद्द गर्नुहोस्';

  @override
  String get doneButton => 'भयो';

  @override
  String get okButton => 'ठिक छ';

  @override
  String get retryButton => 'पुनः प्रयास गर्नुहोस्';

  @override
  String get goodMorning => 'शुभ प्रभात';

  @override
  String get goodAfternoon => 'शुभ दिउँसो';

  @override
  String get goodEvening => 'शुभ साँझ';

  @override
  String get todaysTasks => 'आजका काम';

  @override
  String get noTasksToday => 'आजका लागि कुनै काम छैन। दिन मज्जाले बिताउनुहोस्!';

  @override
  String get allTasksDone => 'तपाईंले आजका सबै काम सकाउनुभयो!';

  @override
  String get taskStatusDone => 'सम्पन्न';

  @override
  String get taskStatusMissed => 'छुटेको';

  @override
  String get taskStatusUpcoming => 'आउँदो';

  @override
  String get gamesTitle => 'मेमोरी गेमहरू';

  @override
  String get gamesSubtitle => 'प्रतिदिन आफ्नो दिमाग सक्रिय राख्नुहोस्';

  @override
  String get readMemorizeTitle => 'पढ्नुहोस्, सम्झनुहोस् र बोल्नुहोस्';

  @override
  String get readMemorizeSubtitle =>
      'एउटा अनुच्छेद पढ्नुहोस्, सम्झनुहोस् र ठूलो आवाजमा बोल्नुहोस्';

  @override
  String get pictureMatchTitle => 'तस्बिर मिलाउनुहोस्';

  @override
  String get pictureMatchSubtitle =>
      'उत्तर-पूर्वका सांस्कृतिक प्रतीकहरूको जोडी मिलाउनुहोस्';

  @override
  String get routineRecallTitle => 'दैनिक दिनचर्या सम्झनुहोस्';

  @override
  String get routineRecallSubtitle => 'दैनिक गतिविधिहरू सही क्रममा मिलाउनुहोस्';

  @override
  String get patternRecognitionTitle => 'ढाँचा पहिचान गर्नुहोस्';

  @override
  String get patternRecognitionSubtitle =>
      'परम्परागत बुनाइको ढाँचा पहिचान र पूरा गर्नुहोस्';

  @override
  String get selectCategory => 'श्रेणी छान्नुहोस्';

  @override
  String get selectLanguage => 'भाषा छान्नुहोस्';

  @override
  String get selectLength => 'लम्बाइ छान्नुहोस्';

  @override
  String get categoryConversation => 'दैनिक कुराकानी';

  @override
  String get categoryStories => 'कथाहरू';

  @override
  String get categoryWisdom => 'ज्ञान';

  @override
  String get lengthShort => 'छोटो';

  @override
  String get lengthMedium => 'मध्यम';

  @override
  String get lengthLong => 'लामो';

  @override
  String get readPhaseTitle => 'पढ्नुहोस् र सम्झनुहोस्';

  @override
  String get readPhaseHint =>
      'अनुच्छेदलाई ध्यानपूर्वक पढ्नुहोस्। जति समय चाहिन्छ लिनुहोस्।';

  @override
  String get listenButton => 'सुन्नुहोस्';

  @override
  String get readyToSpeak => 'म बोल्न तयार छु! 🎙️';

  @override
  String get speakPhaseTitle => 'सम्झेर बोल्नुहोस्';

  @override
  String get speakPhaseHint =>
      'पाठ अहिले लुकाइएको छ। जे सम्झनुहुन्छ त्यो बोल्नुहोस्!';

  @override
  String get tapToRecord => 'रेकर्ड गर्न माइकमा थिच्नुहोस्';

  @override
  String get tapToStop => 'रोक्न थिच्नुहोस्';

  @override
  String get listeningLabel => 'सुनिरहेको छु...';

  @override
  String get resultsTitle => 'वाह, धेरै राम्रो!';

  @override
  String wordsRecalled(int count, int total) {
    return '$total मध्ये $count शब्द सम्झनुभयो';
  }

  @override
  String get star1Message =>
      'ठिकै छ! हरेक प्रयासले तपाईंको सम्झनाशक्तिमा मद्दत गर्छ!';

  @override
  String get star2Message => 'राम्रो प्रयास! अभ्यास जारी राख्नुहोस्!';

  @override
  String get star3Message => 'अद्भुत! तपाईंले यति राम्रोसँग सम्झनुभयो!';

  @override
  String get ttsNotSupported => 'यस भाषामा अडियो उपलब्ध छैन';

  @override
  String get careplanTitle => 'हेरचाह योजना';

  @override
  String get addTaskButton => '+ काम थप्नुहोस्';

  @override
  String get addReminderButton => '+ सम्झाउने थप्नुहोस्';

  @override
  String get taskNameHint => 'कामको नाम लेख्नुहोस्...';

  @override
  String get setTimeLabel => 'समय तोक्नुहोस्';

  @override
  String get medicineTab => 'औषधि';

  @override
  String get hydrationTab => 'पानी';

  @override
  String get remindersTab => 'सम्झाउने';

  @override
  String get noRemindersYet => 'अहिलेसम्म कुनै सम्झाउने छैन।';

  @override
  String get noMedicinesYet => 'अहिलेसम्म कुनै औषधि तय गरिएको छैन।';

  @override
  String get progressTitle => 'प्रगति';

  @override
  String get sessionsThisWeek => 'यो हप्ताका सत्रहरू';

  @override
  String get noSessionsYet =>
      'अहिलेसम्म कुनै सत्र खेलिएको छैन। एउटा खेल सुरु गर्नुहोस्!';

  @override
  String get profileTitle => 'प्रोफाइल';

  @override
  String get patientNameLabel => 'बिरामीको नाम';

  @override
  String get caregiverNameLabel => 'हेरचाहकर्ताको नाम';

  @override
  String get emergencyContactLabel => 'आपत्कालीन सम्पर्क';

  @override
  String get languageSettingsTitle => 'भाषा सेटिङ';

  @override
  String get primaryLanguageLabel => 'मुख्य भाषा';

  @override
  String get additionalLanguagesLabel => 'खेल खेल्नुहोस् यसमा:';

  @override
  String get textSizeLabel => 'अक्षरको आकार';

  @override
  String get ttsSpeedLabel => 'बोल्ने गति';

  @override
  String get logoutButton => 'लगआउट';

  @override
  String get logoutConfirm => 'के तपाईं साँच्चै लगआउट गर्न चाहनुहुन्छ?';

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
  String get adminDashTitle => 'ड्यासबोर्ड';

  @override
  String get patientsTabLabel => 'बिरामीहरू';

  @override
  String get overviewLabel => 'सारांश';

  @override
  String get cognitiveIndexLabel => 'बौद्धिक सूचकाङ्क';

  @override
  String get lastActiveLabel => 'अन्तिम सक्रिय';

  @override
  String get syncButton => 'अहिले सिंक गर्नुहोस्';

  @override
  String get syncComplete => 'सिंक सम्पन्न!';

  @override
  String get attentionNeeded => 'ध्यान चाहिन्छ';

  @override
  String get stableStatus => 'स्थिर';

  @override
  String get emergencyCallButton => 'आपत्कालीन कल';

  @override
  String get emergencyConfirmTitle => 'आपत्कालीन कल';

  @override
  String get emergencyConfirmBody => 'अहिले हेरचाहकर्तालाई कल गर्नुहोस्?';

  @override
  String get yes => 'हो';

  @override
  String get no => 'होइन';

  @override
  String get medicineAlarmTitle => 'औषधि खाने समय';

  @override
  String get hydrationAlarmTitle => 'पानी पिउने समय';

  @override
  String get taskAlarmTitle => 'कामको सम्झाउने';

  @override
  String get loadingLabel => 'लोड भइरहेको छ...';

  @override
  String translatingContent(String language) {
    return '$language सामग्री तयार भइरहेको छ...';
  }

  @override
  String needsInternetForSetup(String language) {
    return '$language पहिलो पटक सेट अप गर्न इन्टरनेट चाहिन्छ। जडान भएपछि स्वतः पूरा हुनेछ।';
  }

  @override
  String translationComplete(String language) {
    return '$language सामग्री तयार छ!';
  }

  @override
  String get somethingWentWrong => 'केही गलत भयो। फेरि प्रयास गर्नुहोस्।';

  @override
  String downloadingModel(String language) {
    return '$language भाषा मोडल डाउनलोड भइरहेको छ (एक पटक, Wi-Fi चाहिन्छ)...';
  }

  @override
  String modelReady(String language) {
    return '$language मोडल तयार छ — अब अफलाइनमा पनि काम गर्नेछ!';
  }

  @override
  String get welcomeBack => 'फिर्ता स्वागत छ';

  @override
  String get signInToContinue => 'जारी राख्न साइन इन गर्नुहोस्';

  @override
  String get username => 'प्रयोगकर्ता नाम';

  @override
  String get enterUsername => 'आफ्नो प्रयोगकर्ता नाम लेख्नुहोस्';

  @override
  String get password => 'पासवर्ड';

  @override
  String get enterPassword => 'आफ्नो पासवर्ड लेख्नुहोस्';

  @override
  String get signInButton => 'साइन इन';

  @override
  String get wrongCredentials => 'गलत प्रयोगकर्ता नाम वा पासवर्ड।';

  @override
  String get navHome => 'होम';

  @override
  String get navHealth => 'स्वास्थ्य';

  @override
  String get navGames => 'खेलहरू';

  @override
  String get navProfile => 'प्रोफाइल';

  @override
  String get addTask => 'काम थप्नुहोस्';

  @override
  String get seeAllTasks => 'सबै काम हेर्नुहोस्';

  @override
  String get deleteTaskTitle => 'काम मेट्ने?';

  @override
  String get yesDelete => 'हो, मेट्नुहोस्';

  @override
  String get brainGames => 'मस्तिष्क खेलहरू';

  @override
  String get brainGamesSubtitle => 'हरेक दिन आफ्नो मन व्यायाम गर्नुहोस्';

  @override
  String get viewPracticeHistory => 'अभ्यास इतिहास हेर्नुहोस्';

  @override
  String get newTask => 'नयाँ काम';

  @override
  String get quickPick => 'छिटो छान्नुहोस्';

  @override
  String get choosePracticeLanguage => 'अभ्यास भाषा छान्नुहोस्';

  @override
  String get gameLanguageHint =>
      'तपाईंको एप भाषा पहिले नै चयन गरिएको छ। यो खेलको लागि मात्र बदल्नुहोस्।';

  @override
  String get healthTitle => 'स्वास्थ्य';

  @override
  String get noTasksHint => 'सुरु गर्न \"काम थप्नुहोस्\" थिच्नुहोस्';

  @override
  String get medicines => 'औषधिहरू';

  @override
  String get hydration => 'पानी पिउने';

  @override
  String get noMedicinesScheduled => 'आजका लागि कुनै औषधि तोकिएको छैन';

  @override
  String get askCaregiverMedicine =>
      'औषधिको समय तोक्न परिचर्यकारीलाई भन्नुहोस्';

  @override
  String get takenButton => 'लिइयो';

  @override
  String get doneMark => 'भयो ✓';

  @override
  String get hydrationGreat => 'साबास! 🎉';

  @override
  String get hydrationKeepGoing => 'पानी पिइरहनुहोस्!';

  @override
  String glassesOfDay(int count, int total) {
    return 'आज $totalमध्ये $count गिलास';
  }

  @override
  String get drankGlass => 'मैले एक गिलास पानी पिएँ';

  @override
  String get dailyGoalReached => 'आजको पानी पिउने लक्ष्य पूरा भयो!';

  @override
  String get byCaregiver => 'परिचर्यकारीद्वारा';

  @override
  String get byYou => 'तपाईंद्वारा';

  @override
  String get markAsDone => 'सम्पन्न भनेर चिन्ह लगाउनुहोस्';

  @override
  String get imStartingNow => 'म अहिले सुरु गर्दैछु';

  @override
  String get remindMeLater => 'पछि सम्झाउनुहोस्';

  @override
  String get editTask => 'सम्पादन गर्नुहोस्';

  @override
  String get practiceTitle => 'अभ्यास ✨';

  @override
  String get whatYouPractised => 'तपाईंले के अभ्यास गर्नुभयो';

  @override
  String get todayLabel => 'आज';

  @override
  String get totalLabel => 'जम्मा';

  @override
  String get readyToBegin => 'सुरु गर्न तयार हुनुहुन्छ?';

  @override
  String get practiseMemoryHint =>
      'आफ्नो स्मृति अभ्यास गर्नुहोस् — हरेक सत्रले तपाईंको दिमागलाई तेज राख्छ!';

  @override
  String get practiceAgain => 'फेरि अभ्यास गर्नुहोस्';

  @override
  String get startPractising => 'अभ्यास सुरु गर्नुहोस्';

  @override
  String get warmMessage3Stars => 'अद्भुत अभ्यास!';

  @override
  String get warmMessage2Stars => 'राम्रो प्रयास!';

  @override
  String get warmMessage1Star => 'हरेक अभ्यासले मद्दत गर्छ! ❤️';

  @override
  String get originalPassageLabel => 'मूल अनुच्छेद:';

  @override
  String get whatYouSaidLabel => 'तपाईंले के भन्नुभयो:';

  @override
  String get nothingRecorded => '(केही रेकर्ड भएन)';

  @override
  String get tryAgainGame => 'फेरि प्रयास गर्नुहोस् 💪';

  @override
  String get saveAndFinish => 'सुरक्षित गर्नुहोस् र समाप्त गर्नुहोस् 🏁';

  @override
  String get wonderfulJob => 'अद्भुत काम!';

  @override
  String get backToGames => 'खेलमा फर्कनुहोस्';

  @override
  String get greatSequence => 'राम्रो क्रम!';

  @override
  String get goodEffortLabel => 'राम्रो प्रयास!';

  @override
  String get patternCompleted => 'ढाँचा सम्पन्न भयो!';

  @override
  String get orderYourRoutine => 'आफ्नो दैनिक दिनचर्या मिलाउनुहोस्';

  @override
  String get dragReorderHint =>
      'कार्डहरूलाई बिहानदेखि साँझसम्मको क्रममा मिलाउनुहोस्।';

  @override
  String get checkRoutineSequence => 'दिनचर्याको क्रम जाँच गर्नुहोस्';

  @override
  String get lookAtPattern => 'तलको ढाँचा हेर्नुहोस्। अर्को के हुन्छ?';

  @override
  String get selectCorrectMotif => 'सही डिजाइन छान्नुहोस्:';

  @override
  String movesLabel(int count) {
    return 'चाल: $count';
  }

  @override
  String timeLabel(int seconds) {
    return 'समय: $secondsसे';
  }

  @override
  String pairsLabel(int found, int total) {
    return 'जोडी: $found/$total';
  }

  @override
  String questionLabel(int current, int total) {
    return 'प्रश्न $current/$total';
  }

  @override
  String youMatchedAll(int pairs, int moves, int seconds) {
    return 'तपाईंले $moves चालमा र $seconds सेकेन्डमा $pairs जोडी मिलाउनुभयो!';
  }

  @override
  String youPlaced(int correct, int total, int seconds) {
    return 'तपाईंले $seconds सेकेन्डमा $totalमध्ये $correctवटा क्रियाकलाप सही क्रममा राख्नुभयो।';
  }

  @override
  String youSolved(int correct, int total, int seconds) {
    return 'तपाईंले $seconds सेकेन्डमा $totalमध्ये $correctवटा ढाँचा सही रूपमा हल गर्नुभयो!';
  }

  @override
  String get warmResultGreat =>
      'अद्भुत! तपाईंले यति राम्रोसँग याद गर्नुभयो! 🌟';

  @override
  String get warmResultGood => 'राम्रो प्रयास! जारी राख्नुहोस्! 💪';

  @override
  String get warmResultOkay =>
      'कुनै समस्या छैन! हरेक अभ्यासले स्मृतिलाई मद्दत गर्छ! ❤️';

  @override
  String get subResultGreat => 'तपाईंको स्मृति आज शानदार काम गरिरहेको छ।';

  @override
  String get subResultGood => 'हरेक प्रयासमा तपाईं सुधार गर्दैहुनुहुन्छ!';

  @override
  String get subResultOkay => 'फेरि प्रयास गर्न चाहनुहुन्छ? पाठ फर्कनेछ।';
}
