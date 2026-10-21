import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../models/enums.dart';
import '../../services/speech_input_service.dart';
import '../../services/tts_service.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../state/tutor_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_widgets.dart';
import '../../widgets/common.dart';
import '../../widgets/mic_button.dart';
import '../../widgets/zloy_mascot.dart';

/// Chat with the tutor: type or speak, get corrections, replay them aloud.
class TutorScreen extends StatefulWidget {
  const TutorScreen({super.key});

  @override
  State<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends State<TutorScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _inputFocus = FocusNode();

  bool _grammarFocus = true;
  bool _listening = false;
  String _partial = '';
  bool _speaking = false;
  DateTime? _listenStart;

  @override
  void initState() {
    super.initState();
    _input.addListener(_onInputChanged);
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _input.removeListener(_onInputChanged);
    _input.dispose();
    _scroll.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    _input.clear();
    _inputFocus.unfocus();
    await context.read<TutorController>().send(
      text,
      grammarFocus: _grammarFocus,
    );
    _scrollToBottom();
  }

  Future<void> _startListening() async {
    final settings = context.read<SettingsController>();
    final speech = context.read<SpeechInputService>();
    if (!settings.settings.voiceInputEnabled) {
      showZloySnack(
        context,
        'Voice input is disabled in Settings → Voice.',
        error: true,
      );
      return;
    }
    if (!settings.settings.allowPlatformSpeechRecognition) {
      showZloySnack(
        context,
        'Platform speech recognition is disabled in Privacy settings. '
        'Type your message instead.',
        error: true,
      );
      return;
    }

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      if (!mounted) return;
      _showPermissionDialog(permission);
      return;
    }

