// lib/services/db_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';

class DatabaseService {
  static Database? _database;
  static const String TABLE_USERS = 'users';
  static const String TABLE_ALERTS = 'alerts';

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'AlertNowLocal.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT,
            barangay TEXT,
            municipality TEXT,
            province TEXT,
            contact_no TEXT,
            first_name TEXT,
            middle_name TEXT,
            last_name TEXT,
            age INTEGER,
            house_no TEXT,
            street_no TEXT,
            position TEXT,
            assigned_hospital TEXT,
            synced INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE alerts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            data TEXT,
            synced INTEGER
          )
        ''');
      },
    );
  }

  Future<bool> insertUser(Map<String, dynamic> values) async {
    final db = await database;
    try {
      await db.insert(TABLE_USERS, values, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (e) {
      print('Insert failed: $e');
      return false;
    }
  }

  Future<User?> getUser(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_USERS,
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<bool> checkUsernameExists(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_USERS,
      where: 'username = ?',
      whereArgs: [username],
    );
    return maps.isNotEmpty;
  }

  Future<User?> getUserByUsernamePassword(String username, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_USERS,
      where: 'username = ? AND password = ?',
      whereArgs: [username, password],
    );
    if (maps.isNotEmpty) return User.fromMap(maps.first);
    return null;
  }

  Future<String?> getUserRoleByMunicipalityContactNoPassword(
      String role, String municipality, String contactNo, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_USERS,
      where: 'role = ? AND municipality = ? AND contact_no = ? AND password = ?',
      whereArgs: [role, municipality, contactNo, password],
    );
    if (maps.isNotEmpty) return maps.first['role'];
    return null;
  }

  Future<String?> getAssignedHospitalByContactNo(String contactNo) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_USERS,
      columns: ['assigned_hospital'],
      where: 'contact_no = ?',
      whereArgs: [contactNo],
    );
    if (maps.isNotEmpty) return maps.first['assigned_hospital'];
    return null;
  }

  Future<List<Map<String, dynamic>>> getUsersByRoles(List<String> roles) async {
    final db = await database;
    final placeholders = roles.map((_) => '?').join(',');
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT role, municipality, contact_no, password, assigned_hospital FROM $TABLE_USERS WHERE role IN ($placeholders)',
      roles,
    );
    return maps;
  }

  Future<Map<String, String>?> getUserAddressByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_USERS,
      columns: ['house_no', 'street_no', 'barangay'],
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return {
        'house_no': maps.first['house_no'] ?? '',
        'street_no': maps.first['street_no'] ?? '',
        'barangay': maps.first['barangay'] ?? '',
      };
    }
    return null;
  }

  Future<String?> getBarangayByUsername(String username) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_USERS,
      columns: ['barangay'],
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) return maps.first['barangay'];
    return null;
  }

  Future<void> insertAlert(String alertData) async {
    final db = await database;
    await db.insert(
      TABLE_ALERTS,
      {'data': alertData, 'synced': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getLatestAlert() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_ALERTS,
      columns: ['data'],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      try {
        return jsonDecode(maps.first['data']);
      } catch (e) {
        print('Error parsing latest alert: $e');
      }
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getUnsyncedUsers() async {
    final db = await database;
    return await db.query(
      TABLE_USERS,
      where: 'synced = 0',
    );
  }

  Future<void> updateSyncStatus(String username, int synced) async {
    final db = await database;
    await db.update(
      TABLE_USERS,
      {'synced': synced},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  Future<void> storeAlert(Map<String, dynamic> alert) async {
    final db = await database;
    await db.insert(
      TABLE_ALERTS,
      {'data': jsonEncode(alert), 'synced': 0},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> syncAlerts(IO.Socket socket) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      TABLE_ALERTS,
      columns: ['id', 'data'],
      where: 'synced = 0',
    );

    for (var map in maps) {
      final id = map['id'];
      final data = map['data'];
      try {
        final alert = jsonDecode(data);
        if (socket.connected) {
          socket.emit('alert', alert);
          await db.update(
            TABLE_ALERTS,
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [id],
          );
          print('Synced alert with ID: $id');
        } else {
          print('Socket not connected, cannot sync alert ID: $id');
        }
      } catch (e) {
        print('Error syncing alert ID $id: $e');
      }
    }
  }
}