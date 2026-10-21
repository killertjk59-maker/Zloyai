import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/enums.dart';
import '../theme/app_theme.dart';

/// The ZLOY.AI mascot: an ember-coloured, mortarboard-wearing grump.
///
/// Drawn entirely with a CustomPainter so it costs no assets, scales to any
/// size and animates cheaply with a single controller.
class ZloyMascot extends StatefulWidget {
  const ZloyMascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 120,
    this.animate = true,
  });

  final MascotMood mood;
  final double size;
  final bool animate;

  @override
  State<ZloyMascot> createState() => _ZloyMascotState();
}

class _ZloyMascotState extends State<ZloyMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant ZloyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.animate && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'ZLOY mascot, ${widget.mood.name}',
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _MascotPainter(mood: widget.mood, t: _controller.value),
          ),
        ),
      ),
    );
  }
}

class _MascotPainter extends CustomPainter {
  _MascotPainter({required this.mood, required this.t});

  final MascotMood mood;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final scale = s / 100.0;
    canvas.save();
    canvas.scale(scale);

    // Breathing: gentle vertical squash, faster when excited.
    final speed = switch (mood) {
      MascotMood.thinking => 2.0,
      MascotMood.speaking => 1.6,
      MascotMood.celebrate => 3.0,
      MascotMood.angry => 2.4,
      _ => 1.0,
    };
    final phase = math.sin(t * math.pi * 2 * speed);
    final bounce = mood == MascotMood.celebrate
        ? -math.sin(t * math.pi * 2 * 3).abs() * 6
        : 0.0;
    final squash = 1 + phase * 0.015;

    canvas.translate(50, 56 + bounce);
    canvas.scale(1 / squash, squash);
    canvas.translate(-50, -56);

