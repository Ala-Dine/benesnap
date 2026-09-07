import 'dart:io';

import 'package:benesnap/data/db/connection.dart';
import 'package:benesnap/data/exceptions.dart';
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
    test('a dotted directory name is not mistaken for an extension', () async {
      // A real path this happens on: /home/someone/photos.2024/scan.
      // Scanning the whole path for the last '.' yields '.2024/scan', and
      // the copy then lands in a directory that doesn't exist.
      final dotted = Directory(p.join(tempDir.path, 'photos.2024'))
        ..createSync();
      final noExtension = File(p.join(dotted.path, 'scan'))
        ..writeAsBytesSync([9]);

      final filename = await images.importImage(noExtension.path);

      expect(filename, isNot(contains('/')));
      expect(await File(storage.resolveImage(filename)).exists(), isTrue);
    });

    test('an unreadable source is reported as an AppException', () async {
      // Never a raw FileSystemException: exceptions.dart's whole contract is
      // that nothing the screen catches carries a raw exception string.
      await expectLater(
        images.importImage(p.join(tempDir.path, 'does_not_exist.png')),
        throwsA(isA<ImageException>()),
      );
    });

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
    test('never throws, even when the file cannot be removed', () async {
      // ProductFormScreen calls this from dispose() as a fire-and-forget
      // future, where a rejection has nowhere to go but the root zone.
      // A directory standing where the file should be is the cheapest way
      // to make the delete actually fail.
      Directory(storage.resolveImage('img_locked.png')).createSync();
      Directory(
        p.join(storage.resolveImage('img_locked.png'), 'child'),
      ).createSync();

      await expectLater(images.deleteImage('img_locked.png'), completes);
    });

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
