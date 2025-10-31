import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cm/pages/contact_us.dart';
import 'package:cm/pages/old_cases.dart';
import 'package:cm/pages/profile.dart';
import 'package:cm/pages/report_case_vehicle.dart';
import 'package:cm/pages/injury_tracker_page.dart';
import 'package:cm/pages/reg_vehicles.dart';
import 'package:cm/theme/app_theme.dart';
import 'login_page.dart';

class DashboardScreen extends StatefulWidget {
  final String token;
  final String nic;

  const DashboardScreen({
    required this.token,
    required this.nic,
    super.key,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  String userName = '';
  int activeClaims = 0;
  int totalClaims = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String _getDisplayName(String? name) {
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }
    
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      return user!.displayName!.trim();
    }
    
    if (user?.email != null && user!.email!.isNotEmpty) {
      // Extract name from email (part before @)
      String emailName = user!.email!.split('@').first;
      // Capitalize first letter
      return emailName.isNotEmpty 
          ? emailName[0].toUpperCase() + emailName.substring(1)
          : 'User';
    }
    
    return 'User';
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        // Load user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        String firestoreName = '';
        if (userDoc.exists && userDoc.data() != null) {
          firestoreName = userDoc.data()?['name']?.toString() ?? '';
        }
        
        // Use helper method to get the best available display name
        setState(() {
          userName = _getDisplayName(firestoreName);
          print('Dashboard: Setting userName to: "$userName"');
          print('Dashboard: Firestore name was: "$firestoreName"');
          print('Dashboard: User displayName: "${user?.displayName}"');
          print('Dashboard: User email: "${user?.email}"');
        });

        // Load claims data
        final claimsSnapshot = await FirebaseFirestore.instance
            .collection('claims')
            .where('userId', isEqualTo: user!.uid)
            .get();

        final activeClaimsSnapshot = await FirebaseFirestore.instance
            .collection('claims')
            .where('userId', isEqualTo: user!.uid)
            .where('status', whereIn: ['submitted', 'pending', 'processing'])
            .get();

        setState(() {
          totalClaims = claimsSnapshot.docs.length;
          activeClaims = activeClaimsSnapshot.docs.length;
          isLoading = false;
        });
      } catch (e) {
        print('Error loading data: $e');
        setState(() {
          // Ensure userName is set even if there's an error
          if (userName.isEmpty) {
            userName = _getDisplayName(null);
          }
          isLoading = false;
        });
      }
    } else {
      // Handle case when user is null
      setState(() {
        userName = 'Guest User';
        isLoading = false;
      });
    }
  }

  void _handleNewClaim() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReportCaseVehicle(),
      ),
    );
  }

  void _handleViewClaims() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OldCases(),
      ),
    );
  }

  void _handleProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Profile(),
      ),
    );
  }

  void _handleInjuryTracker() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const InjuryTrackerPage(),
      ),
    );
  }

  void _handleRegisterVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegVehicles(),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required String description,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color ?? AppTheme.primaryColor,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty 
                                ? 'Welcome, $userName!' 
                                : 'Welcome!',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.pending_actions,
                                        color: AppTheme.primaryColor,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        activeClaims.toString(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const Text(
                                        'Active Claims',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(
                                        Icons.history,
                                        color: AppTheme.primaryColor,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        totalClaims.toString(),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const Text(
                                        'Total Claims',
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Quick Actions Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  title: 'New Claim',
                                  icon: Icons.add_circle_outline,
                                  description: 'File a new insurance claim',
                                  onTap: _handleNewClaim,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildActionCard(
                                  title: 'My Claims',
                                  icon: Icons.description_outlined,
                                  description: 'View your claim history',
                                  onTap: _handleViewClaims,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  title: 'Profile',
                                  icon: Icons.person_outline,
                                  description: 'Manage your account',
                                  onTap: _handleProfile,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildActionCard(
                                  title: 'Support',
                                  icon: Icons.help_outline,
                                  description: 'Get help and support',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const ContactUs(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionCard(
                                  title: 'Register Vehicle',
                                  icon: Icons.directions_car_outlined,
                                  description: 'Add your vehicles for claims',
                                  onTap: _handleRegisterVehicle,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildActionCard(
                                  title: 'Injury Tracker',
                                  icon: Icons.medical_services_outlined,
                                  description: 'AI-powered wound analysis',
                                  onTap: _handleInjuryTracker,
                                  color: Colors.purple,
                                ),
                              ),
                            ],
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
