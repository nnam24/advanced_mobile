import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:supercharged/supercharged.dart';

class AnimatedBackground extends StatelessWidget {
  const AnimatedBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Positioned.fill(
      child: CustomAnimationBuilder<double>(
        control: Control.mirror,
        tween: 0.0.tweenTo(1.0),
        duration: 20.seconds,
        builder: (context, value, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: [0, value * 0.3, value * 0.6, 1],
                colors: isDarkMode
                    ? [
                        const Color(0xFF121212),
                        const Color(0xFF1A237E).withOpacity(0.5),
                        const Color(0xFF0D47A1).withOpacity(0.3),
                        const Color(0xFF121212),
                      ]
                    : [
                        const Color(0xFFF8F9FA),
                        const Color(0xFFE3F2FD),
                        const Color(0xFFBBDEFB),
                        const Color(0xFFF8F9FA),
                      ],
              ),
            ),
            child: Stack(
              children: [
                // Animated particles
                Positioned.fill(
                  child: ParticleLayer(
                    particleCount: 15,
                    isDarkMode: isDarkMode,
                  ),
                ),
                
                // Subtle pattern overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.03,
                    child: Image.network(
                      'https://www.transparenttextures.com/patterns/cubes.png',
                      repeat: ImageRepeat.repeat,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ParticleLayer extends StatelessWidget {
  final int particleCount;
  final bool isDarkMode;
  
  const ParticleLayer({
    super.key,
    required this.particleCount,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: List.generate(
            particleCount,
            (index) => Particle(
              index: index,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
    );
  }
}

class Particle extends StatelessWidget {
  final int index;
  final double width;
  final double height;
  final bool isDarkMode;
  
  const Particle({
    super.key,
    required this.index,
    required this.width,
    required this.height,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final random = index * 10.0;
    final size = (random % 20) + 5;
    final speedFactor = ((random % 10) + 5) / 5;
    
    final colors = isDarkMode
        ? [
            Colors.blue.withOpacity(0.1),
            Colors.indigo.withOpacity(0.1),
            Colors.purple.withOpacity(0.1),
          ]
        : [
            Colors.blue.withOpacity(0.1),
            Colors.lightBlue.withOpacity(0.1),
            Colors.cyan.withOpacity(0.1),
          ];
    
    return CustomAnimationBuilder<double>(
      control: Control.loop,
      tween: 0.0.tweenTo(1.0),
      duration: (10 * speedFactor).seconds,
      builder: (context, value, child) {
        final posX = ((random % width) + value * width) % width;
        final posY = ((random % height) + value * height / 2) % height;
        
        return Positioned(
          left: posX,
          top: posY,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: colors[index % colors.length],
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors[index % colors.length],
                  blurRadius: size,
                  spreadRadius: size / 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

