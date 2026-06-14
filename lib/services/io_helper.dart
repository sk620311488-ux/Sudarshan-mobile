
abstract class IoHelper {
  static Future<void> saveFile(String path, List<int> bytes) async {
    throw UnsupportedError('IO not supported on this platform');
  }

  static String get pathSeparator => '/';
}

// These are satisfied by the conditional imports in main or where used
// but we'll use a better pattern.
