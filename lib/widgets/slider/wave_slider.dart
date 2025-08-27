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
  final Duration animateDuration;

  const WaveSlider({
    super.key,
    required this.value,
    this.enabled = true,
    this.onChanged,
    this.onChangeEnd,
    this.width = 250,
    this.height = 100,
    this.color = Colors.blue,
    this.animateDuration = const Duration(milliseconds: 500),
  });

  @override
  State<WaveSlider> createState() => _WaveSliderState();
}

class _WaveSliderState extends State<WaveSlider> with TickerProviderStateMixin {
  final int wavePoints = 150;
  late List<double> yOffsets;
  double _velocity = 0.0;
  bool _isInteracting = false;
  bool _isAnimating = false;
  late double _internalValue;

  late AnimationController _waveController;
  AnimationController? _slideController;
  Animation<double>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    yOffsets = List.generate(wavePoints, (_) => 0.0);
    _internalValue = widget.value.clamp(0.0, 1.0);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateWave);
    _waveController.repeat();
  }

  @override
  void didUpdateWidget(covariant WaveSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Fix: Never update _internalValue from widget.value while animating
    if (!_isAnimating && (widget.value != _internalValue)) {
      _internalValue = widget.value.clamp(0.0, 1.0);
    }
  }

  void _updateWave() {
    double damping = 0.9;
    double tension = 0.1;

    int thumbIndex = (_internalValue * (yOffsets.length - 1)).round();
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
    if (!widget.enabled || _isAnimating) return;
    setState(() => _isInteracting = true);
    double localDx = details.localPosition.dx.clamp(0, widget.width);
    double newValue = localDx / widget.width;
    _velocity = (newValue - _internalValue) * widget.width;
    _internalValue = newValue;
    widget.onChanged?.call(_internalValue);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enabled) return;
    setState(() => _isInteracting = false);
    widget.onChangeEnd?.call(_internalValue);
  }

  void _handleTap(TapDownDetails details) {
    if (!widget.enabled) return;
    setState(() => _isInteracting = true);
    double localDx = details.localPosition.dx.clamp(0, widget.width);
    double targetValue = localDx / widget.width;
    _animateToValue(targetValue);
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isInteracting = false);
    widget.onChangeEnd?.call(_internalValue);
  }

  void _animateToValue(double targetValue) {
    _slideController?.dispose();
    _isAnimating = true;
    final animationStartValue = _internalValue;
    _slideController = AnimationController(
      vsync: this,
      duration: widget.animateDuration,
    );
    _slideAnimation = Tween<double>(
      begin: animationStartValue,
      end: targetValue,
    ).animate(CurvedAnimation(parent: _slideController!, curve: Curves.easeOut))
      ..addListener(() {
        _velocity = (_slideAnimation!.value - _internalValue) * widget.width * 2;
        _internalValue = _slideAnimation!.value;
        setState(() {}); // Only update local UI
        _updateWave();
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
          _isAnimating = false;

          setState(() => _isInteracting = false);

          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onChanged?.call(_internalValue);
            widget.onChangeEnd?.call(_internalValue);
          });
        }
      });
    _slideController!.forward(from: 0);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _handleDrag,
      onHorizontalDragEnd: _handleDragEnd,
      onTapDown: _handleTap,
      onTapUp: _handleTapUp,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: CustomPaint(
          painter: _WaveSliderPainter(
            yOffsets: yOffsets,
            value: _internalValue,
            color: widget.enabled ? widget.color : Colors.grey.shade700,
            glow: _isInteracting ? 24 : 10,
            glowOpacity: _isInteracting ? 0.55 : 0.25,
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
  final double glow;
  final double glowOpacity;

  _WaveSliderPainter({
    required this.yOffsets,
    required this.value,
    required this.color,
    this.glow = 10,
    this.glowOpacity = 0.25,
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

    final thumbX = value * size.width;
    final thumbY = centerY - yOffsets[(value * (yOffsets.length - 1)).round()];

    // Draw glow
    final glowPaint = Paint()
      ..color = color.withOpacity(glowOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, glow);
    canvas.drawCircle(Offset(thumbX, thumbY), 18, glowPaint);

    // Draw thumb
    Paint thumbPaint = Paint()..color = color.withOpacity(0.9);
    canvas.drawCircle(
      Offset(thumbX, thumbY),
      12,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _WaveSliderPainter oldDelegate) => true;
}
