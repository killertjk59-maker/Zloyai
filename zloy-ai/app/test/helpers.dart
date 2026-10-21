import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:zloy_app/app/app.dart';
import 'package:zloy_app/models/enums.dart';
import 'package:zloy_app/models/user_profile.dart';
import 'package:zloy_app/services/backend_client.dart';
import 'package:zloy_app/services/offline_tutor.dart';
import 'package:zloy_app/services/preferences_service.dart';
import 'package:zloy_app/services/pronunciation_service.dart';
import 'package:zloy_app/services/speech_input_service.dart';
import 'package:zloy_app/services/tts_service.dart';
import 'package:zloy_app/services/tutor_repository.dart';
import 'package:zloy_app/state/progress_controller.dart';
import 'package:zloy_app/state/settings_controller.dart';
import 'package:zloy_app/state/tutor_controller.dart';

/// Wires the whole app with in-memory storage and an injectable HTTP client so
/// widget tests never touch the network or real plugins.
class Harness {
  Harness({
    required this.prefs,
    required this.settings,
    required this.progress,
    required this.tutor,
    required this.repository,
  });

  final PreferencesService prefs;
  final SettingsController settings;
  final ProgressController progress;
  final TutorController tutor;
  final TutorRepository repository;

  bool _disposed = false;

  /// Cancels controller timers so widget tests can end cleanly.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    tutor.dispose();
    repository.dispose();
  }

  ZloyApp buildApp() => ZloyApp(
    prefs: prefs,
    settings: settings,
    progress: progress,
    tutor: tutor,
    repository: repository,
    tts: TtsService(),
    speech: SpeechInputService(),
    pronunciation: const PronunciationService(),
  );
}

/// Creates the app with optional pre-seeded profile/settings and an optional
/// mock HTTP handler for the backend.
Future<Harness> createHarness({
  UserProfile? profile,
  AppSettings? settings,
  MockClient? httpClient,
  Map<String, Object>? initialPrefs,
}) async {
  SharedPreferences.setMockInitialValues(initialPrefs ?? {});
  final prefs = await PreferencesService.create();
  final settingsController = SettingsController(prefs);
  await settingsController.load();
  if (profile != null) await settingsController.updateProfile(profile);
  if (settings != null) await settingsController.updateSettings(settings);

  final progress = ProgressController(prefs);
  await progress.load();

  final repository = TutorRepository(
    offline: const OfflineTutor(),
    clientFactory: httpClient == null
        ? null
        : () => BackendClient(
            baseUrl: settingsController.settings.backendBaseUrl,
            httpClient: httpClient,
          ),
  );

  final tutor = TutorController(
    prefs: prefs,
    repository: repository,
    settings: settingsController,
    progress: progress,
  );
  await tutor.load();

  return Harness(
    prefs: prefs,
    settings: settingsController,
    progress: progress,
    tutor: tutor,
    repository: repository,
  );
}

/// A profile that has already completed onboarding.
UserProfile onboardedProfile({
  TargetLanguage target = TargetLanguage.english,
  ExplanationLanguage explanation = ExplanationLanguage.tajik,
  ProficiencyLevel level = ProficiencyLevel.beginner,
}) => UserProfile(
  onboardingComplete: true,
  targetLanguage: target,
  explanationLanguage: explanation,
  level: level,
  goals: const {LearningGoal.conversation},
);

/// Pumps the app and settles the splash screen.
/// Logical phone-sized surface so layouts match a real Android device.
void usePhoneSurface(WidgetTester tester, {Size size = const Size(412, 915)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<Harness> pumpApp(
  WidgetTester tester, {
  UserProfile? profile,
  AppSettings? settings,
  MockClient? httpClient,
  bool usePhoneSize = true,
}) async {
  if (usePhoneSize) usePhoneSurface(tester);
  final harness = await createHarness(
    profile: profile,
    settings: settings,
    httpClient: httpClient,
  );
  addTearDown(harness.dispose);
  await tester.pumpWidget(harness.buildApp());
  await tester.pump(); // build splash
  await tester.pump(const Duration(milliseconds: 1000)); // boot delay
  await settle(tester);
  return harness;
}

/// Wraps a single screen in the app's theme plus providers, for focused tests.
Future<void> pumpScreen(
  WidgetTester tester,
  Harness harness,
  Widget screen,
) async {
  usePhoneSurface(tester);
  addTearDown(harness.dispose);
  await tester.pumpWidget(
    ZloyProviders(
      prefs: harness.prefs,
      settings: harness.settings,
      progress: harness.progress,
      tutor: harness.tutor,
      repository: harness.repository,
      tts: TtsService(),
      speech: SpeechInputService(),
      pronunciation: const PronunciationService(),
      child: MaterialApp(home: screen),
    ),
  );
  await settle(tester);
}

/// The mascot animates forever, so `pumpAndSettle` would never return.
/// This helper advances a bounded number of frames instead.
Future<void> settle(WidgetTester tester, {int frames = 10}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}
