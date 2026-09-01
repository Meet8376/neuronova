import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../db/database_helper.dart';

class MemoryItem {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final String dateLabel;
  final DateTime createdAt;

  const MemoryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.dateLabel,
    required this.createdAt,
  });

  factory MemoryItem.fromMap(Map<String, dynamic> map) {
    return MemoryItem(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      imagePath: map['image_path'] as String,
      dateLabel: map['date_label'] as String? ?? 'Memory',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'image_path': imagePath,
      'date_label': dateLabel,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}

class MemoryRepository {
  final _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  Future<List<MemoryItem>> getMemories() async {
    final db = await _db.database;
    final rows = await db.query('memories', orderBy: 'created_at DESC');
    return rows.map(MemoryItem.fromMap).toList();
  }

  Future<MemoryItem> addMemory({
    required String title,
    required String description,
    required String sourceImagePath,
    String dateLabel = 'Personal Memory',
  }) async {
    String finalPath = sourceImagePath;

    // If sourceImagePath is a local file picked from gallery/camera, copy to documents directory for permanent persistence
    if (!sourceImagePath.startsWith('assets/')) {
      try {
        final srcFile = File(sourceImagePath);
        if (await srcFile.exists()) {
          final appDir = await getApplicationDocumentsDirectory();
          final memoriesDir = Directory(p.join(appDir.path, 'memories'));
          if (!await memoriesDir.exists()) {
            await memoriesDir.create(recursive: true);
          }
          final ext = p.extension(sourceImagePath).isNotEmpty
              ? p.extension(sourceImagePath)
              : '.jpg';
          final newFileName = 'memory_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}$ext';
          final destPath = p.join(memoriesDir.path, newFileName);
          final savedFile = await srcFile.copy(destPath);
          finalPath = savedFile.path;
        }
      } catch (_) {
        finalPath = sourceImagePath;
      }
    }

    final item = MemoryItem(
      id: _uuid.v4(),
      title: title,
      description: description,
      imagePath: finalPath,
      dateLabel: dateLabel,
      createdAt: DateTime.now(),
    );

    final db = await _db.database;
    await db.insert('memories', item.toMap());
    return item;
  }

  Future<void> deleteMemory(String id) async {
    final db = await _db.database;
    final rows = await db.query('memories', where: 'id = ?', whereArgs: [id]);
    if (rows.isNotEmpty) {
      final imgPath = rows.first['image_path'] as String;
      if (!imgPath.startsWith('assets/')) {
        try {
          final file = File(imgPath);
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    await db.delete('memories', where: 'id = ?', whereArgs: [id]);
  }
}
