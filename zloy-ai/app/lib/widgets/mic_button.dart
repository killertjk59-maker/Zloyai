import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Microphone button with a light pulse while listening.
///
/// It never claims to be listening when the recogniser is unavailable: the
/// caller passes [enabled] = false and the button renders disabled.
class MicButton extends StatefulWidget {
  const MicButton({
    super.key,
    required this.onPressed,
    this.listening = false,
    this.enabled = true,
    this.size = 56,
    this.tooltip,
  });

  final VoidCallback onPressed;
  final bool listening;
  final bool enabled;
  final double size;
  final String? tooltip;

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.listening) _pulse.repeat();
  }

  @override
  void didUpdateWidget(covariant MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.listening && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.listening && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.listening
        ? ZloyColors.danger
        : (widget.enabled ? ZloyColors.ember : ZloyColors.surfaceHigh);

    return Tooltip(
      message:
          widget.tooltip ?? (widget.listening ? 'Stop listening' : 'Speak'),
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.listening ? 'Stop listening' : 'Start voice input',
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final glow = widget.listening ? (1 - _pulse.value) : 0.0;
            return SizedBox(
              width: widget.size + 16,
              height: widget.size + 16,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.listening)
                    Container(
                      width: widget.size + 16 * glow,
                      height: widget.size + 16 * glow,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: baseColor.withValues(alpha: 0.16 * glow),
                      ),
                    ),
                  child!,
                ],
              ),
            );
          },
          child: Material(
            color: baseColor,
            shape: const CircleBorder(),
            elevation: widget.listening ? 8 : 2,
            shadowColor: baseColor.withValues(alpha: 0.5),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.enabled ? widget.onPressed : null,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: Icon(
                  widget.listening ? Icons.stop_rounded : Icons.mic_rounded,
                  color: widget.enabled ? Colors.white : ZloyColors.textMuted,
                  size: widget.size * 0.44,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
