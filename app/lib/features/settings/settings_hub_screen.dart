import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../models/enums.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/zloy_mascot.dart';

/// Settings hub.
class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final s = settings.settings;
    final profile = settings.profile;

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
                      Text('Settings', style: ZloyType.headline),
                      const SizedBox(height: 2),
                      Text(
                        'No account. Everything stays on this phone.',
                        style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const ZloyMascot(size: 58, mood: MascotMood.idle),
              ],
            ),
            const SizedBox(height: 18),
            SectionCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.targetLanguage.englishName,
                          style: ZloyType.title,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Explained in '
                          '${profile.explanationLanguage.englishName} · '
                          '${profile.level.label}',
                          style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ZloyPill(
                    label: settings.settings.hasBackend
                        ? 'AI READY'
                        : 'OFFLINE',
                    color: settings.settings.hasBackend
                        ? ZloyColors.success
                        : ZloyColors.info,
                    filled: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SectionTitle('Tutor'),
            ActionTile(
              icon: Icons.psychology_alt_rounded,
              title: 'Personality',
              subtitle:
                  '${s.personality.label} · '
                  '${s.profanityEnabled ? 'profanity on' : 'profanity off'}',
              accent: ZloyColors.ember,
              onTap: () => Navigator.of(context).pushNamed(Routes.personality),
            ),
            const SectionTitle('Device'),
            ActionTile(
              icon: Icons.record_voice_over_rounded,
              title: 'Voice',
              subtitle: 'Speech input and playback, speed and pitch',
              accent: ZloyColors.info,
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.voiceSettings),
            ),
            ActionTile(
              icon: Icons.tune_rounded,
              title: 'General',
              subtitle: 'Languages, level, daily goal, backend URL',
              accent: ZloyColors.violet,
              onTap: () =>
                  Navigator.of(context).pushNamed(Routes.generalSettings),
            ),
            const SectionTitle('Legal & info'),
            ActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              subtitle: 'What is stored, what is sent, and to whom',
              accent: ZloyColors.success,
              onTap: () => Navigator.of(context).pushNamed(Routes.privacy),
            ),
            ActionTile(
              icon: Icons.info_outline_rounded,
              title: 'About ZLOY.AI',
              subtitle: 'Version, technology and honest limitations',
              accent: ZloyColors.warning,
              onTap: () => Navigator.of(context).pushNamed(Routes.about),
            ),
            const SizedBox(height: 16),
            Text(
              'ZLOY.AI · version 1.0.0 · free and open source · no ads',
              textAlign: TextAlign.center,
              style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }
}
