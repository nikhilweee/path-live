import 'package:flutter/material.dart';
import '../models/models.dart';
import '../utils/time_utils.dart';
import '../services/storage_service.dart';
import 'color_circle_widget.dart';
import 'countdown_widget.dart';
import 'badge_widget.dart';

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
  int _countdownThreshold = 600;

  bool get _shouldShowCountdown {
    if (_countdownThreshold == 0) return false;
    final remainingSeconds = TimeUtils.remainingSeconds(
      widget.train.secondsToArrival,
      widget.train.lastUpdated,
    );
    return remainingSeconds < _countdownThreshold;
  }

  @override
  void initState() {
    super.initState();
    _updateCountdownThreshold();
  }

  @override
  void didUpdateWidget(TrainCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.train.lastUpdated != widget.train.lastUpdated) {
      int oldSeconds = int.parse(oldWidget.train.secondsToArrival);
      int newSeconds = int.parse(widget.train.secondsToArrival);
      if (oldWidget.train.target != widget.train.target ||
          // Reset highlight if this is likely a new train
          (newSeconds - oldSeconds).abs() > 300) {
        setState(() => _isHighlighted = false);
      }
    }

    // Check if we need to refresh settings
    _updateCountdownThreshold();
  }

  void _toggleHighlight() => setState(() => _isHighlighted = !_isHighlighted);

  Future<void> _updateCountdownThreshold() async {
    final newThreshold = await getSetting(Setting.countdownThreshold);
    if (newThreshold != _countdownThreshold && mounted) {
      setState(() {
        _countdownThreshold = newThreshold;
      });
    }
  }

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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _shouldShowCountdown
                    ? RepaintBoundary(
                        child: CountdownWidget(
                          secondsToArrival: widget.train.secondsToArrival,
                          lastUpdated: widget.train.lastUpdated,
                        ),
                      )
                    : BadgeWidget(
                        text: widget.train.arrivalTimeMessage,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
