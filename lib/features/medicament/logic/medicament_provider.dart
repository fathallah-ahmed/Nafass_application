import 'package:flutter/material.dart';

import '../data/models/medicament_model.dart';
import '../data/repositories/medicament_repository.dart';
import 'prises_provider.dart';

class MedicamentProvider extends ChangeNotifier {
  final MedicamentRepository _repo = MedicamentRepository();
  final PrisesProvider prisesProvider;

  MedicamentProvider({required this.prisesProvider});

  List<Medicament> _medicaments = [];
  List<Medicament> get medicaments => _filteredMedicaments(false);

  List<Medicament> get archivedMedicaments => _filteredMedicaments(true);

  List<Medicament> _filteredMedicaments(bool archived) {
    final meds = _medicaments
        .where((m) => m.archive == archived)
        .toList()
      ..sort((a, b) => a.debut.compareTo(b.debut));
    return meds;
  }

  Future<void> load() async {
    _medicaments = await _repo.loadMedicaments();
    notifyListeners();
  }

  Future<void> addMedicament(Medicament m) async {
    _medicaments.add(m);
    await _repo.saveMedicaments(_medicaments);

    await prisesProvider.genererPrisesPourMedicament(m);

    notifyListeners();
  }

  Future<void> updateMedicament(Medicament m) async {
    final index = _medicaments.indexWhere((x) => x.id == m.id);
    if (index == -1) return;

    _medicaments[index] = m;
    await _repo.saveMedicaments(_medicaments);

    await prisesProvider.mettreAJourPrisesPourMedicament(m);

    notifyListeners();
  }

  Future<void> archiveMedicament(String id) async {
    final index = _medicaments.indexWhere((x) => x.id == id);
    if (index == -1) return;

    _medicaments[index].archive = true;
    await _repo.saveMedicaments(_medicaments);

    await prisesProvider.annulerPrisesFuturesPourMedicament(id);

    notifyListeners();
  }

  Future<void> deleteMedicament(String id) async {
    _medicaments.removeWhere((x) => x.id == id);
    await _repo.saveMedicaments(_medicaments);

    await prisesProvider.supprimerPrisesPourMedicament(id);

    notifyListeners();
  }
}
