import 'dart:math';
import 'package:flutter/material.dart';

class WaveSlider extends StatefulWidget {
  final double value; // normalized 0.0–1.0, driven by parent
  final bool enabled; // disable gestures if no audio
  final ValueChanged<double>? onChanged; // while dragging
  final ValueChanged<double>? onChangeEnd; // when drag/tap ends
  final double width;
  final double height;
  final Color color;

  const WaveSlider({
    super.key,
    required this.value,
    this.enabled = true,
    this.onChanged,
    this.onChangeEnd,
    this.width = 250,
    this.height = 100,
    this.color = Colors.blue,
  });

  @override
  State<WaveSlider> createState() => _WaveSliderState();
}

class _WaveSliderState extends State<WaveSlider> with TickerProviderStateMixin {
  final int wavePoints = 150;
  late List<double> yOffsets;
  double _velocity = 0.0;

  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    yOffsets = List.generate(wavePoints, (_) => 0.0);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateWave);
    _waveController.repeat();
  }

  void _updateWave() {
    double damping = 0.9;
    double tension = 0.1;

    int thumbIndex = (widget.value * (yOffsets.length - 1)).round();
    int effectRange = 4;

    for (int i = 0; i < yOffsets.length; i++) {
      double target = 0;
      double distance = (i - thumbIndex).abs().toDouble();

      if (distance <= effectRange) {
        double falloff = cos((distance / effectRange) * (pi / 2));
        double baseBulge = 25 * falloff;
        double velocityOffset = _velocity.abs() * 1.5 * falloff;
        target = baseBulge + velocityOffset;
      }

      double force = (target - yOffsets[i]) * tension;
      yOffsets[i] += force;
      yOffsets[i] *= damping;
      yOffsets[i] = max(0, yOffsets[i]);
    }

    _velocity *= 0.85;
    setState(() {});
  }

  void _handleDrag(DragUpdateDetails details) {
    if (!widget.enabled) return;
    double localDx = details.localPosition.dx.clamp(0, widget.width);
    double newValue = localDx / widget.width;
    _velocity = (newValue - widget.value) * widget.width;
    widget.onChanged?.call(newValue);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    widget.onChangeEnd?.call(widget.value);
  }

  void _handleTap(TapDownDetails details) {
    if (!widget.enabled) return;
    double localDx = details.localPosition.dx.clamp(0, widget.width);
    double targetValue = localDx / widget.width;
    widget.onChanged?.call(targetValue);
    widget.onChangeEnd?.call(targetValue);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDrag,
      onHorizontalDragEnd: _handleDragEnd,
      onTapDown: _handleTap,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: CustomPaint(
          painter: _WaveSliderPainter(
            yOffsets: yOffsets,
            value: widget.value,
            color: widget.enabled ? widget.color : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _WaveSliderPainter extends CustomPainter {
  final List<double> yOffsets;
  final double value;
  final Color color;

  _WaveSliderPainter({
    required this.yOffsets,
    required this.value,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double centerY = size.height / 2;
    double dx = size.width / (yOffsets.length - 1);

    Paint wavePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    Path path = Path();
    path.moveTo(0, centerY);
    for (int i = 1; i < yOffsets.length; i++) {
      double x = i * dx;
      double y = centerY - yOffsets[i];
      double prevX = (i - 1) * dx;
      double prevY = centerY - yOffsets[i - 1];
      double mx = (prevX + x) / 2;
      double my = (prevY + y) / 2;
      path.quadraticBezierTo(prevX, prevY, mx, my);
    }
    canvas.drawPath(path, wavePaint);

    Paint thumbPaint = Paint()..color = color.withOpacity(0.9);
    canvas.drawCircle(
      Offset(value * size.width, centerY - yOffsets[(value * (yOffsets.length - 1)).round()]),
      12,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveSliderPainter oldDelegate) => true;
}
