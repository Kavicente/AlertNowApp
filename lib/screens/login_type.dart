// lib/pages/login_type.dart
import 'package:flutter/material.dart';
import 'login.dart';
import 'agency_in.dart';
import 'signup_type.dart';

class LogType extends StatelessWidget {
  const LogType({Key? key}) : super(key: key);

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
            top: 25,
            left: 0,
            right: 0,
            child: Container(
              height: 500,
              decoration: const BoxDecoration(
                color: Color(0xFFdeeaee),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 200),
                Image.asset(
                  'assets/alertnow_round.png',
                  width: 150,
                  height: 100,
                ),
                const SizedBox(height: 70),
                const Text(
                  'Select Account to Log In',
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
                          MaterialPageRoute(builder: (context) => const Login()),
                        );
                      },
                     style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdeeaee),
                        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                        fixedSize: const Size(180, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2),
                        ),
                      ),
                      child: const Text('Resident/Official'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const Agencyin()),
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
                const SizedBox(height: 30),
                const SizedBox(width: 18),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignType()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdeeaee),
                        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                        fixedSize: const Size(100, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2),
                        ),
                      ),
                      child: const Text('Sign Up'),
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