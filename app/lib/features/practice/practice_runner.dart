import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/chat_models.dart';
import '../../models/enums.dart';
import '../../models/progress_models.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/zloy_mascot.dart';

/// Shared exercise engine used by vocabulary, grammar, reading, translation and
/// the daily challenge. It records real answers and shows real scores.
class PracticeRunnerScreen extends StatefulWidget {
  const PracticeRunnerScreen({
    super.key,
    required this.lesson,
    this.isChallenge = false,
  });

  final Lesson lesson;
  final bool isChallenge;

  @override
  State<PracticeRunnerScreen> createState() => _PracticeRunnerScreenState();
}

class _PracticeRunnerScreenState extends State<PracticeRunnerScreen> {
  final TextEditingController _answer = TextEditingController();
  late final DateTime _startedAt;
  int _index = 0;
  int _correct = 0;
  bool _checked = false;
  bool _wasCorrect = false;
  String? _selectedChoice;
  bool _finished = false;

  PracticeItem get _item => widget.lesson.items[_index];

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  bool get _canCheck {
    if (_item.isMultipleChoice) return _selectedChoice != null;
    return _answer.text.trim().isNotEmpty;
  }

  Future<void> _check() async {
    if (_checked || !_canCheck) return;
    final input = _item.isMultipleChoice
        ? (_selectedChoice ?? '')
        : _answer.text;
    final correct = _item.check(input);
    final progress = context.read<ProgressController>();
    final haptics = context.read<SettingsController>().settings.hapticsEnabled;

    setState(() {
      _checked = true;
      _wasCorrect = correct;
      if (correct) _correct++;
    });

    await progress.recordAnswer(correct: correct);
    if (widget.lesson.kind == LessonKind.vocabulary) {
      await progress.recordVocabResult(_item.id, correct: correct);
    }
    if (haptics) {
      if (correct) {
        HapticFeedback.lightImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
  }

  Future<void> _next() async {
    if (_index + 1 >= widget.lesson.items.length) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _checked = false;
      _wasCorrect = false;
      _selectedChoice = null;
      _answer.clear();
    });
  }

  Future<void> _finish() async {
    final progress = context.read<ProgressController>();
    final elapsed = DateTime.now().difference(_startedAt);
    final minutes = (elapsed.inSeconds / 60).round();
    if (minutes > 0) await progress.addMinutes(minutes);

    await progress.recordSession(
      SessionResult(
        id: 's${DateTime.now().microsecondsSinceEpoch}',
        kind: widget.lesson.kind,
        title: widget.lesson.title,
        correct: _correct,
        total: widget.lesson.items.length,
        completedAt: DateTime.now(),
        detail: '${elapsed.inSeconds}s',
      ),
    );

    if (widget.isChallenge || widget.lesson.kind == LessonKind.challenge) {
      await progress.completeChallenge(
        correct: _correct,
        total: widget.lesson.items.length,
      );
    }

    if (!mounted) return;
    setState(() => _finished = true);
  }