    final available = await speech.initialize();
    if (!mounted) return;
    if (!available) {
      showZloySnack(
        context,
        'Speech recognition is not available on this device. '
        'You can still type.',
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
          _partial = text;
          if (text.isNotEmpty) _input.text = text;
        });
        if (isFinal) _stopListening();
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );

    if (!mounted) return;
    switch (started) {
      case ListenStartResult.started:
        setState(() {
          _listening = true;
          _listenStart = DateTime.now();
          _partial = '';
        });
      case ListenStartResult.unavailable:
        showZloySnack(
          context,
          'Speech recognition is unavailable here.',
          error: true,
        );
      case ListenStartResult.permissionDenied:
        _showPermissionDialog(PermissionStatus.denied);
      case ListenStartResult.disabledByUser:
      case ListenStartResult.busy:
        break;
    }
  }

  Future<void> _stopListening() async {
    final speech = context.read<SpeechInputService>();
    await speech.stop();
    final started = _listenStart;
    if (started != null) {
      final seconds = DateTime.now().difference(started).inSeconds;
      if (seconds > 0 && mounted) {
        await context.read<ProgressController>().recordSpeakingSeconds(seconds);
      }
    }
    if (!mounted) return;
    setState(() {
      _listening = false;
      _listenStart = null;
    });
  }

  void _showPermissionDialog(PermissionStatus status) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Microphone permission needed'),
        content: Text(
          status.isPermanentlyDenied
              ? 'Microphone access was permanently denied. Open the app '
                    'settings and allow the microphone. You can always type.'
              : 'ZLOY needs microphone access to turn your speech into text. '
                    'Nothing is recorded or stored by this app. You can always '
                    'type instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (status.isPermanentlyDenied) openAppSettings();
            },
            child: Text(status.isPermanentlyDenied ? 'Open settings' : 'OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _speak(String text) async {
    final settings = context.read<SettingsController>();
    if (!settings.settings.voiceOutputEnabled) {
      showZloySnack(context, 'Voice output is disabled in Settings → Voice.');
      return;
    }
    final tts = context.read<TtsService>();
    if (_speaking) {
      await tts.stop();
      if (mounted) setState(() => _speaking = false);
      return;
    }

    // Cyrillic text is the explanation language; Latin text is the target.
    final isCyrillic = RegExp(r'[\u0400-\u04FF]').hasMatch(text);
    final locale = isCyrillic
        ? settings.profile.explanationLanguage.ttsLocale
        : _targetLocale(settings.profile.targetLanguage);

    setState(() => _speaking = true);
    final result = await tts.speak(
      text,
      locale: locale,
      rate: settings.settings.speechRate,
      pitch: settings.settings.speechPitch,
    );
    if (!mounted) return;
    setState(() => _speaking = false);
    if (result == SpeechStartResult.engineUnavailable) {
      showZloySnack(
        context,
        'Text-to-speech is not available on this device.',
        error: true,
      );
    } else if (result == SpeechStartResult.languageMissing) {
      showZloySnack(
        context,
        'No speech voice is installed for this language. '
        'Install a voice in Android Settings → Text-to-speech.',
        error: true,
      );
    }
  }

  String _targetLocale(TargetLanguage language) => switch (language) {
    TargetLanguage.english => 'en-US',
    TargetLanguage.russian => 'ru-RU',
    TargetLanguage.tajik => 'tg-TJ',
  };

  @override
  Widget build(BuildContext context) {
    final tutor = context.watch<TutorController>();
    final settings = context.watch<SettingsController>();
    final messages = tutor.messages;

    if (messages.isNotEmpty) _scrollToBottom();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF121A25), ZloyColors.background],
          stops: [0, 0.3],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ZLOY tutor'),
              Text(
                '${settings.profile.targetLanguage.flag} '
                '${settings.profile.targetLanguage.englishName} · '
                '${settings.settings.personality.label}',
                style: ZloyType.bodyMuted.copyWith(fontSize: 11),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Clear conversation',
              onPressed: messages.isEmpty
                  ? null
                  : () => _confirmClear(context, tutor),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _EmptyChat(
                        onSuggestion: (text) {
                          _input.text = text;
                          _send();
                        },
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        itemCount: messages.length + (tutor.isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= messages.length) {
                            return const _ThinkingBubble();
                          }
                          final message = messages[index];
                          return ChatBubble(
                            message: message,
                            speaking: _speaking,
                            mood: tutor.mood,
                            onSpeak: _speak,
                            onRetry: tutor.retryLast,
                            onOfflineFallback: message.error == null
                                ? null
                                : tutor.useOfflineFallback,
                            onEdit: (text) {
                              _input.text = text;
                              _input.selection = TextSelection.collapsed(
                                offset: text.length,
                              );
                              _inputFocus.requestFocus();
                            },
                          );
                        },
                      ),
              ),
              _Composer(
                controller: _input,
                focusNode: _inputFocus,
                listening: _listening,
                partial: _partial,
                grammarFocus: _grammarFocus,
                onGrammarFocus: (v) => setState(() => _grammarFocus = v),
                onMic: _listening ? _stopListening : _startListening,
                onSend: _input.text.trim().isEmpty ? null : _send,
                onOfflineCheck: () {
                  final text = _input.text.trim();
                  if (text.isEmpty) {
                    showZloySnack(
                      context,
                      'Type a sentence first, then run the offline check.',
                    );
                    return;
                  }
                  _input.clear();
                  tutor.checkOffline(text);
                },
                personality: settings.settings.personality,
                onPersonality: () => _pickPersonality(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    TutorController tutor,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear conversation?'),
        content: const Text(
          'This removes the chat from this device. Your mistake history and '
          'progress stay intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true) await tutor.clear();
  }

  Future<void> _pickPersonality(BuildContext context) async {
    final settings = context.read<SettingsController>();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text('Tutor mood', style: ZloyType.title),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).pushNamed(Routes.personality);
                    },
                    child: const Text('All settings'),
                  ),
                ],
              ),
            ),
            for (final mode in PersonalityMode.values)
              ListTile(
                leading: Icon(
                  _personalityIcon(mode),
                  color: settings.settings.personality == mode
                      ? ZloyColors.ember
                      : ZloyColors.textMuted,
                ),
                title: Text(mode.label),
                subtitle: Text(
                  mode.description,
                  style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                ),
                trailing: settings.settings.personality == mode
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: ZloyColors.ember,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  settings.setPersonality(mode);
                  Navigator.of(sheetContext).pop();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _personalityIcon(PersonalityMode mode) => switch (mode) {
    PersonalityMode.normal => Icons.sentiment_satisfied_rounded,
    PersonalityMode.strict => Icons.gavel_rounded,
    PersonalityMode.roast => Icons.local_fire_department_rounded,
    PersonalityMode.shout => Icons.campaign_rounded,
  };
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.onSuggestion});

  final void Function(String) onSuggestion;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final tutor = context.watch<TutorController>();
    final lang = settings.profile.explanationLanguage;
    final mode = settings.settings.personality;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ZloyMascot(
              size: 110,
              mood: settings.settings.hasBackend
                  ? MascotMood.idle
                  : MascotMood.encourage,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            tutor.greeting(lang, mode, settings.profile.displayName),
            style: ZloyType.body,
          ),
          const SizedBox(height: 18),
          const SectionTitle('Try one of these'),
          for (final suggestion in const [
            'I would to school.',
            'He go to work every day.',
            'Yesterday I buy a new phone.',
            'I have 20 years old.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onSuggestion(suggestion),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: ZloyColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ZloyColors.outline),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.north_east_rounded,
                        size: 14,
                        color: ZloyColors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: ZloyType.bodyMuted.copyWith(
                            fontSize: 13.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (!settings.settings.hasBackend)
            const InfoBanner(
              message:
                  'No backend configured: answers come from the on-device '
                  'checker and are labelled OFFLINE CHECK. Configure a backend '
                  'URL for full AI answers.',
              color: ZloyColors.info,
            ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 4, right: 40),
      child: Row(
        children: [
          const ZloyMascot(size: 36, mood: MascotMood.thinking),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: ZloyColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZloyColors.outline),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'ZLOY is thinking…',
                  style: ZloyType.bodyMuted.copyWith(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.listening,
    required this.partial,
    required this.grammarFocus,
    required this.onGrammarFocus,
    required this.onMic,
    required this.onSend,
    required this.onOfflineCheck,
    required this.personality,
    required this.onPersonality,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool listening;
  final String partial;
  final bool grammarFocus;
  final ValueChanged<bool> onGrammarFocus;
  final VoidCallback onMic;
  final VoidCallback? onSend;
  final VoidCallback onOfflineCheck;
  final PersonalityMode personality;
  final VoidCallback onPersonality;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: const BoxDecoration(
        color: ZloyColors.surface,
        border: Border(top: BorderSide(color: ZloyColors.outline)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ToggleChip(
                          label: 'Grammar check',
                          selected: grammarFocus,
                          icon: Icons.spellcheck_rounded,
                          onTap: () => onGrammarFocus(!grammarFocus),
                        ),
                        const SizedBox(width: 8),
                        _ToggleChip(
                          label: personality.label,
                          selected: false,
                          icon: Icons.psychology_alt_rounded,
                          onTap: onPersonality,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: onOfflineCheck,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    foregroundColor: ZloyColors.info,
                  ),
                  child: const Text(
                    'Offline check',
                    style: TextStyle(fontSize: 11.5),
                  ),
                ),
              ],
            ),
            if (listening) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.graphic_eq_rounded,
                    size: 15,
                    color: ZloyColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      partial.isEmpty
                          ? 'Listening… speak now'
                          : 'Listening: $partial',
                      style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: 'Write a sentence or ask something…',
                      isDense: true,
                    ),
                    style: ZloyType.body,
                  ),
                ),
                const SizedBox(width: 6),
                MicButton(
                  onPressed: onMic,
                  listening: listening,
                  size: 44,
                  tooltip: listening ? 'Stop listening' : 'Speak',
                ),
                const SizedBox(width: 2),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: FilledButton(
                    onPressed: onSend,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(46, 46),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.arrow_upward_rounded, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? ZloyColors.ember.withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? ZloyColors.ember.withValues(alpha: 0.6)
                : ZloyColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: selected ? ZloyColors.ember : ZloyColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? ZloyColors.ember : ZloyColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
