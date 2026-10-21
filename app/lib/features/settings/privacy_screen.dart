import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Plain-language privacy information. No marketing, no vagueness.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZloyPage(
      title: 'Privacy',
      child: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 32),
        children: const [
          InfoBanner(
            message:
                'Short version: no account, no ads, no analytics. Your '
                'learning data stays on this phone. Messages are sent out only '
                'when you chat with the AI tutor and a backend is configured.',
            icon: Icons.lock_outline_rounded,
            color: ZloyColors.success,
          ),
          SizedBox(height: 18),
          _Section(
            title: 'Stored on this device',
            icon: Icons.phone_android_rounded,
            items: [
              'Your name (optional), learning language, explanation language, '
                  'level, goals and learning style.',
              'Personality, voice, profanity and backend URL settings.',
              'Practice answers, per-day activity, session scores, vocabulary '
                  'progress and corrections.',
              'The tutor conversation, so it survives closing the app.',
            ],
          ),
          _Section(
            title: 'Never collected',
            icon: Icons.block_rounded,
            items: [
              'No account, email, phone number or password.',
              'No raw voice recordings. Speech is converted to text by the '
                  'platform recogniser; ZLOY never stores audio.',
              'No location, contacts, calendar, files or camera access.',
              'No advertising identifiers, no third-party analytics SDKs.',
            ],
          ),
          _Section(
            title: 'When data leaves the device',
            icon: Icons.cloud_upload_outlined,
            items: [
              'Only when you send a message to the tutor and a backend URL is '
                  'configured. The message and the settings needed for the '
                  'answer (languages, level, personality) are sent to that '
                  'backend.',
              'The backend may forward your text to the configured AI provider '
                  '(for example OpenRouter) to produce the answer. The provider '
                  'then processes your text under its own policy.',
              'If no backend URL is set, or offline mode is enabled, nothing '
                  'leaves the device — the built-in rule checker runs locally.',
            ],
          ),
          _Section(
            title: 'Voice recognition and synthesis',
            icon: Icons.mic_none_rounded,
            items: [
              'Speech-to-text uses Android’s speech recognition service. On '
                  'many devices that is a Google service and audio may be sent '
                  'to it for processing. This is controlled by Android, not by '
                  'ZLOY.',
              'You can disable microphone input entirely in Settings → Voice, '
                  'or turn off platform recognition in the settings below.',
              'Speech playback uses the Text-to-Speech engine installed on your '
                  'device and works offline when a voice is installed.',
            ],
          ),
          _Section(
            title: 'Your controls',
            icon: Icons.tune_rounded,
            items: [
              'Settings → General → Delete all local data removes everything '
                  'this app stored.',
              'Settings → General → Offline mode only keeps every request on '
                  'the device.',
              'Mistake history can be cleared separately from Learning history.',
            ],
          ),
          InfoBanner(
            message:
                'The app never sends the AI provider API key anywhere: it '
                'lives only in the backend’s environment. There is no key in '
                'the APK.',
            icon: Icons.vpn_key_off_rounded,
            color: ZloyColors.violet,
          ),
          SizedBox(height: 14),
          Text(
            'ZLOY.AI does not knowingly collect data from children, because it '
            'collects no personal data centrally at all.',
            style: ZloyType.bodyMuted,
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.items,
  });

  final String title;
  final IconData icon;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: ZloyColors.ember),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: ZloyType.title.copyWith(fontSize: 15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 8),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: ZloyColors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: ZloyType.bodyMuted.copyWith(
                          fontSize: 12.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
