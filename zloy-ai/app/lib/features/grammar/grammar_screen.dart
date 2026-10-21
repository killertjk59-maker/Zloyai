import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../data/bundled_content.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/lesson_card.dart';
import '../history/history_screen.dart';
import '../practice/practice_runner.dart';

/// Grammar practice: bundled rules and drills, always available offline.
class GrammarScreen extends StatelessWidget {
  const GrammarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final progress = context.watch<ProgressController>();
    final lang = settings.profile.explanationLanguage;
    final lessons = BundledContent.grammarLessons(lang);

    return ZloyPage(
      title: 'Grammar practice',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        children: [
          const InfoBanner(
            message:
                'These exercises are bundled with the app and work with '
                'no internet. Explanations follow your chosen explanation '
                'language.',
          ),
          const SizedBox(height: 14),
          SectionTitle(
            'Lessons',
            trailing: Text(
              '${lessons.length} available',
              style: ZloyType.bodyMuted.copyWith(fontSize: 11),
            ),
          ),
          for (final lesson in lessons)
            LessonCard(
              lesson: lesson,
              onTap: () => startLesson(context, lesson),
            ),
          const SizedBox(height: 8),
          const SectionTitle('Need a real explanation?'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The AI tutor explains any rule in your own words and '
                  'corrects your own sentences — not just the exercises here.',
                  style: ZloyType.bodyMuted,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pushNamed(Routes.home),
                  icon: const Icon(Icons.forum_rounded, size: 17),
                  label: const Text('Open the tutor tab'),
                ),
              ],
            ),
          ),
          if (progress.unreviewedMistakes.isNotEmpty) ...[
            const SizedBox(height: 16),
            InfoBanner(
              message:
                  'You have ${progress.unreviewedMistakes.length} '
                  'corrections waiting in your mistake history.',
              color: ZloyColors.warning,
              icon: Icons.history_edu_rounded,
              action: TextButton(
                onPressed: () => context.pushScreen(const HistoryScreen()),
                child: const Text('Review'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
