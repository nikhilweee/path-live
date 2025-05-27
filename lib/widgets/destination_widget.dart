import 'package:flutter/material.dart';
import '../models/models.dart';
import 'message_card.dart';

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
      children: destination.messages
          .asMap()
          .entries
          .map<Widget>((entry) => MessageCard(
                key: ValueKey(
                  'message_${entry.key}',
                ),
                message: entry.value,
              ))
          .toList(),
    );
  }
}
