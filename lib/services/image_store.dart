import 'dart:io';
import 'dart:math';

import '../data/db/connection.dart';

/// Copies user-picked image files into the app's `images/` folder and hands
/// back only the relative filename — the only thing that gets stored in the
/// database, so the catalogue survives the app moving to a new machine.
class ImageStore {
  ImageStore(this._storage);

  final AppStorage _storage;

  Future<String> importImage(String sourcePath) async {
    final extension = _extensionOf(sourcePath);
    final filename = '${_uniqueStem()}$extension';
    final destination = File(_storage.resolveImage(filename));
    await File(sourcePath).copy(destination.path);
    return filename;
  }

  Future<void> deleteImage(String? relativeName) async {
    if (relativeName == null) return;
    final file = File(_storage.resolveImage(relativeName));
    if (await file.exists()) await file.delete();
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    return dot == -1 ? '' : path.substring(dot);
  }

  String _uniqueStem() {
    final stamp = DateTime.now().microsecondsSinceEpoch;
    final rand = Random().nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'img_${stamp}_$rand';
  }
}
