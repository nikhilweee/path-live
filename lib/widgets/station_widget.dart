import 'package:flutter/material.dart';
import 'dart:async';
import '../models/models.dart';
import 'destination_widget.dart';

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
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        // This will trigger a rebuild of the entire StationWidget and its children
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
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
