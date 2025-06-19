import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/models.dart';

// Storage type definitions
enum StorageType {
  string,
  integer,
  stringList,
  dateTime,
  boolean,
}

// Single enum for ALL storage keys with type safety
enum Setting<T> {
  // App configuration
  authKey<String>(
      'auth_key', "603b1ed9-b5ab-4827-8606-6b501cf50d9e", StorageType.string),
  dbChecksum<String>(
      'db_checksum', "499C6586DE8D66E0028A71F21EB9E55C", StorageType.string),
  lastDbDownload<DateTime?>('last_db_download', null, StorageType.dateTime),
  lastAlertsFetch<DateTime?>('last_alerts_fetch', null, StorageType.dateTime),

  // Train display settings
  progressBarDuration<int>('progress_bar_duration', 30, StorageType.integer),
  countdownThreshold<int>('countdown_threshold', 300, StorageType.integer),

  // User data
  filters<List<String>>('filters', [], StorageType.stringList),
  hasImportantAlerts<bool>('has_important_alerts', false, StorageType.boolean),
  cachedAlertsJson<String>('cached_alerts', '', StorageType.string);

  const Setting(this.key, this.defaultValue, this.storageType);
  final String key;
  final T defaultValue;
  final StorageType storageType;
}

// Cached SharedPreferences instance
SharedPreferences? _prefs;
Future<SharedPreferences> get _instance async {
  _prefs ??= await SharedPreferences.getInstance();
  return _prefs!;
}

// The only two functions you need!
Future<T> getSetting<T>(Setting<T> setting) async {
  try {
    final preferences = await _instance;
    final key = setting.key;
    final defaultValue = setting.defaultValue;

    // Handle each type based on the storage type
    switch (setting.storageType) {
      case StorageType.string:
        return (preferences.getString(key) ?? defaultValue) as T;

      case StorageType.integer:
        return (preferences.getInt(key) ?? defaultValue) as T;

      case StorageType.stringList:
        return List<String>.from(
                preferences.getStringList(key) ?? defaultValue as List<String>)
            as T;

      case StorageType.dateTime:
        final timestamp = preferences.getInt(key);
        return (timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(timestamp)
            : defaultValue) as T;

      case StorageType.boolean:
        return (preferences.getBool(key) ?? defaultValue) as T;
    }
  } catch (e) {
    debugPrint('Error loading ${setting.key}: $e');
    return setting.defaultValue;
  }
}

Future<void> setSetting<T>(Setting<T> setting, T value) async {
  try {
    final preferences = await _instance;
    final key = setting.key;

    // Handle each type based on the storage type
    switch (setting.storageType) {
      case StorageType.string:
        await preferences.setString(key, value as String);

      case StorageType.integer:
        await preferences.setInt(key, value as int);

      case StorageType.stringList:
        await preferences.setStringList(key, value as List<String>);

      case StorageType.dateTime:
        final dateTime = value as DateTime?;
        if (dateTime != null) {
          await preferences.setInt(key, dateTime.millisecondsSinceEpoch);
        } else {
          await preferences.remove(key);
        }

      case StorageType.boolean:
        await preferences.setBool(key, value as bool);
    }
  } catch (e) {
    debugPrint('Error saving ${setting.key}: $e');
  }
}

// Utility functions for common operations
Future<void> resetAllTrainSettings() async {
  await Future.wait([
    setSetting(
        Setting.progressBarDuration, Setting.progressBarDuration.defaultValue),
    setSetting(
        Setting.countdownThreshold, Setting.countdownThreshold.defaultValue),
  ]);
}

Future<bool> shouldDownloadDatabase() async {
  try {
    final lastDownload = await getSetting(Setting.lastDbDownload);
    if (lastDownload == null) return true;
    return DateTime.now().difference(lastDownload).inHours >= 6;
  } catch (e) {
    debugPrint('Error checking database download status: $e');
    return true;
  }
}

Future<bool> shouldFetchAlerts() async {
  try {
    final lastFetch = await getSetting(Setting.lastAlertsFetch);
    if (lastFetch == null) return true;
    return DateTime.now().difference(lastFetch).inHours >= 1;
  } catch (e) {
    debugPrint('Error checking alerts fetch status: $e');
    return true;
  }
}

// Alert-specific functions
Future<List<Incident>> getCachedAlerts() async {
  try {
    final cachedAlertsJson = await getSetting(Setting.cachedAlertsJson);
    if (cachedAlertsJson.isEmpty) return [];

    final List<dynamic> alertsList = json.decode(cachedAlertsJson);
    return alertsList.map((json) => Incident.fromJson(json)).toList();
  } catch (e) {
    debugPrint('Error loading cached alerts: $e');
    return [];
  }
}

Future<void> cacheAlerts(List<dynamic> alertsData) async {
  await setSetting(Setting.cachedAlertsJson, json.encode(alertsData));
}
