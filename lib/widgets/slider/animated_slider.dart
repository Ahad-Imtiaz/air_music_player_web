import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: LocalizedWaveSliderDemo()));
}

class LocalizedWaveSliderDemo extends StatefulWidget {
  const LocalizedWaveSliderDemo({super.key});

  @override
  LocalizedWaveSliderDemoState createState() => LocalizedWaveSliderDemoState();
}

class LocalizedWaveSliderDemoState extends State<LocalizedWaveSliderDemo> with TickerProviderStateMixin {
  double _value = 0.5;
  double _velocity = 0.0;
  bool _isAnimating = false;

  final int wavePoints = 150;
  late AnimationController _controller;
  late List<double> yOffsets;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    yOffsets = List.generate(wavePoints, (_) => 0.0);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateWave);
    _controller.repeat();

    _animationController = AnimationController(vsync: this)
      ..addListener(() {
        // drive slider movement every frame
        _velocity = (_animation.value - _value) * MediaQuery.of(context).size.width * 0.65 * 2;
        _value = _animation.value;
        _updateWave();
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {}
      });
  }

  void _updateWave() {
    double damping = 0.9;
    double tension = 0.1;

    // Thumb index on the wave
    int thumbIndex = (_value * (yOffsets.length - 1)).round();
    int effectRange = 4; // how many points around the thumb are affected

    for (int i = 0; i < yOffsets.length; i++) {
      double target = 0;

      // distance from the thumb
      double distance = (i - thumbIndex).abs().toDouble();

      // Only apply wave within the effect range
      if (distance <= effectRange) {
        // smooth falloff, single bulge
        double falloff = cos((distance / effectRange) * (pi / 2));
        double baseBulge = 30 * falloff;
        double velocityOffset = _velocity.abs() * 1.5 * falloff;
        target = baseBulge + velocityOffset;
      }

      // spring towards target
      double force = (target - yOffsets[i]) * tension;
      yOffsets[i] += force;
      yOffsets[i] *= damping;

      // keep wave only upward
      yOffsets[i] = max(0, yOffsets[i]);
    }

    _velocity *= 0.85;
    setState(() {});
  }

  void _applyDragForce(DragUpdateDetails details, double width) {
    if (_isAnimating) return;

    double localDx = details.localPosition.dx.clamp(0, width);
    double newValue = localDx / width;

    _velocity = (newValue - _value) * width;
    _value = newValue;
    _updateWave();
  }

  void _animateToValue(double targetValue, double width) {
    for (int i = 0; i < yOffsets.length; i++) {
      yOffsets[i] = 0;
    }

    final startValue = _value;
    _isAnimating = true;

    _animation = Tween<double>(begin: startValue, end: targetValue).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.duration = const Duration(milliseconds: 500);

    _animationController.forward(from: 0).whenComplete(() {
      _isAnimating = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double lineWidth = MediaQuery.of(context).size.width * 0.65;

    return Scaffold(
      body: Center(
        child: GestureDetector(
          onHorizontalDragUpdate: (details) => _applyDragForce(details, lineWidth),
          onTapDown: (details) {
            double localDx = details.localPosition.dx.clamp(0, lineWidth);
            double targetValue = localDx / lineWidth;
            _animateToValue(targetValue, lineWidth);
          },
          child: SizedBox(
            width: lineWidth,
            height: 100,
            child: CustomPaint(
              painter: WaveSeekerPainter(yOffsets: yOffsets, value: _value),
            ),
          ),
        ),
      ),
    );
  }
}

class WaveSeekerPainter extends CustomPainter {
  final List<double> yOffsets;
  final double value;

  WaveSeekerPainter({required this.yOffsets, required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    double centerY = size.height / 2;
    double dx = size.width / (yOffsets.length - 1);

    Paint wavePaint = Paint()
      ..color = Colors.blue
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

    Paint thumbPaint = Paint()..color = Colors.blueAccent;
    canvas.drawCircle(
      Offset(value * size.width, centerY - yOffsets[(value * (yOffsets.length - 1)).round()]),
      12,
      thumbPaint,
    );
  }

  @override
  bool shouldRepaint(covariant WaveSeekerPainter oldDelegate) => true;
}
