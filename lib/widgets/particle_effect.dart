import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ParticleEffect extends StatefulWidget {
  final Color color;
  final int particleCount;

  const ParticleEffect({
    Key? key,
    required this.color,
    this.particleCount = 20,
  }) : super(key: key);

  @override
  State<ParticleEffect> createState() => _ParticleEffectState();
}

class _ParticleEffectState extends State<ParticleEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Particle> particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    particles = List.generate(widget.particleCount, (index) => Particle(widget.color));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(220, 220),
          painter: ParticlePainter(particles, _controller.value),
        );
      },
    );
  }
}

class Particle {
  final double x;
  final double y;
  final double speed;
  final double size;
  final Color color;

  Particle(Color baseColor)
      : x = Random().nextDouble() * 220,
        y = Random().nextDouble() * 220,
        speed = Random().nextDouble() * 2 + 1,
        size = Random().nextDouble() * 3 + 1,
        color = baseColor.withOpacity(Random().nextDouble() * 0.5 + 0.2);
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double progress;

  ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()..color = particle.color;
      final position = Offset(
        particle.x,
        (particle.y + (progress * particle.speed * 50)) % size.height,
      );
      canvas.drawCircle(position, particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
} 