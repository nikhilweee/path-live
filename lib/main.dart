import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

import 'models/models.dart';
import 'widgets/result_widget.dart';
import 'widgets/progress_bar.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.lightBlue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const MainWidget(),
    );
  }
}

class MainWidget extends StatefulWidget {
  const MainWidget({super.key});

  @override
  _MainWidgetState createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  final ScrollController _scrollController = ScrollController();

  final Map<String, LatLong> _stationCoordinates = {
    "NWK": LatLong(40.7357214, -74.1613136),
    "HAR": LatLong(40.7376621, -74.1562678),
    "JSQ": LatLong(40.7319329, -74.0653761),
    "GRV": LatLong(40.7190822, -74.0445114),
    "EXP": LatLong(40.7169196, -74.0340219),
    "WTC": LatLong(40.7142535, -74.0194767),
    "NEW": LatLong(40.7246329, -74.0339884),
    "HOB": LatLong(40.7331754, -74.0302369),
    "CHR": LatLong(40.7341757, -74.0085746),
    "09S": LatLong(40.7354038, -74.0005162),
    "14S": LatLong(40.7365777, -73.9992338),
    "23S": LatLong(40.7425656, -73.993305),
    "33S": LatLong(40.7488743, -73.9886441),
  };

  List<Result> _results = [];
  List<String> _filters = [];
  IconData _fabIcon = Icons.near_me_outlined;
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _loadFilters();
    fetchJsonData();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final direction = _scrollController.position.userScrollDirection;
    final shouldShow = direction == ScrollDirection.forward;

    if (_isFabVisible != shouldShow) {
      setState(() => _isFabVisible = shouldShow);
    }
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      _getUserLocation();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  String _findClosestStation(Position position) {
    return _stationCoordinates.entries
        .map((entry) => MapEntry(
            entry.key,
            Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              entry.value.latitude,
              entry.value.longitude,
            )))
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final closestStation = _findClosestStation(position);
      setState(() {
        _fabIcon = Icons.near_me;
        _filters = [closestStation];
      });
      _saveFilters();
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  Future<void> fetchJsonData() async {
    try {
      final response = await http.get(
          Uri.parse('https://www.panynj.gov/bin/portauthority/ridepath.json'));

      final results = response.statusCode == 200
          ? (json.decode(response.body)['results'] as List)
              .map((json) => Result.fromJson(json))
              .toList()
          : <Result>[];

      setState(() => _results = results);
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => _results = []);
    }
  }

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _filters = prefs.getStringList('filters') ?? []);
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('filters', _filters);
  }

  void _toggleFilter(String station) {
    setState(() {
      _filters.contains(station)
          ? _filters.remove(station)
          : _filters.add(station);
      _saveFilters();
    });
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Wrap(
          spacing: 8.0,
          children: _stationCoordinates.keys
              .map((station) => FilterChip(
                    label: Text(station),
                    selected: _filters.contains(station),
                    onSelected: (_) => _toggleFilter(station),
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
    final filteredResults = _filters.isEmpty
        ? _results
        : _results
            .where((r) => _filters.contains(r.consideredStation))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("PATH Live", style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: fetchJsonData,
        child: Column(
          children: [
            ProgressBar(
              duration: const Duration(seconds: 15),
              color: Theme.of(context).colorScheme.onPrimary,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              onCompleted: fetchJsonData,
            ),
            AnimatedContainer(
              color: Theme.of(context).colorScheme.surface,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _isFabVisible ? 60 : 0.0,
              child: _buildFilterChips(),
            ),
            Expanded(
              child: filteredResults.isEmpty
                  ? const Center(child: Text("Failed to load data"))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      controller: _scrollController,
                      itemCount: filteredResults.length,
                      itemBuilder: (_, index) => ResultWidget(
                        key: ValueKey(
                            'result_${filteredResults[index].consideredStation}'),
                        result: filteredResults[index],
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
