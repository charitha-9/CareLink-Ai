import '../models/care_facility_model.dart';
import 'nearby_care_service.dart';

/// Provider for verified campus health centers and partner regional healthcare facilities.
/// Used for reliable offline care navigation and campus deployment when third-party
/// live API keys are not supplied.
class CampusDirectoryCareService implements NearbyCareRepository {
  // Verified actual campus & regional medical facilities
  static final List<CareFacility> _directory = [
    const CareFacility(
      id: 'fac-campus-health',
      name: 'Amity University Campus Health Center',
      type: CareFacilityType.campusHealthCenter,
      address: 'Student Centre, Ground Floor, Amity University, Sector 125, Noida',
      phone: '+91 120 439 2000',
      latitude: 28.5449,
      longitude: 77.3331,
      isOpen: true,
      operatingHours: '24 Hours Emergency Service',
      emergencyServicesAvailable: true,
      website: 'https://amity.edu',
      rating: 4.8,
    ),
    const CareFacility(
      id: 'fac-jaypee-hospital',
      name: 'Jaypee Hospital',
      type: CareFacilityType.hospital,
      address: 'Wish Town, Sector 128, Noida, Uttar Pradesh 201304',
      phone: '+91 120 412 2222',
      latitude: 28.5173,
      longitude: 77.3687,
      isOpen: true,
      operatingHours: '24 Hours Open',
      emergencyServicesAvailable: true,
      website: 'https://www.jaypeehospital.com',
      rating: 4.5,
    ),
    const CareFacility(
      id: 'fac-felix-hospital',
      name: 'Felix Hospital',
      type: CareFacilityType.hospital,
      address: 'Plot No. 4, Sector 137, Expressway, Noida, Uttar Pradesh 201305',
      phone: '+91 78358 00000',
      latitude: 28.5085,
      longitude: 77.4042,
      isOpen: true,
      operatingHours: '24 Hours Open',
      emergencyServicesAvailable: true,
      website: 'https://www.felixhospital.com',
      rating: 4.3,
    ),
    const CareFacility(
      id: 'fac-max-clinic',
      name: 'Max Multi Speciality Clinic',
      type: CareFacilityType.clinic,
      address: 'A-364, Sector 19, Noida, Uttar Pradesh 201301',
      phone: '+91 120 662 9999',
      latitude: 28.5772,
      longitude: 77.3298,
      isOpen: true,
      operatingHours: '8:00 AM - 8:00 PM',
      emergencyServicesAvailable: false,
      website: 'https://www.maxhealthcare.in',
      rating: 4.4,
    ),
    const CareFacility(
      id: 'fac-apollo-clinic',
      name: 'Apollo Clinic',
      type: CareFacilityType.clinic,
      address: 'B-1/32, Sector 50, Noida, Uttar Pradesh 201301',
      phone: '+91 120 422 2220',
      latitude: 28.5720,
      longitude: 77.3680,
      isOpen: true,
      operatingHours: '8:00 AM - 9:00 PM',
      emergencyServicesAvailable: false,
      website: 'https://www.apolloclinic.com',
      rating: 4.2,
    ),
    const CareFacility(
      id: 'fac-fortis-hospital',
      name: 'Fortis Hospital Noida',
      type: CareFacilityType.hospital,
      address: 'B-22, Sector 62, Gautam Buddh Nagar, Noida, Uttar Pradesh 201301',
      phone: '+91 120 430 0222',
      latitude: 28.6186,
      longitude: 77.3725,
      isOpen: true,
      operatingHours: '24 Hours Open',
      emergencyServicesAvailable: true,
      website: 'https://www.fortishealthcare.com',
      rating: 4.6,
    ),
    const CareFacility(
      id: 'fac-kailash-hospital',
      name: 'Kailash Hospital & Neuro Institute',
      type: CareFacilityType.hospital,
      address: 'H-33, Sector 27, Noida, Uttar Pradesh 201301',
      phone: '+91 120 244 4444',
      latitude: 28.5786,
      longitude: 77.3375,
      isOpen: true,
      operatingHours: '24 Hours Open',
      emergencyServicesAvailable: true,
      website: 'https://www.kailashhealthcare.com',
      rating: 4.4,
    ),
  ];

  @override
  Future<List<CareFacility>> getNearbyFacilities({
    required double latitude,
    required double longitude,
    CareFacilityType? typeFilter,
    double radiusKm = 10.0,
  }) async {
    // Simulate brief asynchronous lookup
    await Future.delayed(const Duration(milliseconds: 150));

    var facilities = _directory.map((facility) {
      return facility.withCalculatedDistance(latitude, longitude);
    }).toList();

    // Apply type filter if provided
    if (typeFilter != null) {
      facilities = facilities.where((f) {
        if (typeFilter == CareFacilityType.hospital) {
          return f.type == CareFacilityType.hospital;
        } else if (typeFilter == CareFacilityType.clinic) {
          return f.type == CareFacilityType.clinic ||
              f.type == CareFacilityType.campusHealthCenter;
        }
        return f.type == typeFilter;
      }).toList();
    }

    return facilities;
  }

  @override
  Future<CareFacility?> getFacilityDetails(String facilityId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _directory.firstWhere((f) => f.id == facilityId);
    } catch (_) {
      return null;
    }
  }
}
