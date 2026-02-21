class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String userType; // 'passenger' o 'driver'
  final String? photoUrl;
  final double rating;
  final int totalRides;
  final Map<String, dynamic>? vehicleInfo; // Info del vehículo para conductores
  final String? economicNumber; // Número económico de la unidad (conductores)
  final String? licenseNumber; // Licencia de conducir
  final String? token; // Token de autenticación

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.photoUrl,
    this.rating = 5.0,
    this.totalRides = 0,
    this.vehicleInfo,
    this.economicNumber,
    this.licenseNumber,
    this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['userType'] ?? 'passenger',
      photoUrl: json['profilePhoto'] ?? json['photoUrl'],
      rating: (json['rating'] ?? 5.0).toDouble(),
      totalRides: json['totalRides'] ?? 0,
      vehicleInfo: json['vehicleInfo'],
      economicNumber: json['economicNumber'],
      licenseNumber: json['licenseNumber'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'profilePhoto': photoUrl,
      'rating': rating,
      'totalRides': totalRides,
      'vehicleInfo': vehicleInfo,
      'economicNumber': economicNumber,
      'licenseNumber': licenseNumber,
    };
  }
}
