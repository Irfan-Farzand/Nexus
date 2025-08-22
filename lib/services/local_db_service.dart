import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDbService {
  static Database? _db;

  static Future<Database> getDb() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'tasknest.db'),
      version: 1,
      onCreate: (db, version) async {
        // Tasks table
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            dueDate TEXT,
            priority TEXT,
            assignedUserId TEXT,
            assignedTeamId TEXT,
            goalId TEXT,
            isCompleted INTEGER,
            createdBy TEXT,
            status TEXT,
            updatedAt TEXT,
            fileUrl TEXT
          )
        ''');

        // Comments table
        await db.execute('''
          CREATE TABLE comments (
            id TEXT PRIMARY KEY,
            taskId TEXT,
            userId TEXT,
            content TEXT,
            createdAt TEXT
          )
        ''');

        // Teams table
        await db.execute('''
          CREATE TABLE teams (
            id TEXT PRIMARY KEY,
            name TEXT,
            description TEXT,
            memberIds TEXT, -- comma separated user ids
            createdBy TEXT,
            createdAt TEXT
          )
        ''');

        // Goals table
        await db.execute('''
          CREATE TABLE goals (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            dueDate TEXT,
            createdBy TEXT,
            createdAt TEXT,
            updatedAt TEXT
          )
        ''');

        // Users table
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT,
            fcmToken TEXT,
            createdAt TEXT
          )
        ''');
      },
    );
    return _db!;
  }
}
