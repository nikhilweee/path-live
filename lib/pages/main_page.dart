import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../widgets/station_widget.dart';
import '../widgets/progress_bar.dart';
import 'alerts_page.dart';
import 'settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _chipKeys = {};

  List<Station> _stations = [];
  List<String> _filters = [];
  IconData _fabIcon = Icons.near_me_outlined;
  bool _isFabVisible = true;
  bool _isLoadingLocation = false;
  int _progressBarDuration = 15; // default value

  @override
  void initState() {
    super.initState();
    _initialize();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initialize() async {
    await _loadFilters();
    await _loadProgressBarDuration();
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
    setState(() => _isLoadingLocation = true);

    final hasPermission = await LocationService.requestLocationPermission();

    if (hasPermission) {
      await _getUserLocation();
    }

    setState(() => _isLoadingLocation = false);
  }

  Future<void> _getUserLocation() async {
    final closestStation = await LocationService.getClosestStation();

    if (closestStation != null) {
      setState(() {
        _fabIcon = Icons.near_me;
        _filters = [closestStation];
      });
      await _saveFilters();

      // Auto-scroll to the selected chip
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final chipKey = _chipKeys[closestStation];
        if (chipKey?.currentContext != null) {
          Scrollable.ensureVisible(
            chipKey!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  Future<void> _fetchStations() async {
    final stations = await ApiService.fetchStations();
    setState(() => _stations = stations);
  }

  Future<void> _loadFilters() async {
    final filters = await getSetting(Setting.filters);
    setState(() => _filters = filters);
  }

  Future<void> _loadProgressBarDuration() async {
    final duration = await getSetting(Setting.progressBarDuration);
    setState(() => _progressBarDuration = duration);
  }

  Future<void> _saveFilters() async {
    await setSetting(Setting.filters, _filters);
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
    return OverflowBox(
      maxHeight: 50,
      alignment: Alignment.bottomCenter,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: LocationService.stationCoordinates.keys.map((station) {
            // Create or get the GlobalKey for this station
            _chipKeys[station] ??= GlobalKey();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                key: _chipKeys[station],
                label: Text(station),
                selected: _filters.contains(station),
                onSelected: (_) => _toggleFilter(station),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _navigateToAlerts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AlertsPage()),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    ).then((_) {
      // Reload settings when returning from settings page
      _loadProgressBarDuration();
      // Trigger a rebuild to update all RealTimeDisplay widgets
      setState(() {});
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
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _navigateToAlerts,
            tooltip: 'Alerts',
          ),
        ],
      ),
      body: Column(
        children: [
          ProgressBar(
            duration: Duration(seconds: _progressBarDuration),
            color: Theme.of(context).colorScheme.primary,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            onCompleted: _fetchStations,
          ),
          AnimatedContainer(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: _isFabVisible ? 50 : 0,
            clipBehavior: Clip.hardEdge,
            child: _buildFilterChips(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchStations,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    itemCount:
                        filteredStations.isEmpty ? 1 : filteredStations.length,
                    itemBuilder: (context, index) {
                      if (filteredStations.isEmpty) {
                        return SizedBox(
                          height: constraints.maxHeight,
                          child:
                              const Center(child: Text('Failed to load data')),
                        );
                      }
                      return StationWidget(
                        key: ValueKey(
                          'station_${filteredStations[index].consideredStation}',
                        ),
                        station: filteredStations[index],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        offset: _isFabVisible ? Offset.zero : const Offset(0, 2),
        child: FloatingActionButton(
          onPressed: _isLoadingLocation ? null : _requestLocationPermission,
          tooltip: 'Get Location',
          child: _isLoadingLocation
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : Icon(_fabIcon),
        ),
      ),
    );
  }
}
