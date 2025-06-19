import 'package:flutter/material.dart';
import '../utils/time_utils.dart';
import '../models/models.dart';
import 'color_circle_widget.dart';
import 'badge_widget.dart';

class StopCard extends StatefulWidget {
  final Stop tripStop;

  const StopCard({
    super.key,
    required this.tripStop,
  });

  @override
  State<StopCard> createState() => _StopCardState();
}

class _StopCardState extends State<StopCard> {
  bool _isHighlighted = false;

  void _toggleHighlight() => setState(() => _isHighlighted = !_isHighlighted);

  @override
  Widget build(BuildContext context) {
    final colors = [
      widget.tripStop.routeColor,
      if (widget.tripStop.routeSecondaryRouteColor?.isNotEmpty == true)
        widget.tripStop.routeSecondaryRouteColor!,
    ];

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
              child: ColorCircleWidget(colors: colors),
            ),
            Expanded(
              child: Text(
                widget.tripStop.stopName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            BadgeWidget(
              text: TimeUtils.formatTime(widget.tripStop.departureTime),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              textColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
