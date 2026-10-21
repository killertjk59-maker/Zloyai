import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';

/// Standard page scaffold with the ZLOY dark backdrop.
class ZloyPage extends StatelessWidget {
  const ZloyPage({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.showBack = true,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.padded = true,
    this.scrollable = false,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool padded;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final content = padded
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: child,
          )
        : child;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E131B), ZloyColors.background],
          stops: [0, 0.35],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: title == null
            ? null
            : AppBar(
                title: Text(title!),
                automaticallyImplyLeading: showBack,
                actions: actions,
              ),
        body: SafeArea(
          top: title == null,
          child: scrollable
              ? SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: content,
                )
              : content,
        ),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}

/// Card with the project's border / padding conventions.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.gradient,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient ?? ZloyColors.cardSheen,
        borderRadius: BorderRadius.circular(ZloyTheme.radius),
        border: Border.all(color: borderColor ?? ZloyColors.outline),
      ),
      child: onTap == null
          ? content
          : Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(ZloyTheme.radius),
                onTap: onTap,
                child: content,
              ),
            ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing, this.padding});

  final String text;
  final Widget? trailing;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Expanded(child: Text(text.toUpperCase(), style: ZloyType.label)),
          if (trailing != null) Flexible(child: trailing!),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.color = ZloyColors.ember,
  });

  final String value;
  final String label;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: ZloyType.bodyMuted.copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: ZloyColors.surfaceAlt,
                shape: BoxShape.circle,
                border: Border.all(color: ZloyColors.outline),
              ),
              child: Icon(icon, size: 28, color: ZloyColors.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: ZloyType.title),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ZloyType.bodyMuted,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Honest error panel: explains what failed and offers a way forward.
class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.message,
    this.title,
    this.onRetry,
    this.secondaryLabel,
    this.onSecondary,
    this.detail,
  });

  final String message;
  final String? title;
  final VoidCallback? onRetry;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1618),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF5A2A2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 18,
                color: ZloyColors.danger,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title ?? 'AI unavailable',
                  style: ZloyType.title.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: ZloyType.bodyMuted),
          if (detail != null) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: ZloyType.bodyMuted.copyWith(
                fontSize: 11,
                color: ZloyColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              if (onSecondary != null && secondaryLabel != null)
                OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 42),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(secondaryLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label = 'Loading…'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            const SizedBox(height: 12),
            Text(label, style: ZloyType.bodyMuted),
          ],
        ),
      ),
    );
  }
}

/// Small pill used for source labels, levels and statuses.
class ZloyPill extends StatelessWidget {
  const ZloyPill({
    super.key,
    required this.label,
    this.color = ZloyColors.ember,
    this.icon,
    this.filled = false,
  });

  final String label;
  final Color color;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? color.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Label that tells the user where an answer came from. Never overstates it.
class TutorSourceBadge extends StatelessWidget {
  const TutorSourceBadge({super.key, required this.source});

  final TutorSource? source;

  @override
  Widget build(BuildContext context) {
    switch (source) {
      case TutorSource.ai:
        return const ZloyPill(
          label: 'AI',
          color: ZloyColors.violet,
          icon: Icons.auto_awesome_rounded,
          filled: true,
        );
      case TutorSource.mock:
        return const ZloyPill(
          label: 'MOCK',
          color: ZloyColors.warning,
          icon: Icons.science_rounded,
          filled: true,
        );
      case TutorSource.offline:
        return const ZloyPill(
          label: 'OFFLINE CHECK',
          color: ZloyColors.info,
          icon: Icons.offline_bolt_rounded,
          filled: true,
        );
      case null:
        return const SizedBox.shrink();
    }
  }
}

/// Tappable row used by the practice and settings hubs.
class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.accent = ZloyColors.ember,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: ZloyColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ZloyColors.outline),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: ZloyType.title.copyWith(fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  trailing ??
                      Icon(
                        onTap == null
                            ? Icons.lock_outline_rounded
                            : Icons.chevron_right_rounded,
                        color: ZloyColors.textMuted,
                        size: 20,
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim informational banner (offline notices, limitations).
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = ZloyColors.info,
    this.action,
  });

  final String message;
  final IconData icon;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: ZloyType.bodyMuted.copyWith(fontSize: 12.5),
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

void showZloySnack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFF5A2A2E)
            : ZloyColors.surfaceHigh,
        duration: const Duration(seconds: 3),
      ),
    );
}
