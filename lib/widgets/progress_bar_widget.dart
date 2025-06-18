import 'package:flutter/material.dart';

class ProgressBarWidget extends StatefulWidget {
  final Duration duration;
  final Color color;
  final Color backgroundColor;
  final Future<void> Function() onCompleted;

  const ProgressBarWidget({
    super.key,
    required this.duration,
    required this.color,
    required this.backgroundColor,
    required this.onCompleted,
  });

  @override
  State<ProgressBarWidget> createState() => _ProgressBarWidgetState();
}

class _ProgressBarWidgetState extends State<ProgressBarWidget>
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

  @override
  void didUpdateWidget(ProgressBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _animationController.duration = widget.duration;
      if (!_isRefreshing) {
        _animationController.forward(from: 0.0);
      }
    }
  }

  void _handleAnimationStatus(AnimationStatus status) async {
    if (status == AnimationStatus.completed && !_isRefreshing) {
      _isRefreshing = true;

      try {
        await widget.onCompleted();
      } catch (e) {
        debugPrint('Error in progress bar completion: $e');
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
