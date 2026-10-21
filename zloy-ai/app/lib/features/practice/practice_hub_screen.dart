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
import '../history/history_screen.dart';
import '../reading/reading_screen.dart';
import '../vocabulary/vocabulary_screen.dart';
import '../voice/voice_screen.dart';

/// Hub for all practice modes.
class PracticeHubScreen extends StatelessWidget {
  const PracticeHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final progress = context.watch<ProgressController>();
    final profile = settings.profile;
    final challenge = BundledContent.dailyChallenge(
      day: DateTime.now(),
      lang: profile.explanationLanguage,
      level: profile.level,
    );

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
                      Text('Practice', style: ZloyType.headline),
                      const SizedBox(height: 2),
                      Text(
                        'Everything here works offline.',
                        style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                ZloyMascot(size: 62, mood: MascotMood.idle),
              ],
            ),
            const SizedBox(height: 18),
            _FeatureCard(
              title: 'Daily challenge',
              subtitle: progress.challengeCompletedToday
                  ? 'Completed today — come back tomorrow.'
                  : '${challenge.items.length} mixed tasks for today',
              icon: Icons.local_fire_department_rounded,
              color: ZloyColors.ember,
              badge: progress.challengeCompletedToday ? 'DONE' : 'TODAY',
              onTap: () => context.pushScreen(const DailyChallengeScreen()),
            ),
            const SizedBox(height: 12),
            ActionTile(
              icon: Icons.rule_rounded,
              title: 'Grammar drills',
              subtitle:
                  '${BundledContent.grammarLessons(profile.explanationLanguage).length} lessons · '
                  'rules explained in your language',
              accent: ZloyColors.success,
              onTap: () => context.pushScreen(const GrammarScreen()),
            ),
            ActionTile(
              icon: Icons.auto_stories_rounded,
              title: 'Vocabulary',
              subtitle:
                  '${BundledContent.vocabularyLessons(profile.explanationLanguage).length} word sets · '
                  'review queue from your mistakes',
              accent: ZloyColors.violet,
              onTap: () => context.pushScreen(const VocabularyScreen()),
            ),
            ActionTile(
              icon: Icons.menu_book_rounded,
              title: 'Reading & translation',
              subtitle: 'Short passages, comprehension, sentence translation',
              accent: ZloyColors.info,
              onTap: () => context.pushScreen(const ReadingScreen()),
            ),
            ActionTile(
              icon: Icons.mic_rounded,
              title: 'Speaking practice',
              subtitle: 'Read a sentence aloud and compare what was recognised',
              accent: ZloyColors.warning,
              onTap: () => context.pushScreen(const VoiceScreen()),
            ),
            ActionTile(
              icon: Icons.history_edu_rounded,
              title: 'Mistake review',
              subtitle: progress.unreviewedMistakes.isEmpty
                  ? 'No corrections waiting'
                  : '${progress.unreviewedMistakes.length} corrections waiting',
              accent: ZloyColors.danger,
              onTap: () => context.pushScreen(const HistoryScreen()),
            ),
            const SizedBox(height: 14),
            const InfoBanner(
              message:
                  'Typing always works. Microphone and speech playback '
                  'depend on your Android device.',
              icon: Icons.info_outline_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.55),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ZloyType.title.copyWith(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                badge!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
