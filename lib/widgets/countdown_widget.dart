import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/time_utils.dart';
import 'badge_widget.dart';

class CountdownWidget extends StatefulWidget {
  final String secondsToArrival;
  final String lastUpdated;

  const CountdownWidget({
    super.key,
    required this.secondsToArrival,
    required this.lastUpdated,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _countdownTimer;

  int get _totalSeconds => TimeUtils.remainingSeconds(
        widget.secondsToArrival,
        widget.lastUpdated,
      );

  Color get _backgroundColor {
    final colorScheme = Theme.of(context).colorScheme;
    return _totalSeconds >= 0
        ? colorScheme.error // Red for arriving (positive)
        : colorScheme.secondary; // White for departed (negative)
  }

  Color get _textColor {
    final colorScheme = Theme.of(context).colorScheme;
    return _totalSeconds >= 0
        ? colorScheme.onError // White for arriving (positive)
        : colorScheme.onSecondary; // Red for departed (negative)
  }

  @override
  void initState() {
    super.initState();
    _startCountdownTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BadgeWidget(
      text: TimeUtils.formatTotalSeconds(_totalSeconds),
      backgroundColor: _backgroundColor,
      textColor: _textColor,
    );
  }
}
