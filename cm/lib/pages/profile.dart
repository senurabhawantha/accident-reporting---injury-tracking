import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cm/theme/app_theme.dart';
import 'package:cm/pages/contact_us.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  Map<String, dynamic> userData = {};
  int claimCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadClaimCount();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      if (user != null) {
        // Add a small delay to ensure Firebase is ready
        await Future.delayed(const Duration(milliseconds: 200));
        
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (!mounted) return;

        if (doc.exists && doc.data() != null) {
          setState(() {
            userData = doc.data() as Map<String, dynamic>;
            isLoading = false;
          });
        } else {
          // If no Firestore data, use Firebase Auth data and create user document
          final defaultUserData = {
            'name': user!.displayName ?? 'User',
            'email': user!.email ?? '',
            'phone': user!.phoneNumber ?? 'Not set',
            'address': 'Not set',
            'totalClaims': 0,
            'createdAt': FieldValue.serverTimestamp(),
          };
          
          // Create user document in Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .set(defaultUserData, SetOptions(merge: true));
          
          setState(() {
            userData = defaultUserData;
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        // Fallback to Firebase Auth data on error
        setState(() {
          userData = {
            'name': user?.displayName ?? 'User',
            'email': user?.email ?? '',
            'phone': user?.phoneNumber ?? 'Not set',
            'address': 'Not set',
          };
          isLoading = false;
        });
      }
    }
  }

  Future<void> _loadClaimCount() async {
    if (user == null) return;
    
    try {
      final QuerySnapshot claimsSnapshot = await FirebaseFirestore.instance
          .collection('claims')
          .where('userId', isEqualTo: user!.uid)
          .get();
      
      if (mounted) {
        setState(() {
          claimCount = claimsSnapshot.docs.length;
        });
        
        // Update user's total claims count in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'totalClaims': claimCount});
      }
    } catch (e) {
      print('Error loading claim count: $e');
    }
  }

  Future<int> _getVehicleCount() async {
    if (user == null) return 0;
    
    try {
      final QuerySnapshot vehiclesSnapshot = await FirebaseFirestore.instance
          .collection('vehicles')
          .where('userId', isEqualTo: user!.uid)
          .get();
      
      return vehiclesSnapshot.docs.length;
    } catch (e) {
      print('Error loading vehicle count: $e');
      return 0;
    }
  }

  Future<void> _editField(String fieldName, String currentValue) async {
    final TextEditingController controller = TextEditingController(text: currentValue == 'Not set' ? '' : currentValue);
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $fieldName'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: fieldName,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          keyboardType: fieldName.contains('Phone') ? TextInputType.phone : TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty && result != currentValue) {
      await _updateUserField(fieldName.toLowerCase(), result);
    }
  }

  Future<void> _updateUserField(String fieldName, String value) async {
    if (user == null) return;
    
    try {
      setState(() => isLoading = true);
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({fieldName: value});
      
      setState(() {
        userData[fieldName] = value;
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fieldName[0].toUpperCase()}${fieldName.substring(1)} updated successfully'),
            backgroundColor: AppTheme.primaryColor,
          ),
        );
      }
    } catch (e) {
      print('Error updating field: $e');
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error updating profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Recently joined';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else {
        return 'Recently joined';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime).inDays;
      
      if (difference < 30) {
        return 'This month';
      } else if (difference < 365) {
        final months = (difference / 30).floor();
        return '$months month${months > 1 ? 's' : ''} ago';
      } else {
        final years = (difference / 365).floor();
        return '$years year${years > 1 ? 's' : ''} ago';
      }
    } catch (e) {
      return 'Recently joined';
    }
  }

  Widget _buildInfoTile({
    required String label,
    required String value,
    IconData? icon,
    bool isEditable = false,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isEditable && onEdit != null)
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                onPressed: onEdit,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await _loadUserData();
    await _loadClaimCount();
  }

  Future<void> _showSignOutDialog() async {
    final bool? shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error signing out. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          backgroundImage: user?.photoURL != null
                              ? NetworkImage(user!.photoURL!)
                              : null,
                          child: user?.photoURL == null
                              ? const Icon(Icons.person,
                                  size: 50, color: AppTheme.primaryColor)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          userData['name'] ?? user?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user?.email ?? 'No email',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Profile Information
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoTile(
                          label: 'Phone Number',
                          value: userData['phone'] ?? 'Not set',
                          icon: Icons.phone,
                          isEditable: true,
                          onEdit: () => _editField('Phone', userData['phone'] ?? 'Not set'),
                        ),
                        _buildInfoTile(
                          label: 'Address',
                          value: userData['address'] ?? 'Not set',
                          icon: Icons.location_on,
                          isEditable: true,
                          onEdit: () => _editField('Address', userData['address'] ?? 'Not set'),
                        ),
                        _buildInfoTile(
                          label: 'Total Claims',
                          value: claimCount.toString(),
                          icon: Icons.description,
                        ),
                        _buildInfoTile(
                          label: 'Member Since',
                          value: userData['createdAt'] != null 
                              ? _formatDate(userData['createdAt'])
                              : 'Recently joined',
                          icon: Icons.calendar_today,
                        ),

                        const SizedBox(height: 24),

                        // Statistics Section
                        const Text(
                          'Quick Stats',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.accentColor.withOpacity(0.1)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.description,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      claimCount.toString(),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const Text(
                                      'Total Claims',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.directions_car,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    FutureBuilder<int>(
                                      future: _getVehicleCount(),
                                      builder: (context, snapshot) => Text(
                                        snapshot.data?.toString() ?? '0',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      'Vehicles',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Contact Us Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ContactUs(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Contact Us',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Sign Out Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _showSignOutDialog(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Sign Out',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
