import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/challenge/daily_challenge_screen.dart';
import '../features/grammar/grammar_screen.dart';
import '../features/history/history_screen.dart';
import '../features/onboarding/onboarding_flow.dart';
import '../features/vocabulary/vocabulary_screen.dart';
import '../features/voice/voice_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/general_settings_screen.dart';
import '../features/settings/personality_settings_screen.dart';
import '../features/settings/privacy_screen.dart';
import '../features/settings/voice_settings_screen.dart';
import '../features/shell/root_shell.dart';
import '../features/splash/splash_screen.dart';
import '../services/preferences_service.dart';
import '../services/pronunciation_service.dart';
import '../services/speech_input_service.dart';
import '../services/tts_service.dart';
import '../services/tutor_repository.dart';
import '../state/progress_controller.dart';
import '../state/settings_controller.dart';
import '../state/tutor_controller.dart';
import '../theme/app_theme.dart';

/// Route names used with [Navigator].
class Routes {
  Routes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const tutor = '/tutor';
  static const voice = '/voice';
  static const grammar = '/practice/grammar';
  static const vocabulary = '/practice/vocabulary';
  static const challenge = '/practice/challenge';
  static const history = '/history';
  static const personality = '/settings/personality';
  static const voiceSettings = '/settings/voice';
  static const generalSettings = '/settings/general';
  static const privacy = '/settings/privacy';
  static const about = '/settings/about';
}

class ZloyApp extends StatelessWidget {
  const ZloyApp({
    super.key,
    required this.prefs,
    required this.settings,
    required this.progress,
    required this.tutor,
    required this.repository,
    required this.tts,
    required this.speech,
    required this.pronunciation,
  });

  final PreferencesService prefs;
  final SettingsController settings;
  final ProgressController progress;
  final TutorController tutor;
  final TutorRepository repository;
  final TtsService tts;
  final SpeechInputService speech;
  final PronunciationService pronunciation;

  @override
  Widget build(BuildContext context) {
    return ZloyProviders(
      prefs: prefs,
      settings: settings,
      progress: progress,
      tutor: tutor,
      repository: repository,
      tts: tts,
      speech: speech,
      pronunciation: pronunciation,
      child: MaterialApp(
        title: 'ZLOY.AI',
        debugShowCheckedModeBanner: false,
        theme: ZloyTheme.dark,
        darkTheme: ZloyTheme.dark,
        themeMode: ThemeMode.dark,
        initialRoute: Routes.splash,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings routeSettings) {
    Widget page;
    switch (routeSettings.name) {
      case Routes.splash:
        page = const SplashScreen();
      case Routes.onboarding:
        page = const OnboardingFlow();
      case Routes.home:
        page = const RootShell();
      case Routes.grammar:
        page = const GrammarScreen();
      case Routes.vocabulary:
        page = const VocabularyScreen();
      case Routes.challenge:
        page = const DailyChallengeScreen();
      case Routes.history:
        page = const HistoryScreen();
      case Routes.voice:
        page = const VoiceScreen();
      case Routes.personality:
        page = const PersonalitySettingsScreen();
      case Routes.voiceSettings:
        page = const VoiceSettingsScreen();
      case Routes.generalSettings:
        page = const GeneralSettingsScreen();
      case Routes.privacy:
        page = const PrivacyScreen();
      case Routes.about:
        page = const AboutScreen();
      default:
        page = const SplashScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: routeSettings);
  }
}

/// Convenience helpers so screens do not repeat transition boilerplate.
extension ZloyNavigation on BuildContext {
  Future<T?> pushScreen<T>(Widget screen) {
    return Navigator.of(this)
        .push<T>(MaterialPageRoute<T>(builder: (_) => screen));
  }
}

/// Dependency-injection wrapper kept separate so tests can mount individual
/// screens with the exact same providers the app uses.
class ZloyProviders extends StatelessWidget {
  const ZloyProviders({
    super.key,
    required this.prefs,
    required this.settings,
    required this.progress,
    required this.tutor,
    required this.repository,
    required this.tts,
    required this.speech,
    required this.pronunciation,
    required this.child,
  });

  final PreferencesService prefs;
  final SettingsController settings;
  final ProgressController progress;
  final TutorController tutor;
  final TutorRepository repository;
  final TtsService tts;
  final SpeechInputService speech;
  final PronunciationService pronunciation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<PreferencesService>.value(value: prefs),
        ChangeNotifierProvider<SettingsController>.value(value: settings),
        ChangeNotifierProvider<ProgressController>.value(value: progress),
        ChangeNotifierProvider<TutorController>.value(value: tutor),
        Provider<TutorRepository>.value(value: repository),
        Provider<TtsService>.value(value: tts),
        Provider<SpeechInputService>.value(value: speech),
        Provider<PronunciationService>.value(value: pronunciation),
      ],
      child: child,
    );
  }
}
