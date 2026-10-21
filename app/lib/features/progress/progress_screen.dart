import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../models/chat_models.dart';
import '../../models/enums.dart';
import '../../models/progress_models.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/zloy_mascot.dart';
import '../history/history_screen.dart';

/// Progress dashboard. Every figure comes from stored activity.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final progress = context.watch<ProgressController>();
    final profile = settings.profile;
    final days = progress.lastSevenDays;
    final hasData =
        progress.totalItemsAnswered > 0 || progress.totalMinutes > 0;

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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress', style: ZloyType.headline),
                      const SizedBox(height: 2),
                      Text(
                        '${profile.targetLanguage.englishName} · '
                        '${profile.level.label}',
                        style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                ZloyMascot(
                  size: 62,
                  mood: hasData ? MascotMood.correct : MascotMood.idle,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (!hasData)
              EmptyStateView(
                icon: Icons.insights_rounded,
                title: 'No data yet',
                message:
                    'Answer a few exercises and your real numbers will '
                    'appear here. Nothing is invented.',
                actionLabel: 'Start the daily challenge',
                onAction: () => Navigator.of(context).pushNamed(Routes.home),
              )
            else ...[
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle('Last 7 days'),
                    SizedBox(
                      height: 110,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < days.length; i++)
                            Expanded(
                              child: _DayBar(
                                day: days[i],
                                isToday: i == days.length - 1,
                                maxMinutes: _maxMinutes(days),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Minutes of practice per day.',
                      style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                child: Column(
                  children: [
                    Row(
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
                            value: '${progress.totalMinutes}',
                            label: 'minutes practised',
                            icon: Icons.timer_outlined,
                            color: ZloyColors.info,
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            value:
                                '${(progress.weeklyAccuracy * 100).round()}%',
                            label: 'accuracy (7d)',
                            icon: Icons.track_changes_rounded,
                            color: ZloyColors.success,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: StatTile(
                            value: '${progress.totalItemsAnswered}',
                            label: 'answers given',
                            icon: Icons.functions_rounded,
                            color: ZloyColors.violet,
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            value: '${progress.sessionsCompleted}',
                            label: 'sessions',
                            icon: Icons.event_available_rounded,
                            color: ZloyColors.ember,
                          ),
                        ),
                        Expanded(
                          child: StatTile(
                            value: '${progress.totalAiMessages}',
                            label: 'tutor messages',
                            icon: Icons.forum_outlined,
                            color: ZloyColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.tips_and_updates_outlined,
                          size: 16,
                          color: ZloyColors.violet,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'Level check',
                          style: ZloyType.title.copyWith(fontSize: 14.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      progress.suggestedLevelHint(
                        profile.level,
                        profile.explanationLanguage,
                      ),
                      style: ZloyType.bodyMuted,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context)
                              .pushNamed(Routes.generalSettings),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                      ),
                      child: const Text('Change level'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SectionTitle(
                'Recent sessions',
                trailing: TextButton(
                  onPressed: () => context.pushScreen(const HistoryScreen()),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 30),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text(
                    'All history',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
              if (progress.sessions.isEmpty)
                SectionCard(
                  child: Text(
                    'No completed sessions yet. Finish a lesson to see it here.',
                    style: ZloyType.bodyMuted,
                  ),
                )
              else
                for (final session in progress.sessions.take(5))
                  _SessionTile(session: session),
            ],
          ],
        ),
      ),
    );
  }

  static int _maxMinutes(List<DailyActivity> days) {
    var max = 1;
    for (final day in days) {
      if (day.minutes > max) max = day.minutes;
    }
    return max;
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.day,
    required this.isToday,
    required this.maxMinutes,
  });

  final DailyActivity day;
  final bool isToday;
  final int maxMinutes;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final ratio = (day.minutes / maxMinutes).clamp(0.0, 1.0);
    final height = 8 + ratio * 70;
    final color = day.isEmpty
        ? ZloyColors.surfaceHigh
        : (isToday
              ? ZloyColors.ember
              : ZloyColors.ember.withValues(alpha: 0.55));

    return Tooltip(
      message: '${day.minutes} min · ${day.itemsAnswered} answers',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            day.minutes == 0 ? '' : '${day.minutes}',
            style: ZloyType.bodyMuted.copyWith(fontSize: 9.5),
          ),
          const SizedBox(height: 3),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            height: height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _weekdays[day.dayKey.weekday - 1],
            style: ZloyType.label.copyWith(
              fontSize: 10,
              color: isToday ? ZloyColors.ember : ZloyColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session});

  final SessionResult session;

  @override
  Widget build(BuildContext context) {
    final percent = (session.score * 100).round();
    final color = session.score >= 0.8
        ? ZloyColors.success
        : session.score >= 0.5
        ? ZloyColors.warning
        : ZloyColors.danger;
    final icon = switch (session.kind) {
      LessonKind.vocabulary => Icons.auto_stories_rounded,
      LessonKind.grammar => Icons.rule_rounded,
      LessonKind.reading => Icons.menu_book_rounded,
      LessonKind.translation => Icons.translate_rounded,
      LessonKind.challenge => Icons.local_fire_department_rounded,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ZloyColors.textSecondary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.title,
                    style: ZloyType.body.copyWith(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${session.correct}/${session.total} · '
                    '${_formatDate(session.completedAt)}',
                    style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'today';
    if (diff == 1) return 'yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.day}.${date.month}.${date.year}';
  }
}
