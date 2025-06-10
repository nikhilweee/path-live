import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/models.dart';

class StorageService {
  // Storage keys
  static const String _filtersKey = 'filters';
  static const String _cachedAlertsKey = 'cached_alerts';
  static const String _authKeyKey = 'auth_key';
  static const String _dbChecksumKey = 'db_checksum';
  static const String _lastDbDownloadKey = 'last_db_download';

  // Train display settings keys
  static const String _previousTrainsCountKey = 'previous_trains_count';
  static const String _futureTrainsCountKey = 'future_trains_count';
  static const String _progressBarDurationKey = 'progress_bar_duration';
  static const String _countdownThresholdKey = 'countdown_threshold';

  // Default values
  static const String _defaultAuthKey = "603b1ed9-b5ab-4827-8606-6b501cf50d9e";
  static const String _defaultDbChecksum = "499C6586DE8D66E0028A71F21EB9E55C";

  // Train display settings configuration
  static const Map<String, int> _trainDisplayDefaults = {
    _previousTrainsCountKey: 5,
    _futureTrainsCountKey: 25,
    _progressBarDurationKey: 30,
    _countdownThresholdKey: 300,
  };

  // Generic helper methods
  static Future<T> _getValue<T>(
      String key, T defaultValue, String operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (T == String) {
        return (prefs.getString(key) ?? defaultValue) as T;
      } else if (T == int) {
        return (prefs.getInt(key) ?? defaultValue) as T;
      } else if (T == bool) {
        return (prefs.getBool(key) ?? defaultValue) as T;
      } else {
        throw ArgumentError('Unsupported type $T');
      }
    } catch (e) {
      debugPrint('Error $operation: $e');
      return defaultValue;
    }
  }

  static Future<void> _setValue<T>(
      String key, T value, String operation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (T == String) {
        await prefs.setString(key, value as String);
      } else if (T == int) {
        await prefs.setInt(key, value as int);
      } else if (T == bool) {
        await prefs.setBool(key, value as bool);
      } else {
        throw ArgumentError('Unsupported type $T');
      }
    } catch (e) {
      debugPrint('Error $operation: $e');
    }
  }

  // Filter methods
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

  // Alert methods
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

  // Configuration methods
  static Future<String> getAuthKey() =>
      _getValue(_authKeyKey, _defaultAuthKey, 'loading auth key');

  static Future<void> setAuthKey(String authKey) =>
      _setValue(_authKeyKey, authKey, 'saving auth key');

  static Future<String> getDbChecksum() =>
      _getValue(_dbChecksumKey, _defaultDbChecksum, 'loading DB checksum');

  static Future<void> setDbChecksum(String dbChecksum) =>
      _setValue(_dbChecksumKey, dbChecksum, 'saving DB checksum');

  // Database download time methods
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
      if (lastDownload == null) return true;
      return DateTime.now().difference(lastDownload).inHours >= 6;
    } catch (e) {
      debugPrint('Error checking if should download database: $e');
      return true;
    }
  }

  // Train display settings methods (unified approach)
  static Future<int> getPreviousTrainsCount() => _getValue(
      _previousTrainsCountKey,
      _trainDisplayDefaults[_previousTrainsCountKey]!,
      'loading previous trains count');

  static Future<void> setPreviousTrainsCount(int count) =>
      _setValue(_previousTrainsCountKey, count, 'saving previous trains count');

  static Future<int> getFutureTrainsCount() => _getValue(
      _futureTrainsCountKey,
      _trainDisplayDefaults[_futureTrainsCountKey]!,
      'loading future trains count');

  static Future<void> setFutureTrainsCount(int count) =>
      _setValue(_futureTrainsCountKey, count, 'saving future trains count');

  static Future<int> getProgressBarDuration() => _getValue(
      _progressBarDurationKey,
      _trainDisplayDefaults[_progressBarDurationKey]!,
      'loading progress bar duration');

  static Future<void> setProgressBarDuration(int duration) => _setValue(
      _progressBarDurationKey, duration, 'saving progress bar duration');

  static Future<int> getCountdownThreshold() => _getValue(
      _countdownThresholdKey,
      _trainDisplayDefaults[_countdownThresholdKey]!,
      'loading countdown threshold');

  static Future<void> setCountdownThreshold(int threshold) => _setValue(
      _countdownThresholdKey, threshold, 'saving countdown threshold');

  static Future<void> resetTrainDisplaySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _trainDisplayDefaults.keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Error resetting train display settings: $e');
    }
  }
}
