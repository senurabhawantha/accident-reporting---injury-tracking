import 'package:flutter/material.dart';
import 'package:cm/scripts/add_sample_vehicles.dart';
import 'package:cm/theme/app_theme.dart';

/// Developer page to add sample data to Firebase
/// Access this page from the dashboard or create a route to it
class AddSampleDataPage extends StatefulWidget {
  const AddSampleDataPage({super.key});

  @override
  State<AddSampleDataPage> createState() => _AddSampleDataPageState();
}

class _AddSampleDataPageState extends State<AddSampleDataPage> {
  bool _isLoading = false;
  String _message = '';

  Future<void> _addVehicles() async {
    setState(() {
      _isLoading = true;
      _message = 'Adding vehicles to Firebase...';
    });

    try {
      final script = AddSampleVehicles();
      await script.addVehiclesToFirebase();
      setState(() {
        _isLoading = false;
        _message = '✅ Vehicles added successfully!';
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: const Text('Sample vehicles have been added to Firebase. You can now use them in the Report Case flow.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = '❌ Error: $e';
      });
    }
  }

  Future<void> _deleteVehicles() async {
    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: const Text('Are you sure you want to delete all your vehicles from Firebase? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _message = 'Deleting vehicles from Firebase...';
    });

    try {
      final script = AddSampleVehicles();
      await script.deleteAllUserVehicles();
      setState(() {
        _isLoading = false;
        _message = '✅ Vehicles deleted successfully!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = '❌ Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Sample Data'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚗 Vehicle Data Setup',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Use this page to add sample vehicle data to Firebase. This is useful for testing the claim submission flow.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    if (_message.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _message.contains('✅') ? Colors.green[50] : Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _message,
                          style: TextStyle(
                            color: _message.contains('✅') ? Colors.green[900] : Colors.red[900],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _addVehicles,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add_circle),
              label: const Text('Add Sample Vehicles to Firebase'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _deleteVehicles,
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              label: const Text('Delete All My Vehicles', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: Colors.red),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Sample Data Info',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• 4 sample vehicles will be added\n'
                      '• Honda Dio (Motorcycle)\n'
                      '• Toyota Camry (Hybrid Car)\n'
                      '• Ford Mustang (Sports Car)\n'
                      '• Suzuki Alto (Economy Car)\n'
                      '• All vehicles include insurance details',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
