import 'package:flutter/material.dart';
import '../utils/time_utils.dart';
import '../models/models.dart';
import 'color_circle_widget.dart';
import 'badge_widget.dart';

class StopCard extends StatefulWidget {
  final Stop stop;

  const StopCard({
    super.key,
    required this.stop,
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
      widget.stop.routeColor,
      if (widget.stop.routeSecondaryRouteColor?.isNotEmpty == true)
        widget.stop.routeSecondaryRouteColor!,
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
                widget.stop.stopName,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            BadgeWidget(
              text: TimeUtils.formatTime(widget.stop.departureTime),
              backgroundColor: Theme.of(context).colorScheme.secondary,
              textColor: Theme.of(context).colorScheme.onSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
