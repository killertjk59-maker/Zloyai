import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'services/offline_tutor.dart';
import 'services/preferences_service.dart';
import 'services/pronunciation_service.dart';
import 'services/speech_input_service.dart';
import 'services/tts_service.dart';
import 'services/tutor_repository.dart';
import 'state/progress_controller.dart';
import 'state/settings_controller.dart';
import 'state/tutor_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0D13),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await PreferencesService.create();

  final settings = SettingsController(prefs);
  final progress = ProgressController(prefs);
  final repository = TutorRepository(offline: const OfflineTutor());
  final tutor = TutorController(
    prefs: prefs,
    repository: repository,
    settings: settings,
    progress: progress,
  );

  runApp(
    ZloyApp(
      prefs: prefs,
      settings: settings,
      progress: progress,
      tutor: tutor,
      repository: repository,
      tts: TtsService(),
      speech: SpeechInputService(),
      pronunciation: const PronunciationService(),
    ),
  );
}
