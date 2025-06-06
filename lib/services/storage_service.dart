import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/models.dart';

class StorageService {
  static const String _filtersKey = 'filters';
  static const String _cachedAlertsKey = 'cached_alerts';

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
}
