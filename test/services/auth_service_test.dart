import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/repositories/admin_repository.dart';
import 'package:benesnap/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

class _FakeClock {
  DateTime _now = DateTime.utc(2026, 1, 1);

  DateTime call() => _now;

  void advance(Duration by) => _now = _now.add(by);
}

void main() {
  late AppDatabase db;
  late AdminRepository admins;
  late _FakeClock clock;
  late AuthService auth;

  setUp(() async {
    db = createTestDatabase();
    admins = AdminRepository(db);
    clock = _FakeClock();
    auth = AuthService(admins, now: clock.call);
    await auth.createAdmin('shopowner', 'correct-horse-battery');
  });

  group('createAdmin', () {
    test('never stores the plaintext password', () async {
      final hash = await admins.passwordHashFor('shopowner');
      expect(hash, isNot(contains('correct-horse-battery')));
    });

    test('is case-sensitive-safe: username is stored trimmed', () async {
      await auth.createAdmin('  padded  ', 'whatever-password');
      expect(await admins.passwordHashFor('padded'), isNotNull);
    });
  });

  group('login', () {
    test('succeeds with the right password', () async {
      final failure = await auth.login('shopowner', 'correct-horse-battery');
      expect(failure, isNull);
    });

    test('rejects the wrong password', () async {
      final failure = await auth.login('shopowner', 'wrong-password');
      expect(failure?.reason, LoginFailureReason.invalidCredentials);
    });

    test(
      'rejects an unknown username the same way as a wrong password',
      () async {
        final failure = await auth.login('nobody', 'anything');
        expect(failure?.reason, LoginFailureReason.invalidCredentials);
      },
    );

    test('a successful login resets the failed-attempt counter', () async {
      for (var i = 0; i < 4; i++) {
        await auth.login('shopowner', 'wrong');
      }
      expect((await auth.login('shopowner', 'correct-horse-battery')), isNull);

      // Counter was reset by the success, so this is attempt 1, not 5.
      final failure = await auth.login('shopowner', 'wrong');
      expect(failure?.reason, LoginFailureReason.invalidCredentials);
    });
  });

  group('lockout', () {
    test('the 5th consecutive failure locks the account out', () async {
      for (var i = 0; i < 4; i++) {
        final failure = await auth.login('shopowner', 'wrong');
        expect(failure?.reason, LoginFailureReason.invalidCredentials);
      }

      final fifth = await auth.login('shopowner', 'wrong');
      expect(fifth?.reason, LoginFailureReason.lockedOut);
      expect(fifth?.lockoutRemaining, AuthService.lockoutDuration);
    });

    test('the correct password is still rejected while locked out', () async {
      for (var i = 0; i < 5; i++) {
        await auth.login('shopowner', 'wrong');
      }

      final attempt = await auth.login('shopowner', 'correct-horse-battery');
      expect(attempt?.reason, LoginFailureReason.lockedOut);
    });

    test('login is allowed again once the lockout has elapsed', () async {
      for (var i = 0; i < 5; i++) {
        await auth.login('shopowner', 'wrong');
      }

      clock.advance(AuthService.lockoutDuration + const Duration(seconds: 1));

      final attempt = await auth.login('shopowner', 'correct-horse-battery');
      expect(attempt, isNull);
    });

    test('lockout is scoped per username', () async {
      await auth.createAdmin('otherstaff', 'another-password');

      for (var i = 0; i < 5; i++) {
        await auth.login('shopowner', 'wrong');
      }

      final otherLogin = await auth.login('otherstaff', 'another-password');
      expect(otherLogin, isNull);
    });

    test('username comparison for lockout is case-insensitive', () async {
      for (var i = 0; i < 5; i++) {
        await auth.login('shopowner', 'wrong');
      }

      final attempt = await auth.login('SHOPOWNER', 'correct-horse-battery');
      expect(attempt?.reason, LoginFailureReason.lockedOut);
    });
  });

  group('updateCredentials', () {
    test('renames the account with no password given', () async {
      final failure = await auth.updateCredentials(
        currentUsername: 'shopowner',
        newUsername: 'newname',
      );

      expect(failure, isNull);
      expect(await admins.passwordHashFor('newname'), isNotNull);
      // The old password still works under the new name — untouched.
      expect(await auth.login('newname', 'correct-horse-battery'), isNull);
    });

    test(
      'does not require the current password for a username-only change',
      () async {
        final failure = await auth.updateCredentials(
          currentUsername: 'shopowner',
          newUsername: 'newname',
          currentPassword: null,
        );

        expect(failure, isNull);
      },
    );

    test('changes the password when the current one verifies', () async {
      final failure = await auth.updateCredentials(
        currentUsername: 'shopowner',
        newUsername: 'shopowner',
        currentPassword: 'correct-horse-battery',
        newPassword: 'new-password-123',
      );

      expect(failure, isNull);
      expect(await auth.login('shopowner', 'new-password-123'), isNull);
      expect(
        (await auth.login('shopowner', 'correct-horse-battery'))?.reason,
        LoginFailureReason.invalidCredentials,
      );
    });

    test('rejects a password change with the wrong current password', () async {
      final failure = await auth.updateCredentials(
        currentUsername: 'shopowner',
        newUsername: 'shopowner',
        currentPassword: 'not-the-password',
        newPassword: 'new-password-123',
      );

      expect(failure?.reason, LoginFailureReason.invalidCredentials);
      // The password must be unchanged.
      expect(await auth.login('shopowner', 'correct-horse-battery'), isNull);
    });

    test(
      'a failed password-change attempt counts toward the same lockout as login',
      () async {
        for (var i = 0; i < 5; i++) {
          await auth.updateCredentials(
            currentUsername: 'shopowner',
            newUsername: 'shopowner',
            currentPassword: 'wrong',
            newPassword: 'new-password-123',
          );
        }

        final attempt = await auth.login('shopowner', 'correct-horse-battery');
        expect(attempt?.reason, LoginFailureReason.lockedOut);
      },
    );
  });
}
