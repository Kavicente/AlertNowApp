// lib/pages/resident.dart
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:geolocator/geolocator.dart';
import '../services/image_service.dart';
import '../services/network_service.dart';
import '../widgets/custom_button.dart';
import 'login.dart';

class ResidentPage extends StatefulWidget {
  const ResidentPage({super.key});

  @override
  _ResidentPageState createState() => _ResidentPageState();
}

class _ResidentPageState extends State<ResidentPage> {
  IO.Socket? socket;
  late SharedPreferences prefs;
  final ImageService _imageService = ImageService();
  Uint8List? _imageBytes;
  bool isNetworkAvailable = true;
  Timer? _photoTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    prefs = await SharedPreferences.getInstance();
    String? username = prefs.getString('username');
    String? role = prefs.getString('role');
    String? barangay = prefs.getString('barangay');

    if (username == null || role != 'resident' || barangay == null || barangay.isEmpty) {
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

    isNetworkAvailable = await NetworkService().checkNetwork();
    if (!isNetworkAvailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Offline, cannot send alerts')),
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

      socket!.onConnect((_) {
        print('Socket connected');
        socket!.emit('register_role', {
          'role': 'resident',
          'barangay': prefs.getString('barangay')?.toLowerCase() ?? '',
        });
      });

      socket!.on('new_alert', (data) {
        try {
          final alert = data as Map<String, dynamic>;
          if (!alert.containsKey('image')) {
            socket!.emit('forward_alert', {
              'alert_id': alert['alert_id'],
              'role': 'barangay',
              'barangay': prefs.getString('barangay')?.toLowerCase() ?? '',
            });
          }
        } catch (e) {
          print('Error processing new_alert: $e');
        }
      });

      socket!.onDisconnect((_) {
        print('Socket disconnected, attempting to reconnect');
        socket!.connect();
      });

      socket!.onConnectError((data) {
        print('Connection error: $data');
      });

      socket!.connect();
    } catch (e) {
      print('Socket initialization failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to initialize socket')),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final bytes = await _imageService.pickImage();
    if (bytes != null) {
      setState(() {
        _imageBytes = bytes;
      });
      _startPhotoTimer();
    }
  }

  void _startPhotoTimer() {
    _photoTimer?.cancel();
    _photoTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _imageBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Time's up! Photo discarded.")),
        );
      }
    });
  }

  void _sendAlert() async {
    if (!isNetworkAvailable) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No network connection')),
        );
      }
      return;
    }

    if (socket == null || !socket!.connected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Socket not connected')),
        );
      }
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final barangay = prefs.getString('barangay')?.toLowerCase() ?? 'N/A';
      final houseNo = prefs.getString('house_no') ?? 'N/A';
      final streetNo = prefs.getString('street_no') ?? 'N/A';
      final alertId = DateTime.now().millisecondsSinceEpoch.toString();

      final alertData = {
        'alert_id': alertId,
        'house_no': houseNo,
        'street_no': streetNo,
        'barangay': barangay,
        'emergency_type': 'Emergency',
        'lat': position.latitude,
        'lon': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'image': _imageBytes != null ? base64Encode(_imageBytes!) : null,
      };

      socket!.emit('alert', alertData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert Sent Successfully')),
        );
      }

      setState(() {
        _imageBytes = null;
      });
      _photoTimer?.cancel();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to Send Alert')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 88, 88),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Location Text
                const SizedBox(height: 198),
                const Text(
                  'Location: N/A', // Map removed, so coordinates unavailable
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 10),

                // Photo Preview
                _imageBytes != null
                    ? Image.memory(
                        _imageBytes!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      )
                    : const SizedBox(height: 100),
                const SizedBox(height: 58),

                // Upload Photo Button
                CustomButton(
                  text: 'Upload Photo',
                  onPressed: _pickImage,
                  backgroundColor: const Color.fromARGB(255, 233, 88, 88),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 2),
                ),
                const SizedBox(height: 18),

                // Alert Now Button (Circular)
                CustomButton(
                  text: 'Alert Now',
                  onPressed: _sendAlert,
                  backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                  foregroundColor: const Color(0xFFFF5252),
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(30),
                  fontSize: 30,
                  elevation: 8, // Added shadow
                  shadowColor: Colors.black, // Added shadow color
                  width: 200,
                  height: 200,
                ),

                const Spacer(),

                // Log Out Button
                CustomButton(
                  text: 'Log Out',
                  onPressed: () {
                    socket?.disconnect();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const Login()),
                    );
                  },
                  backgroundColor: const Color.fromARGB(255, 233, 88, 88),
                  foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                  side: const BorderSide(color: Color.fromARGB(255, 255, 255, 255), width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _photoTimer?.cancel();
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }
}