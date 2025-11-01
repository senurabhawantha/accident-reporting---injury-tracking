import 'package:flutter/material.dart';
import 'package:cm/theme/app_theme.dart';
import 'package:cm/services/claims_service.dart';
import 'package:cm/pages/report_case_driver.dart';

class ReportCaseVehicle extends StatefulWidget {
  const ReportCaseVehicle({super.key});

  @override
  State<ReportCaseVehicle> createState() => _ReportCaseVehicleState();
}

class _ReportCaseVehicleState extends State<ReportCaseVehicle> {
  final ClaimsService _claimsService = ClaimsService();
  List<Map<String, dynamic>> _vehicles = [];
  Map<String, dynamic>? _selectedVehicle;
  bool _isLoading = true;
  String? _selectedVehicleId;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    setState(() => _isLoading = true);
    try {
      final vehicles = await _claimsService.getUserVehicles();
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading vehicles: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vehicles: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _proceedToNext() {
    if (_selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle'), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Create form data and navigate to driver form
    final formData = ClaimFormData(vehicleId: _selectedVehicleId, vehicleData: _selectedVehicle);
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => ReportCaseDriver(formData: formData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
        title: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Report Your Case', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20)), Text('Step 1: Vehicle', style: TextStyle(color: Colors.grey, fontSize: 13))]),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _vehicles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_car_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 24),
                    const Text(
                      'No Vehicles Found',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You need to add vehicles to Firebase before reporting a case.',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Go back to dashboard
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Dashboard'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadVehicles,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20 : 16), 
              itemCount: _vehicles.length, 
              itemBuilder: (context, index) {
        final vehicle = _vehicles[index];
        final isSelected = _selectedVehicleId == vehicle['id'];
        return GestureDetector(
          onTap: () => setState(() {_selectedVehicle = vehicle; _selectedVehicleId = vehicle['id'];}),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!, width: isSelected ? 2 : 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: Row(children: [
              Icon(Icons.directions_car, size: 40, color: isSelected ? AppTheme.primaryColor : Colors.grey),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vehicle['vehicleNumber'] ?? 'N/A', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''}'.trim(), style: TextStyle(color: Colors.grey[600])),
              ])),
              if (isSelected) Icon(Icons.check_circle, color: AppTheme.primaryColor),
            ]),
          ),
        );
      }),
      bottomNavigationBar: _vehicles.isEmpty ? null : Container(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: _proceedToNext,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
          child: const Text('Next', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }
}
