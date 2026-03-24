import 'dart:async';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/post.dart';

class DatabaseHelper {
  static const _databaseName = 'offline_posts_manager.db';
  static const _databaseVersion = 1;
  static const table = 'posts';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onConfigure: _onConfigure,
    );
  }

  FutureOr<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  Future<List<Post>> getAllPosts() async {
    try {
      final db = await database;
      final maps = await db.query(table, orderBy: 'createdAt DESC');
      return maps.map((map) => Post.fromMap(map)).toList();
    } on DatabaseException catch (e) {
      throw Exception('Database error while fetching posts: ${e.toString()}');
    } catch (e) {
      throw Exception('Unexpected error while fetching posts: $e');
    }
  }

  Future<Post> insertPost(Post post) async {
    try {
      final db = await database;
      final id = await db.insert(table, post.toMap());
      return post.copyWith(id: id);
    } on DatabaseException catch (e) {
      throw Exception('Insert error: ${e.toString()}');
    }
  }

  Future<int> updatePost(Post post) async {
    if (post.id == null) {
      throw Exception('Cannot update post without id');
    }
    try {
      final db = await database;
      return await db.update(
        table,
        post.toMap(),
        where: 'id = ?',
        whereArgs: [post.id],
      );
    } on DatabaseException catch (e) {
      throw Exception('Update error: ${e.toString()}');
    }
  }

  Future<int> deletePost(int id) async {
    try {
      final db = await database;
      return await db.delete(table, where: 'id = ?', whereArgs: [id]);
    } on DatabaseException catch (e) {
      throw Exception('Delete error: ${e.toString()}');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
