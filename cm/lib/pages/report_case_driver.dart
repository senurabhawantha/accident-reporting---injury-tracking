import 'package:flutter/material.dart';
import 'package:cm/theme/app_theme.dart';
import 'package:cm/services/claims_service.dart';
import 'package:cm/pages/report_case_case.dart';
import 'package:intl/intl.dart';

class ReportCaseDriver extends StatefulWidget {
  final ClaimFormData formData;

  const ReportCaseDriver({required this.formData, super.key});

  @override
  State<ReportCaseDriver> createState() => _ReportCaseDriverState();
}

class _ReportCaseDriverState extends State<ReportCaseDriver> {
  final _formKey = GlobalKey<FormState>();
  final _driverNameController = TextEditingController();
  final _driverNicController = TextEditingController();
  final _driverLicenseController = TextEditingController();
  final _driverPhoneController = TextEditingController();
  final _driverAddressController = TextEditingController();
  DateTime? _licenseIssuedDate;
  DateTime? _licenseExpiryDate;
  bool _isSameAsOwner = false;

  @override
  void initState() {
    super.initState();
  }

  void _toggleSameAsOwner(bool? value) {
    setState(() {
      _isSameAsOwner = value ?? false;
      if (_isSameAsOwner && widget.formData.vehicleData != null) {
        final vehicleData = widget.formData.vehicleData!;
        _driverNameController.text = vehicleData['ownerName'] ?? '';
        _driverNicController.text = vehicleData['ownerNic'] ?? '';
        _driverPhoneController.text = vehicleData['ownerPhone'] ?? '';
      } else {
        _driverNameController.clear();
        _driverNicController.clear();
        _driverPhoneController.clear();
      }
    });
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate 
        ? (_licenseIssuedDate ?? DateTime.now()) 
        : (_licenseExpiryDate ?? DateTime.now().add(const Duration(days: 365))),
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _licenseIssuedDate = picked;
        } else {
          _licenseExpiryDate = picked;
        }
      });
    }
  }

  void _proceedToNext() {
    if (_formKey.currentState!.validate()) {
      if (_licenseIssuedDate == null || _licenseExpiryDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select license issue and expiry dates'), 
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Save driver data to form data
      final driverData = {
        'driverName': _driverNameController.text.trim(),
        'driverNic': _driverNicController.text.trim(),
        'driverLicense': _driverLicenseController.text.trim(),
        'driverPhone': _driverPhoneController.text.trim(),
        'driverAddress': _driverAddressController.text.trim(),
        'licenseIssuedDate': _licenseIssuedDate!.toIso8601String(),
        'licenseExpiryDate': _licenseExpiryDate!.toIso8601String(),
        'isSameAsOwner': _isSameAsOwner,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Create updated form data with driver details
      final updatedFormData = widget.formData.copyWith(driverData: driverData);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Driver details saved! Proceeding to case details...'), 
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate to case details form with the updated form data
      Navigator.push(
        context, 
        MaterialPageRoute(
          builder: (context) => ReportCaseCase(formData: updatedFormData),
        ),
      );
    }
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
              'Step 2: Driver Details', 
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Same as Owner Checkbox
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: CheckboxListTile(
                title: const Text(
                  'Driver is same as vehicle owner', 
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                value: _isSameAsOwner,
                onChanged: _toggleSameAsOwner,
                activeColor: AppTheme.primaryColor,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 20),

            // Driver Name Field
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _driverNameController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Full Name', 
                    prefixIcon: Icon(Icons.person), 
                    border: InputBorder.none,
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Driver NIC Field
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _driverNicController,
                  decoration: const InputDecoration(
                    labelText: 'Driver NIC', 
                    prefixIcon: Icon(Icons.credit_card), 
                    border: InputBorder.none,
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Driver License Field
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _driverLicenseController,
                  decoration: const InputDecoration(
                    labelText: 'Driving License Number', 
                    prefixIcon: Icon(Icons.badge), 
                    border: InputBorder.none,
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // License Issue Date
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('License Issued Date'),
                subtitle: Text(
                  _licenseIssuedDate != null 
                    ? DateFormat('yyyy-MM-dd').format(_licenseIssuedDate!) 
                    : 'Select date',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectDate(context, true),
              ),
            ),
            const SizedBox(height: 16),

            // License Expiry Date
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('License Expiry Date'),
                subtitle: Text(
                  _licenseExpiryDate != null 
                    ? DateFormat('yyyy-MM-dd').format(_licenseExpiryDate!) 
                    : 'Select date',
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _selectDate(context, false),
              ),
            ),
            const SizedBox(height: 16),

            // Driver Phone Field
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _driverPhoneController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Phone', 
                    prefixIcon: Icon(Icons.phone), 
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Driver Address Field
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextFormField(
                  controller: _driverAddressController,
                  decoration: const InputDecoration(
                    labelText: 'Driver Address', 
                    prefixIcon: Icon(Icons.home), 
                    border: InputBorder.none,
                  ),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _proceedToNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor, 
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Next', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold, 
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _driverNameController.dispose();
    _driverNicController.dispose();
    _driverLicenseController.dispose();
    _driverPhoneController.dispose();
    _driverAddressController.dispose();
    super.dispose();
  }
}
