// lib/services/location_service.dart
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;

class LocationService {
  static Map<String, List<double>> barangayMap = {};
  static Map<String, List<double>> municipalityMap = {};
  static bool coordinatesLoaded = false;

  Future<void> loadCoordinates() async {
    if (coordinatesLoaded) return;

    try {
      String data = await rootBundle.loadString('assets/coords.txt');
      final List<dynamic> locations = jsonDecode(data);

      for (var loc in locations) {
        String? type = loc['type']?.toString().trim().toLowerCase();
        String? name = loc['name']?.toString().trim();
        double? lat = double.tryParse(loc['latitude'].toString());
        double? lon = double.tryParse(loc['longitude'].toString());

        if (type == null || name == null || lat == null || lon == null) continue;

        if (type == 'barangay') {
          barangayMap[name] = [lat, lon];
        } else if (type == 'municipality') {
          municipalityMap[name] = [lat, lon];
        }
      }

      // Fallback if no data loaded
      if (barangayMap.isEmpty && municipalityMap.isEmpty) {
        _setFallbackCoordinates();
      }

      coordinatesLoaded = true;
    } catch (e) {
      print('Error loading coordinates: $e, using fallback');
      _setFallbackCoordinates();
      coordinatesLoaded = true;
      rethrow; // Optional: rethrow if you want caller to handle
    }
  }

  void _setFallbackCoordinates() {
    barangayMap['Barangay Santa Monica'] = [14.0549, 121.3013];
    barangayMap['Barangay Santa Cruz'] = [14.0625, 121.3208];
    municipalityMap['San Pablo City'] = [14.0642, 121.3233];
    municipalityMap['Quezon Province'] = [13.9347, 121.9473];
  }

  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permission permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  List<double> getBarangayCoordinates(String barangay) {
    return barangayMap[barangay] ?? [14.5995, 120.9842]; // Default: Manila
  }

  List<double> getMunicipalityCoordinates(String municipality) {
    return municipalityMap[municipality] ?? [14.5995, 120.9842]; // Default: Manila
  }
}