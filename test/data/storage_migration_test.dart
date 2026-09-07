// Renaming the application id renames the app-support directory on Linux and
// macOS, which would leave an installed shop looking at an empty folder while
// its catalogue and photos sat untouched under the old name. This is the
// path that carries them across.

import 'dart:io';

import 'package:benesnap/data/db/connection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory parent;

  setUp(() {
    parent = Directory.systemTemp.createTempSync('benesnap_storage_');
    addTearDown(() => parent.deleteSync(recursive: true));
  });

  Directory legacyWithCatalogue() {
    final legacy = Directory(p.join(parent.path, 'com.example.benesnap'))
      ..createSync(recursive: true);
    File(p.join(legacy.path, 'benesnap.sqlite')).writeAsStringSync('old db');
    Directory(p.join(legacy.path, 'images')).createSync();
    File(p.join(legacy.path, 'images', 'photo.png')).writeAsStringSync('img');
    return legacy;
  }

  Directory newRoot() =>
      Directory(p.join(parent.path, 'com.benesnap.kiosk'))
        ..createSync(recursive: true);

  test('adopts a catalogue left behind under the old application id', () async {
    final legacy = legacyWithCatalogue();
    final root = newRoot();

    await AppStorage.adoptLegacyDirectory(root);

    final storage = AppStorage(root);
    expect(await storage.databaseFile.readAsString(), 'old db');
    expect(await File(storage.resolveImage('photo.png')).exists(), isTrue);
    // Moved, not copied: two catalogues that both look real is worse than one.
    expect(await legacy.exists(), isFalse);
  });

  test('leaves an already-populated new location alone', () async {
    legacyWithCatalogue();
    final root = newRoot();
    File(p.join(root.path, 'benesnap.sqlite')).writeAsStringSync('current db');

    await AppStorage.adoptLegacyDirectory(root);

    // The shop has been using the renamed build; its real catalogue is here.
    expect(await AppStorage(root).databaseFile.readAsString(), 'current db');
  });

  test('does nothing on a fresh install with no legacy folder', () async {
    final root = newRoot();

    await AppStorage.adoptLegacyDirectory(root);

    expect(await AppStorage(root).databaseFile.exists(), isFalse);
  });
}
