import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/models.dart';
import 'storage_service.dart';

// Global alert notifier for UI updates
final alertNotifier = ValueNotifier<bool>(false);

class ApiService {
  // ============================================================================
  // STATION DATA API
  // ============================================================================

  static const String _baseUrl = 'https://www.panynj.gov/bin/portauthority';
  static const String _stationsEndpoint = '$_baseUrl/ridepath.json';

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

  // ============================================================================
  // ALERTS API
  // ============================================================================

  static const String _alertsEndpoint = '$_baseUrl/everbridge/incidents';

  /// Initializes the alert notifier with persisted state
  static Future<void> initializeAlertNotifier() async {
    final hasImportant = await getSetting(Setting.hasImportantAlerts);
    alertNotifier.value = hasImportant;
  }

  static Future<List<Alert>?> fetchAlerts() async {
    try {
      debugPrint("Fetching alerts");
      final response = await http.get(Uri.parse(_alertsEndpoint));

      if (response.statusCode != 200) return [];

      final jsonData = json.decode(response.body);
      if (jsonData['status'] != 'Success' || jsonData['data'] == null) {
        return [];
      }

      final alerts = (jsonData['data'] as List)
          .map((json) => Alert.fromJson(json))
          .toList();

      // Cache the alerts data
      await cacheAlerts(jsonData['data']);
      return alerts;
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      return null;
    }
  }

  static Future<List<Alert>?> loadAlerts({bool forceRefresh = true}) async {
    List<Alert>? alerts = [];

    if (!forceRefresh && !(await shouldFetchAlerts())) {
      alerts = await getCachedAlerts();
    } else {
      alerts = await fetchAlerts();
    }

    // Update alert status and notifier
    if (alerts != null) {
      final hasImportant =
          alerts.any((alert) => alert.subject != "PATHAlert - Elevators");

      // Update the notifier for immediate UI updates
      alertNotifier.value = hasImportant;

      // Persist to storage for app restarts
      await setSetting(Setting.hasImportantAlerts, hasImportant);
    }

    return alerts;
  }
}
