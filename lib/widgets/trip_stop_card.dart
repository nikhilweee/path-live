import 'package:flutter/material.dart';
import '../utils/time_utils.dart';
import '../models/models.dart';
import 'color_circle.dart';
import 'badge_widget.dart';

class TripStopCard extends StatelessWidget {
  final TripStop tripStop;

  const TripStopCard({
    super.key,
    required this.tripStop,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      tripStop.routeColor,
      if (tripStop.routeSecondaryRouteColor?.isNotEmpty == true)
        tripStop.routeSecondaryRouteColor!,
    ];

    return Card(
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ColorCircleWidget(colors: colors),
          ),
          Expanded(
            child: Text(
              tripStop.stopName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          BadgeWidget(
            text: TimeUtils.formatTime(tripStop.departureTime),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            textColor: Theme.of(context).colorScheme.onSecondary,
          ),
        ],
      ),
    );
  }
}
