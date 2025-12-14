import 'package:flutter/material.dart';
import 'package:saferader/utils/app_color.dart';

class GiverNotificationItemShimmer extends StatefulWidget {
  const GiverNotificationItemShimmer({super.key});

  @override
  State<GiverNotificationItemShimmer> createState() =>
      _GiverNotificationItemShimmerState();
}

class _GiverNotificationItemShimmerState
    extends State<GiverNotificationItemShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  LinearGradient _shimmerGradient() {
    return LinearGradient(
      colors: const [
        Color(0xFFE7CC86),
        Color(0xFFE3E15A),
        Color(0xFFE1D768),
      ],
      stops: [
        (_controller.value - 0.3).clamp(0.0, 1.0),
        _controller.value.clamp(0.0, 1.0),
        (_controller.value + 0.3).clamp(0.0, 1.0),
      ],
      begin: const Alignment(-1.0, -0.3),
      end: const Alignment(1.0, 0.3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              /// Avatar shimmer
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _shimmerGradient(),
                ),
              ),

              const SizedBox(width: 12),

              /// Text shimmer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name / title
                    Container(
                      height: 16,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9CF9D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    const SizedBox(height: 6),

                    Row(
                      children: [
                        // Distance shimmer
                        Container(
                          height: 14,
                          width: MediaQuery.of(context).size.width * 0.25,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9CF9D),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Time shimmer
                        Container(
                          height: 14,
                          width: MediaQuery.of(context).size.width * 0.2,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9CF9D),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
