import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../models/enums.dart';
import '../../services/pronunciation_service.dart';
import '../../services/speech_input_service.dart';
import '../../services/tts_service.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../state/tutor_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/mic_button.dart';
import '../../widgets/zloy_mascot.dart';

/// Speaking practice.
///
/// Two honest modes:
/// * Pronunciation practice — reads a sentence aloud, compares what the platform
///   recogniser heard with the target words (a word-match rate, not a phoneme
///   score).
/// * Voice chat — speak, review the transcript, then send it to the tutor.
class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ZloyPage(
        title: 'Speaking',
        child: Column(
          children: [
            const TabBar(
              labelColor: ZloyColors.ember,
              unselectedLabelColor: ZloyColors.textMuted,
              indicatorColor: ZloyColors.ember,
              dividerColor: ZloyColors.outline,
              tabs: [
                Tab(text: 'Read aloud'),
                Tab(text: 'Voice chat'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [_PronunciationTab(), _VoiceChatTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<(String, String)> _sentences = [
  ('Beginner', 'I go to school every day.'),
  ('Beginner', 'She likes tea with milk.'),
  ('Beginner', 'My brother is a teacher.'),
  ('Elementary', 'Yesterday I went to the market with my friend.'),
  ('Elementary', 'I have lived in Khujand for three years.'),
  ('Intermediate', 'If I had more time, I would practise English every day.'),
  ('Intermediate', 'She told me she had already finished her homework.'),
  (
    'Upper-intermediate',
    'Although the weather was terrible, we decided to continue the journey.',
  ),
];

class _PronunciationTab extends StatefulWidget {
  const _PronunciationTab();

  @override
  State<_PronunciationTab> createState() => _PronunciationTabState();
}

class _PronunciationTabState extends State<_PronunciationTab> {
  int _index = 0;
  bool _listening = false;
  bool _micAvailable = true;
  String _heard = '';
  PronunciationAssessment? _assessment;
  DateTime? _listenStart;
  bool _speaking = false;

  String get _target => _sentences[_index].$2;

  Future<void> _listen() async {
    final settings = context.read<SettingsController>();
    final speech = context.read<SpeechInputService>();
    if (!settings.settings.voiceInputEnabled) {
      showZloySnack(context, 'Voice input is disabled in Settings → Voice.');
      return;
    }
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      if (!mounted) return;
      showZloySnack(
        context,
        permission.isPermanentlyDenied
            ? 'Microphone permission is permanently denied. Enable it in '
                  'Android settings, or use the voice chat tab after typing.'
            : 'Microphone permission denied. You can still read the sentence '
                  'and use speech playback.',
        error: true,
      );
      return;
    }
    final ok = await speech.initialize();
    if (!mounted) return;
    if (!ok) {
      setState(() => _micAvailable = false);
      showZloySnack(
        context,
        'Speech recognition is not available on this device. '
        'The comparison needs it.',
        error: true,
      );
      return;
    }

    final locale = await speech.localeFor('en');
    final started = await speech.listen(
      localeId: locale,
      onText: (text, isFinal) {
        if (!mounted) return;
        setState(() => _heard = text);
        if (isFinal) _stop();
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );

    if (!mounted) return;
    if (started == ListenStartResult.started) {
      setState(() {
        _listening = true;
        _heard = '';
        _assessment = null;
        _listenStart = DateTime.now();
      });
    } else {
      setState(
        () => _micAvailable = started != ListenStartResult.permissionDenied,
      );
      showZloySnack(
        context,
        'Could not start the microphone. Check Android speech services.',
        error: true,
      );
    }
  }

  Future<void> _stop() async {
    await context.read<SpeechInputService>().stop();
    final started = _listenStart;
    if (started != null && mounted) {
      final seconds = DateTime.now().difference(started).inSeconds;
      if (seconds > 0) {
        await context.read<ProgressController>().recordSpeakingSeconds(seconds);
      }
    }
    if (!mounted) return;
    setState(() {
      _listening = false;
      _listenStart = null;
    });
  }

  void _compare() {
    if (_heard.trim().isEmpty) {
      showZloySnack(context, 'Record something first.');
      return;
    }
    final assessment = context.read<PronunciationService>().assess(
      expected: _target,
      heard: _heard,
    );
    setState(() => _assessment = assessment);
  }

  Future<void> _speakModel() async {
    final settings = context.read<SettingsController>();
    final tts = context.read<TtsService>();
    if (!settings.settings.voiceOutputEnabled) {
      showZloySnack(context, 'Voice output is disabled in Settings → Voice.');
      return;
    }
    setState(() => _speaking = true);
    final result = await tts.speak(
      _target,
      locale: 'en-US',
      rate: settings.settings.speechRate,
      pitch: settings.settings.speechPitch,
    );
    if (!mounted) return;
    setState(() => _speaking = false);
    if (result != SpeechStartResult.speaking) {
      showZloySnack(
        context,
        result == SpeechStartResult.languageMissing
            ? 'No English voice is installed on this device.'
            : 'Speech playback failed.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final lang = settings.profile.explanationLanguage;
    final assessment = _assessment;

    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        const InfoBanner(
          message:
              'This compares the words your device recognised with the '
              'target sentence. That is a word-match rate — not a phoneme-level '
              'pronunciation score. No free, reliable pronunciation engine is '
              'bundled.',
          icon: Icons.info_outline_rounded,
          color: ZloyColors.warning,
        ),
        const SizedBox(height: 14),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ZloyPill(
                    label: _sentences[_index].$1,
                    color: ZloyColors.violet,
                    filled: true,
                  ),
                  const Spacer(),
                  Text(
                    '${_index + 1}/${_sentences.length}',
                    style: ZloyType.bodyMuted.copyWith(fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(_target, style: ZloyType.headline.copyWith(fontSize: 22)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _speakModel,
                    icon: Icon(
                      _speaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                      size: 17,
                    ),
                    label: Text(_speaking ? 'Stop' : 'Hear it'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _index == 0
                        ? null
                        : () => setState(() {
                            _index--;
                            _heard = '';
                            _assessment = null;
                          }),
                    icon: const Icon(Icons.chevron_left_rounded, size: 18),
                    label: const Text('Prev'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _index == _sentences.length - 1
                        ? null
                        : () => setState(() {
                            _index++;
                            _heard = '';
                            _assessment = null;
                          }),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Column(
            children: [
              ZloyMascot(
                size: 92,
                mood: _listening ? MascotMood.listening : MascotMood.idle,
                animate: _listening,
              ),
              const SizedBox(height: 8),
              MicButton(
                onPressed: _listening ? _stop : _listen,
                listening: _listening,
                enabled: _micAvailable,
                size: 64,
                tooltip: _listening ? 'Stop' : 'Read the sentence aloud',
              ),
              const SizedBox(height: 6),
              Text(
                _listening
                    ? 'Listening… speak clearly'
                    : (_micAvailable
                          ? 'Tap and read the sentence'
                          : 'Microphone unavailable'),
                style: ZloyType.bodyMuted.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('What the device heard'),
              Text(
                _heard.isEmpty ? '— nothing yet —' : _heard,
                style: _heard.isEmpty
                    ? ZloyType.bodyMuted.copyWith(fontStyle: FontStyle.italic)
                    : ZloyType.body,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _compare,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      child: const Text('Compare'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() {
                        _heard = '';
                        _assessment = null;
                      }),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 46),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (assessment != null) ...[
          const SizedBox(height: 16),
          _AssessmentCard(assessment: assessment, language: lang),
        ],
        const SizedBox(height: 8),
        Text(
          'Recognition may use Google speech services on your device. '
          'No audio is stored by ZLOY.',
          textAlign: TextAlign.center,
          style: ZloyType.bodyMuted.copyWith(fontSize: 11),
        ),
      ],
    );
  }
}

class _AssessmentCard extends StatelessWidget {
  const _AssessmentCard({required this.assessment, required this.language});

  final PronunciationAssessment assessment;
  final ExplanationLanguage language;

  @override
  Widget build(BuildContext context) {
    final percent = (assessment.matchRate * 100).round();
    final color = assessment.matchRate >= 0.85
        ? ZloyColors.success
        : assessment.matchRate >= 0.6
        ? ZloyColors.warning
        : ZloyColors.danger;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Word match', style: ZloyType.title),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: assessment.matchRate,
              minHeight: 7,
              backgroundColor: ZloyColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final word in assessment.words)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (word.matched ? ZloyColors.success : ZloyColors.danger)
                            .withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    word.word,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: word.matched
                          ? ZloyColors.success
                          : ZloyColors.danger,
                    ),
                  ),
                ),
            ],
          ),
          if (assessment.extraWords.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Extra words recognised: ${assessment.extraWords.join(', ')}',
              style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
            ),
          ],
          const SizedBox(height: 10),
          Text(assessment.summary(language), style: ZloyType.body),
          const SizedBox(height: 8),
          Text(
            'This is a word-recognition comparison. It cannot judge stress, '
            'intonation or individual sounds.',
            style: ZloyType.bodyMuted.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _VoiceChatTab extends StatefulWidget {
  const _VoiceChatTab();

  @override
  State<_VoiceChatTab> createState() => _VoiceChatTabState();
}

class _VoiceChatTabState extends State<_VoiceChatTab> {
  final TextEditingController _text = TextEditingController();
  bool _listening = false;
  String _transcript = '';
  bool _sending = false;
  String? _reply;
  String? _error;
  bool _speaking = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _listen() async {
    final settings = context.read<SettingsController>();
    final speech = context.read<SpeechInputService>();
    if (!settings.settings.voiceInputEnabled) {
      showZloySnack(context, 'Voice input is disabled in Settings → Voice.');
      return;
    }
    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      if (!mounted) return;
      showZloySnack(
        context,
        'Microphone permission denied. You can type your message instead.',
        error: true,
      );
      return;
    }
    final ok = await speech.initialize();
    if (!mounted) return;
    if (!ok) {
      showZloySnack(
        context,
        'Speech recognition is not available on this device.',
        error: true,
      );
      return;
    }
    final locale = await speech.localeFor(settings.profile.targetLanguage.code);
    final started = await speech.listen(
      localeId: locale,
      onText: (text, isFinal) {
        if (!mounted) return;
        setState(() {
          _transcript = text;
          _text.text = text;
        });
        if (isFinal) _stop();
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!mounted) return;
    if (started == ListenStartResult.started) {
      setState(() => _listening = true);
    } else {
      showZloySnack(context, 'Could not start the microphone.', error: true);
    }
  }

  Future<void> _stop() async {
    await context.read<SpeechInputService>().stop();
    if (!mounted) return;
    setState(() => _listening = false);
  }

  Future<void> _send() async {
    final text = _transcript.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _error = null;
      _reply = null;
    });
    final tutor = context.read<TutorController>();
    final before = tutor.messages.length;
    await tutor.send(text, grammarFocus: false);
    if (!mounted) return;
    final newMessages = tutor.messages.skip(before).toList();
    final failed = newMessages.where((m) => m.error != null).toList();
    if (failed.isNotEmpty) {
      setState(() {
        _error = failed.first.error;
        _sending = false;
      });
      return;
    }
    final reply = newMessages.where((m) => !m.isUser).toList();
    setState(() {
      _reply = reply.isEmpty ? null : reply.last.text;
      _sending = false;
      _transcript = '';
      _text.clear();
    });
    if (_reply != null) await _speak(_reply!);
  }

  Future<void> _speak(String text) async {
    final settings = context.read<SettingsController>();
    final tts = context.read<TtsService>();
    if (!settings.settings.voiceOutputEnabled) return;
    setState(() => _speaking = true);
    final isCyrillic = RegExp(r'[\u0400-\u04FF]').hasMatch(text);
    await tts.speak(
      text,
      locale: isCyrillic
          ? settings.profile.explanationLanguage.ttsLocale
          : 'en-US',
      rate: settings.settings.speechRate,
      pitch: settings.settings.speechPitch,
    );
    if (mounted) setState(() => _speaking = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: [
        const InfoBanner(
          message:
              'Speak, then check the transcript before sending it. '
              'Nothing is sent until you press Send.',
          icon: Icons.mic_none_rounded,
        ),
        const SizedBox(height: 16),
        Center(
          child: ZloyMascot(
            size: 100,
            mood: _listening
                ? MascotMood.listening
                : (_sending
                      ? MascotMood.thinking
                      : (_speaking ? MascotMood.speaking : MascotMood.idle)),
            animate: _listening || _speaking || _sending,
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: MicButton(
            onPressed: _listening ? _stop : _listen,
            listening: _listening,
            size: 68,
            tooltip: _listening ? 'Stop' : 'Speak',
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            _listening ? 'Listening…' : 'Tap to speak',
            style: ZloyType.bodyMuted.copyWith(fontSize: 12),
          ),
        ),
        const SizedBox(height: 18),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Your message'),
              TextField(
                controller: _text,
                onChanged: (v) => setState(() => _transcript = v),
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Speak or type here…',
                ),
                style: ZloyType.body,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _sending || _transcript.trim().isEmpty
                    ? null
                    : _send,
                child: Text(_sending ? 'Sending…' : 'Send to ZLOY'),
              ),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          ErrorStateView(
            message: _error!,
            onRetry: _send,
            secondaryLabel: 'Set up backend',
            onSecondary: () =>
                Navigator.of(context).pushNamed(Routes.generalSettings),
          ),
        ],
        if (_reply != null) ...[
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('ZLOY', style: ZloyType.label),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _speak(_reply!),
                      icon: const Icon(Icons.volume_up_rounded, size: 18),
                      tooltip: 'Replay',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Text(_reply!, style: ZloyType.body),
                if (!settings.settings.hasBackend) ...[
                  const SizedBox(height: 8),
                  const InfoBanner(
                    message:
                        'Offline mode: this answer came from the built-in '
                        'checker, not from an AI model.',
                    color: ZloyColors.info,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
