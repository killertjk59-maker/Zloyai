import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/chat_models.dart';
import '../../models/progress_models.dart';
import '../../services/tts_service.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Learning history: completed sessions and every recorded correction.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressController>();

    return DefaultTabController(
      length: 2,
      child: ZloyPage(
        title: 'Learning history',
        child: Column(
          children: [
            TabBar(
              labelColor: ZloyColors.ember,
              unselectedLabelColor: ZloyColors.textMuted,
              indicatorColor: ZloyColors.ember,
              dividerColor: ZloyColors.outline,
              tabs: [
                Tab(text: 'Sessions (${progress.sessions.length})'),
                Tab(
                  text:
                      'Mistakes '
                      '(${progress.unreviewedMistakes.length} new)',
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _SessionsTab(sessions: progress.sessions),
                  _MistakesTab(mistakes: progress.mistakes),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionsTab extends StatelessWidget {
  const _SessionsTab({required this.sessions});

  final List<SessionResult> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return const EmptyStateView(
        icon: Icons.event_note_rounded,
        title: 'No sessions yet',
        message:
            'Completed lessons and challenges will be listed here with '
            'their real scores.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final percent = (session.score * 100).round();
        final color = session.score >= 0.8
            ? ZloyColors.success
            : session.score >= 0.5
            ? ZloyColors.warning
            : ZloyColors.danger;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: SectionCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: ZloyType.title.copyWith(fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${session.kind.name} · ${session.correct}/'
                        '${session.total} correct · '
                        '${session.completedAt.day}.'
                        '${session.completedAt.month}.'
                        '${session.completedAt.year} '
                        '${session.completedAt.hour.toString().padLeft(2, '0')}:'
                        '${session.completedAt.minute.toString().padLeft(2, '0')}',
                        style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MistakesTab extends StatelessWidget {
  const _MistakesTab({required this.mistakes});

  final List<MistakeRecord> mistakes;

  @override
  Widget build(BuildContext context) {
    final progress = context.read<ProgressController>();

    if (mistakes.isEmpty) {
      return const EmptyStateView(
        icon: Icons.history_edu_rounded,
        title: 'No corrections yet',
        message:
            'When the tutor corrects a sentence, it is saved here so you '
            'can review it later.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: mistakes.length + 1,
      itemBuilder: (context, index) {
        if (index == mistakes.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 20),
            child: TextButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('Clear mistake history?'),
                    content: const Text(
                      'Corrections are removed from this device. Your practice '
                      'scores stay.',
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
                if (confirmed == true) await progress.clearMistakes();
              },
              icon: const Icon(Icons.delete_sweep_outlined, size: 16),
              label: const Text('Clear mistake history'),
              style: TextButton.styleFrom(
                foregroundColor: ZloyColors.textMuted,
              ),
            ),
          );
        }
        final mistake = mistakes[index];
        return _MistakeCard(mistake: mistake);
      },
    );
  }
}

class _MistakeCard extends StatefulWidget {
  const _MistakeCard({required this.mistake});

  final MistakeRecord mistake;

  @override
  State<_MistakeCard> createState() => _MistakeCardState();
}

class _MistakeCardState extends State<_MistakeCard> {
  bool _expanded = false;

  Future<void> _speak() async {
    final settings = context.read<SettingsController>();
    final tts = context.read<TtsService>();
    if (!settings.settings.voiceOutputEnabled) {
      showZloySnack(context, 'Voice output is disabled in Settings → Voice.');
      return;
    }
    final result = await tts.speak(
      widget.mistake.corrected,
      locale: 'en-US',
      rate: settings.settings.speechRate,
      pitch: settings.settings.speechPitch,
    );
    if (!mounted) return;
    if (result != SpeechStartResult.speaking) {
      showZloySnack(
        context,
        'Speech playback is unavailable on this device.',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mistake = widget.mistake;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!mistake.reviewed)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: ZloyPill(
                      label: 'NEW',
                      color: ZloyColors.ember,
                      filled: true,
                    ),
                  ),
                if (mistake.rule != null)
                  Flexible(
                    child: Text(
                      mistake.rule!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZloyType.bodyMuted.copyWith(fontSize: 11),
                    ),
                  ),
                const Spacer(),
                Text(
                  '${mistake.createdAt.day}.${mistake.createdAt.month}',
                  style: ZloyType.bodyMuted.copyWith(fontSize: 10.5),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mistake.original,
              style: ZloyType.bodyMuted.copyWith(
                decoration: TextDecoration.lineThrough,
                decorationColor: ZloyColors.danger,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: ZloyColors.success,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    mistake.corrected,
                    style: ZloyType.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB8F5D0),
                    ),
                  ),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 10),
              Text(mistake.explanation, style: ZloyType.bodyMuted),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: Text(
                    _expanded ? 'Hide explanation' : 'Why?',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: _speak,
                  icon: const Icon(Icons.volume_up_rounded, size: 15),
                  label: const Text('Listen', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    foregroundColor: ZloyColors.textSecondary,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
                const Spacer(),
                if (!mistake.reviewed)
                  TextButton(
                    onPressed: () => context
                        .read<ProgressController>()
                        .markMistakeReviewed(mistake.id),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      foregroundColor: ZloyColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                    child: const Text(
                      'Reviewed',
                      style: TextStyle(fontSize: 12),
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
