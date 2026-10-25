import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A once-per-launch cover; the WebView loads underneath it.
class LaunchIntro extends StatefulWidget {
  const LaunchIntro({super.key, required this.ready, required this.onComplete});

  final bool ready;
  final VoidCallback onComplete;

  @override
  State<LaunchIntro> createState() => _LaunchIntroState();
}

class _LaunchIntroState extends State<LaunchIntro>
    with TickerProviderStateMixin {
  late final AnimationController _cut = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..addStatusListener((_) => _revealWhenReady());
  late final AnimationController _reveal =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) widget.onComplete();
          });
        }
      });
  ui.Image? _logo;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _loadLogo();
  }

  Future<void> _loadLogo() async {
    try {
      final bytes = await rootBundle.load('assets/brand/logo.png');
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      if (!mounted) {
        frame.image.dispose();
        return;
      }
      setState(() => _logo = frame.image);
    } catch (_) {
      // The wordmark fallback still lets the site open if asset decoding fails.
      if (!mounted) return;
    }
    _cut.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion) {
      _cut.duration = Duration.zero;
      _reveal.duration = Duration.zero;
    }
  }

  @override
  void didUpdateWidget(LaunchIntro oldWidget) {
    super.didUpdateWidget(oldWidget);
    _revealWhenReady();
  }

  void _revealWhenReady() {
    if (widget.ready &&
        _cut.isCompleted &&
        !_reveal.isAnimating &&
        _reveal.value == 0) {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _cut.dispose();
    _reveal.dispose();
    _logo?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading elTahi',
    container: true,
    child: AnimatedBuilder(
      animation: Listenable.merge([_cut, _reveal]),
      builder: (context, _) => Opacity(
        opacity: 1 - Curves.easeInCubic.transform(_reveal.value),
        child: ColoredBox(
          color: Colors.white,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: AspectRatio(
                      aspectRatio: 400 / 200,
                      child: CustomPaint(
                        key: const ValueKey('launch-artwork'),
                        painter: LaunchArtwork(
                          logo: _logo,
                          progress: _reduceMotion ? 0 : _cut.value,
                          reveal: _reduceMotion ? 0 : _reveal.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_cut.isCompleted && !widget.ready)
                Center(
                  child: Transform.translate(
                    offset: const Offset(0, 110),
                    child: const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFB8D057),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

class LaunchArtwork extends CustomPainter {
  const LaunchArtwork({
    required this.logo,
    required this.progress,
    required this.reveal,
  });

  final ui.Image? logo;
  final double progress;
  final double reveal;

  double _phase(double start, double end) =>
      ((progress - start) / (end - start)).clamp(0.0, 1.0);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 400);
    const word = Rect.fromLTWH(132, 57, 244, 87);
    final sweep = Curves.easeInOutCubic.transform(_phase(.22, .75));
    final split = Curves.easeOutCubic.transform(_phase(.76, 1));
    final opening = Curves.easeInCubic.transform(reveal);
    final separation = split * 14 + opening * 90;

    if (separation == 0) {
      _paintWord(canvas, word);
    } else {
      for (final upper in [true, false]) {
        canvas.save();
        canvas.translate(
          -split * 54 + (upper ? -split * 5 : split * 5),
          (upper ? -1 : 1) * separation,
        );
        canvas.clipRect(
          Rect.fromLTRB(
            word.left - 1,
            upper ? word.top - 1 : word.center.dy,
            word.right + 1,
            upper ? word.center.dy : word.bottom + 1,
          ),
        );
        _paintWord(canvas, word);
        canvas.restore();
      }
    }

    // The blade crosses the word's midline before its two halves separate.
    if (sweep < 1) {
      final x = 14 + sweep * 400;
      canvas.save();
      canvas.translate(x, word.center.dy - 12);
      canvas.rotate(-.12 * (1 - sweep));
      canvas.scale(.16);
      canvas.translate(-218, -432);
      final knife = Path()
        ..moveTo(230, 465)
        ..quadraticBezierTo(218, 465, 218, 480)
        ..lineTo(218, 532)
        ..quadraticBezierTo(218, 547, 234, 547)
        ..lineTo(407, 547)
        ..quadraticBezierTo(423, 547, 423, 531)
        ..lineTo(423, 480)
        ..quadraticBezierTo(423, 465, 407, 465)
        ..close()
        ..moveTo(440, 432)
        ..lineTo(810, 432)
        ..cubicTo(772, 499, 712, 552, 615, 570)
        ..cubicTo(560, 580, 497, 581, 440, 574)
        ..close();
      canvas.drawPath(knife, Paint()..color = const Color(0xFFB8D057));
      canvas.restore();
    }
    canvas.restore();
  }

  void _paintWord(Canvas canvas, Rect destination) {
    if (logo == null) {
      final text = TextPainter(
        text: const TextSpan(
          text: 'elTahi',
          style: TextStyle(fontSize: 72, color: Color(0xFF58595B)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, destination.topLeft);
      text.dispose();
      return;
    }
    // Display the original lettering without its above-word blade; no new font.
    const source = Rect.fromLTRB(35, 80, 610, 285);
    final scale = destination.width / source.width;
    final bladeArea = Rect.fromLTWH(
      destination.left + (350 - source.left) * scale,
      destination.top,
      destination.width,
      35 * scale,
    );
    canvas.save();
    canvas.clipPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(destination),
        Path()..addRect(bladeArea),
      ),
    );
    canvas.drawImageRect(
      logo!,
      source,
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(LaunchArtwork oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.reveal != reveal ||
      oldDelegate.logo != logo;
}
