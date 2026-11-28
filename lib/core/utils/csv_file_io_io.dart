import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<String?> pickCsvFile() async {
  final file = await FilePicker.pickFile(
    dialogTitle: 'Import contacts',
    type: FileType.custom,
    allowedExtensions: const ['csv'],
  );
  if (file == null) return null;
  return utf8.decode(await file.readAsBytes(), allowMalformed: true);
}

Future<bool> downloadCsvFile(String filename, String contents) async {
  final uri = await FilePicker.saveFile(
    dialogTitle: 'Export contacts',
    fileName: filename,
    bytes: Uint8List.fromList(utf8.encode(contents)),
    mimeType: 'text/csv',
  );
  return uri != null;
}
