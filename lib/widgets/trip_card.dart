import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/time_utils.dart';
import '../models/models.dart';
import '../pages/stops_page.dart';
import 'color_circle_widget.dart';
import 'badge_widget.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  final bool isPast;

  const TripCard({
    super.key,
    required this.trip,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      trip.routeColor,
      if (trip.routeSecondaryRouteColor?.isNotEmpty == true)
        trip.routeSecondaryRouteColor!,
    ];

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StopsPage(
                tripId: trip.tripId,
                tripHeadsign: trip.tripHeadsign,
              ),
            ),
          );
        },
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ColorCircleWidget(colors: colors),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(trip.tripHeadsign),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgeWidget(
                  text: DateFormat('M/d').format(trip.departureDate),
                  backgroundColor: isPast
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  textColor: isPast
                      ? Theme.of(context).colorScheme.onError
                      : Theme.of(context).colorScheme.onPrimary,
                ),
                BadgeWidget(
                  text: TimeUtils.formatTime(trip.departureTime),
                  backgroundColor: isPast
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  textColor: isPast
                      ? Theme.of(context).colorScheme.onError
                      : Theme.of(context).colorScheme.onPrimary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
