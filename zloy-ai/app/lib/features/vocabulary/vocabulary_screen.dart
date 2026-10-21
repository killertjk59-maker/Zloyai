import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/bundled_content.dart';
import '../../models/chat_models.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/lesson_card.dart';
import '../practice/practice_runner.dart';

/// Vocabulary practice with a real review queue based on recorded answers.
class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final progress = context.watch<ProgressController>();
    final lang = settings.profile.explanationLanguage;
    final lessons = BundledContent.vocabularyLessons(lang);
    final allItems = lessons.expand((l) => l.items).toList();

    final weakItems = allItems.where((item) {
      final state = progress.vocabProgress(item.id);
      return state != null && state.box < 3;
    }).toList();

    final newItems = allItems
        .where((item) => progress.vocabProgress(item.id) == null)
        .take(10)
        .toList();

    return ZloyPage(
      title: 'Vocabulary',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        children: [
          SectionCard(
            child: Row(
              children: [
                Expanded(
                  child: StatTile(
                    value: '${progress.wordsPractised}',
                    label: 'words practised',
                    icon: Icons.style_rounded,
                    color: ZloyColors.info,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    value: '${progress.masteredWordCount}',
                    label: 'mastered',
                    icon: Icons.workspace_premium_rounded,
                    color: ZloyColors.success,
                  ),
                ),
                Expanded(
                  child: StatTile(
                    value: '${newItems.length}',
                    label: 'not started',
                    icon: Icons.new_releases_rounded,
                    color: ZloyColors.violet,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (weakItems.isNotEmpty) ...[
            const SectionTitle('Review queue'),
            LessonCard(
              lesson: Lesson(
                id: 'vocab-review',
                title: 'Weak words',
                subtitle: '${weakItems.length} words you got wrong before',
                kind: LessonKind.vocabulary,
                level: settings.profile.level,
                items: weakItems.take(12).toList(),
                emoji: '🔁',
              ),
              onTap: () => startLesson(
                context,
                Lesson(
                  id: 'vocab-review',
                  title: 'Weak words',
                  subtitle: '${weakItems.length} words',
                  kind: LessonKind.vocabulary,
                  level: settings.profile.level,
                  items: weakItems.take(12).toList(),
                  emoji: '🔁',
                ),
              ),
              trailingText: '• prioritised',
            ),
            const SizedBox(height: 8),
          ],
          const SectionTitle('Word sets'),
          for (final lesson in lessons)
            LessonCard(
              lesson: lesson,
              onTap: () => startLesson(context, lesson),
            ),
          const SizedBox(height: 10),
          const InfoBanner(
            message:
                'A word moves to "mastered" after three correct answers '
                'in a row. A wrong answer sends it back to the review queue.',
            icon: Icons.school_outlined,
          ),
        ],
      ),
    );
  }
}
