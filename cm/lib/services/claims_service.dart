import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Service to manage claims, vehicles, and related data in Firebase
class ClaimsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // ==================== VEHICLE METHODS ====================

  /// Fetch all registered vehicles for current user
  Future<List<Map<String, dynamic>>> getUserVehicles() async {
    try {
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('vehicles')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error fetching vehicles: $e');
      return [];
    }
  }

  /// Get specific vehicle details
  Future<Map<String, dynamic>?> getVehicleDetails(String vehicleId) async {
    try {
      final doc = await _firestore.collection('vehicles').doc(vehicleId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      print('Error fetching vehicle details: $e');
      return null;
    }
  }

  /// Add a new vehicle for the current user
  Future<String?> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      if (userId == null) throw Exception('User not authenticated');

      final data = {
        ...vehicleData,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('vehicles').add(data);
      print('✅ Vehicle added successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error adding vehicle: $e');
      throw e;
    }
  }

  // ==================== CLAIM METHODS ====================

  /// Create a new claim with vehicle and driver details
  Future<String?> createClaim({
    required String vehicleId,
    required Map<String, dynamic> vehicleData,
    required Map<String, dynamic> driverData,
    required Map<String, dynamic> caseData,
    List<String>? imageUrls,
  }) async {
    try {
      if (userId == null) throw Exception('User not authenticated');

      final claimData = {
        'userId': userId,
        'vehicleId': vehicleId,
        'vehicleData': vehicleData,
        'driverData': driverData,
        'caseData': caseData,
        'imageUrls': imageUrls ?? [],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('claims').add(claimData);
      print('✅ Claim created successfully: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating claim: $e');
      return null;
    }
  }

  /// Update existing claim
  Future<bool> updateClaim(String claimId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('claims').doc(claimId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating claim: $e');
      return false;
    }
  }

  /// Get all claims for current user
  Future<List<Map<String, dynamic>>> getUserClaims() async {
    try {
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('claims')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      print('Error fetching claims: $e');
      return [];
    }
  }

  /// Get specific claim details
  Future<Map<String, dynamic>?> getClaimDetails(String claimId) async {
    try {
      final doc = await _firestore.collection('claims').doc(claimId).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      print('Error fetching claim details: $e');
      return null;
    }
  }

  // ==================== IMAGE UPLOAD METHODS ====================

  /// Upload images to Firebase Storage and return URLs
  Future<List<String>> uploadClaimImages(
    String claimId,
    List<File> imageFiles,
  ) async {
    List<String> uploadedUrls = [];

    try {
      for (int i = 0; i < imageFiles.length; i++) {
        final file = imageFiles[i];
        final fileName = 'claim_${claimId}_image_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = _storage.ref().child('claims/$claimId/$fileName');

        // Upload file
        print('📤 Uploading image ${i + 1}/${imageFiles.length}...');
        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        
        uploadedUrls.add(downloadUrl);
        print('✅ Image ${i + 1} uploaded successfully');
      }

      return uploadedUrls;
    } catch (e) {
      print('❌ Error uploading images: $e');
      return uploadedUrls; // Return partial results
    }
  }

  // ==================== USER PROFILE METHODS ====================

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Update user statistics (increment claim count)
  Future<void> updateUserStats() async {
    try {
      if (userId == null) return;

      await _firestore.collection('users').doc(userId).update({
        'totalClaims': FieldValue.increment(1),
        'lastClaimDate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user stats: $e');
    }
  }

  /// Submit complete claim with all data
  Future<String?> submitCompleteClaim(ClaimFormData formData) async {
    try {
      if (userId == null) throw Exception('User not authenticated');

      // Generate claim reference
      final claimRef = generateClaimReference();

      // Prepare image paths (local storage)
      final imagePaths = formData.imageFiles?.map((file) => file.path).toList() ?? [];

      final claimData = {
        'userId': userId,
        'claimReference': claimRef,
        'vehicleId': formData.vehicleId,
        'vehicleData': formData.vehicleData,
        'driverData': formData.driverData,
        'caseData': formData.caseData,
        'imagePaths': imagePaths, // Local file paths
        'imageCount': imagePaths.length,
        'status': 'submitted',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('claims').add(claimData);
      print('✅ Complete claim submitted successfully: ${docRef.id}');

      // Update user statistics
      await updateUserStats();

      return docRef.id;
    } catch (e) {
      print('❌ Error submitting claim: $e');
      return null;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Generate claim reference number
  String generateClaimReference() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    return 'CM${DateTime.now().year}$random';
  }

  /// Format timestamp to readable date
  String formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'N/A';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  /// Format timestamp to readable date and time
  String formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else {
      return 'N/A';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Model for passing claim data between screens
class ClaimFormData {
  String? vehicleId;
  Map<String, dynamic>? vehicleData;
  Map<String, dynamic>? driverData;
  Map<String, dynamic>? caseData;
  List<File>? imageFiles;
  String? claimId;

  ClaimFormData({
    this.vehicleId,
    this.vehicleData,
    this.driverData,
    this.caseData,
    this.imageFiles,
    this.claimId,
  });

  ClaimFormData copyWith({
    String? vehicleId,
    Map<String, dynamic>? vehicleData,
    Map<String, dynamic>? driverData,
    Map<String, dynamic>? caseData,
    List<File>? imageFiles,
    String? claimId,
  }) {
    return ClaimFormData(
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleData: vehicleData ?? this.vehicleData,
      driverData: driverData ?? this.driverData,
      caseData: caseData ?? this.caseData,
      imageFiles: imageFiles ?? this.imageFiles,
      claimId: claimId ?? this.claimId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': vehicleId,
      'vehicleData': vehicleData,
      'driverData': driverData,
      'caseData': caseData,
      'claimId': claimId,
    };
  }
}
