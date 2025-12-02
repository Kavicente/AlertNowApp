// lib/widgets/barangay_response_form.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BarangayResponseForm extends StatefulWidget {
  final String alertId;
  final String barangay;
  final String emergencyType;
  final Map<String, dynamic> alert;
  final Function(Map<String, dynamic>, String) onRedirect;

  const BarangayResponseForm({
    Key? key,
    required this.alertId,
    required this.barangay,
    required this.emergencyType,
    required this.alert,
    required this.onRedirect,
  }) : super(key: key);

  @override
  _BarangayResponseFormState createState() => _BarangayResponseFormState();
}

class _BarangayResponseFormState extends State<BarangayResponseForm> {
  bool _accept = false;
  bool _decline = false;
  bool _showPNPTypes = false;
  String _status = 'PENDING ALERT';

  @override
  Widget build(BuildContext context) {
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
            'RECEIVED ALERTS\nEmergency at ${widget.barangay} Resident from ${widget.alert['resident_barangay'] ?? widget.barangay}',
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
          Row(
            children: [
              Checkbox(
                value: _accept,
                onChanged: (value) {
                  setState(() {
                    _accept = value ?? false;
                    _decline = false;
                    _showPNPTypes = false;
                    if (_accept) _status = 'ACCEPTED';
                    else _status = 'PENDING ALERT';
                  });
                },
                activeColor: Colors.white,
                checkColor: Colors.black,
              ),
              const Text('Accept', style: TextStyle(color: Colors.white, fontSize: 20)),
              const SizedBox(width: 20),
              Checkbox(
                value: _decline,
                onChanged: (value) {
                  setState(() {
                    _decline = value ?? false;
                    _accept = false;
                    _showPNPTypes = false;
                    _status = _decline ? 'DECLINED' : 'PENDING ALERT';
                  });
                },
                activeColor: Colors.white,
                checkColor: Colors.black,
              ),
              const Text('Decline', style: TextStyle(color: Colors.white, fontSize: 20)),
            ],
          ),
          if (_accept) ...[
            const SizedBox(height: 8),
            ..._buildRoleButtons(),
            if (_showPNPTypes) ..._buildPNPTypeButtons(),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildRoleButtons() {
    const roles = ['CDRRMO', 'PNP', 'BFP', 'Health', 'Hospital'];
    return roles.map((role) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                if (role.toLowerCase() == 'pnp') {
                  _showPNPTypes = true;
                } else {
                  _showPNPTypes = false;
                  _status = 'RESPONDED';
                  final emergencyType = _determineEmergencyType(role.toLowerCase());
                  final redirectData = Map<String, dynamic>.from(widget.alert)
                    ..['target_role'] = role.toLowerCase()
                    ..['emergency_type'] = emergencyType
                    ..['municipality'] = _getMunicipalityFromBarangay(widget.barangay);
                  widget.onRedirect(redirectData, 'redirect_alert');
                  widget.onRedirect({
                    'alert_id': widget.alertId,
                    'emergency_type': emergencyType,
                    'barangay': widget.barangay.toLowerCase(),
                  }, 'update_dashboard_emergency_type');
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDEEAEE),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Send to $role'),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPNPTypeButtons() {
    const pnpTypes = ['Road Accident', 'Fire Incident', 'Crime Incident'];
    return pnpTypes.map((type) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _status = 'RESPONDED';
                _showPNPTypes = false;
                final redirectData = Map<String, dynamic>.from(widget.alert)
                  ..['target_role'] = 'pnp'
                  ..['emergency_type'] = type
                  ..['municipality'] = _getMunicipalityFromBarangay(widget.barangay);
                widget.onRedirect(redirectData, 'pnp_redirect_alert');
                widget.onRedirect({
                  'alert_id': widget.alertId,
                  'emergency_type': type,
                  'barangay': widget.barangay.toLowerCase(),
                }, 'update_dashboard_emergency_type');
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDEEAEE),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(type),
          ),
        ),
      );
    }).toList();
  }

  String _determineEmergencyType(String role) {
    switch (role) {
      case 'cdrrmo':
        return 'Road Accident';
      case 'bfp':
        return 'Fire Incident';
      case 'health':
      case 'hospital':
        return 'Health Emergency';
      default:
        return 'Unknown';
    }
  }

  String _getMunicipalityFromBarangay(String barangay) {
    return 'San Pablo City';
  }

  String _formatTime(DateTime time) {
    return DateFormat('hh:mm a').format(time);
  }
}