import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../models/enums.dart';
import '../../models/user_profile.dart';
import '../../state/settings_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/zloy_mascot.dart';

/// Five-step onboarding: language, explanation language, level, goals, style.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _totalSteps = 6;
  int _step = 0;

  late UserProfile _draft;

  @override
  void initState() {
    super.initState();
    _draft = context.read<SettingsController>().profile;
  }

  bool get _canContinue {
    switch (_step) {
      case 1:
        return true; // target language always has a value
      case 2:
        return true;
      case 3:
        return true;
      case 4:
        return _draft.goals.isNotEmpty;
      default:
        return true;
    }
  }

  Future<void> _next() async {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
      return;
    }
    final settings = context.read<SettingsController>();
    await settings.updateProfile(_draft.copyWith(onboardingComplete: true));
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(Routes.home);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  children: [
                    if (_step > 0)
                      IconButton(
                        onPressed: _back,
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: 'Back',
                      )
                    else
                      const SizedBox(width: 48),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (_step + 1) / _totalSteps,
                          minHeight: 5,
                          backgroundColor: ZloyColors.surfaceHigh,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('${_step + 1}/$_totalSteps', style: ZloyType.label),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_step),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: _buildStep(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  children: [
                    if (_step == 0)
                      Text(
                        'Free · no account · works offline',
                        style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                      ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: _canContinue ? _next : null,
                      child: Text(
                        _step == 0
                            ? 'Start'
                            : (_step == _totalSteps - 1
                                  ? 'Finish'
                                  : 'Continue'),
                      ),
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

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return _WelcomeStep();
      case 1:
        return _ChoiceStep<TargetLanguage>(
          title: 'What do you want to learn?',
          subtitle:
              'English is the primary language for now. '
              'The structure supports more later.',
          options: TargetLanguage.values,
          selected: {_draft.targetLanguage},
          labelOf: (l) => l.englishName,
          subtitleOf: (l) => l.flag,
          onSelect: (l) =>
              setState(() => _draft = _draft.copyWith(targetLanguage: l)),
        );
      case 2:
        return _ChoiceStep<ExplanationLanguage>(
          title: 'How should I explain?',
          subtitle: 'Corrections and grammar rules appear in this language.',
          options: ExplanationLanguage.values,
          selected: {_draft.explanationLanguage},
          labelOf: (l) => l.nativeName,
          subtitleOf: (l) => l.englishName,
          onSelect: (l) =>
              setState(() => _draft = _draft.copyWith(explanationLanguage: l)),
        );
      case 3:
        return _ChoiceStep<ProficiencyLevel>(
          title: 'Your current level',
          subtitle: 'Be honest. ZLOY will notice anyway.',
          options: ProficiencyLevel.values,
          selected: {_draft.level},
          labelOf: (l) => '${l.label} · ${l.cefr}',
          subtitleOf: (l) => l.description,
          onSelect: (l) => setState(() => _draft = _draft.copyWith(level: l)),
        );
      case 4:
        return _GoalsStep(
          selected: _draft.goals,
          onToggle: (goal) {
            final goals = Set<LearningGoal>.from(_draft.goals);
            if (!goals.add(goal)) goals.remove(goal);
            setState(() => _draft = _draft.copyWith(goals: goals));
          },
        );
      case 5:
      default:
        return _StyleStep(
          style: _draft.learningStyle,
          minutes: _draft.dailyGoalMinutes,
          onStyle: (s) =>
              setState(() => _draft = _draft.copyWith(learningStyle: s)),
          onMinutes: (m) =>
              setState(() => _draft = _draft.copyWith(dailyGoalMinutes: m)),
        );
    }
  }
}

