import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

import '../models/models.dart';
import 'storage_service.dart';

class ApiService {
  static const String _baseUrl = 'https://www.panynj.gov/bin/portauthority';
  static const String _stationsEndpoint = '$_baseUrl/ridepath.json';
  static const String _alertsEndpoint = '$_baseUrl/everbridge/incidents';

  static Future<List<Station>> fetchStations() async {
    try {
      final response = await http.get(Uri.parse(_stationsEndpoint));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return (jsonData['results'] as List)
            .map((json) => Station.fromJson(json))
            .toList();
      } else {
        debugPrint('Failed to fetch stations: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching stations: $e');
      return [];
    }
  }

  static Future<List<Incident>?> fetchAlerts() async {
    try {
      final response = await http.get(Uri.parse(_alertsEndpoint));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'Success' && jsonData['data'] != null) {
          final incidents = (jsonData['data'] as List)
              .map((json) => Incident.fromJson(json))
              .toList();
          
          // Cache the alerts data
          await StorageService.cacheAlerts(jsonData['data']);
          
          return incidents;
        }
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching alerts: $e');
      return null;
    }
  }
}
