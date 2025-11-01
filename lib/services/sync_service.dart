import 'package:http/http.dart' as http;
import 'dart:convert';
import 'db_service.dart';
import '../models/user.dart';

class SyncService {
  final List<String> serverUrls = ['https://alertnow-wi0n.onrender.com/sync'];

  Future<void> syncUser(String username) async {
    try {
      final db = DatabaseService();
      final user = await db.getUser(username);
      if (user == null) return;

      final data = user.toMap();
      final response = await http.post(
        Uri.parse(serverUrls.first),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        await db.insertUser(User(
          username: user.username,
          password: user.password,
          role: user.role,
          barangay: user.barangay,
          municipality: user.municipality,
          province: user.province,
          contactNo: user.contactNo,
          firstName: user.firstName,
          middleName: user.middleName,
          lastName: user.lastName,
          age: user.age,
          houseNo: user.houseNo,
          streetNo: user.streetNo,
          position: user.position,
          syncStatus: 1,
        ) as Map<String, dynamic>);
      }
    } catch (e) {
      print('Sync failed for $username: $e');
    }
  }
}