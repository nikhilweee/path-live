import 'package:flutter/material.dart';
import '../models/models.dart';
import 'train_card.dart';
import '../pages/schedules_page.dart';

class StationWidget extends StatelessWidget {
  final Station station;

  const StationWidget({
    super.key,
    required this.station,
  });

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
                  builder: (context) => SchedulesPage(station: station),
                ),
              );
            },
            child: Card.outlined(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    station.consideredStationFullName,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ),
            ),
          ),
        ),
        ...station.trains
            .asMap()
            .entries
            .map<Widget>((entry) => TrainCard(
                  key: ValueKey('train_${entry.key}'),
                  train: entry.value,
                )),
      ],
    );
  }
}
