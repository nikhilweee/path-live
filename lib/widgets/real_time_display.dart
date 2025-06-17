import 'dart:async';
import 'package:flutter/material.dart';
import '../utils/time_utils.dart';
import '../services/storage_service.dart';
import 'badge_widget.dart';

class RealTimeDisplay extends StatefulWidget {
  final String secondsToArrival;
  final String lastUpdated;
  final String arrivalTimeMessage;

  const RealTimeDisplay({
    super.key,
    required this.secondsToArrival,
    required this.lastUpdated,
    required this.arrivalTimeMessage,
  });

  @override
  State<RealTimeDisplay> createState() => _RealTimeDisplayState();
}

class _RealTimeDisplayState extends State<RealTimeDisplay> {
  bool _showCountdown = false;
  int _countdownThreshold = 600;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  @override
  void didUpdateWidget(RealTimeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_hasDataChanged(oldWidget)) {
      _updateCountdownVisibility();
    }
    // Check if we need to refresh settings (this covers setting changes)
    _checkSettingsUpdate();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool _hasDataChanged(RealTimeDisplay oldWidget) {
    return oldWidget.secondsToArrival != widget.secondsToArrival ||
        oldWidget.lastUpdated != widget.lastUpdated;
  }

  Future<void> _initializeSettings() async {
    _countdownThreshold = await getSetting(Setting.countdownThreshold);
    if (mounted) {
      setState(() {
        _updateCountdownVisibility();
      });
    }
  }

  Future<void> _checkSettingsUpdate() async {
    final newThreshold = await getSetting(Setting.countdownThreshold);
    if (newThreshold != _countdownThreshold) {
      _countdownThreshold = newThreshold;
      if (mounted) {
        setState(() {
          _updateCountdownVisibility();
        });
      }
    }
  }

  void _updateCountdownVisibility() {
    if (_countdownThreshold == 0) {
      _showCountdown = false;
      _stopCountdownTimer();
      return;
    }

    final remainingSeconds = TimeUtils.remainingSeconds(
      widget.secondsToArrival,
      widget.lastUpdated,
    );
    final shouldShow = remainingSeconds < _countdownThreshold;

    if (shouldShow != _showCountdown) {
      _showCountdown = shouldShow;
      if (_showCountdown) {
        _startCountdownTimer();
      } else {
        _stopCountdownTimer();
      }
    }
  }

  void _startCountdownTimer() {
    _stopCountdownTimer();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _stopCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_showCountdown)
          BadgeWidget(
            text: TimeUtils.formatSecondsToArrival(
              widget.secondsToArrival,
              widget.lastUpdated,
            ),
            backgroundColor: colorScheme.error,
            textColor: colorScheme.onError,
          ),
        BadgeWidget(
          text: widget.arrivalTimeMessage,
          backgroundColor: colorScheme.primary,
          textColor: colorScheme.onPrimary,
        ),
      ],
    );
  }
}
