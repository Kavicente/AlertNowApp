// lib/pages/signup_type.dart
import 'package:flutter/material.dart';
import 'signup.dart';
import 'agency_up.dart';
import 'login_type.dart';

class SignType extends StatelessWidget {
  const SignType({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF224380),
      body: Stack(
        children: [
          Container(
            height: 500,
            width:413,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            top: 25,
            child: Container(
              height: 500,
              width: 413,
              decoration: const BoxDecoration(
                color: Color(0xFFdeeaee),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30), // Same curve as image
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 160),
                Image.asset(
                  'assets/alertnow_round.png',
                  width: 150,
                  height: 100,
                ),
                const SizedBox(height: 30),
                const Text(
                  'Choose Account To Sign Up',
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Signup()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdeeaee),
                        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                        elevation: 0,
                        fixedSize: const Size(230, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2),
                        ),
                      ),
                      child: const Text('Resident/Barangay Official'),
                    ),
                    const SizedBox(width: 18),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AgencyUp()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdeeaee),
                        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                        fixedSize: const Size(150, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2),
                        ),
                      ),
                      child: const Text('Agencies'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SizedBox(width: 18),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LogType()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdeeaee),
                        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                        fixedSize: const Size(200, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2),
                        ),
                      ),
                      child: const Text('Log In'),
                    ),
                    const SizedBox(height: 200),
              ],
              
            ),
          ),
        ],
      ),
    );
  }
}