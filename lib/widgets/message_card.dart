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
  late AnimationController _animationController;
  late Animation<Color?> _animation;
  bool _isHighlighted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
      value: 1.0,
    );
  }

  @override
  void didUpdateWidget(MessageCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.message.lastUpdated != widget.message.lastUpdated) {
      _animationController.reset();
      _animationController.forward();

      // Reset highlight if this is likely a new train
      int oldSeconds = int.parse(oldWidget.message.secondsToArrival);
      int newSeconds = int.parse(widget.message.secondsToArrival);
      if (oldWidget.message.target != widget.message.target ||
          (newSeconds - oldSeconds).abs() > 300) {
        setState(() => _isHighlighted = false);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animation = ColorTween(
      begin: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      end: Theme.of(context).cardColor,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleHighlight() => setState(() => _isHighlighted = !_isHighlighted);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleHighlight,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (_, child) => Card(
          color: _isHighlighted
              ? Theme.of(context).colorScheme.primaryContainer
              : _animation.value,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: child,
          ),
        ),
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
      ),
    );
  }
}