  void _restart() {
    setState(() {
      _index = 0;
      _correct = 0;
      _checked = false;
      _wasCorrect = false;
      _selectedChoice = null;
      _finished = false;
      _answer.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return _SummaryView(
        lesson: widget.lesson,
        correct: _correct,
        onRestart: _restart,
      );
    }

    final total = widget.lesson.items.length;
    final ratio = total == 0 ? 0.0 : (_index + (_checked ? 1 : 0)) / total;
    final settings = context.watch<SettingsController>();

    return ZloyPage(
      title: widget.lesson.title,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Center(
            child: Text(
              '${_index + 1}/$total',
              style: ZloyType.label.copyWith(color: ZloyColors.textSecondary),
            ),
          ),
        ),
      ],
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: ZloyColors.surfaceHigh,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              children: [
                Row(
                  children: [
                    ZloyMascot(
                      size: 48,
                      mood: !_checked
                          ? MascotMood.idle
                          : (_wasCorrect
                                ? MascotMood.correct
                                : MascotMood.incorrect),
                      animate: _checked,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _item.isMultipleChoice
                            ? 'Choose the correct option'
                            : 'Type your answer',
                        style: ZloyType.label,
                      ),
                    ),
                    if (_item.hint != null)
                      TextButton.icon(
                        onPressed: () => showZloySnack(context, _item.hint!),
                        icon: const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15,
                        ),
                        label: const Text(
                          'Hint',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 32),
                          foregroundColor: ZloyColors.warning,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SectionCard(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    _item.prompt,
                    style: ZloyType.headline.copyWith(fontSize: 20),
                  ),
                ),
                const SizedBox(height: 16),
                if (_item.isMultipleChoice)
                  ..._item.choiceAnswers.map(
                    (choice) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: _ChoiceTile(
                        text: choice,
                        selected: _selectedChoice == choice,
                        correct: _checked && _item.check(choice),
                        wrong:
                            _checked &&
                            _selectedChoice == choice &&
                            !_item.check(choice),
                        onTap: _checked
                            ? null
                            : () => setState(() => _selectedChoice = choice),
                      ),
                    ),
                  )
                else
                  TextField(
                    controller: _answer,
                    enabled: !_checked,
                    textCapitalization: TextCapitalization.sentences,
                    maxLines: 3,
                    minLines: 1,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _checked ? _next() : _check(),
                    decoration: InputDecoration(
                      hintText: widget.lesson.kind == LessonKind.translation
                          ? 'English translation…'
                          : 'Your answer…',
                      suffixIcon: _checked
                          ? Icon(
                              _wasCorrect
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: _wasCorrect
                                  ? ZloyColors.success
                                  : ZloyColors.danger,
                            )
                          : null,
                    ),
                    style: ZloyType.body.copyWith(fontSize: 16),
                  ),
                if (_checked) ...[
                  const SizedBox(height: 14),
                  _FeedbackCard(
                    correct: _wasCorrect,
                    expected: _item.answer,
                    explanation: _item.explanation,
                    language: settings.profile.explanationLanguage,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FilledButton(
              onPressed: _checked ? _next : (_canCheck ? _check : null),
              child: Text(
                _checked
                    ? (_index + 1 >= total ? 'See results' : 'Next')
                    : 'Check',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.text,
    required this.selected,
    required this.correct,
    required this.wrong,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool correct;
  final bool wrong;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color border;
    final Color background;
    if (correct) {
      border = ZloyColors.success;
      background = ZloyColors.success.withValues(alpha: 0.12);
    } else if (wrong) {
      border = ZloyColors.danger;
      background = ZloyColors.danger.withValues(alpha: 0.12);
    } else if (selected) {
      border = ZloyColors.ember;
      background = ZloyColors.ember.withValues(alpha: 0.12);
    } else {
      border = ZloyColors.outline;
      background = ZloyColors.surface;
    }

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: border,
              width: correct || wrong ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  style: ZloyType.body.copyWith(
                    fontSize: 15,
                    fontWeight: selected || correct ? FontWeight.w600 : null,
                  ),
                ),
              ),
              if (correct)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 18,
                  color: ZloyColors.success,
                )
              else if (wrong)
                const Icon(
                  Icons.cancel_rounded,
                  size: 18,
                  color: ZloyColors.danger,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.correct,
    required this.expected,
    required this.explanation,
    required this.language,
  });

  final bool correct;
  final String expected;
  final String? explanation;
  final ExplanationLanguage language;

  @override
  Widget build(BuildContext context) {
    final color = correct ? ZloyColors.success : ZloyColors.danger;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 17,
                color: color,
              ),
              const SizedBox(width: 7),
              Text(
                correct ? 'Correct' : 'Not quite',
                style: ZloyType.title.copyWith(fontSize: 14, color: color),
              ),
            ],
          ),
          if (!correct) ...[
            const SizedBox(height: 8),
            Text(
              'Answer: $expected',
              style: ZloyType.body.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
          if (explanation != null && explanation!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(explanation!, style: ZloyType.bodyMuted),
          ],
        ],
      ),
    );
  }
}

class _SummaryView extends StatelessWidget {
  const _SummaryView({
    required this.lesson,
    required this.correct,
    required this.onRestart,
  });

  final Lesson lesson;
  final int correct;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final total = lesson.items.length;
    final ratio = total == 0 ? 0.0 : correct / total;
    final mood = ratio >= 0.8
        ? MascotMood.celebrate
        : ratio >= 0.5
        ? MascotMood.encourage
        : MascotMood.incorrect;
    final progress = context.watch<ProgressController>();

    return ZloyPage(
      title: 'Results',
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ZloyMascot(size: 140, mood: mood),
                    const SizedBox(height: 18),
                    Text('$correct / $total', style: ZloyType.display),
                    const SizedBox(height: 6),
                    Text(
                      ratio >= 0.8
                          ? 'Acceptable. Barely.'
                          : ratio >= 0.5
                          ? 'Half-decent. Keep working.'
                          : 'We have a lot to fix. Start again.',
                      textAlign: TextAlign.center,
                      style: ZloyType.bodyMuted,
                    ),
                    const SizedBox(height: 20),
                    SectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              value: '${(ratio * 100).round()}%',
                              label: 'this session',
                              icon: Icons.percent_rounded,
                            ),
                          ),
                          Expanded(
                            child: StatTile(
                              value: '${progress.streakDays}',
                              label: 'day streak',
                              color: ZloyColors.warning,
                              icon: Icons.local_fire_department_rounded,
                            ),
                          ),
                          Expanded(
                            child: StatTile(
                              value: '${progress.totalItemsAnswered}',
                              label: 'answers total',
                              color: ZloyColors.violet,
                              icon: Icons.functions_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const InfoBanner(
                      message:
                          'Review this lesson any time. Repetition is the '
                          'only trick that works.',
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              children: [
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Done'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onRestart,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the runner for a lesson.
Future<void> startLesson(
  BuildContext context,
  Lesson lesson, {
  bool isChallenge = false,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) =>
          PracticeRunnerScreen(lesson: lesson, isChallenge: isChallenge),
    ),
  );
}

/// Re-exported for screens that need a level badge colour.
Color levelColor(ProficiencyLevel level) => switch (level) {
  ProficiencyLevel.beginner => ZloyColors.success,
  ProficiencyLevel.elementary => ZloyColors.info,
  ProficiencyLevel.intermediate => ZloyColors.violet,
  ProficiencyLevel.upperIntermediate => ZloyColors.warning,
  ProficiencyLevel.advanced => ZloyColors.ember,
};
