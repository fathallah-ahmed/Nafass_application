import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/models/prise_medicament_model.dart';
import '../data/models/medicament_model.dart';
import '../data/repositories/prises_repository.dart';

class PrisesProvider extends ChangeNotifier {
  final PrisesRepository _repo = PrisesRepository();

  List<PriseMedicament> _prises = [];
  List<PriseMedicament> get prises => _prises;

  List<PriseMedicament> prisesPourMedicament(String medicamentId) {
    return _prises
        .where((p) => p.medicamentId == medicamentId)
        .toList()
      ..sort((a, b) => a.dateHeurePrevue.compareTo(b.dateHeurePrevue));
  }

  Map<StatutPrise, int> statistiquesPourMedicament(String medicamentId) {
    final Map<StatutPrise, int> stats = {
      for (final statut in StatutPrise.values) statut: 0,
    };

    for (final prise in _prises) {
      if (prise.medicamentId == medicamentId) {
        stats[prise.statut] = (stats[prise.statut] ?? 0) + 1;
      }
    }
    return stats;
  }

  Future<void> load() async {
    _prises = await _repo.loadPrises();
    _sortPrises();
    notifyListeners();
  }

  Future<void> genererPrisesPourMedicament(
      Medicament m, {
        DateTime? startAt,
      }) async {
    final DateTime startBoundary = DateTime(
      m.debut.year,
      m.debut.month,
      m.debut.day,
    );
    final DateTime initial = startAt != null
        ? DateTime(startAt.year, startAt.month, startAt.day)
        : startBoundary;

    DateTime current = initial.isBefore(startBoundary) ? startBoundary : initial;

    final DateTime endBoundary = DateTime(
      m.fin.year,
      m.fin.month,
      m.fin.day,
    );

    if (current.isAfter(endBoundary)) {
      return;
    }

    final List<PriseMedicament> nouvelles = [];

    while (!current.isAfter(endBoundary)) {
      for (final heure in m.heures) {
        final parts = heure.split(':');
        if (parts.length != 2) continue;
        final h = int.tryParse(parts[0]);
        final min = int.tryParse(parts[1]);
        if (h == null || min == null) continue;

        final dateHeure = DateTime(
          current.year,
          current.month,
          current.day,
          h,
          min,
        );

        final alreadyExists = _prises.any(
              (p) =>
          p.medicamentId == m.id &&
              p.dateHeurePrevue.isAtSameMomentAs(dateHeure),
        );

        if (!alreadyExists) {
          nouvelles.add(
            PriseMedicament(
              id: const Uuid().v4(),
              medicamentId: m.id,
              dateHeurePrevue: dateHeure,
            ),
          );
        }
      }

      current = current.add(const Duration(days: 1));
    }

    if (nouvelles.isEmpty) {
      return;
    }

    _prises.addAll(nouvelles);
    _sortPrises();
    await _repo.savePrises(_prises);
    notifyListeners();
  }

  Future<void> mettreAJourPrisesPourMedicament(Medicament m) async {
    _prises.removeWhere((p) =>
    p.medicamentId == m.id &&
        p.dateHeurePrevue.isAfter(DateTime.now()));

    await genererPrisesPourMedicament(
      m,
      startAt: DateTime.now(),
    );
  }

  Future<void> changerStatutPrise(
      String priseId, StatutPrise statut,
      {DateTime? nouvelleDate}) async {
    final index = _prises.indexWhere((p) => p.id == priseId);
    if (index == -1) return;

    final prise = _prises[index];

    prise.statut = statut;

    if (statut == StatutPrise.reportee) {
      if (nouvelleDate != null) {
        prise.dateHeurePrevue = nouvelleDate;
      }
      prise.dateHeureReelle = null;
    } else if (statut == StatutPrise.prevue) {
      prise.dateHeureReelle = null;
    } else {
      prise.dateHeureReelle = DateTime.now();
    }

    _sortPrises();

    await _repo.savePrises(_prises);
    notifyListeners();
  }

  Future<void> annulerPrisesFuturesPourMedicament(String medicamentId) async {
    _prises.removeWhere((p) =>
    p.medicamentId == medicamentId &&
        p.dateHeurePrevue.isAfter(DateTime.now()));

    await _repo.savePrises(_prises);
    notifyListeners();
  }

  Future<void> supprimerPrisesPourMedicament(String medicamentId) async {
    _prises.removeWhere((p) => p.medicamentId == medicamentId);
    _sortPrises();
    await _repo.savePrises(_prises);
    notifyListeners();
  }

  void _sortPrises() {
    _prises.sort((a, b) => a.dateHeurePrevue.compareTo(b.dateHeurePrevue));
  }
}
