import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/zloy_mascot.dart';

/// About screen, including the limitations this build genuinely has.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ZloyPage(
      title: 'About',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        children: [
          Center(
            child: Column(
              children: [
                const ZloyMascot(size: 120),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'ZLOY',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          color: ZloyColors.ember,
                        ),
                      ),
                      TextSpan(
                        text: '.AI',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1,
                          color: ZloyColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0 (build 1)',
                  style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SectionCard(
            child: Text(
              'ZLOY.AI is a language tutor with a personality disorder: '
              'patient one minute, furious about your verb tenses the next. '
              'Every correction comes with an explanation in the language you '
              'chose.',
              style: ZloyType.body,
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Technology'),
          SectionCard(
            child: Column(
              children: const [
                _TechRow(label: 'App', value: 'Flutter · Dart · Material 3'),
                Divider(height: 16),
                _TechRow(
                  label: 'Backend',
                  value: 'FastAPI · Pydantic · SQLite',
                ),
                Divider(height: 16),
                _TechRow(
                  label: 'AI',
                  value: 'OpenRouter-compatible backend, model configurable',
                ),
                Divider(height: 16),
                _TechRow(
                  label: 'Voice',
                  value: 'Android SpeechRecognizer + TextToSpeech',
                ),
                Divider(height: 16),
                _TechRow(label: 'Cost', value: 'Free and open source'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Honest limitations'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _Limitation(
                  text:
                      'AI answers require a backend you host yourself and an '
                      'AI provider key stored on that backend. Without it, the '
                      'app uses a small rule-based checker, clearly labelled '
                      'OFFLINE CHECK.',
                ),
                _Limitation(
                  text:
                      'The offline checker only knows a fixed list of common '
                      'English mistakes. It is not a language model and cannot '
                      'understand free conversation.',
                ),
                _Limitation(
                  text:
                      'Pronunciation feedback compares recognised words with '
                      'the target sentence. It is not a phoneme-level score and '
                      'cannot judge stress or intonation.',
                ),
                _Limitation(
                  text:
                      'Tajik text-to-speech is not available on most Android '
                      'devices. The app will tell you when it falls back to '
                      'another voice.',
                ),
                _Limitation(
                  text:
                      'SHOUT mode changes wording only. No phone voice '
                      'actually shouts.',
                ),
                _Limitation(
                  text:
                      'Everything is local. There is no cloud sync between '
                      'devices and no cross-device backup.',
                ),
                _Limitation(
                  text:
                      'Free tiers of AI providers and hosting services change '
                      'without notice. Nothing here guarantees permanent free '
                      'access to a model.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'ZLOY.AI',
              applicationVersion: '1.0.0',
              applicationLegalese:
                  'Open source. Built with Flutter, FastAPI and open models.',
            ),
            icon: const Icon(Icons.description_outlined, size: 17),
            label: const Text('Open source licenses'),
          ),
          const SizedBox(height: 12),
          Text(
            'Mascot and artwork are drawn in code for this project. No '
            'third-party character assets are used.',
            textAlign: TextAlign.center,
            style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _TechRow extends StatelessWidget {
  const _TechRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 76, child: Text(label, style: ZloyType.label)),
        Expanded(
          child: Text(value, style: ZloyType.bodyMuted.copyWith(fontSize: 13)),
        ),
      ],
    );
  }
}

class _Limitation extends StatelessWidget {
  const _Limitation({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 8),
            child: Icon(
              Icons.warning_amber_rounded,
              size: 14,
              color: ZloyColors.warning,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: ZloyType.bodyMuted.copyWith(fontSize: 12.5, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
