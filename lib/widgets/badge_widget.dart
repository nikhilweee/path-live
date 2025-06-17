import 'package:flutter/material.dart';

class BadgeWidget extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  final EdgeInsets padding;
  final double? minWidth;

  const BadgeWidget({
    super.key,
    required this.text,
    this.backgroundColor,
    this.textColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
    this.minWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.primary,
        borderRadius: BorderRadius.circular(8.0),
      ),
      constraints: BoxConstraints(
        minWidth: minWidth ?? 40,
      ),
      padding: padding,
      margin: EdgeInsets.only(right: 4.0),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor ?? colorScheme.onPrimary,
            ),
      ),
    );
  }
}
