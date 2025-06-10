import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../utils/time_utils.dart';
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

  bool _isLoading = false;
  String? _statusMessage;
  List<TrainSchedule> _allTrains = [];
  Set<String> _selectedRoutes = {};
  bool _isFilterVisible = true;

  List<TrainSchedule> get _filteredTrains {
    if (_selectedRoutes.isEmpty) return _allTrains;
    return _allTrains
        .where((train) => _selectedRoutes.contains(train.routeNameShort))
        .toList();
  }

  (List<TrainSchedule>, List<TrainSchedule>) get _splitTrains {
    final currentTimeString = TimeUtils.getCurrentTimeString();

    final pastTrains = <TrainSchedule>[];
    final futureTrains = <TrainSchedule>[];

    for (final train in _filteredTrains) {
      if (train.departureTime.compareTo(currentTimeString) <= 0) {
        pastTrains.add(train);
      } else {
        futureTrains.add(train);
      }
    }

    pastTrains.sort((a, b) => b.departureTime.compareTo(a.departureTime));
    final limitedPastTrains = pastTrains.take(5).toList();

    futureTrains.sort((a, b) => a.departureTime.compareTo(b.departureTime));
    final limitedFutureTrains = futureTrains.take(20).toList();

    return (limitedPastTrains, limitedFutureTrains);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _updateDatabase();
  }

  void _onScroll() {
    final direction = _scrollController.position.userScrollDirection;
    final shouldShow = direction == ScrollDirection.forward;

    if (_isFilterVisible != shouldShow) {
      setState(() => _isFilterVisible = shouldShow);
    }
  }

  void _updateState({
    bool? isLoading,
    String? statusMessage,
    List<TrainSchedule>? allTrains,
  }) {
    if (mounted) {
      setState(() {
        if (isLoading != null) _isLoading = isLoading;
        if (statusMessage != null) _statusMessage = statusMessage;
        if (allTrains != null) _allTrains = allTrains;
      });
    }
  }

  Future<void> _updateDatabase() async {
    _updateState(isLoading: true, statusMessage: null);

    try {
      final dbPath = await ApiService.updatePathDatabase();
      if (dbPath != null) {
        await _loadUpcomingTrains();
      } else {
        _updateState(
            isLoading: false, statusMessage: 'Failed to update database');
      }
    } catch (e) {
      _updateState(
          isLoading: false, statusMessage: 'Failed to update database: $e');
    }
  }

  Future<void> _loadUpcomingTrains() async {
    try {
      final trains = await DatabaseService.getUpcomingTrains(
        widget.station.consideredStationFullName,
      );
      _updateState(isLoading: false, allTrains: trains);
    } catch (e) {
      _updateState(
          isLoading: false,
          statusMessage: 'Failed to load train schedules: $e');
    }
  }

  List<Widget> _buildTrainList() {
    final (pastTrains, futureTrains) = _splitTrains;
    final widgets = <Widget>[];

    // Add past trains
    widgets.addAll(
        pastTrains.map((train) => ScheduleCard(schedule: train, isPast: true)));

    // Add future trains
    widgets.addAll(futureTrains
        .map((train) => ScheduleCard(schedule: train, isPast: false)));

    return widgets;
  }

  void _toggleRouteFilter(String route) {
    setState(() {
      _selectedRoutes.contains(route)
          ? _selectedRoutes.remove(route)
          : _selectedRoutes.add(route);
    });
  }

  Widget _buildFilterChips() {
    final uniqueRoutes =
        _allTrains.map((train) => train.routeNameShort).toSet().toList();

    if (uniqueRoutes.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: uniqueRoutes
            .map(
              (route) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FilterChip(
                  label: Text(route),
                  selected: _selectedRoutes.contains(route),
                  onSelected: (_) => _toggleRouteFilter(route),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.station.consideredStationFullName),
        forceMaterialTransparency: true,
      ),
      body: RefreshIndicator(
        onRefresh: _updateDatabase,
        child: Column(
          children: [
            SizedBox(
              height: 4,
              child: _isLoading ? const LinearProgressIndicator() : null,
            ),
            AnimatedContainer(
              color: Theme.of(context).colorScheme.surface,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              // TODO: Fix Animation
              height: _isFilterVisible ? 50 : 50,
              child: _buildFilterChips(),
            ),
            if (_statusMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    _statusMessage!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else if (_filteredTrains.isNotEmpty)
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  children: _buildTrainList(),
                ),
              )
            else if (!_isLoading)
              const Expanded(
                child: Center(
                  child: Text(
                    'No upcoming trains found',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
