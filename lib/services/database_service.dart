import 'dart:io';
import 'package:flutter/foundation.dart';
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

  static Future<List<String>> _getActiveServiceIds(
      Database db, String dayColumn) async {
    final serviceResults = await db.rawQuery('''
      SELECT service_id
      FROM [gtfs.base.vw_calendar_active_services]
      WHERE $dayColumn = '1'
    ''');

    if (serviceResults.isEmpty) {
      debugPrint("No active services found for $dayColumn");
      return [];
    }

    final activeServiceIds =
        serviceResults.map((row) => row['service_id'] as String).toList();

    debugPrint("Found ${activeServiceIds.length} active service_ids "
        "for $dayColumn: ${activeServiceIds.join(', ')}");
    return activeServiceIds;
  }

  static Future<List<Map<String, Object?>>> _getTrainsForServices(
      Database db, List<String> serviceIds, String stopName) async {
    if (serviceIds.isEmpty) return [];

    final placeholders = serviceIds.map((_) => '?').join(',');

    return await db.rawQuery('''
      SELECT
          r.route_color,
          raf.route_secondary_route_color,
          st.departure_time,
          t.trip_headsign,
          hs.trip_destination_abbreviation as route_name_short
      FROM
          [gtfs.base.trips] t
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
          t.service_id IN ($placeholders)
          AND s.stop_name = ?
      ORDER BY
          st.departure_time
    ''', [...serviceIds, stopName]);
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

      debugPrint("running db query for $dayColumn at $stopName");

      // Get active service IDs for the day
      final activeServiceIds = await _getActiveServiceIds(db, dayColumn);
      if (activeServiceIds.isEmpty) {
        return [];
      }

      // Get train schedules for those services
      final results =
          await _getTrainsForServices(db, activeServiceIds, stopName);
      debugPrint("found ${results.length} results");

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
