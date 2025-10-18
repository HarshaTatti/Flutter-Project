/// Model class to represent personal data stored locally
class PersonalData {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String dateOfBirth;
  final String occupation;
  final Map<String, dynamic> preferences;
  final List<String> interests;

  PersonalData({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.dateOfBirth,
    required this.occupation,
    required this.preferences,
    required this.interests,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'dateOfBirth': dateOfBirth,
      'occupation': occupation,
      'preferences': preferences,
      'interests': interests,
    };
  }

  factory PersonalData.fromJson(Map<String, dynamic> json) {
    return PersonalData(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      dateOfBirth: json['dateOfBirth'] ?? '',
      occupation: json['occupation'] ?? '',
      preferences: Map<String, dynamic>.from(json['preferences'] ?? {}),
      interests: List<String>.from(json['interests'] ?? []),
    );
  }

  // Helper method to get all searchable text
  String getAllData() {
    return '$name $email $phone $address $dateOfBirth $occupation ${interests.join(' ')}';
  }
}
