import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/app.dart';
import '../../models/enums.dart';
import '../../state/progress_controller.dart';
import '../../state/settings_controller.dart';
import '../../state/tutor_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/zloy_mascot.dart';

/// Branded splash. Loads persisted state, then routes to onboarding or home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  String? _error;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    // Loading notifies controllers, which must not happen during the first
    // build phase, so it starts after the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _boot();
    });
  }

  Future<void> _boot() async {
    final started = DateTime.now();
    try {
      final settings = context.read<SettingsController>();
      final progress = context.read<ProgressController>();
      final tutor = context.read<TutorController>();
      await Future.wait([settings.load(), progress.load(), tutor.load()]);
      // Keep the brand visible briefly, but never block longer than 1.2s.
      final elapsed = DateTime.now().difference(started);
      if (elapsed < const Duration(milliseconds: 900)) {
        await Future<void>.delayed(const Duration(milliseconds: 900) - elapsed);
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        settings.needsOnboarding ? Routes.onboarding : Routes.home,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.runtimeType.toString());
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.1,
            colors: [Color(0x33FF5A3C), ZloyColors.background],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _intro,
                  curve: Curves.easeOutBack,
                ),
                child: const ZloyMascot(size: 150, mood: MascotMood.idle),
              ),
              const SizedBox(height: 18),
              FadeTransition(
                opacity: _intro,
                child: Column(
                  children: [
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'ZLOY',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: ZloyColors.ember,
                            ),
                          ),
                          TextSpan(
                            text: '.AI',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 1.5,
                              color: ZloyColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your language tutor with an attitude',
                      style: ZloyType.bodyMuted.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              if (_error == null)
                const SizedBox(
                  width: 90,
                  child: ClipRRect(
                    borderRadius: BorderRadius.all(Radius.circular(3)),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      backgroundColor: ZloyColors.surfaceHigh,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        'Could not read local storage ($_error). '
                        'The app can still run with default settings.',
                        textAlign: TextAlign.center,
                        style: ZloyType.bodyMuted,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            Navigator.of(context)
                                .pushReplacementNamed(Routes.onboarding),
                        child: const Text('Continue'),
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
