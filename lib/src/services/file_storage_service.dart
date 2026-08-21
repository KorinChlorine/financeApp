import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

class FileStorageService {
  Future<String?> exportPdf(List<int> bytes) async {
    final result = await FilePicker.platform.saveFile(
      fileName: 'khoraise-report.pdf',
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null) {
      return null;
    }

    final file = File(result);
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    return result;
  }

  Future<String?> exportJson(String jsonData) async {
    final result = await FilePicker.platform.saveFile(
      fileName: 'khoraise-export.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) {
      return null;
    }

    final file = File(result);
    await file.create(recursive: true);
    await file.writeAsString(jsonData);
    return result;
  }

  Future<Map<String, dynamic>?> importJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.first;
    final rawData = file.bytes != null
        ? utf8.decode(file.bytes!)
        : await File(file.path!).readAsString();

    final decoded = jsonDecode(rawData);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return decoded;
  }
}
