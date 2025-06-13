import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/models.dart';
import 'api_service.dart';

class DatabaseService {
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

  static Future<List<TrainSchedule>> getTrainsForDay(
      String stopName, tz.TZDateTime date) async {
    final dbPath = await ApiService.getDatabasePath();
    if (!File(dbPath).existsSync()) {
      throw Exception('Database file not found: $dbPath');
    }

    final db = await openDatabase(dbPath, readOnly: true);
    try {
      tz.initializeTimeZones();
      final dayColumn = _getDayColumn(date);

      print("running db query for $dayColumn at $stopName");

      final results = await db.rawQuery('''
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
            c.$dayColumn = '1'
            AND s.stop_name = ?
        ORDER BY
            st.departure_time
      ''', [stopName]);

      print("found ${results.length} results");

      // Convert the date to a simple DateTime for the date field
      final dateOnly = DateTime(date.year, date.month, date.day);
      return results
          .map((row) => TrainSchedule.fromMap(row, date: dateOnly))
          .toList();
    } finally {
      await db.close();
    }
  }
}
