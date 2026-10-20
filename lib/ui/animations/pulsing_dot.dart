import 'package:flutter/material.dart';

/// A small dot that pulses its opacity between [minOpacity] and 1.0.
///
/// Used by the SYNCED indicator, live alert dots and stock alerts.
class PulsingDot extends StatefulWidget {
  const PulsingDot({
    super.key,
    this.size = 8,
    required this.color,
    this.duration = const Duration(seconds: 2),
    this.minOpacity = 0.35,
    this.glow = false,
  });

  final double size;
  final Color color;
  final Duration duration;
  final double minOpacity;
  final bool glow;

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);
    _opacity = Tween<double>(begin: widget.minOpacity, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
          boxShadow: widget.glow
              ? [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.45),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}