class _WelcomeStep extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Center(child: ZloyMascot(size: 150)),
        const SizedBox(height: 18),
        Text('I am ZLOY.', style: ZloyType.display),
        const SizedBox(height: 8),
        Text(
          'Your language tutor. I correct grammar, explain rules in your own '
          'language, and I do not pretend your mistakes are cute.',
          style: ZloyType.bodyMuted.copyWith(fontSize: 15),
        ),
        const SizedBox(height: 22),
        _Bullet(
          icon: Icons.record_voice_over_rounded,
          title: 'Choose my mood',
          text: 'Normal, Strict, Roast or Shout. Profanity is off by default.',
        ),
        _Bullet(
          icon: Icons.mic_rounded,
          title: 'Speak or type',
          text:
              'Voice input and speech playback use your device. '
              'Typing always works.',
        ),
        _Bullet(
          icon: Icons.offline_bolt_rounded,
          title: 'Offline lessons',
          text:
              'Vocabulary, grammar, reading and a daily challenge are '
              'bundled and need no internet.',
        ),
        _Bullet(
          icon: Icons.lock_outline_rounded,
          title: 'No account',
          text:
              'Progress stays on this phone. No sign-up, no ads, no tracking.',
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ZloyColors.ember.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: ZloyColors.ember),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: ZloyType.title.copyWith(fontSize: 14.5)),
                const SizedBox(height: 2),
                Text(text, style: ZloyType.bodyMuted.copyWith(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceStep<T> extends StatelessWidget {
  const _ChoiceStep({
    required this.title,
    required this.subtitle,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.subtitleOf,
    required this.onSelect,
  });

  final String title;
  final String subtitle;
  final List<T> options;
  final Set<T> selected;
  final String Function(T) labelOf;
  final String Function(T) subtitleOf;
  final void Function(T) onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text(title, style: ZloyType.headline),
        const SizedBox(height: 6),
        Text(subtitle, style: ZloyType.bodyMuted),
        const SizedBox(height: 20),
        for (final option in options)
          _SelectableCard(
            selected: selected.contains(option),
            title: labelOf(option),
            subtitle: subtitleOf(option),
            onTap: () => onSelect(option),
          ),
      ],
    );
  }
}

class _GoalsStep extends StatelessWidget {
  const _GoalsStep({required this.selected, required this.onToggle});

  final Set<LearningGoal> selected;
  final void Function(LearningGoal) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text('Why are you learning?', style: ZloyType.headline),
        const SizedBox(height: 6),
        Text(
          'Pick at least one. I use it to choose examples and tasks.',
          style: ZloyType.bodyMuted,
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final goal in LearningGoal.values)
              _GoalChip(
                goal: goal,
                selected: selected.contains(goal),
                onTap: () => onToggle(goal),
              ),
          ],
        ),
      ],
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  final LearningGoal goal;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? ZloyColors.ember.withValues(alpha: 0.16)
              : ZloyColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? ZloyColors.ember : ZloyColors.outline,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(goal.emoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                goal.label,
                style: ZloyType.body.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleStep extends StatelessWidget {
  const _StyleStep({
    required this.style,
    required this.minutes,
    required this.onStyle,
    required this.onMinutes,
  });

  final LearningStyle style;
  final int minutes;
  final void Function(LearningStyle) onStyle;
  final void Function(int) onMinutes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        Text('How do you learn best?', style: ZloyType.headline),
        const SizedBox(height: 6),
        Text(
          'This shapes how ZLOY explains things.',
          style: ZloyType.bodyMuted,
        ),
        const SizedBox(height: 16),
        for (final option in LearningStyle.values)
          _SelectableCard(
            selected: style == option,
            title: option.label,
            subtitle: option.description,
            onTap: () => onStyle(option),
          ),
        const SizedBox(height: 22),
        Text('Daily goal', style: ZloyType.title),
        const SizedBox(height: 4),
        Text(
          '$minutes minutes per day. Small and daily beats heroic and rare.',
          style: ZloyType.bodyMuted,
        ),
        Slider(
          value: minutes.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          label: '$minutes min',
          onChanged: (v) => onMinutes(v.round()),
        ),
      ],
    );
  }
}

class _SelectableCard extends StatelessWidget {
  const _SelectableCard({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? ZloyColors.ember.withValues(alpha: 0.12)
                : ZloyColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? ZloyColors.ember : ZloyColors.outline,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: ZloyType.title.copyWith(fontSize: 15)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? ZloyColors.ember : Colors.transparent,
                  border: Border.all(
                    color: selected ? ZloyColors.ember : ZloyColors.textMuted,
                    width: 1.6,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
