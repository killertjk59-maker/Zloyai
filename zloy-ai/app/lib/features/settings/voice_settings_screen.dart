import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/speech_input_service.dart';
import '../../services/tts_service.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Voice input and output settings with real engine probing.
class VoiceSettingsScreen extends StatefulWidget {
  const VoiceSettingsScreen({super.key});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  bool? _ttsAvailable;
  bool? _speechAvailable;
  int? _ttsLanguageCount;
  bool _probing = false;
  bool _testing = false;

  Future<void> _probe() async {
    setState(() => _probing = true);
    final tts = context.read<TtsService>();
    final speech = context.read<SpeechInputService>();
    final ttsOk = await tts.initialize();
    final speechOk = await speech.initialize();
    if (!mounted) return;
    setState(() {
      _ttsAvailable = ttsOk;
      _speechAvailable = speechOk;
      _ttsLanguageCount = tts.languages.length;
      _probing = false;
    });
  }

  Future<void> _test() async {
    final settings = context.read<SettingsController>();
    final tts = context.read<TtsService>();
    setState(() => _testing = true);
    final result = await tts.speak(
      'Hello. I am ZLOY. Your grammar needs work, but we will fix it.',
      locale: 'en-US',
      rate: settings.settings.speechRate,
      pitch: settings.settings.speechPitch,
    );
    if (!mounted) return;
    setState(() => _testing = false);
    switch (result) {
      case SpeechStartResult.speaking:
        break;
      case SpeechStartResult.engineUnavailable:
        showZloySnack(
          context,
          'No Text-to-Speech engine responded. Install one from the Play Store '
          '(for example Google Speech Services).',
          error: true,
        );
      case SpeechStartResult.languageMissing:
        showZloySnack(
          context,
          'The engine has no English voice installed.',
          error: true,
        );
      case SpeechStartResult.error:
        showZloySnack(context, 'Playback failed.', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final s = controller.settings;

    return ZloyPage(
      title: 'Voice',
      child: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 28),
        children: [
          SectionCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: s.voiceOutputEnabled,
                  onChanged: controller.setVoiceOutputEnabled,
                  title: const Text('Speak tutor answers'),
                  subtitle: Text(
                    'Uses the Android Text-to-Speech engine on this device.',
                    style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: s.autoSpeakTutorReplies,
                  onChanged: s.voiceOutputEnabled
                      ? controller.setAutoSpeak
                      : null,
                  title: const Text('Read new answers automatically'),
                  subtitle: Text(
                    'Only works when speech output is enabled.',
                    style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: s.voiceInputEnabled,
                  onChanged: controller.setVoiceInputEnabled,
                  title: const Text('Microphone input'),
                  subtitle: Text(
                    'Turns your speech into text using Android speech '
                    'recognition.',
                    style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: s.soundEffectsEnabled,
                  onChanged: controller.setSoundEffects,
                  title: const Text('Interface sounds'),
                  subtitle: Text(
                    'Short feedback cues. No audio is downloaded.',
                    style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                SwitchListTile(
                  value: s.hapticsEnabled,
                  onChanged: controller.setHaptics,
                  title: const Text('Haptic feedback'),
                  subtitle: Text(
                    'Light vibration on correct and incorrect answers.',
                    style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Speech playback'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Speed', style: ZloyType.body),
                    const Spacer(),
                    Text(
                      s.speechRate.toStringAsFixed(2),
                      style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                Slider(
                  value: s.speechRate,
                  min: 0.25,
                  max: 1.0,
                  divisions: 15,
                  onChanged: controller.setSpeechRate,
                ),
                Row(
                  children: [
                    Text('Pitch', style: ZloyType.body),
                    const Spacer(),
                    Text(
                      s.speechPitch.toStringAsFixed(2),
                      style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                Slider(
                  value: s.speechPitch,
                  min: 0.5,
                  max: 2.0,
                  divisions: 15,
                  onChanged: controller.setSpeechPitch,
                ),
                const SizedBox(height: 6),
                FilledButton.icon(
                  onPressed: _testing ? null : _test,
                  icon: const Icon(Icons.play_arrow_rounded, size: 19),
                  label: Text(_testing ? 'Playing…' : 'Test playback'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pitch and speed are engine features. Some voices ignore '
                  'them, and no engine produces a genuinely angry voice.',
                  style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Engine status'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusRow(
                  label: 'Text-to-speech',
                  available: _ttsAvailable,
                  detail: _ttsLanguageCount == null
                      ? null
                      : '$_ttsLanguageCount voices reported by the engine',
                ),
                const SizedBox(height: 6),
                _StatusRow(
                  label: 'Speech recognition',
                  available: _speechAvailable,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _probing ? null : _probe,
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  label: Text(_probing ? 'Checking…' : 'Check this device'),
                ),
                const SizedBox(height: 8),
                Text(
                  _ttsAvailable == null
                      ? 'Status is checked on demand — the app never assumes '
                            'your device has a voice for every language.'
                      : (_ttsAvailable == true
                            ? 'Speech playback is available. Tajik voices are '
                                  'often missing; the app falls back to another '
                                  'voice and tells you when it does.'
                            : 'No speech engine responded. The app still works: '
                                  'all answers are shown as text.'),
                  style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const InfoBanner(
            message:
                'Voice features are entirely optional. If they are '
                'unavailable, every lesson and the tutor chat still work.',
            icon: Icons.text_fields_rounded,
            color: ZloyColors.success,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.available, this.detail});

  final String label;
  final bool? available;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final (color, text) = switch (available) {
      null => (ZloyColors.textMuted, 'not checked'),
      true => (ZloyColors.success, 'available'),
      false => (ZloyColors.danger, 'unavailable'),
    };
    return Row(
      children: [
        Icon(Icons.circle, size: 9, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ZloyType.body.copyWith(fontSize: 13.5)),
              if (detail != null)
                Text(detail!, style: ZloyType.bodyMuted.copyWith(fontSize: 11)),
            ],
          ),
        ),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
