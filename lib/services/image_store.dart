import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;

import '../data/db/connection.dart';
import '../data/exceptions.dart';

/// Copies user-picked image files into the app's `images/` folder and hands
/// back only the relative filename — the only thing that gets stored in the
/// database, so the catalogue survives the app moving to a new machine.
class ImageStore {
  ImageStore(this._storage);

  final AppStorage _storage;

  /// Copies [sourcePath] in and returns its new relative filename.
  ///
  /// Throws [ImageException] if the file can't be read or written — the
  /// caller is expected to show its message and let the shop pick another
  /// file.
  Future<String> importImage(String sourcePath) async {
    try {
      // `p.extension` stops at the last path separator; a bare
      // `lastIndexOf('.')` would happily reach back into a directory name
      // (`/home/a.b/photo` → `.b/photo`) and build a destination inside a
      // folder that doesn't exist.
      final filename = '${_uniqueStem()}${p.extension(sourcePath)}';
      final destination = File(_storage.resolveImage(filename));
      await File(sourcePath).copy(destination.path);
      return filename;
    } on Object catch (e) {
      throw ImageException(e);
    }
  }

  /// Best-effort removal of an image this app owns.
  ///
  /// Deliberately never throws. Every caller is cleaning up after something
  /// that already succeeded — a saved edit, a deleted product, a staged image
  /// the shop abandoned — and one of them runs from `dispose()`, where a
  /// rejected future has nowhere to go but the root zone. A file that is
  /// already gone is the outcome we wanted anyway, and a file that refuses to
  /// be deleted is not something a shop assistant can act on mid-task; it
  /// costs one stale file in a folder nothing reads by name.
  Future<void> deleteImage(String? relativeName) async {
    if (relativeName == null) return;
    try {
      await File(_storage.resolveImage(relativeName)).delete();
    } on Object {
      // Includes PathNotFoundException — see above.
    }
  }

  String _uniqueStem() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'img_${stamp}_$rand';
  }
}
