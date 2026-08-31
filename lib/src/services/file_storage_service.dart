import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

class FileStorageService {
  Future<String?> exportPdf(List<int> bytes) async {
    final result = await FilePicker.saveFile(
      fileName: 'khoraise-report.pdf',
      bytes: Uint8List.fromList(bytes),
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    return result?.toFilePath();
  }

  Future<String?> exportJson(String jsonData) async {
    final result = await FilePicker.saveFile(
      fileName: 'khoraise-export.json',
      bytes: Uint8List.fromList(utf8.encode(jsonData)),
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    return result?.toFilePath();
  }

  Future<Map<String, dynamic>?> importJson() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result.isEmpty) {
      return null;
    }

    final bytes = await result.first.readAsBytes();
    final rawData = utf8.decode(bytes);

    final decoded = jsonDecode(rawData);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return decoded;
  }
}
