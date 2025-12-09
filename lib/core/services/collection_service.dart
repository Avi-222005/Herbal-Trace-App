import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/collection_event.dart';

class CollectionService {
  static const String baseUrl = 'https://herbal-trace-production.up.railway.app';
  static const String bearerToken =
      "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiJhZG1pbi0wMDEiLCJ1c2VybmFtZSI6ImFkbWluIiwiZW1haWwiOiJhZG1pbkBoZXJiYWx0cmFjZS5jb20iLCJmdWxsTmFtZSI6IlN5c3RlbSBBZG1pbmlzdHJhdG9yIiwib3JnTmFtZSI6IkhlcmJhbFRyYWNlIiwicm9sZSI6IkFkbWluIiwiaWF0IjoxNzY1MjM1MDU2LCJleHAiOjE3NjUzMjE0NTZ9.obOcf9rK86hhrf4Xqq_4MvKoM20qKICNI6TXfbls8B4";

  /// Fetch all collections from the backend database
  /// GET /api/v1/collections
  static Future<List<CollectionEvent>> fetchAllCollections() async {
    try {
      print('📡 Fetching collections from backend...');
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/collections'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $bearerToken',
        },
      ).timeout(const Duration(seconds: 30));

      print('✅ Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('📦 Response: $decoded');

        if (decoded['success'] == true && decoded['data'] != null) {
          final List collectionsData = decoded['data'] as List;
          print('✅ Found ${collectionsData.length} collections in database');

          // Convert backend data to CollectionEvent objects
          final List<CollectionEvent> events = collectionsData.map((item) {
            return CollectionEvent(
              id: item['id']?.toString() ?? item['_id']?.toString() ?? '',
              farmerId: item['farmerId']?.toString() ?? item['userId']?.toString() ?? '',
              species: item['species']?.toString() ?? '',
              latitude: _parseDouble(item['latitude']),
              longitude: _parseDouble(item['longitude']),
              imagePaths: _parseImagePaths(item['imagePaths'] ?? item['images']),
              weight: _parseDouble(item['quantity'] ?? item['weight']),
              moisture: _parseDouble(item['moisture']),
              temperature: _parseDouble(item['temperature']),
              humidity: _parseDouble(item['humidity']),
              weatherCondition: item['weatherCondition']?.toString(),
              timestamp: _parseTimestamp(item['harvestDate'] ?? item['timestamp'] ?? item['createdAt']),
              isSynced: true, // Data from backend is always synced
              blockchainHash: item['blockchainHash']?.toString() ?? item['id']?.toString(),
              commonName: item['commonName']?.toString(),
              scientificName: item['scientificName']?.toString(),
              harvestMethod: item['harvestMethod']?.toString(),
              partCollected: item['partCollected']?.toString(),
              altitude: _parseDouble(item['altitude']),
              latitudeAccuracy: _parseDouble(item['latitudeAccuracy']),
              longitudeAccuracy: _parseDouble(item['longitudeAccuracy']),
              locationName: item['locationName']?.toString(),
              soilType: item['soilType']?.toString(),
              notes: item['notes']?.toString(),
            );
          }).toList();

          return events;
        } else {
          print('⚠️  No data in response or success=false');
          return [];
        }
      } else {
        print('❌ Failed to fetch collections: ${response.statusCode}');
        print('❌ Response: ${response.body}');
        return [];
      }
    } catch (e) {
      print('💥 Error fetching collections from backend: $e');
      return [];
    }
  }

  /// Helper to parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Helper to parse image paths
  static List<String> _parseImagePaths(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    if (value is String) {
      // Handle comma-separated string or single image
      if (value.contains(',')) {
        return value.split(',').map((e) => e.trim()).toList();
      }
      return [value];
    }
    return [];
  }

  /// Helper to parse timestamp
  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    
    try {
      if (value is DateTime) return value;
      if (value is String) {
        // Try ISO8601 format first
        return DateTime.parse(value);
      }
      if (value is int) {
        // Unix timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
    } catch (e) {
      print('⚠️  Failed to parse timestamp: $value, error: $e');
    }
    
    return DateTime.now();
  }
}
