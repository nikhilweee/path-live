import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../widgets/schedule_card.dart';

class StationDetailsPage extends StatefulWidget {
  final Station station;

  const StationDetailsPage({
    super.key,
    required this.station,
  });

  @override
  State<StationDetailsPage> createState() => _StationDetailsPageState();
}

class _StationDetailsPageState extends State<StationDetailsPage> {
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  String? _statusMessage;
  List<TrainSchedule> _upcomingTrains = [];
  List<TrainSchedule> _allTrains = [];
  List<String> _selectedRoutes = [];
  bool _isFilterVisible = true;

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

  Future<void> _updateDatabase() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final dbPath = await ApiService.updatePathDatabase();
      if (mounted && dbPath != null) {
        await _loadUpcomingTrains();
        setState(() {
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _statusMessage = 'Failed to update database';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to update database: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadUpcomingTrains() async {
    try {
      final trains = await DatabaseService.getUpcomingTrains(
        widget.station.consideredStationFullName,
      );
      if (mounted) {
        setState(() {
          _allTrains = trains;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to load train schedules: $e';
        });
      }
    }
  }

  void _applyFilters() {
    if (_selectedRoutes.isEmpty) {
      _upcomingTrains = _allTrains;
    } else {
      _upcomingTrains = _allTrains
          .where((train) => _selectedRoutes.contains(train.routeNameShort))
          .toList();
    }
  }

  void _toggleRouteFilter(String route) {
    setState(() {
      _selectedRoutes.contains(route)
          ? _selectedRoutes.remove(route)
          : _selectedRoutes.add(route);
      _applyFilters();
    });
  }

  Widget _buildFilterChips() {
    final uniqueRoutes = _allTrains
        .map((train) => train.routeNameShort)
        .toSet()
        .toList();
    
    if (uniqueRoutes.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Wrap(
          spacing: 8.0,
          children: uniqueRoutes
              .map((route) => FilterChip(
                    label: Text(route),
                    selected: _selectedRoutes.contains(route),
                    onSelected: (_) => _toggleRouteFilter(route),
                  ))
              .toList(),
        ),
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
              height: _isFilterVisible ? 60 : 0.0,
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
          else if (_upcomingTrains.isNotEmpty)
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _upcomingTrains.length,
                itemBuilder: (context, index) {
                  final train = _upcomingTrains[index];
                  return ScheduleCard(schedule: train);
                },
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
