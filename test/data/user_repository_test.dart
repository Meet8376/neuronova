import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:neuronova/data/repositories/user_repository.dart';
import 'package:neuronova/data/db/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('UserRepository Tests', () {
    late UserRepository userRepo;

    setUp(() async {
      await DatabaseHelper.instance.initInMemoryDatabase();
      userRepo = UserRepository();
    });

    tearDown(() async {
      final db = await DatabaseHelper.instance.database;
      await db.close();
      DatabaseHelper.instance.setDatabaseForTesting(null);
    });

    test('Register new user and prevent duplicate username', () async {
      final regSuccess = await userRepo.registerUser(
        username: 'testpatient',
        displayName: 'Test Patient',
        password: 'securePassword123',
        role: 'patient',
      );
      expect(regSuccess, isTrue);

      final duplicate = await userRepo.registerUser(
        username: 'testpatient',
        displayName: 'Another Test',
        password: 'password',
        role: 'patient',
      );
      expect(duplicate, isFalse);
    });

    test('Validate credentials with correct and incorrect passwords', () async {
      await userRepo.registerUser(
        username: 'asha_worker_1',
        displayName: 'Ananya Sharma',
        password: 'ashaPassword456',
        role: 'admin',
      );

      final validUser = await userRepo.validateUser('asha_worker_1', 'ashaPassword456');
      expect(validUser, isNotNull);
      expect(validUser!['display_name'], 'Ananya Sharma');
      expect(validUser['role'], 'admin');

      final invalidPass = await userRepo.validateUser('asha_worker_1', 'wrongPassword');
      expect(invalidPass, isNull);

      final nonExistent = await userRepo.validateUser('ghost_user', 'anyPassword');
      expect(nonExistent, isNull);
    });
  });
}
