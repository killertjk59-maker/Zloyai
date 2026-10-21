import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/enums.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/zloy_mascot.dart';

/// Personality and profanity controls.
class PersonalitySettingsScreen extends StatelessWidget {
  const PersonalitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final selected = settings.settings.personality;
    final lang = settings.profile.explanationLanguage;

    return ZloyPage(
      title: 'Personality',
      child: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 28),
        children: [
          Center(
            child: ZloyMascot(
              size: 100,
              mood: switch (selected) {
                PersonalityMode.normal => MascotMood.encourage,
                PersonalityMode.strict => MascotMood.idle,
                PersonalityMode.roast => MascotMood.correct,
                PersonalityMode.shout => MascotMood.angry,
              },
            ),
          ),
          const SizedBox(height: 10),
          for (final mode in PersonalityMode.values)
            _ModeCard(
              mode: mode,
              selected: selected == mode,
              sample: _sample(mode, lang),
              onTap: () => settings.setPersonality(mode),
            ),
          const SizedBox(height: 16),
          const SectionTitle('Language of the abuse'),
          SectionCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.settings.profanityEnabled,
                  onChanged: settings.setProfanity,
                  title: const Text('Allow mild profanity'),
                  subtitle: Text(
                    'Insults are aimed at grammar and mistakes, never at you '
                    'as a person. Off by default.',
                    style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                  ),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const InfoBanner(
            message:
                'Rules the tutor always follows: no attacks on your '
                'identity, no threats, no encouragement of self-harm, and every '
                'correction ends with a real explanation.',
            icon: Icons.shield_outlined,
            color: ZloyColors.success,
          ),
          const SizedBox(height: 12),
          const InfoBanner(
            message:
                'SHOUT mode changes wording and capitalisation only. Your '
                'device voice cannot actually shout — ZLOY will never claim it '
                'does.',
            icon: Icons.volume_off_rounded,
            color: ZloyColors.warning,
          ),
        ],
      ),
    );
  }

  static String _sample(PersonalityMode mode, ExplanationLanguage lang) {
    switch (lang) {
      case ExplanationLanguage.tajik:
        return switch (mode) {
          PersonalityMode.normal =>
            'Хатои хурд: «I went» на «I go». Ҳамин тавр дуруст мешавад.',
          PersonalityMode.strict =>
            'Ин ҷумла нодуруст аст. Қоидаи замони феълро аз нав омӯз.',
          PersonalityMode.roast =>
            'Ин грамматика аз ту кӯмак пурсид! Биё, якҷоя ислоҳаш мекунем.',
          PersonalityMode.shout =>
            'ИСТ! Аввал замони феълро санҷ! Баъд ҷавоб деҳ!',
        };
      case ExplanationLanguage.russian:
        return switch (mode) {
          PersonalityMode.normal =>
            'Небольшая ошибка: нужно «I went», а не «I go». Вот и всё.',
          PersonalityMode.strict =>
            'Это предложение неверно. Повтори правило прошедшего времени.',
          PersonalityMode.roast =>
            'Эта грамматика взывала о помощи! Давай исправим вместе.',
          PersonalityMode.shout =>
            'СТОП! Сначала проверь время глагола! Потом отвечай!',
        };
      case ExplanationLanguage.english:
        return switch (mode) {
          PersonalityMode.normal =>
            'Small slip: it should be "I went", not "I go". Easy fix.',
          PersonalityMode.strict =>
            'That sentence is wrong. Review the past tense rule and try again.',
          PersonalityMode.roast =>
            'That grammar was begging for help! Let us fix it together.',
          PersonalityMode.shout =>
            'STOP! Check the verb tense first! Then answer!',
        };
    }
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.sample,
    required this.onTap,
  });

  final PersonalityMode mode;
  final bool selected;
  final String sample;
  final VoidCallback onTap;

  IconData get _icon => switch (mode) {
    PersonalityMode.normal => Icons.sentiment_satisfied_rounded,
    PersonalityMode.strict => Icons.gavel_rounded,
    PersonalityMode.roast => Icons.local_fire_department_rounded,
    PersonalityMode.shout => Icons.campaign_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: selected
            ? ZloyColors.ember.withValues(alpha: 0.10)
            : ZloyColors.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? ZloyColors.ember : ZloyColors.outline,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _icon,
                      size: 19,
                      color: selected
                          ? ZloyColors.ember
                          : ZloyColors.textSecondary,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      mode.label,
                      style: ZloyType.title.copyWith(fontSize: 15),
                    ),
                    const Spacer(),
                    if (selected)
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 18,
                        color: ZloyColors.ember,
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  mode.description,
                  style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: ZloyColors.background.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '“$sample”',
                    style: ZloyType.bodyMuted.copyWith(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
