// lib/screens/barangay.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../services/db_service.dart';
import '../services/location_service.dart';
import '../services/network_service.dart';
import '../widgets/alert_card.dart';
import '../widgets/barangay_response_form.dart';
import '../models/alert.dart';
import 'login.dart';

class BarangayPage extends StatefulWidget {
  const BarangayPage({super.key});

  @override
  _BarangayPageState createState() => _BarangayPageState();
}

class _BarangayPageState extends State<BarangayPage> {
  late IO.Socket socket;
  late SharedPreferences prefs;
  final List<Map<String, dynamic>> alertsList = [];
  late DatabaseService dbHelper;
  bool isNetworkAvailable = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? barangay = prefs.getString('barangay');
    String? role = prefs.getString('role');

    if (username == null || barangay == null || barangay.isEmpty || role != 'official') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
      return;
    }

    try {
      dbHelper = DatabaseService();
      await dbHelper.database;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Database initialization error: $e')),
        );
        Navigator.pop(context);
      }
      return;
    }

    await LocationService().loadCoordinates();
    isNetworkAvailable = await NetworkService().checkNetwork();
    if (!isNetworkAvailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline, cannot receive new alerts')),
      );
    }

    _initializeSocket();
  }

  void _initializeSocket() {
    try {
      socket = IO.io('https://alertnow-wi0n.onrender.com', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      socket.onConnect((_) {
        print('Socket connected');
        socket.emit('register_role', {
          'role': 'barangay',
          'barangay': prefs.getString('barangay')?.toLowerCase() ?? '',
        });
      });

      socket.on('new_alert', (data) {
        print('Received new_alert: $data');
        final alert = data as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            alertsList.insert(0, alert);
          });
        }
      });

      socket.on('barangay_response', (data) {
        print('Received barangay_response: $data');
      });

      socket.onDisconnect((_) {
        print('Socket disconnected, attempting to reconnect');
        socket.connect();
      });

      socket.onConnectError((data) {
        print('Connection error: $data');
      });

      socket.connect();
    } catch (e) {
      print('Socket initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize socket')),
        );
      }
    }
  }

  

  void _showImageDialog(String base64Image) {
    final bytes = base64Decode(base64Image);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        contentPadding: EdgeInsets.zero,
        content: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Image.memory(bytes, fit: BoxFit.contain),
        ),
      ),
    );
  }

  void _onRedirect(Map<String, dynamic> redirectData, String event) {
    socket.emit(event, redirectData);
  }

  @override
  Widget build(BuildContext context) {
    final barangay = prefs.getString('barangay') ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF224380),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Barangay Label (Top-left)
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text(
                      'Barangay $barangay',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 150),
                // Alerts List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: alertsList.length,
                    itemBuilder: (context, index) {
                      final alert = alertsList[index];
                      return Column(
                        children: [
                          AlertCard(
                            alert: Alert.fromMap(alert),
                            onImageTap: () {
                              if (alert['image'] != null) {
                                _showImageDialog(alert['image']);
                              }
                            },
                          ),
                          BarangayResponseForm(
                            alertId: alert['alert_id'] ?? 'N/A',
                            barangay: alert['barangay'] ?? 'N/A',
                            emergencyType: alert['emergency_type'] ?? 'N/A',
                            alert: alert,
                            onRedirect: _onRedirect,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
            // Logout Button (Bottom-right)
            Positioned(
              bottom: 30,
              right: 5,
              child: ElevatedButton(
                onPressed: () {
                  socket.disconnect();
                  prefs.clear();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Login()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDEEAEE),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Log Out'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    socket.disconnect();
    socket.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}