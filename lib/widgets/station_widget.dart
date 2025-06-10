import 'package:flutter/material.dart';
import '../models/models.dart';
import 'destination_widget.dart';
import '../pages/schedules_page.dart';

class StationWidget extends StatefulWidget {
  final Station station;

  const StationWidget({
    super.key,
    required this.station,
  });

  @override
  _StationWidgetState createState() => _StationWidgetState();
}

class _StationWidgetState extends State<StationWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SchedulesPage(station: widget.station),
                ),
              );
            },
            child: Card.outlined(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    widget.station.consideredStationFullName,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
          ),
        ),
        ...widget.station.destinations.map<Widget>((destination) {
          return DestinationWidget(
            key: ValueKey('destination_${destination.label}'),
            destination: destination,
          );
        }),
      ],
    );
  }
}
