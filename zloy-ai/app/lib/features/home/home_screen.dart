import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../data/bundled_content.dart';
import '../../models/enums.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/zloy_mascot.dart';
import '../challenge/daily_challenge_screen.dart';
import '../grammar/grammar_screen.dart';
import '../vocabulary/vocabulary_screen.dart';
import '../voice/voice_screen.dart';

/// The dashboard. Every number here is derived from recorded activity.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final progress = context.watch<ProgressController>();
    final profile = settings.profile;
    final today = progress.today;
    final goal = profile.dailyGoalMinutes;
    final progressRatio = goal == 0
        ? 0.0
        : (today.minutes / goal).clamp(0.0, 1.0);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF101722), ZloyColors.background],
          stops: [0, 0.4],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(name: profile.displayName),
                    const SizedBox(height: 16),
                    _HeroCard(
                      targetLanguage: profile.targetLanguage,
                      level: profile.level,
                      streak: progress.streakDays,
                      mood: progress.challengeCompletedToday
                          ? MascotMood.celebrate
                          : (progress.streakDays > 2
                                ? MascotMood.correct
                                : MascotMood.idle),
                    ),
                    const SizedBox(height: 14),
                    _DailyGoalCard(
                      minutes: today.minutes,
                      goal: goal,
                      answered: today.itemsAnswered,
                      correct: today.itemsCorrect,
                      progressRatio: progressRatio,
                      onAdjust: () => _openGoals(context),
                    ),
                    const SizedBox(height: 14),
                    if (!settings.settings.hasBackend ||
                        settings.settings.preferOfflineOnly)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: InfoBanner(
                          message:
                              'AI tutor is in offline mode: only the built-in '
                              'checker runs. Add a backend URL in Settings for '
                              'full AI answers and chat.',
                          color: ZloyColors.info,
                          action: TextButton(
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed(Routes.generalSettings),
                            child: const Text('Set up'),
                          ),
                        ),
                      ),
                    SectionTitle(
                      'Today',
                      trailing: Text(
                        BundledContent.dailyChallengeHeadline(
                          profile.explanationLanguage,
                          BundledContent.dailyChallenge(
                            day: DateTime.now(),
                            lang: profile.explanationLanguage,
                            level: profile.level,
                          ).items.length,
                        ),
                        style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                      ),
                    ),
                    _ChallengeCard(
                      completed: progress.challengeCompletedToday,
                      items: BundledContent.dailyChallenge(
                        day: DateTime.now(),
                        lang: profile.explanationLanguage,
                        level: profile.level,
                      ).items.length,
                      onStart: () =>
                          context.pushScreen(const DailyChallengeScreen()),
                    ),
                    const SizedBox(height: 20),
                    const SectionTitle('Jump back in'),
                    _QuickGrid(
                      onTutor: () => onSelectTab(1),
                      onVoice: () => context.pushScreen(const VoiceScreen()),
                      onVocabulary: () =>
                          context.pushScreen(const VocabularyScreen()),
                      onGrammar: () =>
                          context.pushScreen(const GrammarScreen()),
                    ),
                    const SizedBox(height: 20),
                    const SectionTitle('Your numbers'),
                    SectionCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: StatTile(
                              value: '${progress.streakDays}',
                              label: 'day streak',
                              icon: Icons.local_fire_department_rounded,
                              color: ZloyColors.warning,
                            ),
                          ),
                          Expanded(
                            child: StatTile(
                              value: progress.totalItemsAnswered == 0
                                  ? '—'
                                  : '${(progress.overallAccuracy * 100).round()}%',
                              label: 'accuracy',
                              icon: Icons.track_changes_rounded,
                              color: ZloyColors.success,
                            ),
                          ),
                          Expanded(
                            child: StatTile(
                              value: '${progress.masteredWordCount}',
                              label: 'words mastered',
                              icon: Icons.auto_stories_rounded,
                              color: ZloyColors.violet,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Progress is stored only on this device.',
                        style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openGoals(BuildContext context) {
    Navigator.of(context).pushNamed(Routes.generalSettings);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final greeting = name.trim().isEmpty
        ? 'Welcome back'
        : 'Салом, ${name.trim()}';
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: ZloyType.headline.copyWith(fontSize: 22),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Ready to make mistakes? I will fix them.',
                style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: ZloyColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ZloyColors.outline),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, size: 15, color: ZloyColors.ember),
              const SizedBox(width: 4),
              Text(
                'ZLOY.AI',
                style: ZloyType.label.copyWith(color: ZloyColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.targetLanguage,
    required this.level,
    required this.streak,
    required this.mood,
  });

  final TargetLanguage targetLanguage;
  final ProficiencyLevel level;
  final int streak;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 8, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF24161A), Color(0xFF141B26)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x33FF5A3C)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      targetLanguage.flag,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${targetLanguage.englishName} · ${level.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ZloyType.title.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  streak > 0
                      ? '$streak day${streak == 1 ? '' : 's'} in a row. '
                            'Do not ruin it now.'
                      : 'No streak yet. One short session starts it.',
                  style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ZloyPill(
                      label: level.cefr,
                      color: ZloyColors.ember,
                      filled: true,
                    ),
                    ZloyPill(
                      label: '${streak}d streak',
                      color: ZloyColors.warning,
                      icon: Icons.local_fire_department_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          ZloyMascot(mood: mood, size: 92),
        ],
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.minutes,
    required this.goal,
    required this.answered,
    required this.correct,
    required this.progressRatio,
    required this.onAdjust,
  });

  final int minutes;
  final int goal;
  final int answered;
  final int correct;
  final double progressRatio;
  final VoidCallback onAdjust;

  @override
  Widget build(BuildContext context) {
    final done = minutes >= goal && goal > 0;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.verified_rounded : Icons.timer_outlined,
                size: 17,
                color: done ? ZloyColors.success : ZloyColors.textSecondary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  done
                      ? 'Daily goal reached. Show-off.'
                      : 'Daily goal · $minutes / $goal min',
                  style: ZloyType.title.copyWith(fontSize: 14.5),
                ),
              ),
              TextButton(
                onPressed: onAdjust,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: const Text('Adjust', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progressRatio,
              minHeight: 8,
              backgroundColor: ZloyColors.surfaceHigh,
              valueColor: AlwaysStoppedAnimation(
                done ? ZloyColors.success : ZloyColors.ember,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            answered == 0
                ? 'No practice recorded yet today.'
                : '$correct of $answered answers correct today.',
            style: ZloyType.bodyMuted.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  const _ChallengeCard({
    required this.completed,
    required this.items,
    required this.onStart,
  });

  final bool completed;
  final int items;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      gradient: completed
          ? const LinearGradient(colors: [Color(0xFF12291D), Color(0xFF121821)])
          : ZloyColors.emberGradient,
      borderColor: completed ? const Color(0x552ED573) : Colors.transparent,
      padding: const EdgeInsets.all(18),
      onTap: onStart,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: completed
                  ? ZloyColors.success.withValues(alpha: 0.16)
                  : Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              completed ? Icons.check_rounded : Icons.local_fire_department,
              color: completed ? ZloyColors.success : Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  completed ? 'Challenge done' : 'Daily challenge',
                  style: ZloyType.title.copyWith(
                    fontSize: 16,
                    color: completed ? ZloyColors.textPrimary : Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  completed
                      ? 'Come back tomorrow for a new set.'
                      : '$items mixed tasks · vocabulary, grammar, reading',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: completed
                        ? ZloyColors.textSecondary
                        : Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 15,
            color: completed
                ? ZloyColors.textMuted
                : Colors.white.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}

class _QuickGrid extends StatelessWidget {
  const _QuickGrid({
    required this.onTutor,
    required this.onVoice,
    required this.onVocabulary,
    required this.onGrammar,
  });

  final VoidCallback onTutor;
  final VoidCallback onVoice;
  final VoidCallback onVocabulary;
  final VoidCallback onGrammar;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // A fixed tile height keeps the layout intact on 320dp-wide screens
      // instead of relying on an aspect ratio.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 116,
      ),
      children: [
        _QuickTile(
          icon: Icons.forum_rounded,
          label: 'AI tutor',
          caption: 'Chat & correct',
          color: ZloyColors.ember,
          onTap: onTutor,
        ),
        _QuickTile(
          icon: Icons.mic_rounded,
          label: 'Speaking',
          caption: 'Voice practice',
          color: ZloyColors.info,
          onTap: onVoice,
        ),
        _QuickTile(
          icon: Icons.auto_stories_rounded,
          label: 'Vocabulary',
          caption: 'Word drills',
          color: ZloyColors.violet,
          onTap: onVocabulary,
        ),
        _QuickTile(
          icon: Icons.rule_rounded,
          label: 'Grammar',
          caption: 'Rules & drills',
          color: ZloyColors.success,
          onTap: onGrammar,
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.caption,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ZloyColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: ZloyColors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZloyType.title.copyWith(fontSize: 14),
                    ),
                    Text(
                      caption,
                      style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
