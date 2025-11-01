import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script to add sample vehicles to Firebase Firestore
/// Run this once to populate your Firebase with test vehicle data
class AddSampleVehicles {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add sample vehicles for the current logged-in user
  Future<void> addVehiclesToFirebase() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ Error: No user is logged in. Please login first.');
        return;
      }

      print('🔄 Adding vehicles to Firebase for user: $userId');

      // Sample vehicles data
      final vehicles = [
        {
          'userId': userId,
          'vehicleNumber': 'WP BEA-1622',
          'make': 'Honda',
          'model': 'Dio',
          'year': '2022',
          'color': 'Red',
          'fuelType': 'Petrol',
          'engineCapacity': '110cc',
          'chassisNumber': 'MH1JF5011CK001234',
          'engineNumber': 'JF5011E001234',
          'vehicleType': 'Motorcycle',
          'insuranceCompany': 'Ceylinco Insurance',
          'insurancePolicyNumber': 'POL-2022-001',
          'insuranceExpiryDate': '2025-12-31',
          'ownerName': 'John Doe',
          'ownerNic': '950123456V',
          'ownerPhone': '+94771234567',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'vehicleNumber': 'WP CBE-1287',
          'make': 'Toyota',
          'model': 'Camry',
          'year': '2021',
          'color': 'Silver',
          'fuelType': 'Hybrid',
          'engineCapacity': '2500cc',
          'chassisNumber': 'JTDK4RBE1L3012345',
          'engineNumber': '2AR-FXE012345',
          'vehicleType': 'Car',
          'insuranceCompany': 'Allianz Insurance',
          'insurancePolicyNumber': 'POL-2021-002',
          'insuranceExpiryDate': '2025-11-30',
          'ownerName': 'John Doe',
          'ownerNic': '950123456V',
          'ownerPhone': '+94771234567',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'vehicleNumber': 'WP BBD-1785',
          'make': 'Ford',
          'model': 'Mustang',
          'year': '2023',
          'color': 'Blue',
          'fuelType': 'Petrol',
          'engineCapacity': '5000cc',
          'chassisNumber': '1FA6P8CF4L5123456',
          'engineNumber': 'COYOTE-V8-123456',
          'vehicleType': 'Car',
          'insuranceCompany': 'AIG Insurance',
          'insurancePolicyNumber': 'POL-2023-003',
          'insuranceExpiryDate': '2026-01-15',
          'ownerName': 'John Doe',
          'ownerNic': '950123456V',
          'ownerPhone': '+94771234567',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        {
          'userId': userId,
          'vehicleNumber': 'WP CAA-2456',
          'make': 'Suzuki',
          'model': 'Alto',
          'year': '2020',
          'color': 'White',
          'fuelType': 'Petrol',
          'engineCapacity': '800cc',
          'chassisNumber': 'MA3FD12S000123456',
          'engineNumber': 'F8D-123456',
          'vehicleType': 'Car',
          'insuranceCompany': 'SLIC Insurance',
          'insurancePolicyNumber': 'POL-2020-004',
          'insuranceExpiryDate': '2025-10-31',
          'ownerName': 'John Doe',
          'ownerNic': '950123456V',
          'ownerPhone': '+94771234567',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ];

      // Add each vehicle to Firestore
      int successCount = 0;
      for (var vehicle in vehicles) {
        try {
          await _firestore.collection('vehicles').add(vehicle);
          print('✅ Added vehicle: ${vehicle['vehicleNumber']}');
          successCount++;
        } catch (e) {
          print('❌ Failed to add vehicle ${vehicle['vehicleNumber']}: $e');
        }
      }

      print('\n🎉 Successfully added $successCount out of ${vehicles.length} vehicles to Firebase!');
      print('📱 You can now view these vehicles in the Report Case page.');
    } catch (e) {
      print('❌ Error adding vehicles: $e');
    }
  }

  /// Delete all vehicles for current user (cleanup function)
  Future<void> deleteAllUserVehicles() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        print('❌ Error: No user is logged in.');
        return;
      }

      print('🔄 Deleting all vehicles for user: $userId');

      final snapshot = await _firestore
          .collection('vehicles')
          .where('userId', isEqualTo: userId)
          .get();

      int deleteCount = 0;
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
        deleteCount++;
      }

      print('✅ Deleted $deleteCount vehicles from Firebase.');
    } catch (e) {
      print('❌ Error deleting vehicles: $e');
    }
  }
}
