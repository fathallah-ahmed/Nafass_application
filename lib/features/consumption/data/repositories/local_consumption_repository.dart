// lib/features/consumption/data/repositories/local_consumption_repository.dart

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/consumption_entry.dart';
import 'consumption_repository.dart';

/// Repository avec persistance locale via SharedPreferences.
/// Toutes les consommations sont stockées dans une seule clé "consumptions".
class LocalConsumptionRepository implements ConsumptionRepository {
  static const String _storageKey = 'consumptions';

  final StreamController<List<ConsumptionEntry>> _controller =
      StreamController<List<ConsumptionEntry>>.broadcast();

  List<ConsumptionEntry> _cache = [];

  LocalConsumptionRepository() {
    _loadAll();
  }

  /// Charge toutes les consommations depuis le stockage
  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null || jsonString.isEmpty) {
      _cache = [];
    } else {
      try {
        final List<dynamic> list = jsonDecode(jsonString) as List<dynamic>;
        _cache = list
            .map((e) => ConsumptionEntry.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _cache = [];
      }
    }

    _emit();
  }

  /// Sauvegarde toutes les consommations dans SharedPreferences
  Future<void> _saveAll() async {
    final prefs = await SharedPreferences.getInstance();
    final listJson = _cache.map((e) => e.toJson()).toList();
    final jsonString = jsonEncode(listJson);

    await prefs.setString(_storageKey, jsonString);
    _emit();
  }

  void _emit() {
    _controller.add(List.unmodifiable(_cache));
  }

  // ---------------------------------------------------------------------------
  // Implémentation du contrat ConsumptionRepository
  // ---------------------------------------------------------------------------

  @override
  Future<List<ConsumptionEntry>> getEntries(String userId) async {
    return _cache.where((e) => e.userId == userId).toList();
  }

  @override
  Future<void> addEntry(ConsumptionEntry entry) async {
    _cache.add(entry);
    await _saveAll();
  }

  @override
  Future<void> updateEntry(ConsumptionEntry entry) async {
    final index = _cache.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      _cache[index] = entry;
      await _saveAll();
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    _cache.removeWhere((e) => e.id == id);
    await _saveAll();
  }

  @override
  Stream<List<ConsumptionEntry>> watchEntries(String userId) {
    // On filtre par userId à chaque emission
    return _controller.stream.map(
      (entries) =>
          entries.where((e) => e.userId == userId).toList(),
    );
  }
}
