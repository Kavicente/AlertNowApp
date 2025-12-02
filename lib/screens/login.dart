// lib/screens/login.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import 'resident.dart';
import 'barangay.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late SharedPreferences _prefs;
  List<Map<String, dynamic>> _profiles = [];
  bool _profilesVisible = false;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required.')),
      );
      return;
    }

    final user = await _dbService.getUserByUsernamePassword(username, password);

    if (user != null) {
      await _prefs.setString('username', username);
      await _prefs.setString('role', user.role);
      await _prefs.setString('barangay', user.barangay ?? '');
      await _prefs.setString('municipality', user.municipality ?? '');
      await _prefs.setString('province', user.province ?? '');
      await _prefs.setString('contact_no', user.contactNo ?? '');
      await _prefs.setString('first_name', user.firstName ?? '');
      await _prefs.setString('middle_name', user.middleName ?? '');
      await _prefs.setString('last_name', user.lastName ?? '');
      await _prefs.setInt('age', user.age ?? 0);
      await _prefs.setString('house_no', user.houseNo ?? '');
      await _prefs.setString('street_no', user.streetNo ?? '');
      await _prefs.setString('position', user.position ?? ''); // Added for official
      await _prefs.setString('assigned_hospital', user.assignedHospital ?? ''); // Added for official

      if (mounted) {
        if (user.role.toLowerCase() == 'resident') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ResidentPage()),
          );
        } else if (user.role.toLowerCase() == 'official') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BarangayPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid role.')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials.')),
        );
      }
    }
  }

  Future<void> _autoLogin(Map<String, dynamic> profile) async {
    final username = profile['username'] ?? '';
    final password = profile['password'] ?? '';

    final user = await _dbService.getUserByUsernamePassword(username, password);
    if (user != null) {
      await _prefs.setString('username', username);
      await _prefs.setString('role', user.role);
      await _prefs.setString('barangay', user.barangay ?? '');
      await _prefs.setString('municipality', user.municipality ?? '');
      await _prefs.setString('province', user.province ?? '');
      await _prefs.setString('contact_no', user.contactNo ?? '');
      await _prefs.setString('first_name', user.firstName ?? '');
      await _prefs.setString('middle_name', user.middleName ?? '');
      await _prefs.setString('last_name', user.lastName ?? '');
      await _prefs.setInt('age', user.age ?? 0);
      await _prefs.setString('house_no', user.houseNo ?? '');
      await _prefs.setString('street_no', user.streetNo ?? '');
      await _prefs.setString('position', user.position ?? ''); // Added for official
      await _prefs.setString('assigned_hospital', user.assignedHospital ?? ''); // Added for official

      if (mounted) {
        if (user.role.toLowerCase() == 'resident') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ResidentPage()),
          );
        } else if (user.role.toLowerCase() == 'official') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BarangayPage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid role for profile.')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials for profile.')),
        );
      }
    }
  }

  Future<void> _showProfiles() async {
    final profiles = await _dbService.getUsersByRoles(['resident']);
    if (mounted) {
      setState(() {
        _profiles = profiles;
        _profilesVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (details.delta.dy < -2 && details.delta.distance > 10) {
          _showProfiles();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF224380),
        body: Stack(
          children: [
            Container(
              height: 500,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 15,
              left: 0,
              right: 0,
              child: Container(
                height: 600,
                decoration: const BoxDecoration(
                  color: Color(0xFFdeeaee),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: TextField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Username',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF224380), width: 2),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF224380), width: 2),
                          ),
                        ),
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdeeaee),
                        foregroundColor: Colors.black,
                        fixedSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: const Text('Log In'),
                    ),
                    if (_profilesVisible) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Saved Resident Profiles',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._profiles.map((profile) => ListTile(
                                  title: Text(profile['username'] ?? 'Unknown'),
                                  subtitle: Text(
                                      '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'),
                                  onTap: () => _autoLogin(profile),
                                )),
                            ElevatedButton(
                              onPressed: () {
                                if (mounted) {
                                  setState(() {
                                    _profilesVisible = false;
                                  });
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF224380),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Close Profiles'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}