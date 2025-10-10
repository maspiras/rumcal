// ignore_for_file: depend_on_referenced_packages

import 'dart:developer';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _database;
  static const String dbName = "app_database.db";

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: 8,
      onCreate: _createDB,
      onUpgrade: _upGradeDB,
      singleInstance: true, // ✅ Ensure only one instance of the DB is used
    );
  }

  static Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE Users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullname TEXT NOT NULL,
        userId TEXT NOT NULL,
        mobileNumber TEXT NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        isLoggedIn INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE LoginUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL,
        password TEXT NOT NULL,
        fullname TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE Rooms (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        room_name TEXT NOT NULL,
        room_desc TEXT,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES LoginUsers(id)
      );
    ''');

    await db.execute('''
     CREATE TABLE IF NOT EXISTS Reservations (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  checkin TEXT NOT NULL,
  checkout TEXT NOT NULL,
  fullname TEXT NOT NULL,
  phone TEXT NOT NULL,
  email TEXT NOT NULL,
  roomName TEXT NOT NULL,
  rooms TEXT NOT NULL,
  adult INTEGER NOT NULL,
  child INTEGER NOT NULL,
  roomId INTEGER NOT NULL,
  pet INTEGER NOT NULL,
  ratepernight REAL NOT NULL,
  subtotal REAL NOT NULL,
  discount REAL NOT NULL,
  tax REAL NOT NULL,
    taxPercent REAL NOT NULL,   
  grandtotal REAL NOT NULL,
  prepayment REAL NOT NULL,
  balance REAL NOT NULL,
  FOREIGN KEY (user_id) REFERENCES LoginUsers(id) ON DELETE CASCADE
);

    ''');
  }

  static Future<void> _upGradeDB(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 7) {
      await db.execute("ALTER TABLE Reservations ADD COLUMN roomId INTEGER;");
      await db.execute("ALTER TABLE Reservations ADD COLUMN roomName TEXT;");
    }
    if (oldVersion < 8) {
      await db.execute(
          "ALTER TABLE Reservations ADD COLUMN taxPercent REAL DEFAULT 5.0;");
    }
  }

  static Future<List<Map<String, dynamic>>> getLoginUsers() async {
    final db = await database;
    return await db.query('LoginUsers');
  }

  static Future<List<Map<String, dynamic>>> getUsers() async {
    final db = await database;
    log('db---->${db.query('Users')}');
    return await db.query('Users');
  }

  static Future<int> updateUser(Map<String, dynamic> user, int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.update('Users', user, where: 'id = ?', whereArgs: [id]);
    });
  }

  static Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.rawDelete("DELETE FROM Users WHERE id = ?", [id]);
    });
  }

  // CRUD Operations for Rooms
  static Future<int> insertRoom(Map<String, dynamic> room) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.insert('Rooms', room);
    });
  }

  static Future<List<Map<String, dynamic>>> getRooms([int? userId]) async {
    final db = await database;
    if (userId != null) {
      return await db.query('Rooms', where: 'user_id = ?', whereArgs: [userId]);
    }
    return await db.query('Rooms');
  }

  static Future<int> updateRoom(Map<String, dynamic> room, int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.update('Rooms', room, where: 'id = ?', whereArgs: [id]);
    });
  }

  static Future<int> deleteRoom(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.rawDelete("DELETE FROM Rooms WHERE id = ?", [id]);
    });
  }

  // CRUD Operations for Reservations
  static Future<int> insertReservation(Map<String, dynamic> reservation) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.insert('Reservations', reservation);
    });
  }

  static Future<List<Map<String, dynamic>>> getReservations([int? userId]) async {
    final db = await database;
    if (userId != null) {
      return await db.query('Reservations', where: 'user_id = ?', whereArgs: [userId]);
    }
    return await db.query('Reservations');
  }

  static Future<int> updateReservation(
      Map<String, dynamic> reservation, int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.update('Reservations', reservation,
          where: 'id = ?', whereArgs: [id]);
    });
  }

  static Future<int> deleteReservation(int id) async {
    final db = await database;
    return await db.transaction((txn) async {
      return await txn.rawDelete("DELETE FROM Reservations WHERE id = ?", [id]);
    });
  }

  // Method to log out the user by clearing SharedPreferences only
  static Future<void> logout() async {
    // Only clear SharedPreferences, keep database data intact
    // Data will be filtered by user_id on next login
  }
}
