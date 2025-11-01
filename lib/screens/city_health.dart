// lib/screens/city_health.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:audioplayers/audioplayers.dart';
import '../services/db_service.dart';
import '../services/location_service.dart';
import '../services/network_service.dart';
import '../widgets/health_response_form.dart';
import 'agency_in.dart';

class CityHealthPage extends StatefulWidget {
  const CityHealthPage({super.key});

  @override
  _CityHealthPageState createState() => _CityHealthPageState();
}

class _CityHealthPageState extends State<CityHealthPage> {
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
  }

  Future<void> _initialize(SharedPreferences preferences) async {
    prefs = preferences;

    String? username = prefs!.getString('username');
    String? municipality = prefs!.getString('municipality');
    String? role = prefs!.getString('role');

    if (username == null || municipality == null || municipality.isEmpty || role != 'health') {
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

    try {
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
          'role': 'health',
          'municipality': prefs!.getString('municipality')?.toLowerCase() ?? '',
        });
      });

      socket!.on('redirected_alert', (data) {
        print('Received redirected_alert: $data');
        final alert = data as Map<String, dynamic>;
        if (alert['target_role'] == 'health' && mounted) {
          setState(() {
            alertsList.insert(0, alert);
          });
          _playAlertSound();
        }
      });

      socket!.on('health_response', (data) {
        print('Received health_response: $data');
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

  void _onRespond(String alertId, String barangay, String type, bool accepted) {
    final responseData = {
      'alert_id': alertId,
      'emergency_type': type,
      'municipality': prefs!.getString('municipality')?.toLowerCase() ?? '',
      'lat': alertsList.firstWhere((a) => a['alert_id'] == alertId)['lat'],
      'lon': alertsList.firstWhere((a) => a['alert_id'] == alertId)['lon'],
      'accepted': accepted,
    };

    socket?.emit('health_response', responseData);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accepted ? 'Alert Accepted' : 'Alert Declined')),
      );
    }

    setState(() {
      alertsList.removeWhere((a) => a['alert_id'] == alertId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading preferences'));
        }

        final prefs = snapshot.data!;
        _initialize(prefs);

        final municipality = prefs.getString('municipality') ?? '';

        return Scaffold(
          backgroundColor: const Color(0xFF224380),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    // City Health Label (Top-left)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 10, 0, 0),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'City Health $municipality',
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
                          return HealthResponseForm(
                            alertId: alert['alert_id'] ?? 'N/A',
                            barangay: alert['barangay'] ?? 'N/A',
                            emergencyType: alert['emergency_type'] ?? 'N/A',
                            alert: alert,
                            socket: socket,
                            municipality: municipality,
                            onRespond: _onRespond,
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
                      prefs.clear();
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