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
    // Show countdown only when seconds are between 0 and 600
    int seconds = TimeUtils.remainingSeconds(
      widget.secondsToArrival,
      widget.lastUpdated,
    );
    _showCountdown = seconds > 0 && seconds < 600;
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
      child: _showCountdown
          ? Text(
              TimeUtils.formatSecondsToArrival(
                widget.secondsToArrival,
                widget.lastUpdated,
              ),
              style: Theme.of(context).textTheme.labelLarge,
            )
          : Text(
              TimeUtils.formatMinutesToArrival(
                widget.secondsToArrival,
                widget.lastUpdated,
              ),
              style: Theme.of(context).textTheme.labelLarge,
            ),
    );
  }
}
