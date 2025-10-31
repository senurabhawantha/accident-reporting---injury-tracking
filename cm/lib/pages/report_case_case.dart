import 'package:cm/pages/contact_us.dart';
import 'package:cm/pages/report_case_images.dart';
import 'package:cm/services/claims_service.dart';
import 'package:cm/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class ReportCaseCase extends StatefulWidget {
  final ClaimFormData formData;

  const ReportCaseCase({required this.formData, super.key});

  @override
  State<ReportCaseCase> createState() => _ReportCaseCaseState();
}

class _ReportCaseCaseState extends State<ReportCaseCase> {
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _damageController = TextEditingController();
  final TextEditingController _thirdPartyController = TextEditingController();
  String _currentLocation = '';
  bool _disableTextFields = true;
  bool _locationLoading = true;

  @override
  void dispose() {
    _locationController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _descriptionController.dispose();
    _damageController.dispose();
    _thirdPartyController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    _getDateAndTime();
  }

  void _getDateAndTime() {
    DateTime currentDate = DateTime.now();
    String formattedDate =
        currentDate.toString(); // Customize the date format as needed
    _dateController.text = formattedDate.split(' ')[0]; // Extract date
    _timeController.text =
        formattedDate.split(' ')[1].split('.')[0]; // Extract time
  }

  Future<void> _getLocation() async {
    setState(() {
      _locationLoading = true;
      _locationController.text = 'Detecting location...';
    });

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever || 
          permission == LocationPermission.denied) {
        setState(() {
          _locationLoading = false;
          _disableTextFields = false;  // Allow manual entry
          _locationController.text = '';
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Please enter location manually.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentLocation = 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        _locationController.text = _currentLocation;
        _locationLoading = false;
      });

      print('✅ Location detected: $_currentLocation');

    } catch (e) {
      print('❌ Location error: $e');
      setState(() {
        _locationLoading = false;
        _disableTextFields = false;  // Allow manual entry
        _locationController.text = '';
      });
      
      if (mounted) {
        String errorMessage = 'Could not detect location. Please enter manually.';
        
        // Provide specific error messages for common issues
        if (e.toString().contains('permissions')) {
          errorMessage = 'Location permission required. Please enable location access in settings or enter location manually.';
        } else if (e.toString().contains('disabled')) {
          errorMessage = 'Location services are disabled. Please enable GPS or enter location manually.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Location detection timed out. Please try again or enter location manually.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Manual Entry',
              textColor: Colors.white,
              onPressed: _showManualLocationDialog,
            ),
          ),
        );
      }
    }
  }

  void _showManualLocationDialog() {
    final TextEditingController manualLocationController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Location Manually'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GPS detection failed. Please enter the incident location manually:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: manualLocationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g., Main Street, City Name',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (manualLocationController.text.trim().isNotEmpty) {
                setState(() {
                  _locationController.text = manualLocationController.text.trim();
                  _disableTextFields = true; // Lock it again after manual entry
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Location entered manually'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _proceedToNext() {
    // Check if location is still loading
    if (_locationLoading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait while we detect your location...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate required fields
    List<String> missingFields = [];
    
    if (_dateController.text.trim().isEmpty) missingFields.add('Date');
    if (_timeController.text.trim().isEmpty) missingFields.add('Time');
    if (_locationController.text.trim().isEmpty || _locationController.text == 'Detecting location...') {
      missingFields.add('Location');
    }
    if (_descriptionController.text.trim().isEmpty) missingFields.add('Description');

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in: ${missingFields.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save case data to form data
    final caseData = {
      'incidentDate': _dateController.text.trim(),
      'incidentTime': _timeController.text.trim(),
      'location': _locationController.text.trim(),
      'description': _descriptionController.text.trim(),
      'causeOfDamage': _damageController.text.trim(),
      'thirdPartyDetails': _thirdPartyController.text.trim(),
      'currentLocation': _currentLocation,
      'submittedAt': DateTime.now().toIso8601String(),
    };

    // Create updated form data with case details
    final updatedFormData = widget.formData.copyWith(caseData: caseData);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Case details saved! Proceeding to image upload...'), 
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate to image upload page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportCaseImages(formData: updatedFormData),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Your Case',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              'Step 3: Case Details',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected Vehicle and Driver Summary
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Claim Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.directions_car, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Vehicle: ${widget.formData.vehicleData?['vehicleNumber'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Driver: ${widget.formData.driverData?['driverName'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Case Details Section
            const Text(
              'Incident Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Date and Time Row
            Row(
              children: [
                Expanded(
                  child: _buildDateTimeCard(
                    'Date',
                    _dateController.text.isNotEmpty ? _dateController.text : DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    Icons.calendar_today,
                    () => _selectDate(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTimeCard(
                    'Time',
                    _timeController.text.isNotEmpty ? _timeController.text : DateFormat('HH:mm').format(DateTime.now()),
                    Icons.access_time,
                    () => _selectTime(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location Field
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _locationController,
                  enabled: !_disableTextFields,
                  decoration: InputDecoration(
                    labelText: 'Incident Location',
                    hintText: _locationLoading 
                        ? 'Detecting GPS location...'
                        : (_disableTextFields ? 'GPS location detected' : 'Enter location manually'),
                    prefixIcon: _locationLoading 
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            ),
                          )
                        : Icon(Icons.location_on, color: AppTheme.primaryColor),
                    suffixIcon: !_locationLoading
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_disableTextFields)
                                IconButton(
                                  icon: Icon(Icons.my_location, color: AppTheme.primaryColor),
                                  onPressed: _getLocation,
                                  tooltip: 'Retry GPS detection',
                                ),
                              IconButton(
                                icon: Icon(Icons.edit_location, color: AppTheme.primaryColor),
                                onPressed: _showManualLocationDialog,
                                tooltip: 'Enter location manually',
                              ),
                            ],
                          )
                        : null,
                    border: InputBorder.none,
                    labelStyle: TextStyle(color: AppTheme.primaryColor),
                    hintStyle: TextStyle(color: Colors.grey[400]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Fields
            _buildTextField(
              controller: _descriptionController,
              label: 'Incident Description',
              hint: 'Describe what happened...',
              icon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _damageController,
              label: 'Cause of Damage',
              hint: 'What caused the damage?',
              icon: Icons.warning,
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            _buildTextField(
              controller: _thirdPartyController,
              label: 'Third Party Details (if any)',
              hint: 'Other party information...',
              icon: Icons.people,
              maxLines: 2,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ContactUs()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Need Help?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _proceedToNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeCard(String label, String value, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            border: InputBorder.none,
            labelStyle: TextStyle(color: AppTheme.primaryColor),
            hintStyle: TextStyle(color: Colors.grey[400]),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _timeController.text = picked.format(context);
      });
    }
  }
}
