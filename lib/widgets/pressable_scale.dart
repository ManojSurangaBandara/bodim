import 'package:flutter/material.dart';

/// Small helper that scales its child slightly while the pointer is down.
///
/// Use it to add a subtle press animation without changing button behavior.
class PressableScale extends StatefulWidget {
  final Widget child;
  final double pressedScale;
  final Duration duration;

  const PressableScale({
    Key? key,
    required this.child,
    this.pressedScale = 0.97,
    this.duration = const Duration(milliseconds: 110),
  }) : super(key: key);

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  double _scale = 1.0;

  void _setScale(double s) {
    if (!mounted) return;
    setState(() => _scale = s);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setScale(widget.pressedScale),
      onPointerUp: (_) => _setScale(1.0),
      onPointerCancel: (_) => _setScale(1.0),
      behavior: HitTestBehavior.translucent,
      child: AnimatedScale(
        scale: _scale,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
