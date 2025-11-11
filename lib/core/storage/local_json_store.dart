import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// A simple utility that keeps a JSON file in the application documents folder
/// in sync with an asset bundled with the app. The asset acts as the initial
/// seed while subsequent reads/writes operate on the local copy.
class LocalJsonStore {
  LocalJsonStore({this.baseAssetPath = 'assets/data'});

  final String baseAssetPath;

  Future<Directory> _ensureDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final dataDirectory = Directory('${directory.path}/$baseAssetPath');
    if (!await dataDirectory.exists()) {
      await dataDirectory.create(recursive: true);
    }
    return dataDirectory;
  }

  Future<File> _resolveFile(String fileName) async {
    final directory = await _ensureDirectory();
    final file = File('${directory.path}/$fileName');

    if (!await file.exists()) {
      final assetPath = '$baseAssetPath/$fileName';
      try {
        final assetContent = await rootBundle.loadString(assetPath);
        await file.writeAsString(assetContent);
      } on FlutterError {
        // If the asset is not bundled we still create an empty JSON array.
        await file.writeAsString('[]');
      }
    }

    return file;
  }

  Future<List<Map<String, dynamic>>> readList(String fileName) async {
    final file = await _resolveFile(fileName);
    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      return <Map<String, dynamic>>[];
    }

    final dynamic decoded = jsonDecode(content);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((map) => Map<String, dynamic>.from(map))
          .toList();
    }

    throw const FormatException('Expected a JSON list.');
  }

  Future<void> writeList(
      String fileName,
      List<Map<String, dynamic>> data,
      ) async {
    final file = await _resolveFile(fileName);
    final encoded = jsonEncode(data);
    await file.writeAsString(encoded);
  }
}