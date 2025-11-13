import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/medicament_model.dart';

class MedicamentRepository {
  static const String _assetPath = 'assets/data/medicaments.json';
  static const String _fileName = 'medicaments.json';

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, _fileName));

    if (!await file.exists()) {
      try {
        final data = await rootBundle.loadString(_assetPath);
        await file.writeAsString(data);
      } catch (_) {
        await file.writeAsString('[]');
      }
    }

    return file;
  }

  Future<List<Medicament>> loadMedicaments() async {
    final file = await _getLocalFile();
    final content = await file.readAsString();

    if (content.trim().isEmpty) return [];

    final List decoded = json.decode(content) as List;
    return decoded
        .map((e) => Medicament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveMedicaments(List<Medicament> medicaments) async {
    final file = await _getLocalFile();
    final List<Map<String, dynamic>> jsonList =
    medicaments.map((m) => m.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }
}
