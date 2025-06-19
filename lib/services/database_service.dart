import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import 'storage_service.dart';

class DatabaseService {
  // ============================================================================
  // DATABASE SYNC AND DOWNLOAD
  // ============================================================================

  // PATH database API configuration
  static const String _pathBaseUrl =
      'https://path-mppprod-app.azurewebsites.net/api/v3';
  static const String _configEndpoint = '$_pathBaseUrl/Config/Fetch';
  static const String _datafileEndpoint = '$_pathBaseUrl/file/datafile';

  /// Builds headers for PATH API requests
  static Future<Map<String, String>> _buildPathHeaders(
      [bool includeContentType = false]) async {
    return {
      'AuthKey': await getSetting(Setting.authKey),
      'AppVersion': '6.1.0',
      'DbChecksum': await getSetting(Setting.dbChecksum),
      if (includeContentType) 'Content-Type': 'application/json',
    };
  }

  /// Gets the path to the local database file
  static Future<String> getDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/db.sqlite';
  }

  /// Fetches the latest DB checksum from server
  static Future<String?> fetchLatestDbChecksum() async {
    try {
      final currentChecksum = await getSetting(Setting.dbChecksum);
      final response = await http.get(
        Uri.parse(_configEndpoint),
        headers: await _buildPathHeaders(),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch config: ${response.statusCode}');
        return null;
      }

      final jsonData = json.decode(response.body);
      return jsonData['data']?['db-update']?['db-checksum'] ?? currentChecksum;
    } catch (e) {
      debugPrint('Error fetching config: $e');
      return null;
    }
  }

  /// Downloads and extracts the PATH database
  static Future<String?> downloadAndExtractDatabase() async {
    try {
      final response = await http.post(
        Uri.parse(_datafileEndpoint),
        headers: await _buildPathHeaders(true),
        body: json.encode({
          'checksum': await getSetting(Setting.dbChecksum),
          'type': 'database',
        }),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to download database: ${response.statusCode}');
        return null;
      }

      final dbPath = await getDatabasePath();
      final zipPath = '$dbPath.zip';

      // Write, extract, and cleanup zip
      await File(zipPath).writeAsBytes(response.bodyBytes);
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);

      if (archive.isEmpty) {
        debugPrint('Empty zip archive received');
        await File(zipPath).delete();
        return null;
      }

      await File(dbPath).writeAsBytes(archive.first.content as List<int>);
      await File(zipPath).delete();

      debugPrint('Database downloaded and extracted to: $dbPath');
      return dbPath;
    } catch (e) {
      debugPrint('Error downloading database: $e');
      return null;
    }
  }

  /// Updates the PATH database if needed
  static Future<String?> updatePathDatabase() async {
    try {
      final dbPath = await getDatabasePath();
      final dbExists = await File(dbPath).exists();
      final shouldDownload = await shouldDownloadDatabase();

      // Return existing path if database is fresh
      if (dbExists && !shouldDownload) {
        debugPrint('Database downloaded recently');
        return dbPath;
      }

      // Check for server updates
      final latestChecksum = await fetchLatestDbChecksum();
      if (latestChecksum == null) {
        debugPrint('Failed to fetch checksum');
        return null;
      }

      final currentChecksum = await getSetting(Setting.dbChecksum);
      final needsUpdate =
          !dbExists || shouldDownload || latestChecksum != currentChecksum;

      if (!needsUpdate) {
        debugPrint('Database is up to date');
        return dbPath;
      }

      // Update checksum if changed
      if (latestChecksum != currentChecksum) {
        await setSetting(Setting.dbChecksum, latestChecksum);
        debugPrint('Checksum updated: $currentChecksum -> $latestChecksum');
      }

      // Download database
      final downloadedPath = await downloadAndExtractDatabase();
      if (downloadedPath != null) {
        await setSetting(Setting.lastDbDownload, DateTime.now());
        debugPrint('Database updated successfully');
      }

      return downloadedPath;
    } catch (e) {
      debugPrint('Error updating database: $e');
      return null;
    }
  }

  // ============================================================================
  // DATABASE QUERIES
  // ============================================================================
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
      SELECT
          service_id
      FROM
          [gtfs.base.vw_calendar_active_services]
      WHERE
          $dayColumn = '1'
          AND start_date <= strftime('%Y%m%d', 'now')
          AND end_date >= strftime('%Y%m%d', 'now')
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
          t.trip_id,
          r.route_color,
          raf.route_secondary_route_color,
          st.departure_time,
          hs.trip_destination as trip_headsign,
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

  static Future<List<Trip>> getTrainsForDay(
      String stopName, DateTime date) async {
    final dbPath = await updatePathDatabase();
    if (dbPath == null) {
      throw Exception('Failed to initialize database.');
    }

    final db = await openDatabase(dbPath, readOnly: true);
    try {
      tz.initializeTimeZones();
      final nyLocation = tz.getLocation('America/New_York');
      final tzDateTime =
          tz.TZDateTime(nyLocation, date.year, date.month, date.day);
      final dayColumn = _getDayColumn(tzDateTime);

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
      final dateOnly =
          DateTime(tzDateTime.year, tzDateTime.month, tzDateTime.day);
      return results
          .map((row) => Trip.fromMap(row, date: dateOnly))
          .toList();
    } finally {
      await db.close();
    }
  }

  static Future<List<Stop>> getTripStops(String tripId) async {
    final dbPath = await updatePathDatabase();
    if (dbPath == null) {
      throw Exception('Failed to initialize database.');
    }

    final db = await openDatabase(dbPath, readOnly: true);
    try {
      debugPrint("running db query for trip_id: $tripId");

      final results = await db.rawQuery('''
        SELECT
            s.stop_name,
            r.route_color,
            raf.route_secondary_route_color,
            st.departure_time,
            st.stop_sequence
        FROM
            [gtfs.base.trips] t
            JOIN [gtfs.base.stop_times] st ON t.trip_id = st.trip_id
            JOIN [gtfs.base.stops] s ON s.stop_id = st.stop_id
            -- Join with additional tables for route colors
            JOIN [gtfs.base.routes] r ON r.route_id = t.route_id
            JOIN [gtfs.master.routes_additional_info] raf ON raf.route_id = r.route_id
        WHERE
            st.trip_id = ?
        ORDER BY
            CAST(st.stop_sequence AS INTEGER)
      ''', [tripId]);

      debugPrint("found ${results.length} stops for trip $tripId");

      return results.map((row) => Stop.fromMap(row)).toList();
    } finally {
      await db.close();
    }
  }
}
