import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'api_service.dart';

class TrainSchedule {
  final String departureTime;
  final String tripHeadsign;
  final String routeNameShort;
  final String routeColor;
  final String? routeSecondaryRouteColor;

  TrainSchedule({
    required this.departureTime,
    required this.tripHeadsign,
    required this.routeNameShort,
    required this.routeColor,
    this.routeSecondaryRouteColor,
  });

  factory TrainSchedule.fromMap(Map<String, dynamic> map) {
    return TrainSchedule(
      departureTime: map['departure_time'] as String,
      tripHeadsign: map['trip_headsign'] as String,
      routeNameShort: map['route_name_short'] as String,
      routeColor: map['route_color'] as String,
      routeSecondaryRouteColor: map['route_secondary_route_color'] as String?,
    );
  }

  @override
  String toString() => '$departureTime - $routeNameShort';
}

class DatabaseService {
  static String _formatTime(tz.TZDateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:'
      '${time.second.toString().padLeft(2, '0')}';

  static String _getDayColumn(tz.TZDateTime dateTime) {
    const days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];
    return days[dateTime.weekday - 1];
  }

  static Future<List<Map<String, dynamic>>> _queryTrains(
      Database db,
      String stopName,
      String day,
      String timeCondition,
      List<String> params) async {
    return await db.rawQuery('''
      SELECT
          r.route_color,
          raf.route_secondary_route_color,
          st.departure_time,
          t.trip_headsign,
          hs.trip_destination_abbreviation as route_name_short
      FROM
          -- Query list of departures for the given day and stop
          [gtfs.base.calendar] c
          JOIN [gtfs.base.trips] t ON c.service_id = t.service_id
          JOIN [gtfs.base.stop_times] st ON st.trip_id = t.trip_id
          JOIN [gtfs.base.stops] s ON s.stop_id = st.stop_id
          -- Join with additional tables for route colors and headsign
          JOIN [gtfs.base.routes] r ON r.route_id = t.route_id
          JOIN [gtfs.gen.trip_headsign] hs ON hs.route_id = r.route_id
          AND hs.direction_id = t.direction_id
          JOIN [gtfs.master.routes_additional_info] raf ON raf.route_id = r.route_id
          -- Filter out departures for the last stop
          JOIN [gtfs.gen.schedule_stops] ss ON ss.trip_id = t.trip_id
          AND ss.stop_id = st.stop_id
          AND ss.next_schedule_stop_sequence IS NOT NULL
      WHERE
          c.$day = '1'
          AND s.stop_name = ?
          AND $timeCondition
      ORDER BY
          st.departure_time
    ''', [stopName, ...params]);
  }

  static Future<List<TrainSchedule>> getUpcomingTrains(String stopName) async {
    final dbPath = await ApiService.getDatabasePath();
    if (!File(dbPath).existsSync()) {
      throw Exception('Database file not found: $dbPath');
    }

    final db = await openDatabase(dbPath, readOnly: true);
    try {
      tz.initializeTimeZones();
      final nyLocation = tz.getLocation('America/New_York');
      final nowNY = tz.TZDateTime.now(nyLocation);
      final startTime = nowNY.subtract(const Duration(hours: 6));
      final endTime = nowNY.add(const Duration(hours: 6));

      final timeStart = _formatTime(startTime);
      final timeEnd = _formatTime(endTime);

      List<Map<String, dynamic>> results = [];

      if (startTime.day != endTime.day) {
        // duration crosses midnight - query both days
        final prevResults = await _queryTrains(db, stopName,
            _getDayColumn(startTime), 'st.departure_time >= ?', [timeStart]);
        final currResults = await _queryTrains(db, stopName,
            _getDayColumn(endTime), 'st.departure_time <= ?', [timeEnd]);
        results = [...prevResults, ...currResults];
      } else {
        // Same day - query once
        results = await _queryTrains(db, stopName, _getDayColumn(nowNY),
            'st.departure_time BETWEEN ? AND ?', [timeStart, timeEnd]);
      }

      return results.map((row) => TrainSchedule.fromMap(row)).toList();
    } finally {
      await db.close();
    }
  }
}
