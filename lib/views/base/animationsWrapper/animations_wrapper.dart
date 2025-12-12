import 'package:flutter/material.dart';

enum AnimationDirection { top, bottom, left, right }

class AnimatedWidgetWrapper extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final AnimationDirection direction;

  const AnimatedWidgetWrapper({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.direction = AnimationDirection.top,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration + delay, // include delay in total tween duration
      curve: Curves.easeOut,
      builder: (context, value, _) {
        // Compute actual animation progress after delay
        double progress = ((value * (duration + delay).inMilliseconds) - delay.inMilliseconds) / duration.inMilliseconds;
        final delayedValue = progress.clamp(0.0, 1.0);

        double dx = 0, dy = 0;
        switch (direction) {
          case AnimationDirection.top:
            dy = (1 - delayedValue) * -50;
            break;
          case AnimationDirection.bottom:
            dy = (1 - delayedValue) * 50;
            break;
          case AnimationDirection.left:
            dx = (1 - delayedValue) * -50;
            break;
          case AnimationDirection.right:
            dx = (1 - delayedValue) * 50;
            break;
        }

        return Transform.translate(
          offset: Offset(dx, dy),
          child: Opacity(
            opacity: delayedValue,
            child: child,
          ),
        );
      },
    );
  }
}

