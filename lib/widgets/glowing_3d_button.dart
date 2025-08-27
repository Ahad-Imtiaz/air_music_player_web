import 'package:flutter/material.dart';

class Glowing3DButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  const Glowing3DButton({super.key, required this.onPressed, required this.text});

  @override
  State<Glowing3DButton> createState() => _Glowing3DButtonState();
}

class _Glowing3DButtonState extends State<Glowing3DButton> {
  bool _hovering = false;
  Offset? _pointerOffset; // null = neutral position

  @override
  Widget build(BuildContext context) {
    const buttonColor = Color(0xFF8E2DE2);

    // Compute rotation only if pointer is over button
    double rotationX = 0;
    double rotationY = 0;

    if (_pointerOffset != null) {
      final relativeX = (_pointerOffset!.dx - 0.5) * 2; // -1 left, 1 right
      final relativeY = (_pointerOffset!.dy - 0.5) * 2; // -1 top, 1 bottom
      const maxTilt = 0.25; // radians
      rotationX = -relativeY * maxTilt; // negative for natural tilt
      rotationY = relativeX * maxTilt;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) {
        setState(() {
          _hovering = false;
          _pointerOffset = null; // reset to neutral
        });
      },
      onHover: (event) {
        final box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(event.position);
        setState(() {
          _pointerOffset = Offset(
            (local.dx / box.size.width).clamp(0, 1),
            (local.dy / box.size.height).clamp(0, 1),
          );
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          final box = context.findRenderObject() as RenderBox;
          final local = box.globalToLocal(details.globalPosition);
          setState(() {
            _pointerOffset = Offset(
              (local.dx / box.size.width).clamp(0, 1),
              (local.dy / box.size.height).clamp(0, 1),
            );
          });
        },
        onTapUp: (_) => setState(() => _pointerOffset = null),
        onTapCancel: () => setState(() => _pointerOffset = null),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001) // perspective
            ..translate(0.0, _hovering ? -6.0 : 0.0)
            ..rotateX(rotationX)
            ..rotateY(rotationY),
          transformAlignment: Alignment.center, // <-- center the rotation
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: buttonColor.withOpacity(_hovering ? 0.8 : 0.5),
                blurRadius: _hovering ? 24 : 12,
                spreadRadius: _hovering ? 4 : 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          alignment: Alignment.center,
          child: Text(
            widget.text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
