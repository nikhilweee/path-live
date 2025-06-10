import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/time_utils.dart';
import '../services/storage_service.dart';

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
  late bool _showCountdown;
  Timer? _timer;
  int _countdownThreshold = 600; // Default value, will be updated from settings

  @override
  void initState() {
    super.initState();
    _loadCountdownThreshold();
    _updateCountdownVisibility();
    _startTimer();
  }

  @override
  void didUpdateWidget(RealTimeDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.secondsToArrival != widget.secondsToArrival ||
        oldWidget.lastUpdated != widget.lastUpdated) {
      _updateCountdownVisibility();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdownVisibility() {
    final seconds = TimeUtils.remainingSeconds(
      widget.secondsToArrival,
      widget.lastUpdated,
    );
    _showCountdown = _countdownThreshold == 0 ? false : seconds < _countdownThreshold;
  }

  Future<void> _loadCountdownThreshold() async {
    final threshold = await StorageService.getCountdownThreshold();
    if (mounted) {
      setState(() {
        _countdownThreshold = threshold;
        _updateCountdownVisibility();
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateCountdownVisibility();
        });
      }
    });
  }

  void _toggleDisplay() {
    setState(() {
      _showCountdown = !_showCountdown;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleDisplay,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_showCountdown)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                borderRadius: BorderRadius.circular(8.0),
              ),
              constraints: BoxConstraints(
                minWidth: 40,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              margin: const EdgeInsets.symmetric(horizontal: 0.0),
              child: Text(
                TimeUtils.formatSecondsToArrival(
                  widget.secondsToArrival,
                  widget.lastUpdated,
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onError,
                    ),
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8.0),
            ),
            constraints: BoxConstraints(
              minWidth: 40,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              widget.arrivalTimeMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
