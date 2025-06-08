import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/station_widget.dart';
import '../widgets/progress_bar.dart';
import 'alerts_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ScrollController _scrollController = ScrollController();

  List<Station> _stations = [];
  List<String> _filters = [];
  IconData _fabIcon = Icons.near_me_outlined;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _initialize();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initialize() async {
    await _loadFilters();
    await _fetchStations();
  }

  void _onScroll() {
    final direction = _scrollController.position.userScrollDirection;
    final shouldShow = direction == ScrollDirection.forward;

    if (_isFabVisible != shouldShow) {
      setState(() => _isFabVisible = shouldShow);
    }
  }

  Future<void> _requestLocationPermission() async {
    final hasPermission = await LocationService.requestLocationPermission();

    if (hasPermission) {
      await _getUserLocation();
    }
  }

  Future<void> _getUserLocation() async {
    final closestStation = await LocationService.getClosestStation();

    if (closestStation != null) {
      setState(() {
        _fabIcon = Icons.near_me;
        _filters = [closestStation];
      });
      await _saveFilters();
    }
  }

  Future<void> _fetchStations() async {
    final stations = await ApiService.fetchStations();
    setState(() => _stations = stations);
  }

  Future<void> _loadFilters() async {
    final filters = await StorageService.loadFilters();
    setState(() => _filters = filters);
  }

  Future<void> _saveFilters() async {
    await StorageService.saveFilters(_filters);
  }

  void _toggleFilter(String station) {
    setState(() {
      _filters.contains(station)
          ? _filters.remove(station)
          : _filters.add(station);
    });
    _saveFilters();
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: LocationService.stationCoordinates.keys
            .map((station) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: FilterChip(
                    label: Text(station),
                    selected: _filters.contains(station),
                    onSelected: (_) => _toggleFilter(station),
                  ),
                ))
            .toList(),
      ),
    );
  }

  void _navigateToAlerts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlertsPage()),
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
    final filteredStations = _filters.isEmpty
        ? _stations
        : _stations
            .where((station) => _filters.contains(station.consideredStation))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'PATH Live',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        forceMaterialTransparency: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _navigateToAlerts,
            tooltip: 'Alerts',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchStations,
        child: Column(
          children: [
            ProgressBar(
              duration: const Duration(seconds: 15),
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              onCompleted: _fetchStations,
            ),
            AnimatedContainer(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              // TODO: Fix Animation
              height: _isFabVisible ? 50 : 50,
              child: _buildFilterChips(),
            ),
            Expanded(
              child: filteredStations.isEmpty
                  ? const Center(child: Text('Failed to load data'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      controller: _scrollController,
                      itemCount: filteredStations.length,
                      itemBuilder: (context, index) => StationWidget(
                        key: ValueKey(
                          'station_${filteredStations[index].consideredStation}',
                        ),
                        station: filteredStations[index],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: FloatingActionButton(
          onPressed: _requestLocationPermission,
          tooltip: 'Get Location',
          child: Icon(_fabIcon),
        ),
      ),
    );
  }
}
