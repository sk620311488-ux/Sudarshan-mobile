import 'dart:io';

class IoHelper {
  static Future<void> saveFile(String filePath, List<int> bytes) async {
    final file = File(filePath);
    final directory = file.parent;
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    await file.writeAsBytes(bytes, flush: true);
  }

  static String get pathSeparator => Platform.pathSeparator;
}
