import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// Models - consolidated into a single file
import 'models/models.dart';

// Widgets
import 'widgets/station_filter.dart';
import 'widgets/result_widget.dart';
import 'widgets/progress_bar.dart';

void main() {
  runApp(const MyApp());
}

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
  List<Result> _results = [];
  List<String> _filters = [];
  IconData _fabIcon = Icons.near_me_outlined;

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

  @override
  void initState() {
    super.initState();
    _loadFilters();
    fetchJsonData();
  }

  Future<void> _loadFilters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _filters = prefs.getStringList('filters') ?? [];
    });
  }

  Future<void> _saveFilters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('filters', _filters);
  }

  void _handleFilterSelection(String station, bool selected) {
    setState(() {
      if (selected) {
        _filters.add(station);
      } else {
        _filters.removeWhere((s) => s == station);
      }
      _saveFilters();
    });
  }

  Future<void> _requestLocationPermissionAndPrint() async {
    var status = await Permission.location.status;

    if (!status.isGranted) {
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      _getUserLocation();
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  String _findClosestStation(Position userPosition) {
    String closestStation = "";
    double closestDistance = double.infinity;

    _stationCoordinates.forEach((station, latLong) {
      double distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        latLong.latitude,
        latLong.longitude,
      );

      if (distance < closestDistance) {
        closestDistance = distance;
        closestStation = station;
      }
    });

    return closestStation;
  }

  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      String closestStation = _findClosestStation(position);
      setState(() {
        _fabIcon = Icons.near_me;
        _filters = [closestStation];
      });
      _saveFilters();
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  Future<void> fetchJsonData() async {
    try {
      final response = await http.get(
          Uri.parse('https://www.panynj.gov/bin/portauthority/ridepath.json'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        List<Result> results = (data['results'] as List)
            .map((resultJson) => Result.fromJson(resultJson))
            .toList();

        setState(() {
          _results = results;
        });
      } else {
        setState(() {
          _results = [];
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      setState(() {
        _results = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Result> filteredResults = _filters.isEmpty
        ? _results
        : _results
            .where((result) => _filters.contains(result.consideredStation))
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
              color: Theme.of(context).colorScheme.primary,
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              onCompleted: () {
                fetchJsonData();
              },
            ),
            StationFilter(
              stations: _stationCoordinates,
              selectedFilters: _filters,
              onFilterSelected: _handleFilterSelection,
            ),
            Expanded(
              child: filteredResults.isEmpty
                  ? const Center(child: Text("Failed to load data"))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.builder(
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          var result = filteredResults[index];
                          return ResultWidget(
                            key: ValueKey('result_${result.consideredStation}'),
                            result: result,
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _requestLocationPermissionAndPrint,
        tooltip: 'Get Location',
        child: Icon(_fabIcon),
      ),
    );
  }
}
