import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cm/theme/app_theme.dart';

class ClaimDetailsPage extends StatefulWidget {
  final String claimId;

  const ClaimDetailsPage({
    required this.claimId,
    super.key,
  });

  @override
  State<ClaimDetailsPage> createState() => _ClaimDetailsPageState();
}

class _ClaimDetailsPageState extends State<ClaimDetailsPage> {
  Map<String, dynamic>? claimData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClaimDetails();
  }

  Future<void> _loadClaimDetails() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('claims')
          .doc(widget.claimId)
          .get();

      if (doc.exists) {
        setState(() {
          claimData = {'id': doc.id, ...doc.data()!};
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading claim details: $e');
      setState(() => isLoading = false);
    }
  }

  String _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'submitted':
      case 'pending':
        return '#FFA000';
      case 'approved':
        return '#4CAF50';
      case 'rejected':
        return '#D32F2F';
      case 'processing':
        return '#1976D2';
      default:
        return '#757575';
    }
  }

  Widget _buildInfoCard(String title, Map<String, dynamic> data) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            ...data.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 120,
                        child: Text(
                          '${entry.key}:',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value?.toString() ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
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
        title: const Text('Claim Details'),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : claimData == null
              ? const Center(
                  child: Text(
                    'Claim not found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Reference Header
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryColor, AppTheme.accentColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Claim Reference',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                claimData?['claimReference']?.toString() ?? 'N/A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Color(int.parse(
                                    '0xFF${_getStatusColor(claimData?['status']?.toString() ?? 'pending').substring(1)}',
                                  )),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  (claimData?['status']?.toString() ?? 'pending').toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Vehicle Information
                      if (claimData?['vehicleData'] != null)
                        _buildInfoCard('Vehicle Information', {
                          'Vehicle Number': claimData!['vehicleData']['vehicleNumber'],
                          'Make': claimData!['vehicleData']['make'],
                          'Model': claimData!['vehicleData']['model'],
                          'Year': claimData!['vehicleData']['year'],
                          'Engine Number': claimData!['vehicleData']['engineNumber'],
                          'Chassis Number': claimData!['vehicleData']['chassisNumber'],
                        }),
                      
                      // Driver Information
                      if (claimData?['driverData'] != null)
                        _buildInfoCard('Driver Information', {
                          'Name': claimData!['driverData']['name'],
                          'License Number': claimData!['driverData']['licenseNumber'],
                          'Phone': claimData!['driverData']['phone'],
                          'Email': claimData!['driverData']['email'],
                        }),
                      
                      // Case Information
                      if (claimData?['caseData'] != null)
                        _buildInfoCard('Incident Information', {
                          'Date & Time': claimData!['caseData']['dateTime'],
                          'Location': claimData!['caseData']['location'],
                          'Description': claimData!['caseData']['description'],
                        }),
                      
                      // Claim Information
                      _buildInfoCard('Claim Information', {
                        'Created': claimData?['createdAt'] != null
                            ? (claimData!['createdAt'] as Timestamp)
                                .toDate()
                                .toString()
                                .split('.')[0]
                            : 'N/A',
                        'Last Updated': claimData?['updatedAt'] != null
                            ? (claimData!['updatedAt'] as Timestamp)
                                .toDate()
                                .toString()
                                .split('.')[0]
                            : 'N/A',
                      }),
                    ],
                  ),
                ),
    );
  }
}