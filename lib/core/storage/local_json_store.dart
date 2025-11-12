import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
/// A simple utility that keeps a JSON file in a writable project directory in
/// sync with an asset bundled with the app. The asset acts as the initial seed
/// while subsequent reads/writes operate on the local copy.
class LocalJsonStore {
  LocalJsonStore({
    this.assetBasePath = 'assets/data',
    this.runtimeDirectory = 'data_dev',
  });

  final String assetBasePath;
  final String runtimeDirectory;

  Directory? _cachedDirectory;

  Future<Directory> _resolveRuntimeDirectory() async {
    if (_cachedDirectory != null) {
      return _cachedDirectory!;
    }


    Directory directory;

    if (kIsWeb) {
      directory = Directory(runtimeDirectory);
    } else {
      try {
        final supportDirectory = await getApplicationSupportDirectory();
        directory = Directory(p.join(supportDirectory.path, runtimeDirectory));
      } on MissingPluginException {
        directory = Directory(runtimeDirectory);
      }
    }

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    _cachedDirectory = directory;
    return directory;
  }

  Future<File> _resolveFile(String fileName) async {
    final directory = await _resolveRuntimeDirectory();
    final file = File('${directory.path}/$fileName');

    if (!await file.exists()) {
      final assetPath = '$assetBasePath/$fileName';
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