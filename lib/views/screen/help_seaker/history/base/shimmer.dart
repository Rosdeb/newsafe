import 'package:flutter/material.dart';

class HistoryItemPlaceholder extends StatefulWidget {
  const HistoryItemPlaceholder({super.key});

  @override
  State<HistoryItemPlaceholder> createState() => _HistoryItemPlaceholderState();
}

class _HistoryItemPlaceholderState extends State<HistoryItemPlaceholder> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient:const LinearGradient(colors: [
              Color(0xFFFFF1A9),
              Color(0xFFF6F5F5),
              Color(0xFFFDEEB0),
            ])
          ),
          child: Row(
            children: [
              // Circle shimmer
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: LinearGradient(
                    colors:const [ Color(0xFFE7CC86), Color(0xFFE3E15A), Color(0xFFE1D768)],
                    stops: [
                      (_controller.value - 0.3).clamp(0.0, 1.0),
                      _controller.value.clamp(0.0, 1.0),
                      (_controller.value + 0.3).clamp(0.0, 1.0)
                    ],
                    begin:const Alignment(-1.0, -0.3),
                    end:const Alignment(1.0, 0.3),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color:const Color(0xFFD9CF9D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.6,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color:const Color(0xFFD9CF9D),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),

                    Container(
                      height: 14,
                      width: MediaQuery.of(context).size.width * 0.4,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color:const Color(0xFFD9CF9D),
                        borderRadius: BorderRadius.circular(4),
                      ),
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