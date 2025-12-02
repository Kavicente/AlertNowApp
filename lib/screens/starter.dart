// lib/pages/starter.dart
import 'package:flutter/material.dart';
import 'signup_type.dart';
import 'login_type.dart';

class Starter extends StatelessWidget {
  const Starter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF224380),
      body: Stack(
        children: [
          // Background Image
          Container(
            height: 500, // Reduced from 1900 — was too tall
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.png'), // Fixed typo
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Curved white overlay
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
                const SizedBox(height: 180),
                Image.asset(
                  'assets/alert_icon.png',
                  width: 400,
                  height: 250,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SignType()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdeeaee),
                        foregroundColor: Colors.black,
                        fixedSize: const Size(150, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Sign Up'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LogType()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFdeeaee),
                        foregroundColor: Colors.black,
                        fixedSize: const Size(150, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Log In'),
                    ),
                  ],
                ),
                const SizedBox(height: 250),
              ],
            ),
          ),
        ],
      ),
    );
  }
}