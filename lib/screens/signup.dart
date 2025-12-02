// lib/screens/signup.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import '../services/db_service.dart';
import 'login.dart';
import '../constants.dart';

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final DatabaseService _dbService = DatabaseService();
  final PageController _pageController = PageController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _contactNoController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _houseNoController = TextEditingController();
  final TextEditingController _streetNoController = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _municipalityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  String _selectedRole = 'resident'; // Default role
  String? _selectedPosition; // Position for official, nullable
  int _currentPage = 0; // Track current page (0 for Step 1, 1 for Step 2)

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _contactNoController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _houseNoController.dispose();
    _streetNoController.dispose();
    _barangayController.dispose();
    _municipalityController.dispose();
    _provinceController.dispose();
    super.dispose();
  }

  Future<void> _quickMapScan() async {
    try {
      // Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied.')),
        );
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // Load coords.txt from assets
      String coordsData = await rootBundle.loadString('assets/coords.txt');
      List<dynamic> locations = json.decode(coordsData);

      // Find the closest location within radius
      Map<String, dynamic>? closestLocation;
      double minDistance = double.infinity;

      for (var loc in locations) {
        double distance = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          loc['latitude'] as double? ?? 0.0,
          loc['longitude'] as double? ?? 0.0,
        ) / 1000; // Convert to kilometers

        if (distance <= (loc['radius_km'] as double? ?? 0.0) && distance < minDistance) {
          minDistance = distance;
          closestLocation = loc;
        }
      }

      if (closestLocation != null) {
        setState(() {
          final loc = closestLocation!;
          _barangayController.text = (loc['barangay'] ?? '').toString();
          _municipalityController.text = (loc['municipality'] ?? '').toString();
          _provinceController.text = (loc['province'] ?? '').toString();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching location found.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _nextPage() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final contactNo = _contactNoController.text.trim();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final age = int.tryParse(_ageController.text.trim()) ?? 0;

    // Validate Step 1 fields
    if (username.isEmpty ||
        password.isEmpty ||
        contactNo.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty ||
        age == 0 ||
        (_selectedRole == 'official' && _selectedPosition == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All required fields must be filled.')),
      );
      return;
    }

    setState(() {
      _currentPage = 1;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void _previousPage() {
    setState(() {
      _currentPage = 0;
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _signup() async {
    final houseNo = _houseNoController.text.trim();
    final streetNo = _streetNoController.text.trim();
    final barangay = _barangayController.text.trim();
    final municipality = _municipalityController.text.trim();
    final province = _provinceController.text.trim();

    // Validate Step 2 fields
    if (houseNo.isEmpty ||
        streetNo.isEmpty ||
        barangay.isEmpty ||
        municipality.isEmpty ||
        province.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All required fields must be filled.')),
      );
      return;
    }

    // Check username uniqueness
    if (await _dbService.checkUsernameExists(_usernameController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username already exists.')),
      );
      return;
    }

    final userData = {
      'username': _usernameController.text.trim(),
      'password': _passwordController.text.trim(),
      'role': _selectedRole,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
      'contact_no': _contactNoController.text.trim(),
      'first_name': _firstNameController.text.trim(),
      'middle_name': _middleNameController.text.trim().isEmpty
          ? null
          : _middleNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'age': int.tryParse(_ageController.text.trim()) ?? 0,
      'house_no': houseNo,
      'street_no': streetNo,
      'position': _selectedRole == 'resident' ? null : _selectedPosition,
      'synced': 0,
    };

    bool success = await _dbService.insertUser(userData);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up successful!')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign up failed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              height: 650,
              decoration: const BoxDecoration(
                color: Color(0xFFdeeaee),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),
          ),
          Center(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(), // Prevent swipe navigation
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                // Step 1: User Information
                SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Step ${_currentPage + 1} of 2', // Step indicator
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _selectedRole == 'resident'
                            ? 'Resident Sign Up'
                            : 'Official Sign Up',
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      // Role Dropdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          decoration: InputDecoration(
                            hintText: 'Select Role',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'resident',
                              child: Text('Resident'),
                            ),
                            DropdownMenuItem(
                              value: 'official',
                              child: Text('Official'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value ?? 'resident';
                              _selectedPosition = null; // Reset position
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (_selectedRole == 'official') ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedPosition,
                            decoration: InputDecoration(
                              hintText: 'Select Position',
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
                                borderSide: const BorderSide(
                                    color: Color(0xFF224380), width: 2),
                              ),
                            ),
                            items: Constants.positions
                                .map((position) => DropdownMenuItem(
                                      value: position,
                                      child: Text(position),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPosition = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 5),
                      ],
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                          obscureText: true,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _contactNoController,
                          decoration: InputDecoration(
                            hintText: 'Contact No',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _firstNameController,
                          decoration: InputDecoration(
                            hintText: 'First Name',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _middleNameController,
                          decoration: InputDecoration(
                            hintText: 'Middle Name (Optional)',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _lastNameController,
                          decoration: InputDecoration(
                            hintText: 'Last Name',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _ageController,
                          decoration: InputDecoration(
                            hintText: 'Age',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _nextPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFdeeaee),
                          foregroundColor: Colors.black,
                          fixedSize: const Size(200, 50),
                        ),
                        child: const Text('Next'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const Login()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFdeeaee),
                          foregroundColor: Colors.black,
                          fixedSize: const Size(200, 50),
                        ),
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
                // Step 2: Address Details
                SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Step ${_currentPage + 1} of 2', // Step indicator
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Address Details',
                        style: const TextStyle(
                          fontSize: 30,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _houseNoController,
                          decoration: InputDecoration(
                            hintText: 'House No',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _streetNoController,
                          decoration: InputDecoration(
                            hintText: 'Street No',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _barangayController,
                          decoration: InputDecoration(
                            hintText: 'Barangay',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _municipalityController,
                          decoration: InputDecoration(
                            hintText: 'Municipality',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 50),
                        child: TextField(
                          controller: _provinceController,
                          decoration: InputDecoration(
                            hintText: 'Province',
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
                              borderSide: const BorderSide(
                                  color: Color(0xFF224380), width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _quickMapScan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFdeeaee),
                          foregroundColor: Colors.black,
                          fixedSize: const Size(200, 50),
                        ),
                        child: const Text('Quick Map Scan'),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _signup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFdeeaee),
                          foregroundColor: Colors.black,
                          fixedSize: const Size(200, 50),
                        ),
                        child: const Text('Sign Up'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: _previousPage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFdeeaee),
                          foregroundColor: Colors.black,
                          fixedSize: const Size(200, 50),
                        ),
                        child: const Text('Back'),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const Login()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFdeeaee),
                          foregroundColor: Colors.black,
                          fixedSize: const Size(200, 50),
                        ),
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}