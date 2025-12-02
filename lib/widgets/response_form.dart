// lib/widgets/response_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ResponseForm extends StatefulWidget {
  final String alertId;
  final String barangay;
  final String emergencyType;
  final String role;
  final Function(String, String, String, [String?]) onUpdateEmergencyType;

  const ResponseForm({
    Key? key,
    required this.alertId,
    required this.barangay,
    required this.emergencyType,
    required this.role,
    required this.onUpdateEmergencyType,
  }) : super(key: key);

  @override
  _ResponseFormState createState() => _ResponseFormState();
}

class _ResponseFormState extends State<ResponseForm> {
  String _status = 'PENDING ALERT';
  bool _isResponded = false;

  void _handleRespond() {
    setState(() {
      _status = 'RESPONDED';
      _isResponded = true;
    });
    widget.onUpdateEmergencyType(
      widget.alertId,
      widget.barangay,
      widget.emergencyType,
    );
  }

  @override
  Widget build(BuildContext context) {
    Color buttonColor;
    switch (widget.role) {
      case 'bfp':
        buttonColor = const Color(0xFFFF0000); // Red
        break;
      case 'cdrrmo':
        buttonColor = const Color(0xFFDEEAEE); // Light grey
        break;
      case 'health':
        buttonColor = const Color(0xFFFF5733); // Orange-red
        break;
      case 'pnp':
        buttonColor = const Color(0xFF3498DB); // Blue
        break;
      default:
        buttonColor = const Color(0xFFDEEAEE);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1F3458),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'RECEIVED ALERTS\nEmergency at ${widget.barangay} Resident from ${widget.barangay}',
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
            'Time: ${_formatTime(DateTime.now())}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (!_isResponded)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isResponded ? null : _handleRespond,
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Respond',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }
}