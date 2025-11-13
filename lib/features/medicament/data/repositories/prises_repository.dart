import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/prise_medicament_model.dart';

class PrisesRepository {
  static const String _fileName = 'prises_medicaments.json';

  Future<File> _getLocalFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, _fileName));

    if (!await file.exists()) {
      await file.writeAsString('[]');
    }

    return file;
  }

  Future<List<PriseMedicament>> loadPrises() async {
    final file = await _getLocalFile();
    final content = await file.readAsString();

    if (content.trim().isEmpty) return [];

    final List decoded = json.decode(content) as List;
    return decoded
        .map((e) => PriseMedicament.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePrises(List<PriseMedicament> prises) async {
    final file = await _getLocalFile();
    final List<Map<String, dynamic>> jsonList =
    prises.map((p) => p.toJson()).toList();
    await file.writeAsString(json.encode(jsonList));
  }
}
