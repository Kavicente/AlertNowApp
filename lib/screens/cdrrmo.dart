// lib/screens/cdrrmo.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';
import '../services/network_service.dart';
import '../widgets/alert_card.dart';
import '../widgets/response_form.dart';
import '../models/alert.dart';
import 'agency_in.dart';

class CDRRMOPage extends StatefulWidget {
  const CDRRMOPage({super.key});

  @override
  _CDRRMOPageState createState() => _CDRRMOPageState();
}

class _CDRRMOPageState extends State<CDRRMOPage> {
  IO.Socket? socket;
  SharedPreferences? prefs;
  final List<Map<String, dynamic>> alertsList = [];
  final AudioPlayer audioPlayer = AudioPlayer();
  late DatabaseService dbHelper;
  bool isNetworkAvailable = true;
  final ScrollController _scrollController = ScrollController();
  bool _isPlayingAlert = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      prefs = await SharedPreferences.getInstance();
      String? username = prefs!.getString('username');
      String? municipality = prefs!.getString('municipality');
      String? role = prefs!.getString('role');

      // Debug logging to verify SharedPreferences
      print('CDRRMOPage init: username=$username, municipality=$municipality, role=$role');

      if (username == null || municipality == null || municipality.isEmpty || role?.toLowerCase() != 'cdrrmo') {
        print('Redirecting to Agencyin: username=$username, municipality=$municipality, role=$role');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please log in')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Agencyin()),
          );
        }
        return;
      }

      dbHelper = DatabaseService();
      await dbHelper.database;

      await LocationService().loadCoordinates();
      isNetworkAvailable = await NetworkService().checkNetwork();
      if (!isNetworkAvailable && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offline, cannot receive new alerts')),
        );
      }

      _initializeSocket();
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Initialization error: $e')),
        );
        Navigator.pop(context);
      }
    }
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
          'role': 'cdrrmo',
          'municipality': prefs!.getString('municipality')?.toLowerCase() ?? '',
        });
      });

      socket!.on('redirected_alert', (data) {
        print('Received redirected_alert: $data');
        final alert = data as Map<String, dynamic>;
        if (alert['target_role'] == 'cdrrmo' && mounted) {
          setState(() {
            alertsList.insert(0, alert);
          });
          _playAlertSound();
        }
      });

      socket!.on('cdrrmo_response', (data) {
        print('Received cdrrmo_response: $data');
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
    }
  }

  void _playAlertSound() async {
    if (_isPlayingAlert) return;
    _isPlayingAlert = true;

    try {
      await audioPlayer.setReleaseMode(ReleaseMode.loop);
      await audioPlayer.play(AssetSource('alert.mp3'));
    } catch (e) {
      print('Error playing alert sound: $e');
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, AsyncSnapshot<SharedPreferences> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading preferences'));
        }
        prefs = snapshot.data;
        final municipality = prefs!.getString('municipality') ?? '';

        return Scaffold(
          backgroundColor: const Color(0xFF224380),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // CDRRM Label (Top-left)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'CDRRMO $municipality',
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
                              ResponseForm(
                                alertId: alert['alert_id'] ?? 'N/A',
                                barangay: alert['barangay'] ?? 'N/A',
                                emergencyType: alert['emergency_type'] ?? 'N/A',
                                role: 'cdrrmo',
                                onUpdateEmergencyType: (id, brgy, typ, [hospital]) {
                                  final responseData = {
                                    'alert_id': id,
                                    'emergency_type': typ,
                                    'municipality': prefs!.getString('municipality')?.toLowerCase() ?? '',
                                    'lat': alert['lat'],
                                    'lon': alert['lon'],
                                  };
                                  socket?.emit('cdrrmo_response', responseData);
                                },
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
                      socket?.disconnect();
                      prefs!.clear();
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const Agencyin()),
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
      },
    );
  }

  @override
  void dispose() {
    socket?.disconnect();
    socket?.dispose();
    audioPlayer.stop();
    audioPlayer.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}