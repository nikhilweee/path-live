import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';
import 'storage_service.dart';

class ApiService {
  static const String _baseUrl = 'https://www.panynj.gov/bin/portauthority';
  static const String _stationsEndpoint = '$_baseUrl/ridepath.json';
  static const String _alertsEndpoint = '$_baseUrl/everbridge/incidents';

  static Future<List<Station>> fetchStations() async {
    try {
      final response = await http.get(Uri.parse(_stationsEndpoint));

      if (response.statusCode != 200) {
        debugPrint('Failed to fetch stations: ${response.statusCode}');
        return [];
      }

      final jsonData = json.decode(response.body);
      return (jsonData['results'] as List)
          .map((json) => Station.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error fetching stations: $e');
      return [];
    }
  }

  static Future<List<Incident>?> fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse(_alertsEndpoint));

      if (response.statusCode != 200) return [];

      final jsonData = json.decode(response.body);
      if (jsonData['status'] != 'Success' || jsonData['data'] == null) {
        return [];
      }

      final incidents = (jsonData['data'] as List)
          .map((json) => Incident.fromJson(json))
          .toList();

      // Cache the alerts data
      await cacheAlerts(jsonData['data']);
      return incidents;
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      return null;
    }
  }

  // PATH database API functionality
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
}
