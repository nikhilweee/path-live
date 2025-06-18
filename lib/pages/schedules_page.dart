import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../widgets/schedule_card.dart';

class SchedulesPage extends StatefulWidget {
  final Station station;

  const SchedulesPage({
    super.key,
    required this.station,
  });

  @override
  State<SchedulesPage> createState() => _SchedulesPageState();
}

class _SchedulesPageState extends State<SchedulesPage> {
  final ScrollController _scrollController = ScrollController();

  List<TrainSchedule> _allTrains = [];
  List<String> _filters = [];
  bool _isLoading = true;
  bool _isFilterVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTrains();
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
    final uniqueRoutes = _allTrains
        .map((train) => train.routeNameShort)
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

  Future<void> _loadTrains() async {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final today = now;
    final tomorrow = now.add(const Duration(days: 1));

    final trains = <TrainSchedule>[];
    trains.addAll(await DatabaseService.getTrainsForDay(
        widget.station.consideredStationFullName, yesterday));
    trains.addAll(await DatabaseService.getTrainsForDay(
        widget.station.consideredStationFullName, today));
    trains.addAll(await DatabaseService.getTrainsForDay(
        widget.station.consideredStationFullName, tomorrow));

    // Sort all trains by datetime
    trains.sort((a, b) => a.departureDateTime.compareTo(b.departureDateTime));

    setState(() {
      _allTrains = trains;
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
    final filteredTrains = _filters.isEmpty
        ? _allTrains
        : _allTrains
            .where((train) => _filters.contains(train.routeNameShort))
            .toList();

    // Recalculate center index for filtered trains
    int filteredCenterIndex = 0;
    for (int i = 0; i < filteredTrains.length; i++) {
      if (!filteredTrains[i].departureDateTime.isBefore(DateTime.now())) {
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
                // Past trains (in reverse order)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final reverseIndex = filteredCenterIndex - 1 - index;
                      if (reverseIndex < 0) return null;
                      return ScheduleCard(
                        schedule: filteredTrains[reverseIndex],
                        isPast: true,
                      );
                    },
                    childCount: filteredCenterIndex,
                  ),
                ),
                // Future trains
                SliverList(
                  key: ValueKey(filteredCenterIndex),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final actualIndex = filteredCenterIndex + index;
                      if (actualIndex >= filteredTrains.length) return null;
                      return ScheduleCard(
                        schedule: filteredTrains[actualIndex],
                        isPast: false,
                      );
                    },
                    childCount: filteredTrains.length - filteredCenterIndex,
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
