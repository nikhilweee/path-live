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
    print("$_showCountdown $seconds");
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
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  TimeUtils.formatSecondsToArrival(
                    widget.secondsToArrival,
                    widget.lastUpdated,
                  ),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.arrivalTimeMessage,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            )
          : Text(
              widget.arrivalTimeMessage,
              style: Theme.of(context).textTheme.labelLarge,
            ),
    );
  }
}
