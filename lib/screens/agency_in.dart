// lib/screens/agency_in.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/db_service.dart';
import 'bfp.dart';
import 'cdrrmo.dart';
import 'city_health.dart';
import 'hospitals.dart';
import 'pnp.dart';

class Agencyin extends StatefulWidget {
  const Agencyin({super.key});

  @override
  _AgencyinState createState() => _AgencyinState();
}

class _AgencyinState extends State<Agencyin> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedRole;
  final _municipalityController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  late DatabaseService dbHelper;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseService();
    _initializePrefs();
  }

  Future<void> _initializePrefs() async {
    prefs = await SharedPreferences.getInstance();
    final savedRole = prefs!.getString('role');

    // Match exactly with dropdown values: 'CDRRMO', 'PNP', 'BFP', 'Health', 'Hospital'
    if (savedRole != null && ['CDRRMO', 'PNP', 'BFP', 'Health', 'Hospital'].contains(savedRole)) {
      setState(() {
        _selectedRole = savedRole;
      });
    } else if (savedRole != null && savedRole.toLowerCase() == 'cdrrmo') {
      setState(() {
        _selectedRole = 'CDRRMO';
      });
      await prefs!.setString('role', 'CDRRMO'); // Normalize to match UI
    } else if (savedRole != null && savedRole.toLowerCase() == 'health') {
      setState(() {
        _selectedRole = 'Health';
      });
      await prefs!.setString('role', 'Health');
    } else if (savedRole != null && savedRole.toLowerCase() == 'hospital') {
      setState(() {
        _selectedRole = 'Hospital';
      });
      await prefs!.setString('role', 'Hospital');
    }
  }

  @override
  void dispose() {
    _municipalityController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final role = _selectedRole?.toLowerCase(); // Convert to DB format
    final municipality = _municipalityController.text.trim();
    final contact = _contactController.text.trim();
    final password = _passwordController.text.trim();

    if (role == null || municipality.isEmpty || contact.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All fields are required.')),
      );
      return;
    }

    final userRole = await dbHelper.getUserRoleByMunicipalityContactNoPassword(
      role,
      municipality,
      contact,
      password,
    );

    if (userRole != null) {
      final username = '${role}_${municipality}_${contact}_${DateTime.now().millisecondsSinceEpoch}';
      await prefs!.setString('username', username);
      await prefs!.setString('role', role); // Store lowercase for DB
      await prefs!.setString('municipality', municipality);
      await prefs!.setString('contact_no', contact);
      if (role == 'hospital') {
        final assignedHospital = await dbHelper.getAssignedHospitalByContactNo(contact);
        if (assignedHospital != null) {
          await prefs!.setString('assigned_hospital', assignedHospital);
        }
      }

      print('SharedPreferences set: username=$username, role=$role, municipality=$municipality, contact_no=$contact');

      Widget destinationPage;
      switch (role) {
        case 'bfp':
          destinationPage = const BFPPage();
          break;
        case 'cdrrmo':
          destinationPage = const CDRRMOPage();
          break;
        case 'health':
          destinationPage = const CityHealthPage();
          break;
        case 'hospital':
          destinationPage = const HospitalsPage();
          break;
        case 'pnp':
          destinationPage = const PNPPage();
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid role')),
          );
          return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destinationPage),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid credentials')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Image.asset(
                      'assets/alertnow_round.png',
                      height: 100,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Agency Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color: Colors.white.withValues(alpha: 0.9),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Role',
                                  labelStyle: TextStyle(color: Colors.black87),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black54),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF224380)),
                                  ),
                                ),
                                initialValue: _selectedRole, // Changed from initialValue → value
                                items: ['CDRRMO', 'PNP', 'BFP', 'Health', 'Hospital'].map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Text(
                                      role,
                                      style: const TextStyle(color: Colors.black87),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                },
                                dropdownColor: Colors.white,
                                validator: (value) => value == null ? 'Please select a role' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _municipalityController,
                                decoration: const InputDecoration(
                                  labelText: 'Municipality',
                                  labelStyle: TextStyle(color: Colors.black87),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black54),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF224380)),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.black87),
                                validator: (value) => value!.isEmpty ? 'Please enter municipality' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _contactController,
                                decoration: const InputDecoration(
                                  labelText: 'Contact Number',
                                  labelStyle: TextStyle(color: Colors.black87),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black54),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF224380)),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.black87),
                                validator: (value) => value!.isEmpty ? 'Please enter contact number' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                decoration: const InputDecoration(
                                  labelText: 'Password',
                                  labelStyle: TextStyle(color: Colors.black87),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black54),
                                  ),
                                  focusedBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(color: Color(0xFF224380)),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.black87),
                                obscureText: true,
                                validator: (value) => value!.isEmpty ? 'Please enter password' : null,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF224380),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 5,
                                ),
                                child: const Text(
                                  'Log In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}