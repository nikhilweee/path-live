import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/time_utils.dart';
import '../models/models.dart';
import '../pages/trip_details_page.dart';
import 'color_circle_widget.dart';
import 'badge_widget.dart';

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
              builder: (context) => TripDetailsPage(
                tripId: schedule.tripId,
                tripHeadsign: schedule.tripHeadsign,
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
                  Text(schedule.tripHeadsign),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                BadgeWidget(
                  text: DateFormat('M/d').format(schedule.departureDate),
                  backgroundColor: isPast
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                  textColor: isPast
                      ? Theme.of(context).colorScheme.onError
                      : Theme.of(context).colorScheme.onPrimary,
                ),
                BadgeWidget(
                  text: TimeUtils.formatTime(schedule.departureTime),
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
