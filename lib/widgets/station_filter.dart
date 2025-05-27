import 'package:flutter/material.dart';
import '../models/models.dart';

class StationFilter extends StatelessWidget {
  final Map<String, LatLong> stations;
  final List<String> selectedFilters;
  final Function(String, bool) onFilterSelected;

  const StationFilter({
    super.key,
    required this.stations,
    required this.selectedFilters,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: stations.keys.map((station) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                key: ValueKey('filter_$station'),
                label: Text(station),
                selected: selectedFilters.contains(station),
                onSelected: (bool selected) {
                  onFilterSelected(station, selected);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
