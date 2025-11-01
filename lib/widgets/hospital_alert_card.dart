// lib/widgets/hospital_alert_card.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert.dart';
import '../constants.dart';

class HospitalAlertCard extends StatefulWidget {
  final Alert alert;
  final VoidCallback? onImageTap;
  final Function(String, String, String, String) onRespond;

  const HospitalAlertCard({
    Key? key,
    required this.alert,
    this.onImageTap,
    required this.onRespond,
  }) : super(key: key);

  @override
  _HospitalAlertCardState createState() => _HospitalAlertCardState();
}

class _HospitalAlertCardState extends State<HospitalAlertCard> {
  String _status = 'PENDING ALERT';
  bool _isResponded = false;
  String? _selectedHospital;

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
            'RECEIVED ALERTS\nEmergency at ${widget.alert.barangay} Resident from ${widget.alert.residentBarangay ?? widget.alert.barangay}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Type: ${widget.alert.emergencyType}',
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
          if (widget.alert.image != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: widget.onImageTap,
              child: Image.memory(
                base64Decode(widget.alert.image!),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (!_isResponded) ...[
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Hospital',
                labelStyle: TextStyle(color: Colors.white),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.white),
                ),
              ),
              initialValue: _selectedHospital,
              items: Constants.assignedHospitals.map((hospital) {
                return DropdownMenuItem(
                  value: hospital,
                  child: Text(
                    hospital,
                    style: const TextStyle(color: Colors.black),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedHospital = value;
                });
              },
              dropdownColor: Colors.white,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedHospital == null
                    ? null
                    : () {
                        setState(() {
                          _status = 'RESPONDED';
                          _isResponded = true;
                        });
                        widget.onRespond(
                          widget.alert.alertId,
                          widget.alert.barangay,
                          widget.alert.emergencyType,
                          _selectedHospital!,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDEEAEE),
                  foregroundColor: Colors.black,
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
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }
}