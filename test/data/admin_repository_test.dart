import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/exceptions.dart';
import 'package:benesnap/data/repositories/admin_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late AdminRepository admins;

  setUp(() {
    db = createTestDatabase();
    admins = AdminRepository(db);
  });

  group('isEmpty', () {
    test('true on a fresh database', () async {
      expect(await admins.isEmpty(), isTrue);
    });

    test('false once an admin exists', () async {
      await admins.create(username: 'owner', passwordHash: 'hash');
      expect(await admins.isEmpty(), isFalse);
    });
  });

  group('create', () {
    test('stores exactly the hash it was given', () async {
      await admins.create(username: 'owner', passwordHash: 'a-bcrypt-hash');
      expect(await admins.passwordHashFor('owner'), 'a-bcrypt-hash');
    });

    test('rejects a second admin differing only in case', () async {
      // The unique index is case-sensitive, so without a proactive check
      // both rows would exist and passwordHashFor could no longer tell them
      // apart.
      await admins.create(username: 'Owner', passwordHash: 'hash');

      await expectLater(
        admins.create(username: 'owner', passwordHash: 'other'),
        throwsA(isA<DuplicateUsernameException>()),
      );
    });

    test('rejects a second admin with the same username', () async {
      await admins.create(username: 'owner', passwordHash: 'hash-1');

      expect(
        () => admins.create(username: 'owner', passwordHash: 'hash-2'),
        throwsA(isA<DuplicateUsernameException>()),
      );
    });
  });

  group('passwordHashFor', () {
    test('finds the account whatever case it is typed in', () async {
      // The lockout counter in AuthService has always been keyed by the
      // lowercased name, so a case-sensitive lookup here meant typing
      // `owner` for an account created as `Owner` could never succeed —
      // while still counting toward that account's lockout.
      await admins.create(username: 'Owner', passwordHash: 'hash');

      expect(await admins.passwordHashFor('owner'), 'hash');
      expect(await admins.passwordHashFor('  OWNER '), 'hash');
    });

    test('null for an unknown username', () async {
      expect(await admins.passwordHashFor('nobody'), isNull);
    });
  });

  group('update', () {
    test('renames the account', () async {
      await admins.create(username: 'owner', passwordHash: 'hash');

      await admins.update(currentUsername: 'owner', newUsername: 'newname');

      expect(await admins.passwordHashFor('owner'), isNull);
      expect(await admins.passwordHashFor('newname'), 'hash');
    });

    test('replaces the password hash when one is given', () async {
      await admins.create(username: 'owner', passwordHash: 'old-hash');

      await admins.update(
        currentUsername: 'owner',
        newUsername: 'owner',
        newPasswordHash: 'new-hash',
      );

      expect(await admins.passwordHashFor('owner'), 'new-hash');
    });

    test('leaves the password hash untouched when none is given', () async {
      await admins.create(username: 'owner', passwordHash: 'unchanged-hash');

      await admins.update(currentUsername: 'owner', newUsername: 'owner');

      expect(await admins.passwordHashFor('owner'), 'unchanged-hash');
    });

    test('rejects renaming onto another admin\'s username', () async {
      await admins.create(username: 'owner', passwordHash: 'hash-1');
      await admins.create(username: 'staff', passwordHash: 'hash-2');

      expect(
        () => admins.update(currentUsername: 'owner', newUsername: 'staff'),
        throwsA(isA<DuplicateUsernameException>()),
      );

      // The rejected rename must not have partially applied.
      expect(await admins.passwordHashFor('owner'), 'hash-1');
    });

    test('reports a missing admin in plain language', () async {
      expect(
        () => admins.update(currentUsername: 'nobody', newUsername: 'someone'),
        throwsA(isA<AdminNotFoundException>()),
      );
    });
  });
}
