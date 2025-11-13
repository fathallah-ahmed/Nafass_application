enum StatutPrise {
  prevue,
  prise,
  oubliee,
  reportee,
}

class PriseMedicament {
  final String id;
  final String medicamentId;
  DateTime dateHeurePrevue;
  StatutPrise statut;
  DateTime? dateHeureReelle;

  PriseMedicament({
    required this.id,
    required this.medicamentId,
    required this.dateHeurePrevue,
    this.statut = StatutPrise.prevue,
    this.dateHeureReelle,
  });

  factory PriseMedicament.fromJson(Map<String, dynamic> json) {
    return PriseMedicament(
      id: json['id'],
      medicamentId: json['medicamentId'],
      dateHeurePrevue: DateTime.parse(json['dateHeurePrevue']),
      statut: StatutPrise.values.firstWhere(
            (e) => e.toString() == 'StatutPrise.${json['statut']}',
        orElse: () => StatutPrise.prevue,
      ),
      dateHeureReelle: json['dateHeureReelle'] != null
          ? DateTime.parse(json['dateHeureReelle'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'medicamentId': medicamentId,
      'dateHeurePrevue': dateHeurePrevue.toIso8601String(),
      'statut': statut.toString().split('.').last,
      'dateHeureReelle': dateHeureReelle?.toIso8601String(),
    };
  }
}
