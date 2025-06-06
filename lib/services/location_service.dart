import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';

import '../models/models.dart';

class LocationService {
  static const Map<String, LatLong> stationCoordinates = {
    "NWK": LatLong(40.7357214, -74.1613136),
    "HAR": LatLong(40.7376621, -74.1562678),
    "JSQ": LatLong(40.7319329, -74.0653761),
    "GRV": LatLong(40.7190822, -74.0445114),
    "EXP": LatLong(40.7169196, -74.0340219),
    "WTC": LatLong(40.7142535, -74.0194767),
    "NEW": LatLong(40.7246329, -74.0339884),
    "HOB": LatLong(40.7331754, -74.0302369),
    "CHR": LatLong(40.7341757, -74.0085746),
    "09S": LatLong(40.7354038, -74.0005162),
    "14S": LatLong(40.7365777, -73.9992338),
    "23S": LatLong(40.7425656, -73.993305),
    "33S": LatLong(40.7488743, -73.9886441),
  };

  static Future<bool> requestLocationPermission() async {
    final status = await Permission.location.request();

    if (status.isGranted) {
      return true;
    } else if (status.isPermanentlyDenied) {
      openAppSettings();
    }
    return false;
  }

  static String findClosestStation(Position position) {
    return stationCoordinates.entries
        .map((entry) => MapEntry(
            entry.key,
            Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              entry.value.latitude,
              entry.value.longitude,
            )))
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
  }

  static Future<String?> getClosestStation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      return findClosestStation(position);
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
}