    final bodyColors = _bodyColors();
    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 30, 64, 58),
      const Radius.circular(26),
    );

    // Ground shadow.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(50, 92), width: 44, height: 7),
      Paint()..color = Colors.black.withValues(alpha: 0.28),
    );

    // Body.
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: bodyColors,
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    // Inner shading for depth.
    canvas.drawRRect(
      bodyRect.deflate(3),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    _paintHat(canvas);
    _paintFace(canvas);
    _paintEffects(canvas);

    canvas.restore();
  }

  List<Color> _bodyColors() {
    switch (mood) {
      case MascotMood.thinking:
        return const [Color(0xFF8B5CF6), Color(0xFF5B34C4)];
      case MascotMood.correct:
      case MascotMood.celebrate:
        return const [Color(0xFF35E07F), Color(0xFF14934F)];
      case MascotMood.incorrect:
        return const [Color(0xFFFF6B4A), Color(0xFFC42A16)];
      case MascotMood.angry:
        return const [Color(0xFFFF3B30), Color(0xFF9E1408)];
      case MascotMood.listening:
        return const [Color(0xFF4FC3FF), Color(0xFF1A6FB5)];
      case MascotMood.speaking:
        return const [Color(0xFFFF8A3C), Color(0xFFD2431B)];
      case MascotMood.encourage:
        return const [Color(0xFFFFC24B), Color(0xFFD98200)];
      case MascotMood.idle:
        return const [Color(0xFFFF5A3C), Color(0xFFB83018)];
    }
  }

  void _paintHat(Canvas canvas) {
    final hatPaint = Paint()..color = const Color(0xFF131A24);
    final trim = Paint()..color = const Color(0xFF2B3648);

    // Cap band.
    final band = RRect.fromRectAndRadius(
      const Rect.fromLTWH(35, 24, 30, 9),
      const Radius.circular(4),
    );
    canvas.drawRRect(band, hatPaint);

    // Board (diamond).
    final board = Path()
      ..moveTo(50, 10)
      ..lineTo(78, 21)
      ..lineTo(50, 32)
      ..lineTo(22, 21)
      ..close();
    canvas.drawPath(board, hatPaint);
    canvas.drawPath(
      board,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.14),
    );

    // Tassel — swings with the animation.
    final swing = math.sin(t * math.pi * 2) * 2.2;
    final tasselPath = Path()
      ..moveTo(74, 20)
      ..quadraticBezierTo(80 + swing, 26, 79 + swing, 34);
    canvas.drawPath(
      tasselPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = ZloyColors.warning,
    );
    canvas.drawCircle(
      Offset(79 + swing, 35),
      2.4,
      Paint()..color = ZloyColors.warning,
    );

    // Board highlight.
    canvas.drawLine(
      const Offset(50, 12),
      const Offset(50, 21),
      trim..strokeWidth = 1,
    );
  }

  void _paintFace(Canvas canvas) {
    const leftEye = Offset(38, 56);
    const rightEye = Offset(62, 56);
    final eyePaint = Paint()..color = Colors.white;

    // Blink: fast close twice per cycle.
    final cycle = (t * 3) % 1;
    final blinking = cycle > 0.94;
    final eyeHeight = blinking ? 1.2 : 7.5;

    for (final center in [leftEye, rightEye]) {
      if (blinking) {
        canvas.drawLine(
          Offset(center.dx - 5, center.dy),
          Offset(center.dx + 5, center.dy),
          Paint()
            ..color = const Color(0xFF131A24)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 11, height: eyeHeight),
          eyePaint,
        );
        // Pupil offset depends on mood.
        final look = switch (mood) {
          MascotMood.thinking => const Offset(0, -2.2),
          MascotMood.listening => const Offset(0, 0.6),
          MascotMood.angry => const Offset(0, 1.2),
          MascotMood.celebrate => const Offset(0, -0.6),
          _ => Offset.zero,
        };
        canvas.drawOval(
          Rect.fromCenter(center: center + look, width: 5.2, height: 5.6),
          Paint()..color = const Color(0xFF11161F),
        );
        canvas.drawCircle(
          center + look + const Offset(-1.4, -1.6),
          1.3,
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
      }
    }

    // Eyebrows: angry V for angry/incorrect, raised for surprise.
    final browPaint = Paint()
      ..color = const Color(0xFF141B25)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    switch (mood) {
      case MascotMood.angry:
      case MascotMood.incorrect:
        canvas.drawLine(const Offset(31, 45), const Offset(43, 49), browPaint);
        canvas.drawLine(const Offset(69, 45), const Offset(57, 49), browPaint);
      case MascotMood.thinking:
        canvas.drawLine(const Offset(31, 46), const Offset(43, 44), browPaint);
        canvas.drawLine(const Offset(69, 46), const Offset(57, 44), browPaint);
      case MascotMood.listening:
      case MascotMood.celebrate:
        canvas.drawLine(const Offset(31, 43), const Offset(43, 45), browPaint);
        canvas.drawLine(const Offset(69, 43), const Offset(57, 45), browPaint);
      default:
        canvas.drawLine(const Offset(31, 47), const Offset(43, 47), browPaint);
        canvas.drawLine(const Offset(69, 47), const Offset(57, 47), browPaint);
    }

    _paintMouth(canvas);

    // Cheeks.
    if (mood == MascotMood.correct ||
        mood == MascotMood.celebrate ||
        mood == MascotMood.encourage) {
      final blush = Paint()..color = Colors.white.withValues(alpha: 0.18);
      canvas.drawCircle(const Offset(29, 65), 3.4, blush);
      canvas.drawCircle(const Offset(71, 65), 3.4, blush);
    }
  }

  void _paintMouth(Canvas canvas) {
    final mouthPaint = Paint()
      ..color = const Color(0xFF141B25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;

    switch (mood) {
      case MascotMood.speaking:
        final open = 3 + (math.sin(t * math.pi * 2 * 6).abs() * 6);
        canvas.drawOval(
          Rect.fromCenter(
            center: const Offset(50, 68),
            width: 13,
            height: open,
          ),
          Paint()..color = const Color(0xFF141B25),
        );
      case MascotMood.correct:
        canvas.drawPath(
          Path()
            ..moveTo(42, 66)
            ..quadraticBezierTo(50, 74, 58, 66),
          mouthPaint,
        );
      case MascotMood.celebrate:
        final open = 6 + math.sin(t * math.pi * 2 * 4).abs() * 3;
        final p = Path()
          ..moveTo(41, 65)
          ..quadraticBezierTo(50, 65 + open * 2, 59, 65)
          ..close();
        canvas.drawPath(p, Paint()..color = const Color(0xFF141B25));
        canvas.drawPath(
          Path()
            ..moveTo(43, 66)
            ..quadraticBezierTo(50, 65 + open, 57, 66),
          Paint()
            ..color = const Color(0xFFFF7B93)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      case MascotMood.incorrect:
        canvas.drawPath(
          Path()
            ..moveTo(42, 71)
            ..quadraticBezierTo(50, 64, 58, 71),
          mouthPaint,
        );
      case MascotMood.angry:
        final p = Path()..moveTo(41, 67);
        for (var i = 0; i <= 4; i++) {
          p.lineTo(41 + i * 4.5, i.isEven ? 67 : 72);
        }
        canvas.drawPath(p, mouthPaint..strokeWidth = 2.2);
      case MascotMood.listening:
        canvas.drawCircle(
          const Offset(50, 68),
          3.6,
          Paint()..color = const Color(0xFF141B25),
        );
      case MascotMood.thinking:
        canvas.drawPath(
          Path()
            ..moveTo(43, 68)
            ..quadraticBezierTo(46.5, 65, 50, 68)
            ..quadraticBezierTo(53.5, 71, 57, 68),
          mouthPaint..strokeWidth = 2.2,
        );
      case MascotMood.encourage:
        canvas.drawPath(
          Path()
            ..moveTo(44, 67)
            ..quadraticBezierTo(50, 71, 56, 67),
          mouthPaint,
        );
      case MascotMood.idle:
        canvas.drawLine(const Offset(45, 68), const Offset(55, 68), mouthPaint);
    }
  }

  void _paintEffects(Canvas canvas) {
    if (mood == MascotMood.angry) {
      // Steam puffs rising from the head.
      for (var i = 0; i < 3; i++) {
        final progress = ((t + i * 0.33) % 1.0);
        final y = 24 - progress * 18;
        final x = i.isEven ? 20.0 : 80.0;
        canvas.drawCircle(
          Offset(x, y),
          3 + progress * 4,
          Paint()
            ..color = Colors.white.withValues(alpha: (1 - progress) * 0.35),
        );
      }
    }
    if (mood == MascotMood.celebrate) {
      for (var i = 0; i < 4; i++) {
        final progress = ((t * 1.4 + i * 0.25) % 1.0);
        final angle = i * math.pi / 2 + t * 1.5;
        final radius = 34 + progress * 14;
        final center = Offset(
          50 + math.cos(angle) * radius,
          58 + math.sin(angle) * radius * 0.7,
        );
        _star(
          canvas,
          center,
          3.2,
          Colors.white.withValues(alpha: 1 - progress),
        );
      }
    }
    if (mood == MascotMood.listening) {
      // Sound waves on both sides.
      for (var i = 0; i < 2; i++) {
        final progress = ((t + i * 0.5) % 1.0);
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = Colors.white.withValues(alpha: (1 - progress) * 0.5);
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(50, 58), radius: 36 + i * 6),
          -0.5,
          1.0,
          false,
          paint,
        );
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(50, 58), radius: 36 + i * 6),
          math.pi - 0.5,
          1.0,
          false,
          paint,
        );
      }
    }
    if (mood == MascotMood.thinking) {
      for (var i = 0; i < 3; i++) {
        final offset = math.sin((t * 2 + i * 0.2) * math.pi).abs();
        canvas.drawCircle(
          Offset(78 + i * 6, 30 - offset * 4),
          1.8 + offset,
          Paint()..color = Colors.white.withValues(alpha: 0.55),
        );
      }
    }
  }

  void _star(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 8; i++) {
      final r = i.isEven ? radius : radius * 0.38;
      final angle = -math.pi / 2 + i * math.pi / 4;
      final point = Offset(
        center.dx + math.cos(angle) * r,
        center.dy + math.sin(angle) * r,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MascotPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.mood != mood;
}
