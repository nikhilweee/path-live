import 'package:flutter/material.dart';
import '../utils/time_utils.dart';

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

  @override
  void initState() {
    super.initState();
    // Show countdown only when time left is less than 10 mins.
    int seconds = TimeUtils.remainingSeconds(
      widget.secondsToArrival,
      widget.lastUpdated,
    );
    _showCountdown = seconds < 600;
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 4.0),
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
