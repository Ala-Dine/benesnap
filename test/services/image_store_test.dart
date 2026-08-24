import 'dart:io';

import 'package:benesnap/data/db/connection.dart';
import 'package:benesnap/services/image_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempDir;
  late AppStorage storage;
  late ImageStore images;
  late File sourceFile;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('benesnap_image_store_test');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    storage = AppStorage(tempDir);
    await storage.imagesDirectory.create(recursive: true);
    images = ImageStore(storage);

    sourceFile = File(p.join(tempDir.path, 'source.png'))
      ..writeAsBytesSync([1, 2, 3, 4]);
  });

  group('importImage', () {
    test('copies the file into the images directory', () async {
      final filename = await images.importImage(sourceFile.path);

      final copied = File(storage.resolveImage(filename));
      expect(await copied.exists(), isTrue);
      expect(await copied.readAsBytes(), [1, 2, 3, 4]);
    });

    test('keeps the source file\'s extension', () async {
      final filename = await images.importImage(sourceFile.path);
      expect(filename, endsWith('.png'));
    });

    test('handles a source file with no extension', () async {
      final noExtFile = File(p.join(tempDir.path, 'noext'))
        ..writeAsBytesSync([1]);

      final filename = await images.importImage(noExtFile.path);

      expect(filename, isNot(contains('.')));
    });

    test('two imports of the same source get different filenames', () async {
      final first = await images.importImage(sourceFile.path);
      final second = await images.importImage(sourceFile.path);

      expect(first, isNot(second));
      expect(await File(storage.resolveImage(first)).exists(), isTrue);
      expect(await File(storage.resolveImage(second)).exists(), isTrue);
    });

    test('the original source file is left in place', () async {
      await images.importImage(sourceFile.path);
      expect(await sourceFile.exists(), isTrue);
    });
  });

  group('deleteImage', () {
    test('removes an existing image', () async {
      final filename = await images.importImage(sourceFile.path);
      final stored = File(storage.resolveImage(filename));
      expect(await stored.exists(), isTrue);

      await images.deleteImage(filename);

      expect(await stored.exists(), isFalse);
    });

    test('null is a no-op', () async {
      await images.deleteImage(null);
      // No exception — that's the whole test.
    });

    test('a filename that was never imported is a no-op', () async {
      await images.deleteImage('never-existed.png');
      // No exception — that's the whole test.
    });
  });
}
