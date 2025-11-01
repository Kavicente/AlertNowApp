// lib/widgets/alert_card.dart
import 'package:flutter/material.dart';
import '../models/alert.dart';

class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onImageTap;

  const AlertCard({super.key, required this.alert, this.onImageTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3458),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PENDING ALERT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Emergency at ${alert.barangay} Resident from ${alert.barangay}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${alert.emergencyType}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Time: ${alert.timestamp}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          if (alert.image != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onImageTap,
              child: Container(
                height: 400,
                color: Colors.grey,
                child: const Center(child: Text('Image Preview')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}