import 'package:flutter/material.dart';

import '../models/chat_models.dart';
import '../models/enums.dart';
import '../theme/app_theme.dart';

/// Card that represents a lesson in the practice hubs.
class LessonCard extends StatelessWidget {
  const LessonCard({
    super.key,
    required this.lesson,
    required this.onTap,
    this.trailingText,
  });

  final Lesson lesson;
  final VoidCallback onTap;
  final String? trailingText;

  @override
  Widget build(BuildContext context) {
    final color = switch (lesson.level) {
      ProficiencyLevel.beginner => ZloyColors.success,
      ProficiencyLevel.elementary => ZloyColors.info,
      ProficiencyLevel.intermediate => ZloyColors.violet,
      ProficiencyLevel.upperIntermediate => ZloyColors.warning,
      ProficiencyLevel.advanced => ZloyColors.ember,
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
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
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    lesson.emoji,
                    style: const TextStyle(fontSize: 21),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: ZloyType.title.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lesson.subtitle,
                        style: ZloyType.bodyMuted.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              lesson.level.cefr,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${lesson.items.length} tasks',
                            style: ZloyType.bodyMuted.copyWith(fontSize: 10.5),
                          ),
                          if (trailingText != null) ...[
                            const SizedBox(width: 6),
                            Text(
                              trailingText!,
                              style: ZloyType.bodyMuted.copyWith(
                                fontSize: 10.5,
                                color: ZloyColors.success,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.play_circle_outline_rounded,
                  color: ZloyColors.ember,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
