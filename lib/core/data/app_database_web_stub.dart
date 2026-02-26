// Stub for web - path_provider doesn't work on web
class Directory {
  String get path => '';
}

Future<Directory> getApplicationDocumentsDirectory() async {
  throw UnsupportedError('Not supported on web');
}
