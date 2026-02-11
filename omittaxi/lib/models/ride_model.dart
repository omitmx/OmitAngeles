import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'user_model.dart';

class RideModel {
  final String id;
  final String passengerId;
  final String? driverId;
  final UserModel? passenger; // Datos del pasajero
  final UserModel? driver; // Datos del conductor
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final String pickupAddress;
  final String dropoffAddress;
  final DateTime requestTime;
  final DateTime? acceptedTime;
  final DateTime? pickupTime;
  final DateTime? dropoffTime;
  final String
  status; // 'requested', 'accepted', 'in_progress', 'completed', 'cancelled'
  final double fare;
  final double distance;
  final int? passengerRating;
  final int? driverRating;
  final String? passengerComment;
  final String? driverComment;
  final String? paymentMethod;

  RideModel({
    required this.id,
    required this.passengerId,
    this.driverId,
    this.passenger,
    this.driver,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.requestTime,
    this.acceptedTime,
    this.pickupTime,
    this.dropoffTime,
    required this.status,
    required this.fare,
    required this.distance,
    this.passengerRating,
    this.driverRating,
    this.passengerComment,
    this.driverComment,
    this.paymentMethod = 'cash',
  });

  factory RideModel.fromJson(Map<String, dynamic> json) {
    // Parsear ubicaciones
    LatLng pickupLoc;
    if (json['pickupLocation']['coordinates'] != null) {
      final coords =
          json['pickupLocation']['coordinates']['coordinates'] as List;
      pickupLoc = LatLng(coords[1], coords[0]); // MongoDB guarda [lng, lat]
    } else {
      pickupLoc = const LatLng(0, 0);
    }

    LatLng dropoffLoc;
    if (json['dropoffLocation']['coordinates'] != null) {
      final coords =
          json['dropoffLocation']['coordinates']['coordinates'] as List;
      dropoffLoc = LatLng(coords[1], coords[0]);
    } else {
      dropoffLoc = const LatLng(0, 0);
    }

    return RideModel(
      id: json['_id'] ?? json['id'] ?? '',
      passengerId: json['passenger'] is String
          ? json['passenger']
          : (json['passenger']?['_id'] ?? ''),
      driverId: json['driver'] is String
          ? json['driver']
          : (json['driver']?['_id']),
      passenger: json['passenger'] is Map
          ? UserModel.fromJson(json['passenger'])
          : null,
      driver: json['driver'] is Map ? UserModel.fromJson(json['driver']) : null,
      pickupLocation: pickupLoc,
      dropoffLocation: dropoffLoc,
      pickupAddress: json['pickupLocation']?['address'] ?? '',
      dropoffAddress: json['dropoffLocation']?['address'] ?? '',
      requestTime: DateTime.parse(json['requestedAt'] ?? json['createdAt']),
      acceptedTime: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'])
          : null,
      pickupTime: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      dropoffTime: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      status: json['status'] ?? 'requested',
      fare: (json['fare']?['total'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      passengerRating: json['passengerRating'],
      driverRating: json['driverRating'],
      passengerComment: json['passengerComment'],
      driverComment: json['driverComment'],
      paymentMethod: json['paymentMethod'] ?? 'cash',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'passenger': passengerId,
      'driver': driverId,
      'pickupLocation': {
        'address': pickupAddress,
        'coordinates': {
          'type': 'Point',
          'coordinates': [pickupLocation.longitude, pickupLocation.latitude],
        },
      },
      'dropoffLocation': {
        'address': dropoffAddress,
        'coordinates': {
          'type': 'Point',
          'coordinates': [dropoffLocation.longitude, dropoffLocation.latitude],
        },
      },
      'requestedAt': requestTime.toIso8601String(),
      'acceptedAt': acceptedTime?.toIso8601String(),
      'startedAt': pickupTime?.toIso8601String(),
      'completedAt': dropoffTime?.toIso8601String(),
      'status': status,
      'fare': {'total': fare},
      'distance': distance,
      'passengerRating': passengerRating,
      'driverRating': driverRating,
      'passengerComment': passengerComment,
      'driverComment': driverComment,
      'paymentMethod': paymentMethod,
    };
  }

  RideModel copyWith({
    String? id,
    String? passengerId,
    String? driverId,
    UserModel? passenger,
    UserModel? driver,
    LatLng? pickupLocation,
    LatLng? dropoffLocation,
    String? pickupAddress,
    String? dropoffAddress,
    DateTime? requestTime,
    DateTime? acceptedTime,
    DateTime? pickupTime,
    DateTime? dropoffTime,
    String? status,
    double? fare,
    double? distance,
    int? passengerRating,
    int? driverRating,
    String? passengerComment,
    String? driverComment,
    String? paymentMethod,
  }) {
    return RideModel(
      id: id ?? this.id,
      passengerId: passengerId ?? this.passengerId,
      driverId: driverId ?? this.driverId,
      passenger: passenger ?? this.passenger,
      driver: driver ?? this.driver,
      pickupLocation: pickupLocation ?? this.pickupLocation,
      dropoffLocation: dropoffLocation ?? this.dropoffLocation,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      requestTime: requestTime ?? this.requestTime,
      acceptedTime: acceptedTime ?? this.acceptedTime,
      pickupTime: pickupTime ?? this.pickupTime,
      dropoffTime: dropoffTime ?? this.dropoffTime,
      status: status ?? this.status,
      fare: fare ?? this.fare,
      distance: distance ?? this.distance,
      passengerRating: passengerRating ?? this.passengerRating,
      driverRating: driverRating ?? this.driverRating,
      passengerComment: passengerComment ?? this.passengerComment,
      driverComment: driverComment ?? this.driverComment,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }
}
