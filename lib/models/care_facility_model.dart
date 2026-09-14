import 'dart:math' as math;

/// Facility classification for care navigation.
enum CareFacilityType {
  hospital,
  clinic,
  campusHealthCenter,
  urgentCare;

  String get displayName {
    switch (this) {
      case CareFacilityType.hospital:
        return 'Hospital';
      case CareFacilityType.clinic:
        return 'Clinic';
      case CareFacilityType.campusHealthCenter:
        return 'Campus Health Center';
      case CareFacilityType.urgentCare:
        return 'Urgent Care';
    }
  }

  static CareFacilityType fromString(String? val) {
    if (val == null) return CareFacilityType.clinic;
    final lower = val.toLowerCase();
    if (lower.contains('campus') || lower.contains('infirmary') || lower.contains('dispensary')) {
      return CareFacilityType.campusHealthCenter;
    }
    if (lower.contains('hospital')) {
      return CareFacilityType.hospital;
    }
    if (lower.contains('urgent')) {
      return CareFacilityType.urgentCare;
    }
    return CareFacilityType.clinic;
  }
}

/// Represents a verified healthcare facility (hospital, clinic, or campus health center)
/// for student care navigation.
class CareFacility {
  final String id;
  final String name;
  final CareFacilityType type;
  final String address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;
  final bool? isOpen;
  final String? operatingHours;
  final bool? emergencyServicesAvailable;
  final String? website;
  final double? rating;

  const CareFacility({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.isOpen,
    this.operatingHours,
    this.emergencyServicesAvailable,
    this.website,
    this.rating,
  });

  /// Formats the calculated distance into a human-readable string.
  /// Examples: "350 m", "1.4 km", or null if distance is unknown.
  String? get formattedDistance {
    if (distanceKm == null) return null;
    if (distanceKm! < 1.0) {
      final meters = (distanceKm! * 1000).round();
      return '$meters m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Calculates geodesic distance using Haversine formula from a given latitude and longitude.
  CareFacility withCalculatedDistance(double fromLat, double fromLng) {
    if (latitude == null || longitude == null) return this;

    const double earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(latitude! - fromLat);
    final dLng = _degreesToRadians(longitude! - fromLng);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(fromLat)) *
            math.cos(_degreesToRadians(latitude!)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final calculatedKm = earthRadiusKm * c;

    return copyWith(distanceKm: calculatedKm);
  }

  static double _degreesToRadians(double degrees) => degrees * (math.pi / 180.0);

  CareFacility copyWith({
    String? id,
    String? name,
    CareFacilityType? type,
    String? address,
    String? phone,
    double? latitude,
    double? longitude,
    double? distanceKm,
    bool? isOpen,
    String? operatingHours,
    bool? emergencyServicesAvailable,
    String? website,
    double? rating,
  }) {
    return CareFacility(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      isOpen: isOpen ?? this.isOpen,
      operatingHours: operatingHours ?? this.operatingHours,
      emergencyServicesAvailable:
          emergencyServicesAvailable ?? this.emergencyServicesAvailable,
      website: website ?? this.website,
      rating: rating ?? this.rating,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'address': address,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'isOpen': isOpen,
      'operatingHours': operatingHours,
      'emergencyServicesAvailable': emergencyServicesAvailable,
      'website': website,
      'rating': rating,
    };
  }

  factory CareFacility.fromMap(Map<String, dynamic> map) {
    return CareFacility(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Healthcare Facility',
      type: CareFacilityType.fromString(map['type'] as String?),
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      distanceKm: (map['distanceKm'] as num?)?.toDouble(),
      isOpen: map['isOpen'] as bool?,
      operatingHours: map['operatingHours'] as String?,
      emergencyServicesAvailable: map['emergencyServicesAvailable'] as bool?,
      website: map['website'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
    );
  }

  /// Parses a Google Places API (New) JSON place object.
  factory CareFacility.fromGooglePlacesNew(Map<String, dynamic> json) {
    final displayName = json['displayName'] is Map
        ? json['displayName']['text'] as String? ?? ''
        : (json['name'] as String? ?? 'Medical Facility');

    final types = (json['types'] as List?)?.cast<String>() ?? [];
    CareFacilityType detectedType = CareFacilityType.clinic;
    if (types.contains('hospital')) {
      detectedType = CareFacilityType.hospital;
    }

    final location = json['location'] as Map<String, dynamic>?;
    final lat = (location?['latitude'] as num?)?.toDouble();
    final lng = (location?['longitude'] as num?)?.toDouble();

    final openingHours = json['currentOpeningHours'] as Map<String, dynamic>?;
    final openNow = openingHours?['openNow'] as bool?;

    return CareFacility(
      id: json['id'] as String? ?? '',
      name: displayName,
      type: detectedType,
      address: json['formattedAddress'] as String? ?? '',
      phone: (json['internationalPhoneNumber'] ?? json['nationalPhoneNumber']) as String?,
      latitude: lat,
      longitude: lng,
      isOpen: openNow,
      website: json['websiteUri'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CareFacility &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
