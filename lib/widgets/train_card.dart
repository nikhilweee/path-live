import 'package:flutter/material.dart';
import '../models/models.dart';
import 'color_circle.dart';
import 'real_time_display.dart';

class TrainCard extends StatefulWidget {
  final Train train;

  const TrainCard({
    super.key,
    required this.train,
  });

  @override
  State<TrainCard> createState() => _TrainCardState();
}

class _TrainCardState extends State<TrainCard> {
  bool _isHighlighted = false;

  @override
  void didUpdateWidget(TrainCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.train.lastUpdated != widget.train.lastUpdated) {
      // Reset highlight if this is likely a new train
      int oldSeconds = int.parse(oldWidget.train.secondsToArrival);
      int newSeconds = int.parse(widget.train.secondsToArrival);
      if (oldWidget.train.target != widget.train.target ||
          (newSeconds - oldSeconds).abs() > 300) {
        setState(() => _isHighlighted = false);
      }
    }
  }

  void _toggleHighlight() => setState(() => _isHighlighted = !_isHighlighted);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleHighlight,
      child: Card(
        color: _isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ColorCircleWidget(colors: widget.train.lineColor),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(widget.train.headSign),
                ],
              ),
            ),
            RealTimeDisplay(
              secondsToArrival: widget.train.secondsToArrival,
              lastUpdated: widget.train.lastUpdated,
              arrivalTimeMessage: widget.train.arrivalTimeMessage,
            ),
          ],
        ),
      ),
    );
  }
}
