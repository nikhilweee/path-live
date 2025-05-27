import 'package:flutter/material.dart';
import '../models/models.dart';
import 'color_circle.dart';
import 'real_time_display.dart';

class MessageCard extends StatefulWidget {
  final Message message;

  const MessageCard({
    super.key,
    required this.message,
  });

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _flashController;
  late Animation<double> _flashAnimation;

  @override
  void initState() {
    super.initState();

    _flashController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
      value: 1.0,
    );

    _flashAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _flashController,
        curve: Curves.easeOutQuart,
      ),
    );
  }

  @override
  void didUpdateWidget(MessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.lastUpdated != widget.message.lastUpdated) {
      _flashController.reset(); // Go to beginning (Tween 1.0)
      _flashController.forward(); // Animate to end (Tween 0.0)
    }
  }

  @override
  void dispose() {
    _flashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _flashAnimation,
      builder: (context, child) {
        return Card(
          color: Color.lerp(
            Theme.of(context).cardColor,
            highlightColor.withValues(alpha: 0.1),
            _flashAnimation.value,
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          ColorCircleWidget(colors: widget.message.lineColor),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.message.headSign),
                RealTimeDisplay(
                  secondsToArrival: widget.message.secondsToArrival,
                  lastUpdated: widget.message.lastUpdated,
                  arrivalTimeMessage: widget.message.arrivalTimeMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
