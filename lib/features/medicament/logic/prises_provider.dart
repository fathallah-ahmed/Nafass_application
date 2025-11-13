import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../data/models/prise_medicament_model.dart';
import '../data/models/medicament_model.dart';
import '../data/repositories/prises_repository.dart';

class PrisesProvider extends ChangeNotifier {
  final PrisesRepository _repo = PrisesRepository();

  List<PriseMedicament> _prises = [];
  List<PriseMedicament> get prises => _prises;

  Future<void> load() async {
    _prises = await _repo.loadPrises();
    notifyListeners();
  }

  Future<void> genererPrisesPourMedicament(Medicament m) async {
    List<PriseMedicament> nouvelles = [];

    DateTime current = m.debut;

    while (current.isBefore(m.fin.add(const Duration(days: 1)))) {
      for (String heure in m.heures) {
        final parts = heure.split(":");
        final h = int.parse(parts[0]);
        final min = int.parse(parts[1]);

        final dateHeure = DateTime(
          current.year,
          current.month,
          current.day,
          h,
          min,
        );

        nouvelles.add(
          PriseMedicament(
            id: const Uuid().v4(),
            medicamentId: m.id,
            dateHeurePrevue: dateHeure,
          ),
        );
      }

      current = current.add(const Duration(days: 1));
    }

    _prises.addAll(nouvelles);
    await _repo.savePrises(_prises);
    notifyListeners();
  }

  Future<void> mettreAJourPrisesPourMedicament(Medicament m) async {
    _prises.removeWhere((p) =>
    p.medicamentId == m.id &&
        p.dateHeurePrevue.isAfter(DateTime.now()));

    await genererPrisesPourMedicament(m);
  }

  Future<void> changerStatutPrise(
      String priseId, StatutPrise statut,
      {DateTime? nouvelleDate}) async {
    final index = _prises.indexWhere((p) => p.id == priseId);
    if (index == -1) return;

    final prise = _prises[index];

    prise.statut = statut;
    prise.dateHeureReelle = DateTime.now();

    if (statut == StatutPrise.reportee && nouvelleDate != null) {
      prise.dateHeurePrevue = nouvelleDate;
    }

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
    await _repo.savePrises(_prises);
    notifyListeners();
  }
}
