import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

String getFirstValue(String value) {
  return value.contains(',') ? value.split(',')[0] : value;
}

class Message {
  final String target;
  final String secondsToArrival;
  final String arrivalTimeMessage;
  final List<String> lineColor;
  final String headSign;
  final String lastUpdated;

  Message({
    required this.target,
    required this.secondsToArrival,
    required this.arrivalTimeMessage,
    required this.lineColor,
    required this.headSign,
    required this.lastUpdated,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      target: json['target'],
      secondsToArrival: json['secondsToArrival'],
      arrivalTimeMessage: json['arrivalTimeMessage'],
      lineColor: json['lineColor'].split(","),
      headSign: json['headSign'],
      lastUpdated: json['lastUpdated'],
    );
  }
}

class Destination {
  final String label;
  final List<Message> messages;

  Destination({
    required this.label,
    required this.messages,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      label: json['label'],
      messages: (json['messages'] as List)
          .map((messageJson) => Message.fromJson(messageJson))
          .toList(),
    );
  }
}

class Result {
  final String consideredStation;
  final List<Destination> destinations;
  final String consideredStationFullName;

  Result({
    required this.consideredStation,
    required this.destinations,
    required this.consideredStationFullName,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    Map<String, String> stations = {
      "NWK": "Newark",
      "HAR": "Harrison",
      "JSQ": "Journal Square",
      "GRV": "Grove Street",
      "NEW": "Newport",
      "EXP": "Exchange Place",
      "HOB": "Hoboken",
      "WTC": "World Trade Center",
      "CHR": "Christopher Street",
      "09S": "9th Street",
      "14S": "14th Street",
      "23S": "23rd Street",
      "33S": "33rd Street"
    };

    String stationCode = json['consideredStation'];
    String consideredStationFullName = stations[stationCode] ?? stationCode;

    return Result(
      consideredStation: json['consideredStation'],
      consideredStationFullName: consideredStationFullName,
      destinations: (json['destinations'] as List)
          .map((destinationJson) => Destination.fromJson(destinationJson))
          .toList(),
    );
  }
}

class LatLong {
  final double latitude;
  final double longitude;

  LatLong(this.latitude, this.longitude);
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
      home: MainWidget(),
    );
  }
}

class MainWidget extends StatefulWidget {
  @override
  _MainWidgetState createState() => _MainWidgetState();
}

class _MainWidgetState extends State<MainWidget> {
  List<Result> _results = [];
  List<String> _filters = [];
  IconData _fabIcon = Icons.near_me_outlined;
  Timer? _timer;

  Map<String, LatLong> _stationCoordinates = {
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
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(seconds: 15), (timer) {
      fetchJsonData();
    });
  }

  // Functions to load filters from SharedPreferences
  Future<void> _loadFilters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _filters = prefs.getStringList('filters') ?? [];
    });
  }

  // Function to save filters to SharedPreferences
  Future<void> _saveFilters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('filters', _filters);
  }

  // Function to request location permission and get location
  Future<void> _requestLocationPermissionAndPrint() async {
    var status = await Permission.location.status;

    if (!status.isGranted) {
      // Request permission if not already granted
      status = await Permission.location.request();
    }

    if (status.isGranted) {
      // Permission granted, get the location
      _getUserLocation();
    } else if (status.isPermanentlyDenied) {
      // Handle the case where the user permanently denied the permission
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

  // Function to get the user's location
  Future<void> _getUserLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      print('Current location: ${position.latitude}, ${position.longitude}');
      String closestStation = _findClosestStation(position);
      print('Closest station: $closestStation');
      setState(() {
        _fabIcon = Icons.near_me;
        _filters = [closestStation];
      });
    } catch (e) {
      print('Error getting location: $e');
    }
  }

  // Function to fetch JSON data from the PATH API
  Future<void> fetchJsonData() async {
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: _stationCoordinates.keys.map((station) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        label: Text(station),
                        selected: _filters.contains(station),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              _filters.add(station);
                            } else {
                              _filters.removeWhere((String s) => s == station);
                            }
                            _saveFilters();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Expanded(
              child: filteredResults.isEmpty
                  ? Center(
                      child: Text("Failed to load data or no data available"))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ListView.builder(
                        itemCount: filteredResults.length,
                        itemBuilder: (context, index) {
                          var result = filteredResults[index];
                          return ResultWidget(result: result);
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

class ResultWidget extends StatefulWidget {
  const ResultWidget({
    super.key,
    required this.result,
  });

  final Result result;

  @override
  _ResultWidgetState createState() => _ResultWidgetState();
}

class _ResultWidgetState extends State<ResultWidget> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        // This will trigger a rebuild of the entire ResultCard and its children
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Card.outlined(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  widget.result.consideredStationFullName,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ),
          ),
        ),
        ...widget.result.destinations.map<Widget>((destination) {
          return DestinationWidget(destination: destination);
        }),
      ],
    );
  }
}

class DestinationWidget extends StatelessWidget {
  const DestinationWidget({
    super.key,
    required this.destination,
  });

  final Destination destination;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...destination.messages.map<Widget>((message) {
          return MessageWidget(message: message);
        }),
      ],
    );
  }
}

class ColorCircleWidget extends StatelessWidget {
  final List<String> colors;

  ColorCircleWidget({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15, // You can adjust the size
      height: 15,
      margin: const EdgeInsets.only(right: 8.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: colors.length == 2
            ? LinearGradient(
                colors: colors.map((color) => _parseColor(color)).toList(),
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [0.5, 0.5])
            : null,
        color: colors.length == 1 ? _parseColor(colors[0]) : null,
      ),
    );
  }

  Color _parseColor(String hexColor) {
    return Color(int.parse("FF$hexColor", radix: 16));
  }
}

class MessageWidget extends StatefulWidget {
  const MessageWidget({
    super.key,
    required this.message,
  });

  final Message message;

  @override
  State<MessageWidget> createState() => _MessageWidgetState();
}

class _MessageWidgetState extends State<MessageWidget> {
  String formatSeconds(String secondsToArrival, String lastUpdated) {
    DateTime lastUpdatedTime = DateTime.parse(lastUpdated);
    Duration timePassed = DateTime.now().difference(lastUpdatedTime);

    int totalSeconds = int.parse(secondsToArrival) - timePassed.inSeconds;

    int minutes = totalSeconds.abs() ~/ 60;
    int seconds = totalSeconds.abs() % 60;

    String formattedMinutes = minutes.abs().toString().padLeft(2, '0');
    String formattedSeconds = seconds.abs().toString().padLeft(2, '0');

    // Add a negative sign if the totalSeconds is negative
    String sign = totalSeconds < 0 ? "-" : "";

    return '$sign$formattedMinutes:$formattedSeconds';
  }

  bool _showArrivalTimeMessage = false;

  void _toggleArrivalTimeMessage() {
    setState(() {
      _showArrivalTimeMessage = !_showArrivalTimeMessage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleArrivalTimeMessage,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  ColorCircleWidget(colors: widget.message.lineColor),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(widget.message.headSign),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_showArrivalTimeMessage) ...[
                              Text(
                                formatSeconds(widget.message.secondsToArrival,
                                    widget.message.lastUpdated),
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ] else ...[
                              Text(
                                widget.message.arrivalTimeMessage,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
