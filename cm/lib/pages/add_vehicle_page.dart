import 'package:flutter/material.dart';
import 'package:cm/services/claims_service.dart';
import 'package:intl/intl.dart';

class AddVehiclePage extends StatefulWidget {
  const AddVehiclePage({super.key});

  @override
  State<AddVehiclePage> createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  final ClaimsService _claimsService = ClaimsService();
  
  // Controllers for form fields
  final _vehicleNumberController = TextEditingController();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _colorController = TextEditingController();
  final _engineCapacityController = TextEditingController();
  final _chassisNumberController = TextEditingController();
  final _engineNumberController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _ownerNicController = TextEditingController();
  final _ownerPhoneController = TextEditingController();
  final _insuranceCompanyController = TextEditingController();
  final _insurancePolicyController = TextEditingController();
  
  String _selectedVehicleType = 'Car';
  String _selectedFuelType = 'Petrol';
  DateTime? _insuranceExpiryDate;
  bool _isLoading = false;

  final List<String> _vehicleTypes = ['Car', 'Motorcycle', 'Van', 'Truck', 'Bus', 'Three Wheeler'];
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'Hybrid', 'Electric', 'CNG'];

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _insuranceExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.blue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _insuranceExpiryDate = picked);
    }
  }

  Future<void> _addVehicle() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_insuranceExpiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select insurance expiry date'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _claimsService.addVehicle({
        'vehicleNumber': _vehicleNumberController.text.trim(),
        'make': _makeController.text.trim(),
        'model': _modelController.text.trim(),
        'year': _yearController.text.trim(),
        'color': _colorController.text.trim(),
        'fuelType': _selectedFuelType,
        'engineCapacity': _engineCapacityController.text.trim(),
        'chassisNumber': _chassisNumberController.text.trim(),
        'engineNumber': _engineNumberController.text.trim(),
        'vehicleType': _selectedVehicleType,
        'insuranceCompany': _insuranceCompanyController.text.trim(),
        'insurancePolicyNumber': _insurancePolicyController.text.trim(),
        'insuranceExpiryDate': DateFormat('yyyy-MM-dd').format(_insuranceExpiryDate!),
        'ownerName': _ownerNameController.text.trim(),
        'ownerNic': _ownerNicController.text.trim(),
        'ownerPhone': _ownerPhoneController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Vehicle registered successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context); // Go back to vehicle list
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
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
        title: const Text(
          'Register Vehicle',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Vehicle Information Section
                  _buildSectionHeader('Vehicle Information', Icons.directions_car),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_vehicleNumberController, 'Vehicle Number', 'e.g., WP BEA-1622', Icons.confirmation_number, required: true),
                  const SizedBox(height: 16),
                  
                  // Responsive layout for make and model
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        // Stack vertically on smaller screens
                        return Column(
                          children: [
                            _buildTextField(_makeController, 'Make', 'e.g., Honda', Icons.business, required: true),
                            const SizedBox(height: 16),
                            _buildTextField(_modelController, 'Model', 'e.g., Civic', Icons.car_rental, required: true),
                          ],
                        );
                      } else {
                        // Side by side on larger screens
                        return Row(
                          children: [
                            Expanded(child: _buildTextField(_makeController, 'Make', 'e.g., Honda', Icons.business, required: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField(_modelController, 'Model', 'e.g., Civic', Icons.car_rental, required: true)),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Responsive layout for year and color
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            _buildTextField(_yearController, 'Year', 'e.g., 2022', Icons.calendar_today, keyboardType: TextInputType.number, required: true),
                            const SizedBox(height: 16),
                            _buildTextField(_colorController, 'Color', 'e.g., Red', Icons.palette, required: true),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: _buildTextField(_yearController, 'Year', 'e.g., 2022', Icons.calendar_today, keyboardType: TextInputType.number, required: true)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildTextField(_colorController, 'Color', 'e.g., Red', Icons.palette, required: true)),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Responsive layout for vehicle and fuel type
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 600) {
                        return Column(
                          children: [
                            _buildDropdown('Vehicle Type', _selectedVehicleType, _vehicleTypes, Icons.category, (value) => setState(() => _selectedVehicleType = value!)),
                            const SizedBox(height: 16),
                            _buildDropdown('Fuel Type', _selectedFuelType, _fuelTypes, Icons.local_gas_station, (value) => setState(() => _selectedFuelType = value!)),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(child: _buildDropdown('Vehicle Type', _selectedVehicleType, _vehicleTypes, Icons.category, (value) => setState(() => _selectedVehicleType = value!))),
                            const SizedBox(width: 12),
                            Expanded(child: _buildDropdown('Fuel Type', _selectedFuelType, _fuelTypes, Icons.local_gas_station, (value) => setState(() => _selectedFuelType = value!))),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_engineCapacityController, 'Engine Capacity', 'e.g., 1500cc', Icons.settings, required: true),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_chassisNumberController, 'Chassis Number', 'Vehicle chassis number', Icons.qr_code, required: true),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_engineNumberController, 'Engine Number', 'Vehicle engine number', Icons.engineering, required: true),
                  const SizedBox(height: 32),

                  // Owner Information Section
                  _buildSectionHeader('Owner Information', Icons.person),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_ownerNameController, 'Owner Name', 'Full name', Icons.person_outline, required: true),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_ownerNicController, 'Owner NIC', 'National ID number', Icons.credit_card, required: true),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_ownerPhoneController, 'Owner Phone', '+94 71 234 5678', Icons.phone, keyboardType: TextInputType.phone, required: true),
                  const SizedBox(height: 32),

                  // Insurance Information Section
                  _buildSectionHeader('Insurance Information', Icons.security),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_insuranceCompanyController, 'Insurance Company', 'e.g., Ceylinco Insurance', Icons.domain, required: true),
                  const SizedBox(height: 16),
                  
                  _buildTextField(_insurancePolicyController, 'Policy Number', 'Insurance policy number', Icons.policy, required: true),
                  const SizedBox(height: 16),
                  
                  _buildDateField(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
      bottomNavigationBar: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _addVehicle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Register Vehicle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.blue),
            border: InputBorder.none,
          ),
          keyboardType: keyboardType,
          validator: required ? (value) => value?.trim().isEmpty ?? true ? 'This field is required' : null : null,
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, IconData icon, void Function(String?) onChanged) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonFormField<String>(
          value: value,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.blue),
            border: InputBorder.none,
          ),
          items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateField() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.calendar_today, color: Colors.blue),
        title: const Text('Insurance Expiry Date', style: TextStyle(color: Colors.black87, fontSize: 14)),
        subtitle: Text(
          _insuranceExpiryDate != null 
              ? DateFormat('yyyy-MM-dd').format(_insuranceExpiryDate!) 
              : 'Select expiry date',
          style: TextStyle(
            color: _insuranceExpiryDate != null ? Colors.black87 : Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: _selectDate,
      ),
    );
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _colorController.dispose();
    _engineCapacityController.dispose();
    _chassisNumberController.dispose();
    _engineNumberController.dispose();
    _ownerNameController.dispose();
    _ownerNicController.dispose();
    _ownerPhoneController.dispose();
    _insuranceCompanyController.dispose();
    _insurancePolicyController.dispose();
    super.dispose();
  }
}