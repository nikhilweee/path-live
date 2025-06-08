import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/models.dart';

class StorageService {
  static const String _filtersKey = 'filters';
  static const String _cachedAlertsKey = 'cached_alerts';
  static const String _authKeyKey = 'auth_key';
  static const String _dbChecksumKey = 'db_checksum';
  static const String _lastDbDownloadKey = 'last_db_download';

  // Default values for AUTH_KEY and DB_CHECKSUM
  static const String _defaultAuthKey = "603b1ed9-b5ab-4827-8606-6b501cf50d9e";
  static const String _defaultDbChecksum = "499C6586DE8D66E0028A71F21EB9E55C";

  static Future<List<String>> loadFilters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_filtersKey) ?? [];
    } catch (e) {
      debugPrint('Error loading filters: $e');
      return [];
    }
  }

  static Future<void> saveFilters(List<String> filters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_filtersKey, filters);
    } catch (e) {
      debugPrint('Error saving filters: $e');
    }
  }

  static Future<List<Incident>> loadCachedAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedAlertsJson = prefs.getString(_cachedAlertsKey);

      if (cachedAlertsJson != null) {
        final List<dynamic> alertsList = json.decode(cachedAlertsJson);
        return alertsList.map((json) => Incident.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error loading cached alerts: $e');
    }
    return [];
  }

  static Future<void> cacheAlerts(List<dynamic> alertsData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedAlertsKey, json.encode(alertsData));
    } catch (e) {
      debugPrint('Error caching alerts: $e');
    }
  }

  // Methods for managing AUTH_KEY and DB_CHECKSUM
  static Future<String> getAuthKey() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_authKeyKey) ?? _defaultAuthKey;
    } catch (e) {
      debugPrint('Error loading auth key: $e');
      return _defaultAuthKey;
    }
  }

  static Future<void> setAuthKey(String authKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authKeyKey, authKey);
    } catch (e) {
      debugPrint('Error saving auth key: $e');
    }
  }

  static Future<String> getDbChecksum() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_dbChecksumKey) ?? _defaultDbChecksum;
    } catch (e) {
      debugPrint('Error loading DB checksum: $e');
      return _defaultDbChecksum;
    }
  }

  static Future<void> setDbChecksum(String dbChecksum) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dbChecksumKey, dbChecksum);
    } catch (e) {
      debugPrint('Error saving DB checksum: $e');
    }
  }

  // Methods for managing last DB download time
  static Future<DateTime?> getLastDbDownloadTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastDbDownloadKey);
      return timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(timestamp)
          : null;
    } catch (e) {
      debugPrint('Error loading last DB download time: $e');
      return null;
    }
  }

  static Future<void> setLastDbDownloadTime(DateTime dateTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastDbDownloadKey, dateTime.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving last DB download time: $e');
    }
  }

  static Future<bool> shouldDownloadDatabase() async {
    try {
      final lastDownload = await getLastDbDownloadTime();
      if (lastDownload == null) return true; // Never downloaded

      final timeSinceLastDownload = DateTime.now().difference(lastDownload);
      return timeSinceLastDownload.inHours >= 6;
    } catch (e) {
      debugPrint('Error checking if should download database: $e');
      return true; // Default to downloading on error
    }
  }
}
