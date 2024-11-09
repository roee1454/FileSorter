import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._();
  static Database? _database;

  DBHelper._();

  factory DBHelper() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'files.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE files (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            label TEXT,
            filePath TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE
          )
        ''');

        // Insert default categories
        List<String> defaultCategories = [
          'עקדים',
          'תול',
          'הוראות סילוק',
          'הוראות אמלח',
          'הוראות זמניות',
          'אחרים'
        ];

        for (String category in defaultCategories) {
          await db.insert('categories', {'name': category},
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      },
    );
  }

  Future<void> insertFile(String label, String filePath) async {
    final db = await database;
    await db.insert('files', {'label': label, 'filePath': filePath});
  }

  Future<List<Map<String, dynamic>>> getFilesByLabel(String label) async {
    final db = await database;
    return await db.query('files', where: 'label = ?', whereArgs: [label]);
  }

  Future<void> deleteFile(int id) async {
    final db = await database;
    await db.delete('files', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> insertCategory(String name) async {
    final db = await database;
    await db.insert('categories', {'name': name},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> updateCategory(String oldName, String newName) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'categories',
        {'name': newName},
        where: 'name = ?',
        whereArgs: [oldName],
      );

      // Update file labels
      await txn.update(
        'files',
        {'label': newName},
        where: 'label = ?',
        whereArgs: [oldName],
      );
    });
  }

  Future<void> updateCategoryOrder(List<String> categories) async {
    final db = await database;
    for (int i = 0; i < categories.length; i++) {
      await db.update(
        'categories',
        {'position': i},
        where: 'name = ?',
        whereArgs: [categories[i]],
      );
    }
  }

  Future<void> deleteCategory(String name) async {
    final db = await database;
    await db.delete('categories', where: 'name = ?', whereArgs: [name]);
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('categories');
    return List.generate(maps.length, (i) => maps[i]['name']);
  }
}
