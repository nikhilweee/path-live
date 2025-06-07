import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'color_circle.dart';

class ScheduleCard extends StatelessWidget {
  final TrainSchedule schedule;

  const ScheduleCard({
    super.key,
    required this.schedule,
  });

  String _formatDepartureTime(String departureTime) {
    // departureTime is in format "HH:MM:SS", we want "HH:MM"
    final parts = departureTime.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return departureTime;
  }

  @override
  Widget build(BuildContext context) {
    // Build colors list based on available route colors
    List<String> colors = [schedule.routeColor];
    if (schedule.routeSecondaryRouteColor?.isNotEmpty == true) {
      colors.add(schedule.routeSecondaryRouteColor!);
    }

    return Card(
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
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8.0),
            ),
            constraints: const BoxConstraints(
              minWidth: 60,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            margin: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              _formatDepartureTime(schedule.departureTime),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
