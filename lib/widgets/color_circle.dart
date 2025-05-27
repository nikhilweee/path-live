import 'package:flutter/material.dart';

class ColorCircleWidget extends StatelessWidget {
  final List<String> colors;

  const ColorCircleWidget({
    super.key,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      margin: const EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: colors.length == 2
            ? LinearGradient(
                colors: colors.map((color) => _parseColor(color)).toList(),
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0.5, 0.5])
            : null,
        color: colors.length == 1 ? _parseColor(colors[0]) : null,
      ),
    );
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse("FF$hexColor", radix: 16));
  }
}
