import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../models/enums.dart';
import '../../services/backend_client.dart';
import '../../services/tutor_repository.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Languages, level, daily goal, backend configuration and data reset.
class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _backend;
  bool _testing = false;
  String? _testMessage;
  bool _testOk = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsController>();
    _name = TextEditingController(text: settings.profile.displayName);
    _backend = TextEditingController(text: settings.settings.backendBaseUrl);
  }

  @override
  void dispose() {
    _name.dispose();
    _backend.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final controller = context.read<SettingsController>();
    final repository = context.read<TutorRepository>();
    setState(() {
      _testing = true;
      _testMessage = null;
    });
    await controller.setBackendUrl(_backend.text);
    try {
      final health = await repository
          .probe(controller.settings)
          .timeout(const Duration(seconds: 20));
      if (!mounted) return;
      setState(() {
        _testOk = health?.ok ?? false;
        _testMessage = health == null
            ? 'No backend URL saved yet.'
            : (health.mock
                  ? 'Connected. Backend is running with its MOCK provider — '
                        'answers are not from a real model.'
                  : 'Connected. Provider: ${health.provider} · '
                        'model: ${health.model}');
        _testing = false;
      });
    } on TutorException catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testMessage = e.message;
        _testing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _testOk = false;
        _testMessage = 'Connection test failed (${e.runtimeType}).';
        _testing = false;
      });
    }
  }

  Future<void> _pickTargetLanguage() async {
    final controller = context.read<SettingsController>();
    final selected = await showModalBottomSheet<TargetLanguage>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Learning language', style: ZloyType.title),
              ),
            ),
            for (final language in TargetLanguage.values)
              ListTile(
                selected: controller.profile.targetLanguage == language,
                leading: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(language.englishName),
                subtitle: Text(
                  language.tajikName,
                  style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                ),
                trailing: controller.profile.targetLanguage == language
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: ZloyColors.ember,
                        size: 20,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(language),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) await controller.setTargetLanguage(selected);
  }

  Future<void> _pickExplanationLanguage() async {
    final controller = context.read<SettingsController>();
    final selected = await showModalBottomSheet<ExplanationLanguage>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Explanation language', style: ZloyType.title),
              ),
            ),
            for (final language in ExplanationLanguage.values)
              ListTile(
                selected: controller.profile.explanationLanguage == language,
                title: Text(
                  '${language.nativeName}  ·  ${language.englishName}',
                ),
                trailing: controller.profile.explanationLanguage == language
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: ZloyColors.ember,
                        size: 20,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(language),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) {
      await controller.setExplanationLanguage(selected);
    }
  }

  Future<void> _pickLevel() async {
    final controller = context.read<SettingsController>();
    final selected = await showModalBottomSheet<ProficiencyLevel>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Your level', style: ZloyType.title),
              ),
            ),
            for (final level in ProficiencyLevel.values)
              ListTile(
                selected: controller.profile.level == level,
                title: Text('${level.label} · ${level.cefr}'),
                subtitle: Text(
                  level.description,
                  style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                ),
                trailing: controller.profile.level == level
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: ZloyColors.ember,
                        size: 20,
                      )
                    : null,
                onTap: () => Navigator.of(sheetContext).pop(level),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (selected != null) await controller.setLevel(selected);
  }

  Future<void> _resetData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete all local data?'),
        content: const Text(
          'This deletes your progress, history, corrections, chat and settings '
          'from this device. It cannot be undone — there is no cloud backup.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: ZloyColors.danger),
            child: const Text('Delete everything'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<SettingsController>().resetEverything(
      progress: context.read<ProgressController>(),
    );
    if (!mounted) return;
    Navigator.of(context)
        .pushNamedAndRemoveUntil(Routes.onboarding, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final profile = controller.profile;
    final settings = controller.settings;

    return ZloyPage(
      title: 'General',
      child: ListView(
        padding: const EdgeInsets.only(top: 10, bottom: 32),
        children: [
          const SectionTitle('Profile'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Your name (optional)',
                    hintText: 'Used only in greetings',
                  ),
                  onSubmitted: (value) => controller.setDisplayName(value),
                  onTapOutside: (_) => controller.setDisplayName(_name.text),
                ),
                const SizedBox(height: 6),
                Text(
                  'Stored on this device only. No account is created.',
                  style: ZloyType.bodyMuted.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Learning'),
          SectionCard(
            child: Column(
              children: [
                _SettingRow(
                  icon: Icons.flag_rounded,
                  label: 'Learning language',
                  value:
                      '${profile.targetLanguage.flag} '
                      '${profile.targetLanguage.englishName}',
                  onTap: _pickTargetLanguage,
                ),
                const Divider(height: 18),
                _SettingRow(
                  icon: Icons.translate_rounded,
                  label: 'Explanation language',
                  value: profile.explanationLanguage.nativeName,
                  onTap: _pickExplanationLanguage,
                ),
                const Divider(height: 18),
                _SettingRow(
                  icon: Icons.stairs_rounded,
                  label: 'Level',
                  value: '${profile.level.label} · ${profile.level.cefr}',
                  onTap: _pickLevel,
                ),
                const Divider(height: 18),
                Row(
                  children: [
                    const Icon(
                      Icons.timer_outlined,
                      size: 17,
                      color: ZloyColors.textSecondary,
                    ),
                    const SizedBox(width: 9),
                    Expanded(child: Text('Daily goal', style: ZloyType.body)),
                    Text(
                      '${profile.dailyGoalMinutes} min',
                      style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ],
                ),
                Slider(
                  value: profile.dailyGoalMinutes.toDouble(),
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: (v) => controller.setDailyGoalMinutes(v.round()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('AI backend'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The app talks to your own FastAPI backend. The OpenRouter '
                  'API key lives only on that server and is never stored in '
                  'this app.',
                  style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _backend,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'Backend base URL',
                    hintText: 'https://your-backend.example.com',
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _testing ? null : _testConnection,
                        child: Text(_testing ? 'Testing…' : 'Save & test'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Clear URL',
                      onPressed: () async {
                        _backend.clear();
                        await controller.setBackendUrl('');
                        if (!mounted) return;
                        setState(() {
                          _testMessage = 'Backend URL cleared. Offline mode.';
                          _testOk = false;
                        });
                      },
                      icon: const Icon(Icons.clear_rounded),
                    ),
                  ],
                ),
                if (_testMessage != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (_testOk ? ZloyColors.success : ZloyColors.danger)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            (_testOk ? ZloyColors.success : ZloyColors.danger)
                                .withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _testMessage!,
                      style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                SwitchListTile(
                  value: settings.preferOfflineOnly,
                  onChanged: controller.setPreferOfflineOnly,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Offline mode only'),
                  subtitle: Text(
                    'Never send messages to the backend. The built-in rule '
                    'checker is used instead.',
                    style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const InfoBanner(
            message:
                'For local development, an Android emulator reaches a '
                'computer backend on 10.0.2.2. A physical phone needs your '
                'computer’s LAN address or a deployed HTTPS backend. '
                'Plain HTTP is blocked by Android unless explicitly allowed.',
            icon: Icons.lan_outlined,
          ),
          const SizedBox(height: 18),
          const SectionTitle('Data'),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your settings, progress, corrections and chat are stored in '
                  'this app’s local storage.',
                  style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _resetData,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ZloyColors.danger,
                    side: const BorderSide(color: Color(0x66FF4757)),
                  ),
                  icon: const Icon(Icons.delete_forever_outlined, size: 18),
                  label: const Text('Delete all local data'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pushNamed(Routes.about),
              child: const Text('About ZLOY.AI'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 17, color: ZloyColors.textSecondary),
            const SizedBox(width: 9),
            Expanded(child: Text(label, style: ZloyType.body)),
            Text(value, style: ZloyType.bodyMuted.copyWith(fontSize: 12.5)),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ZloyColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
