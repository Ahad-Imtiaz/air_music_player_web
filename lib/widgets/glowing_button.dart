import 'package:flutter/material.dart';

class GlowingWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed; // optional for non-clickable widgets
  final double borderRadius; // for rectangular buttons
  final Color glowColor;

  const GlowingWidget({
    super.key,
    required this.child,
    this.onPressed,
    this.borderRadius = 12,
    this.glowColor = const Color(0xFF8E2DE2),
  });

  @override
  State<GlowingWidget> createState() => _GlowingWidgetState();
}

class _GlowingWidgetState extends State<GlowingWidget> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        boxShadow: [
          BoxShadow(
            color: widget.glowColor.withOpacity(_hovering ? 0.8 : 0.4),
            blurRadius: _hovering ? 24 : 12,
            spreadRadius: _hovering ? 4 : 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: widget.child,
    );

    if (widget.onPressed != null) {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onPressed,
          child: content,
        ),
      );
    } else {
      return MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: content,
      );
    }
  }
}
