// lib/widgets/health_response_form.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class HealthResponseForm extends StatefulWidget {
  final String alertId;
  final String barangay;
  final String emergencyType;
  final Map<String, dynamic> alert;
  final IO.Socket? socket;
  final String municipality;
  final Function(String, String, String, bool) onRespond;

  const HealthResponseForm({
    super.key,
    required this.alertId,
    required this.barangay,
    required this.emergencyType,
    required this.alert,
    required this.socket,
    required this.municipality,
    required this.onRespond,
  });

  @override
  _HealthResponseFormState createState() => _HealthResponseFormState();
}

class _HealthResponseFormState extends State<HealthResponseForm> {
  bool _acceptChecked = false;
  bool _declineChecked = false;

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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3458),
        borderRadius: BorderRadius.circular(12),
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
            'RECEIVED ALERTS\nEmergency at ${widget.barangay}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${widget.emergencyType}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Time: ${DateTime.now().toString().substring(11, 16)}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (widget.alert['image'] != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showImageDialog(widget.alert['image']),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(widget.alert['image']),
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: _acceptChecked,
                onChanged: (val) {
                  if (val == true) {
                    setState(() {
                      _acceptChecked = true;
                      _declineChecked = false;
                    });
                    widget.onRespond(widget.alertId, widget.barangay, widget.emergencyType, true);
                  }
                },
                activeColor: Colors.green,
              ),
              const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 18)),
              const SizedBox(width: 20),
              Checkbox(
                value: _declineChecked,
                onChanged: (val) {
                  if (val == true) {
                    setState(() {
                      _declineChecked = true;
                      _acceptChecked = false;
                    });
                    widget.onRespond(widget.alertId, widget.barangay, widget.emergencyType, false);
                  }
                },
                activeColor: Colors.red,
              ),
              const Text('Decline', style: TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}