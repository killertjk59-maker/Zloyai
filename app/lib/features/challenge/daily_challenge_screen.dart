import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/bundled_content.dart';
import '../../models/enums.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/zloy_mascot.dart';
import '../practice/practice_runner.dart';

/// One mixed set of tasks per day, generated locally from the date.
class DailyChallengeScreen extends StatelessWidget {
  const DailyChallengeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final progress = context.watch<ProgressController>();
    final lesson = BundledContent.dailyChallenge(
      day: DateTime.now(),
      lang: settings.profile.explanationLanguage,
      level: settings.profile.level,
    );
    final completed = progress.challengeCompletedToday;
    final state = progress.challengeState;

    return ZloyPage(
      title: 'Daily challenge',
      child: ListView(
        padding: const EdgeInsets.only(top: 12, bottom: 28),
        children: [
          Center(
            child: ZloyMascot(
              size: 130,
              mood: completed ? MascotMood.celebrate : MascotMood.angry,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            completed ? 'Today is done.' : 'No excuses today.',
            textAlign: TextAlign.center,
            style: ZloyType.headline,
          ),
          const SizedBox(height: 6),
          Text(
            completed
                ? 'You finished ${state?.correct ?? 0} of '
                      '${state?.total ?? lesson.items.length} tasks correctly.'
                : '${lesson.items.length} mixed tasks: vocabulary, grammar, '
                      'reading and translation. Takes a few minutes.',
            textAlign: TextAlign.center,
            style: ZloyType.bodyMuted,
          ),
          const SizedBox(height: 22),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Today’s mix'),
                for (final item in lesson.items.take(4))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.circle,
                          size: 6,
                          color: ZloyColors.textMuted,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.prompt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ZloyType.bodyMuted.copyWith(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  '+ ${lesson.items.length - 4 > 0 ? lesson.items.length - 4 : 0} more tasks',
                  style: ZloyType.label,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () async {
              await startLesson(context, lesson, isChallenge: true);
            },
            icon: Icon(completed ? Icons.replay_rounded : Icons.bolt_rounded),
            label: Text(completed ? 'Practise again' : 'Start challenge'),
          ),
          const SizedBox(height: 10),
          const InfoBanner(
            message:
                'The challenge is generated on this device from today’s '
                'date, so it works offline and is the same all day.',
            icon: Icons.offline_bolt_rounded,
          ),
          const SizedBox(height: 8),
          Text(
            'Difficulty is adapted: beginners get fewer, easier tasks.',
            textAlign: TextAlign.center,
            style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
