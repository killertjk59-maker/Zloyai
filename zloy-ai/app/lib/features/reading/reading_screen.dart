import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/bundled_content.dart';
import '../../models/chat_models.dart';
import '../../models/enums.dart';
import '../../models/progress_models.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/lesson_card.dart';
import '../../widgets/zloy_mascot.dart';
import '../practice/practice_runner.dart';

/// Reading comprehension with bundled passages.
class ReadingScreen extends StatelessWidget {
  const ReadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final passages = BundledContent.readingPassages(
      settings.profile.explanationLanguage,
    );

    return ZloyPage(
      title: 'Reading',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        children: [
          const InfoBanner(
            message:
                'Short passages with comprehension questions. All content '
                'is bundled — no internet needed.',
          ),
          const SizedBox(height: 14),
          for (final passage in passages)
            LessonCard(
              lesson: Lesson(
                id: passage.id,
                title: passage.title,
                subtitle:
                    '${passage.questions.length} questions · '
                    'reading comprehension',
                kind: LessonKind.reading,
                level: passage.level,
                items: passage.questions,
                emoji: '📖',
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReadingDetailScreen(passage: passage),
                ),
              ),
            ),
          const SizedBox(height: 10),
          const SectionTitle('Translation drills'),
          for (final lesson in BundledContent.translationLessons(
            settings.profile.explanationLanguage,
          ))
            LessonCard(
              lesson: lesson,
              onTap: () => startLesson(context, lesson),
            ),
        ],
      ),
    );
  }
}

class ReadingDetailScreen extends StatefulWidget {
  const ReadingDetailScreen({super.key, required this.passage});

  final ReadingPassage passage;

  @override
  State<ReadingDetailScreen> createState() => _ReadingDetailScreenState();
}

class _ReadingDetailScreenState extends State<ReadingDetailScreen> {
  final Map<int, String> _answers = {};
  final Map<int, bool> _results = {};
  final DateTime _startedAt = DateTime.now();
  bool _recorded = false;

  int get _answeredCount => _results.length;
  int get _correctCount => _results.values.where((v) => v).length;

  Future<void> _check(int index, PracticeItem item, String input) async {
    if (_results.containsKey(index)) return;
    final correct = item.check(input);
    setState(() => _results[index] = correct);
    await context.read<ProgressController>().recordAnswer(correct: correct);
  }

  Future<void> _finish() async {
    if (_recorded) return;
    _recorded = true;
    final progress = context.read<ProgressController>();
    final elapsed = DateTime.now().difference(_startedAt);
    final minutes = (elapsed.inSeconds / 60).round();
    if (minutes > 0) await progress.addMinutes(minutes);
    await progress.recordSession(
      SessionResult(
        id: 'r${DateTime.now().microsecondsSinceEpoch}',
        kind: LessonKind.reading,
        title: widget.passage.title,
        correct: _correctCount,
        total: widget.passage.questions.length,
        completedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    showZloySnack(
      context,
      'Saved: $_correctCount / ${widget.passage.questions.length} correct.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final questions = widget.passage.questions;
    final allAnswered = _answeredCount == questions.length;

    return ZloyPage(
      title: 'Reading',
      child: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 28),
        children: [
          SectionCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ZloyMascot(
                      size: 40,
                      mood: allAnswered
                          ? MascotMood.celebrate
                          : MascotMood.idle,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(widget.passage.title, style: ZloyType.title),
                    ),
                    ZloyPill(
                      label: widget.passage.level.cefr,
                      color: ZloyColors.violet,
                      filled: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.passage.text,
                  style: ZloyType.body.copyWith(fontSize: 15.5, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionTitle(
            'Questions',
            trailing: Text(
              '$_answeredCount/${questions.length} answered',
              style: ZloyType.bodyMuted.copyWith(fontSize: 11),
            ),
          ),
          for (var i = 0; i < questions.length; i++)
            _QuestionCard(
              index: i,
              item: questions[i],
              answer: _answers[i],
              result: _results[i],
              explanationLanguage: settings.profile.explanationLanguage,
              onChanged: (value) => setState(() => _answers[i] = value),
              onCheck: () => _check(i, questions[i], _answers[i] ?? ''),
            ),
          if (allAnswered) ...[
            const SizedBox(height: 8),
            SectionCard(
              child: Row(
                children: [
                  ZloyMascot(size: 52, mood: MascotMood.celebrate),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$_correctCount of ${questions.length} correct.',
                      style: ZloyType.title.copyWith(fontSize: 15),
                    ),
                  ),
                  FilledButton(
                    onPressed: _finish,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 42),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.item,
    required this.answer,
    required this.result,
    required this.explanationLanguage,
    required this.onChanged,
    required this.onCheck,
  });

  final int index;
  final PracticeItem item;
  final String? answer;
  final bool? result;
  final ExplanationLanguage explanationLanguage;
  final ValueChanged<String> onChanged;
  final VoidCallback onCheck;

  @override
  Widget build(BuildContext context) {
    final answered = result != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ${item.prompt}',
              style: ZloyType.body.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            if (item.isMultipleChoice)
              for (final choice in item.choiceAnswers)
                Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: InkWell(
                    onTap: answered ? null : () => onChanged(choice),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: answer == choice
                            ? ZloyColors.ember.withValues(alpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: answered && item.check(choice)
                              ? ZloyColors.success
                              : answer == choice
                              ? ZloyColors.ember
                              : ZloyColors.outline,
                        ),
                      ),
                      child: Text(
                        choice,
                        style: ZloyType.bodyMuted.copyWith(fontSize: 13.5),
                      ),
                    ),
                  ),
                )
            else
              TextField(
                enabled: !answered,
                onChanged: onChanged,
                decoration: const InputDecoration(
                  hintText: 'Your answer',
                  isDense: true,
                ),
                style: ZloyType.body,
              ),
            const SizedBox(height: 10),
            if (!answered)
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: (answer ?? '').trim().isEmpty ? null : onCheck,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  child: const Text('Check'),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (result! ? ZloyColors.success : ZloyColors.danger)
                      .withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          result!
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 15,
                          color: result!
                              ? ZloyColors.success
                              : ZloyColors.danger,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          result! ? 'Correct' : 'Answer: ${item.answer}',
                          style: ZloyType.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (item.explanation != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        item.explanation!,
                        style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
