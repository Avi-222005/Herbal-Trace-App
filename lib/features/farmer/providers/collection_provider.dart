import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/collection_event.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/collection_service.dart';

class CollectionProvider extends ChangeNotifier {
  final List<CollectionEvent> _events = [];
  bool _isLoading = false;

  List<CollectionEvent> get events => _events;
  List<CollectionEvent> get syncedEvents =>
      _events.where((e) => e.isSynced).toList();
  List<CollectionEvent> get unsyncedEvents =>
      _events.where((e) => !e.isSynced).toList();
  bool get isLoading => _isLoading;

  CollectionProvider() {
    loadEvents();
  }

  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _events.clear();
      
      // Load local collections from Hive
      final localEvents = StorageService.getAllCollectionEvents();
      
      // Fetch collections from backend database
      final backendEvents = await CollectionService.fetchAllCollections();
      
      // Merge local and backend events (avoid duplicates)
      final Map<String, CollectionEvent> mergedEvents = {};
      
      // Add local events first
      for (var event in localEvents) {
        mergedEvents[event.id] = event;
      }
      
      // Add backend events (will override local if same ID exists)
      for (var event in backendEvents) {
        if (!mergedEvents.containsKey(event.id)) {
          mergedEvents[event.id] = event;
        }
      }
      
      _events.addAll(mergedEvents.values);
      _events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      print('✅ Total collections loaded: ${_events.length} (Local: ${localEvents.length}, Backend: ${backendEvents.length})');
    } catch (e) {
      print('❌ Error loading events: $e');
      // Fall back to local only if backend fetch fails
      _events.addAll(StorageService.getAllCollectionEvents());
      _events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> createCollectionEvent({
    required String farmerId,
    required String species,
    required double latitude,
    required double longitude,
    required List<String> imagePaths,
    double? weight,
    double? moisture,
    double? temperature,
    double? humidity,
    String? weatherCondition,
    String? commonName,
    String? scientificName,
    String? harvestMethod,
    String? partCollected,
    double? altitude,
    double? latitudeAccuracy,
    double? longitudeAccuracy,
    String? locationName,
    String? soilType,
    String? notes,
    bool isSynced = false,
    String? blockchainHash,
  }) async {
    final event = CollectionEvent(
      id: const Uuid().v4(),
      farmerId: farmerId,
      species: species,
      latitude: latitude,
      longitude: longitude,
      imagePaths: imagePaths,
      weight: weight,
      moisture: moisture,
      temperature: temperature,
      humidity: humidity,
      weatherCondition: weatherCondition,
      timestamp: DateTime.now(),
      isSynced: isSynced,
      blockchainHash: blockchainHash,
      commonName: commonName,
      scientificName: scientificName,
      harvestMethod: harvestMethod,
      partCollected: partCollected,
      altitude: altitude,
      latitudeAccuracy: latitudeAccuracy,
      longitudeAccuracy: longitudeAccuracy,
      locationName: locationName,
      soilType: soilType,
      notes: notes,
    );

    await StorageService.saveCollectionEvent(event);
    _events.insert(0, event);
    notifyListeners();

    return event.id;
  }

  Future<void> deleteEvent(String eventId) async {
    await StorageService.deleteCollectionEvent(eventId);
    _events.removeWhere((e) => e.id == eventId);
    notifyListeners();
  }

  Future<void> updateSyncStatus(String eventId, String blockchainHash) async {
    await StorageService.markEventAsSynced(eventId, blockchainHash);

    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      _events[index].isSynced = true;
      _events[index].blockchainHash = blockchainHash;
      notifyListeners();
    }
  }

  Map<String, dynamic> getStatistics() {
    return {
      'totalSubmissions': _events.length,
      'syncedCount': syncedEvents.length,
      'pendingCount': unsyncedEvents.length,
      'totalWeight': _events
          .where((e) => e.weight != null)
          .fold<double>(0, (sum, e) => sum + e.weight!),
      'recentSubmissions': _events.take(5).toList(),
    };
  }
}
