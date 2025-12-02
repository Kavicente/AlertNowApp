// lib/models/alert.dart
class Alert {
  final String alertId;
  final String houseNo;
  final String streetNo;
  final String barangay;
  final String emergencyType;
  final double lat;
  final double lon;
  final String? image;
  final String timestamp;
  final String? residentBarangay;

  Alert({
    required this.alertId,
    required this.houseNo,
    required this.streetNo,
    required this.barangay,
    required this.emergencyType,
    required this.lat,
    required this.lon,
    this.image,
    required this.timestamp,
    this.residentBarangay,
  });

  factory Alert.fromMap(Map<String, dynamic> map) {
    return Alert(
      alertId: map['alert_id'] ?? 'N/A',
      houseNo: map['house_no'] ?? 'N/A',
      streetNo: map['street_no'] ?? 'N/A',
      barangay: map['barangay'] ?? 'N/A',
      emergencyType: map['emergency_type'] ?? 'N/A',
      lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
      lon: (map['lon'] as num?)?.toDouble() ?? 0.0,
      image: map['image'],
      timestamp: map['timestamp'] ?? '',
      residentBarangay: map['resident_barangay'] as String?,
      
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'alert_id': alertId,
      'barangay': barangay,
      'emergency_type': emergencyType,
      'image': image,
      'lat': lat,
      'lon': lon,
      'timestamp': timestamp,
      'house_no': houseNo,
      'street_no': streetNo,
      'resident_barangay': residentBarangay,
    };
  }
}