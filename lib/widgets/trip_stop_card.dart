import 'package:flutter/material.dart';
import '../utils/time_utils.dart';
import '../models/models.dart';
import 'color_circle.dart';

class TripStopCard extends StatelessWidget {
  final TripStop tripStop;
  final bool isPast;

  const TripStopCard({
    super.key,
    required this.tripStop,
    this.isPast = false,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isPast
                        ? Theme.of(context).colorScheme.onSurfaceVariant
                        : Theme.of(context).colorScheme.onSurface,
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isPast
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8.0),
            ),
            constraints: const BoxConstraints(
              minWidth: 40,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              TimeUtils.formatTime(tripStop.departureTime),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isPast
                        ? Theme.of(context).colorScheme.onError
                        : Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
