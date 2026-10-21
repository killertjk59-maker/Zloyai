import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_models.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';
import 'common.dart';
import 'zloy_mascot.dart';

/// One chat row. User messages are right-aligned bubbles; tutor messages show
/// the mascot, an honest source badge and an optional correction card.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onSpeak,
    this.onRetry,
    this.onOfflineFallback,
    this.onEdit,
    this.speaking = false,
    this.mood = MascotMood.idle,
  });

  final ChatMessage message;
  final void Function(String text)? onSpeak;
  final VoidCallback? onRetry;
  final VoidCallback? onOfflineFallback;
  final void Function(String text)? onEdit;
  final bool speaking;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    if (message.isUser) return _userBubble(context);
    return _tutorBubble(context);
  }

  Widget _userBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: ZloyColors.emberGradient,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(5),
              ),
              boxShadow: [
                BoxShadow(
                  color: ZloyColors.ember.withValues(alpha: 0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: SelectableText(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (message.correction == null && onEdit != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                onPressed: () => onEdit!(message.text),
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: ZloyColors.textMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _tutorBubble(BuildContext context) {
    if (message.error != null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14, right: 24),
        child: ErrorStateView(
          message: message.error!,
          onRetry: onRetry,
          secondaryLabel: onOfflineFallback == null ? null : 'Check offline',
          onSecondary: onOfflineFallback,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ZloyMascot(
            mood: mood,
            size: 36,
            animate: mood == MascotMood.speaking,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'ZLOY',
                      style: ZloyType.label.copyWith(color: ZloyColors.ember),
                    ),
                    const SizedBox(width: 6),
                    TutorSourceBadge(source: message.source),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: ZloyColors.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(5),
                      topRight: Radius.circular(18),
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                    border: Border.all(color: ZloyColors.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(message.text, style: ZloyType.body),
                      if (message.correction != null) ...[
                        const SizedBox(height: 12),
                        CorrectionCard(
                          correction: message.correction!,
                          onSpeak: onSpeak,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (onSpeak != null)
                            _MiniAction(
                              icon: speaking
                                  ? Icons.stop_circle_outlined
                                  : Icons.volume_up_rounded,
                              label: speaking ? 'Stop' : 'Listen',
                              onTap: () => onSpeak!(
                                message.correction?.corrected.isNotEmpty == true
                                    ? message.correction!.corrected
                                    : message.text,
                              ),
                            ),
                          const Spacer(),
                          if (onEdit != null)
                            _MiniAction(
                              icon: Icons.copy_rounded,
                              label: 'Copy',
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: message.text),
                                );
                                showZloySnack(context, 'Copied');
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: ZloyColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: ZloyColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Structured grammar correction: original, corrected, rule, explanation,
/// examples, optional exercise, and honest handling of ambiguity.
class CorrectionCard extends StatelessWidget {
  const CorrectionCard({super.key, required this.correction, this.onSpeak});

  final Correction correction;
  final void Function(String text)? onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ZloyColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: correction.changed
              ? const Color(0x66FF5A3C)
              : const Color(0x552ED573),
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (correction.changed) ...[
            _row(
              icon: Icons.close_rounded,
              color: ZloyColors.danger,
              label: 'You wrote',
              child: Text(
                correction.original,
                style: ZloyType.bodyMuted.copyWith(
                  decoration: TextDecoration.lineThrough,
                  decorationColor: ZloyColors.danger,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _row(
              icon: Icons.check_rounded,
              color: ZloyColors.success,
              label: 'Correct',
              child: Text(
                correction.corrected,
                style: ZloyType.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB8F5D0),
                ),
              ),
            ),
          ] else ...[
            _row(
              icon: Icons.check_circle_outline_rounded,
              color: ZloyColors.success,
              label: 'No error found',
              child: Text(correction.original, style: ZloyType.body),
            ),
          ],
          if (correction.rule != null && correction.rule!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              children: [
                ZloyPill(
                  label: correction.rule!,
                  color: ZloyColors.violet,
                  icon: Icons.rule_rounded,
                  filled: true,
                ),
              ],
            ),
          ],
          if (correction.explanation.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(correction.explanation, style: ZloyType.body),
          ],
          if (correction.alternatives.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: ZloyColors.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ZloyColors.warning.withValues(alpha: 0.32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.help_outline_rounded,
                        size: 14,
                        color: ZloyColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Ambiguous — possible meanings',
                          style: ZloyType.label.copyWith(
                            color: ZloyColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  for (final alt in correction.alternatives)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '• $alt',
                        style: ZloyType.bodyMuted.copyWith(fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (correction.examples.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('EXAMPLES', style: ZloyType.label),
            const SizedBox(height: 4),
            for (final example in correction.examples)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 6),
                      child: Icon(
                        Icons.arrow_right_rounded,
                        size: 13,
                        color: ZloyColors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        example,
                        style: ZloyType.bodyMuted.copyWith(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (correction.exercise != null &&
              correction.exercise!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: ZloyColors.violet.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: ZloyColors.violet.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 16,
                    color: ZloyColors.violet,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      correction.exercise!,
                      style: ZloyType.bodyMuted.copyWith(
                        fontSize: 13,
                        color: const Color(0xFFDCD2FF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (correction.confidence != CorrectionConfidence.high) ...[
            const SizedBox(height: 8),
            Text(
              'Confidence: ${correction.confidence.id} — the intended meaning '
              'was not certain.',
              style: ZloyType.bodyMuted.copyWith(
                fontSize: 11,
                color: ZloyColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required Color color,
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: ZloyType.label),
              const SizedBox(height: 2),
              child,
            ],
          ),
        ),
      ],
    );
  }
}
