
// lib/features/consumption/data/repositories/consumption_repository.dart

import '../models/consumption_entry.dart';

/// Contrat du repository pour le suivi de consommation
abstract class ConsumptionRepository {
  /// Récupérer toutes les consommations d'un utilisateur
  Future<List<ConsumptionEntry>> getEntries(String userId);

  /// Ajouter une nouvelle consommation
  Future<void> addEntry(ConsumptionEntry entry);

  /// Modifier une consommation existante
  Future<void> updateEntry(ConsumptionEntry entry);

  /// Supprimer une consommation
  Future<void> deleteEntry(String id);

  /// Écouter en temps réel les consommations d'un utilisateur
  Stream<List<ConsumptionEntry>> watchEntries(String userId);
}
