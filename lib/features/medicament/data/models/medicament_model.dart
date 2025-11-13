class Medicament {
  final String id;
  String nom;
  String dosage;
  List<String> heures;        // ["08:00", "20:00"]
  DateTime debut;
  DateTime fin;
  bool archive;

  Medicament({
    required this.id,
    required this.nom,
    required this.dosage,
    required this.heures,
    required this.debut,
    required this.fin,
    this.archive = false,
  });

  factory Medicament.fromJson(Map<String, dynamic> json) {
    return Medicament(
      id: json['id'],
      nom: json['nom'],
      dosage: json['dosage'],
      heures: List<String>.from(json['heures'] ?? []),
      debut: DateTime.parse(json['debut']),
      fin: DateTime.parse(json['fin']),
      archive: json['archive'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'dosage': dosage,
      'heures': heures,
      'debut': debut.toIso8601String(),
      'fin': fin.toIso8601String(),
      'archive': archive,
    };
  }
}
