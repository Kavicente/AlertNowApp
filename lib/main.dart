import 'package:alert_now/screens/signup.dart';
import 'package:flutter/material.dart';
import 'package:alert_now/services/notification_service.dart';
import 'package:alert_now/screens/agency_in.dart';
import 'package:alert_now/screens/agency_up.dart';
import 'package:alert_now/screens/signup_type.dart';
import 'package:alert_now/screens/login_type.dart';
import 'package:alert_now/screens/starter.dart';
import 'package:alert_now/screens/login.dart';
import 'package:alert_now/screens/barangay.dart';
import 'package:alert_now/screens/bfp.dart';
import 'package:alert_now/screens/cdrrmo.dart';
import 'package:alert_now/screens/city_health.dart';
import 'package:alert_now/screens/hospitals.dart';
import 'package:alert_now/screens/pnp.dart';
import 'package:alert_now/screens/resident.dart';
import 'package:timezone/data/latest.dart' as tz;




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService().initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alert Now',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF224380),
      ),
      initialRoute: '/starter',
      routes: {
        '/agencyin':(context)=> const Agencyin(),
        '/agencyup':(context)=> const AgencyUp(),
        '/signup':(context)=> const Signup(),
        '/login': (context) => const Login(),
        '/logintype':(context)=> const LogType(),
        '/signuptype':(context)=> const SignType(),
        '/starter':(context)=> const Starter(),
        '/barangay': (context) => const BarangayPage(),
        '/bfp': (context) => const BFPPage(),
        '/cdrrmo': (context) => const CDRRMOPage(),
        '/city_health': (context) => const CityHealthPage(),
        '/hospitals': (context) => const HospitalsPage(),
        '/pnp': (context) => const PNPPage(),
        '/resident': (context) => const ResidentPage(),
      },
    );
  }
}