import 'package:flutter/material.dart';
import '../utils/time_utils.dart';
import '../models/models.dart';
import '../pages/trip_details_page.dart';
import 'color_circle.dart';

class ScheduleCard extends StatelessWidget {
  final TrainSchedule schedule;
  final bool isPast;

  const ScheduleCard({
    super.key,
    required this.schedule,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      schedule.routeColor,
      if (schedule.routeSecondaryRouteColor?.isNotEmpty == true)
        schedule.routeSecondaryRouteColor!,
    ];

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TripDetailsPage(tripId: schedule.tripId),
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
                  Text(schedule.tripHeadsign),
                ],
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
                minWidth: 60,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    TimeUtils.formatDate(schedule.departureDate),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: isPast
                              ? Theme.of(context).colorScheme.onError
                              : Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    TimeUtils.formatTime(schedule.departureTime),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: isPast
                              ? Theme.of(context).colorScheme.onError
                              : Theme.of(context).colorScheme.onPrimary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
