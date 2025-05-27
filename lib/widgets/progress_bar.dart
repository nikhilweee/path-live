import 'package:flutter/material.dart';

class ProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;
  final Color backgroundColor;
  final Future<void> Function() onCompleted;

  const ProgressBar({
    super.key,
    required this.duration,
    required this.color,
    required this.backgroundColor,
    required this.onCompleted,
  });

  @override
  State<ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<ProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..addStatusListener(_handleAnimationStatus);

    _animationController.forward();
  }

  void _handleAnimationStatus(AnimationStatus status) async {
    if (status == AnimationStatus.completed && !_isRefreshing) {
      _isRefreshing = true;

      try {
        await widget.onCompleted();
      } catch (e) {
        print('Error in progress bar completion: $e');
      } finally {
        if (mounted) {
          _isRefreshing = false;
          _animationController.forward(from: 0.0);
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) => LinearProgressIndicator(
        value: _animationController.value,
        color: widget.color,
        backgroundColor: widget.backgroundColor,
      ),
    );
  }
}
