import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:neuronova/data/repositories/memory_repository.dart';
import 'package:neuronova/data/db/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('MemoryRepository CRUD & Image Tests', () {
    late MemoryRepository repo;

    setUp(() async {
      await DatabaseHelper.instance.initInMemoryDatabase();
      repo = MemoryRepository();
    });

    tearDown(() async {
      final db = await DatabaseHelper.instance.database;
      await db.close();
      DatabaseHelper.instance.setDatabaseForTesting(null);
    });

    test('Loads initial seeded memories', () async {
      final memories = await repo.getMemories();
      expect(memories.length, greaterThanOrEqualTo(3));
      expect(memories.any((m) => m.title == 'Family Garden Reunion'), isTrue);
      expect(memories.any((m) => m.imagePath.startsWith('assets/images/')), isTrue);
    });

    test('Add new memory item and retrieve from database', () async {
      final added = await repo.addMemory(
        title: 'Trip to Kaziranga',
        description: 'Watching the rhinos in the sunset with family.',
        sourceImagePath: 'assets/images/memory_family.png',
        dateLabel: 'Vacation Memory',
      );

      expect(added.id, isNotEmpty);
      expect(added.title, 'Trip to Kaziranga');

      final list = await repo.getMemories();
      expect(list.any((m) => m.id == added.id), isTrue);
    });

    test('Delete memory removes record from database', () async {
      final added = await repo.addMemory(
        title: 'Temporary Memory',
        description: 'To be deleted.',
        sourceImagePath: 'assets/images/memory_tea.png',
      );

      var list = await repo.getMemories();
      expect(list.any((m) => m.id == added.id), isTrue);

      await repo.deleteMemory(added.id);

      list = await repo.getMemories();
      expect(list.any((m) => m.id == added.id), isFalse);
    });
  });
}
