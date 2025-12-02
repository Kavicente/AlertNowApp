class User {
  final String username;
  final String password;
  final String role;
  final String? barangay;
  final String? municipality;
  final String? province;
  final String? contactNo;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final int? age;
  final String? houseNo;
  final String? streetNo;
  final String? position;
  final String? assignedHospital;
  final int? syncStatus;

  User({
    required this.username,
    required this.password,
    required this.role,
    this.barangay,
    this.municipality,
    this.province,
    this.contactNo,
    this.firstName,
    this.middleName,
    this.lastName,
    this.age,
    this.houseNo,
    this.streetNo,
    this.position,
    this.assignedHospital,
    this.syncStatus,
    
  });

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'role': role,
      'barangay': barangay,
      'municipality': municipality,
      'province': province,
      'contact_no': contactNo,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'age': age,
      'house_no': houseNo,
      'street_no': streetNo,
      'position': position,
      'assigned_hospital': assignedHospital,
      'synced': syncStatus,
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'],
      password: map['password'],
      role: map['role'],
      barangay: map['barangay'],
      municipality: map['municipality'],
      province: map['province'],
      contactNo: map['contact_no'],
      firstName: map['first_name'],
      middleName: map['middle_name'],
      lastName: map['last_name'],
      age: map['age'],
      houseNo: map['house_no'],
      streetNo: map['street_no'],
      position: map['position'],
      assignedHospital: map['assigned_hospital'],
      syncStatus: map['synced'],
    );
  }
}