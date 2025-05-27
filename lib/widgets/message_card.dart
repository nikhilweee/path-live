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
  late AnimationController _colorAnimationController;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();

    // Only initialize the controller here, not theme-dependent properties
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
      value: 1.0,
    );

    // We'll set the actual animation in didChangeDependencies
  }

  @override
  void didUpdateWidget(MessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.lastUpdated != widget.message.lastUpdated) {
      _colorAnimationController.reset(); // Go to beginning (Tween 1.0)
      _colorAnimationController.forward(); // Animate to end (Tween 0.0)
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Move the theme-dependent code here
    _colorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      end: Theme.of(context).cardColor,
    ).animate(
      CurvedAnimation(
        parent: _colorAnimationController,
        curve: Curves.easeOutQuart,
      ),
    );
  }

  @override
  void dispose() {
    _colorAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Card(
          color: _colorAnimation.value,
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
