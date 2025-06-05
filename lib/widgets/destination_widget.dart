import 'package:flutter/material.dart';
import '../models/models.dart';
import 'train_card.dart';

class DestinationWidget extends StatelessWidget {
  final Destination destination;

  const DestinationWidget({
    super.key,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: destination.trains
          .asMap()
          .entries
          .map<Widget>((entry) => TrainCard(
                key: ValueKey(
                  'train_${entry.key}',
                ),
                train: entry.value,
              ))
          .toList(),
    );
  }
}
