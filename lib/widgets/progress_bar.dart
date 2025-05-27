import 'package:flutter/material.dart';
import 'dart:async';

class ProgressBar extends StatefulWidget {
  final Duration duration;
  final Color color;
  final Color backgroundColor;
  final VoidCallback onCompleted;

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

class _ProgressBarState extends State<ProgressBar> {
  Timer? _timer;
  double _progress = 0.0;
  static const updateInterval = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _progress = 0.0;
    });

    final progressIncrement =
        updateInterval.inMilliseconds / widget.duration.inMilliseconds;

    _timer = Timer.periodic(updateInterval, (timer) {
      setState(() {
        _progress += progressIncrement;

        if (_progress >= 1.0) {
          _progress = 0.0;
          widget.onCompleted();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: _progress,
      color: widget.color,
      backgroundColor: widget.backgroundColor,
    );
  }
}
