import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/trip_card.dart';

class TripsPage extends StatefulWidget {
  final Station station;

  const TripsPage({
    super.key,
    required this.station,
  });

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  final ScrollController _scrollController = ScrollController();

  List<Trip> _allTrips = [];
  List<String> _filters = [];
  bool _isLoading = true;
  bool _isFilterVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTrips();
  }

  void _onScroll() {
    final direction = _scrollController.position.userScrollDirection;
    final shouldShow = direction == ScrollDirection.forward;

    if (_isFilterVisible != shouldShow) {
      setState(() => _isFilterVisible = shouldShow);
    }
  }

  void _toggleFilter(String routeName) {
    setState(() {
      _filters.contains(routeName)
          ? _filters.remove(routeName)
          : _filters.add(routeName);
    });
  }

  Widget _buildFilterChips() {
    final uniqueRoutes = _allTrips
        .map((trip) => trip.routeNameShort)
        .toSet()
        .toList()
      ..sort();

    return OverflowBox(
      maxHeight: 50,
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: uniqueRoutes
              .map((route) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: FilterChip(
                      label: Text(route),
                      selected: _filters.contains(route),
                      onSelected: (_) => _toggleFilter(route),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Future<void> _loadTrips() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final today = now;
    final tomorrow = now.add(const Duration(days: 1));

    final trips = <Trip>[];
    trips.addAll(await DatabaseService.getTripsForDay(
        widget.station.consideredStationFullName, yesterday));
    trips.addAll(await DatabaseService.getTripsForDay(
        widget.station.consideredStationFullName, today));
    trips.addAll(await DatabaseService.getTripsForDay(
        widget.station.consideredStationFullName, tomorrow));

    // Sort all trips by datetime
    trips.sort((a, b) => a.departureDateTime.compareTo(b.departureDateTime));

    setState(() {
      _allTrips = trips;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTrips = _filters.isEmpty
        ? _allTrips
        : _allTrips
            .where((trip) => _filters.contains(trip.routeNameShort))
            .toList();

    // Recalculate center index for filtered trips
    int filteredCenterIndex = 0;
    for (int i = 0; i < filteredTrips.length; i++) {
      if (!filteredTrips[i].departureDateTime.isBefore(DateTime.now())) {
        filteredCenterIndex = i;
        break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.station.consideredStationFullName,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        forceMaterialTransparency: true,
      ),
      body: Column(
        children: [
          Container(
            height: 4,
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: _isLoading ? const LinearProgressIndicator() : null,
          ),
          AnimatedContainer(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isFilterVisible ? 50 : 0,
            clipBehavior: Clip.hardEdge,
            child: _buildFilterChips(),
          ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              center: ValueKey(filteredCenterIndex),
              slivers: [
                // Past trips (in reverse order)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reverseIndex = filteredCenterIndex - 1 - index;
                      if (reverseIndex < 0) return null;
                      return TripCard(
                        trip: filteredTrips[reverseIndex],
                        isPast: true,
                      );
                    },
                    childCount: filteredCenterIndex,
                  ),
                ),
                // Future trips
                SliverList(
                  key: ValueKey(filteredCenterIndex),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final actualIndex = filteredCenterIndex + index;
                      if (actualIndex >= filteredTrips.length) return null;
                      return TripCard(
                        trip: filteredTrips[actualIndex],
                        isPast: false,
                      );
                    },
                    childCount: filteredTrips.length - filteredCenterIndex,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
