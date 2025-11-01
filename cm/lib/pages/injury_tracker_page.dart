import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cm/services/injury_tracker_service.dart';
import 'package:cm/theme/app_theme.dart';

class InjuryTrackerPage extends StatefulWidget {
  const InjuryTrackerPage({super.key});

  @override
  State<InjuryTrackerPage> createState() => _InjuryTrackerPageState();
}

class _InjuryTrackerPageState extends State<InjuryTrackerPage> {
  final ImagePicker _picker = ImagePicker();
  final User? user = FirebaseAuth.instance.currentUser;
  
  File? _selectedImage;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  
  late InjuryTrackerService _service;
  
  @override
  void initState() {
    super.initState();
    _service = InjuryTrackerService(userId: user?.uid ?? '');
  }
  
  Future<void> _pickImage(ImageSource source) async {
    try {
      print('📸 Picking image from $source...');
      
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final file = File(image.path);
        final fileSize = await file.length();
        
        print('✅ Image selected: ${image.path}');
        print('📊 File size: $fileSize bytes (${(fileSize / 1024).toStringAsFixed(2)} KB)');
        
        // Validate file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          _showError('Image too large. Please select an image smaller than 10MB.');
          return;
        }
        
        // Validate file type
        final fileName = image.path.toLowerCase();
        if (!fileName.endsWith('.jpg') && 
            !fileName.endsWith('.jpeg') && 
            !fileName.endsWith('.png')) {
          _showError('Invalid file type. Please select a JPG or PNG image.');
          return;
        }
        
        setState(() {
          _selectedImage = file;
          _analysisResult = null;
        });
        
        print('✨ Image ready for analysis');
      } else {
        print('❌ No image selected');
      }
    } catch (e) {
      print('💥 Error picking image: $e');
      _showError('Error picking image: $e');
    }
  }
  
  Future<void> _analyzeWound() async {
    if (_selectedImage == null) {
      _showError('Please select an image first');
      return;
    }
    
    print('🚀 Starting wound analysis...');
    print('📁 Image: ${_selectedImage!.path}');
    
    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });
    
    try {
      // Verify file exists
      if (!await _selectedImage!.exists()) {
        throw Exception('Selected image file no longer exists');
      }
      
      print('✅ File exists, sending to API...');
      final result = await _service.analyzeWound(_selectedImage!);
      
      print('🎉 Analysis successful!');
      print('Result: $result');
      
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });
      
      _showSuccess('Analysis complete!');
    } catch (e) {
      print('💥 Analysis error: $e');
      setState(() {
        _isAnalyzing = false;
      });
      
      // Provide more helpful error messages
      String errorMessage = 'Error analyzing wound: $e';
      if (e.toString().contains('400')) {
        errorMessage = 'Server rejected the image. Please try a different image.';
      } else if (e.toString().contains('Failed host lookup') || 
                 e.toString().contains('Network is unreachable')) {
        errorMessage = 'Cannot connect to server. Please check:\n'
                      '1. Your laptop server is running\n'
                      '2. Your phone is on the same Wi-Fi network\n'
                      '3. The IP address in settings is correct';
      } else if (e.toString().contains('Connection refused')) {
        errorMessage = 'Server is not responding. Please ensure:\n'
                      '1. The Python server is running\n'
                      '2. Firewall allows connections on port 8000';
      }
      
      _showError(errorMessage);
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Colors.green;
      case 'moderate':
        return Colors.orange;
      case 'severe':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'mild':
        return Icons.check_circle;
      case 'moderate':
        return Icons.warning;
      case 'severe':
        return Icons.error;
      default:
        return Icons.help;
    }
  }
  
  Widget _buildImageSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    Icons.image_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            if (_selectedImage != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isAnalyzing ? null : _analyzeWound,
                  icon: _isAnalyzing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.analytics),
                  label: Text(_isAnalyzing ? 'Analyzing...' : 'Analyze Wound'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultsSection() {
    if (_analysisResult == null) return const SizedBox.shrink();
    
    final severity = _analysisResult!['severity'] as String;
    final confidence = _analysisResult!['confidence'] as double;
    final description = _analysisResult!['description'] as String;
    final recommendations = _analysisResult!['recommendations'] as Map<String, dynamic>;
    final emergencyInfo = _analysisResult!['emergency_info'] as Map<String, dynamic>;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Severity Badge
            Row(
              children: [
                Icon(
                  _getSeverityIcon(severity),
                  color: _getSeverityColor(severity),
                  size: 32,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      severity.toUpperCase(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getSeverityColor(severity),
                      ),
                    ),
                    Text(
                      'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            
            // Description
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            
            // Emergency Info
            if (emergencyInfo['call_emergency'] == true)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        emergencyInfo['message'] as String,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        emergencyInfo['message'] as String,
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            
            // Immediate Actions
            if (recommendations['immediate_actions'] != null &&
                (recommendations['immediate_actions'] as String).isNotEmpty) ...[
              const Text(
                'Immediate Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(recommendations['immediate_actions'] as String),
              const SizedBox(height: 16),
            ],
            
            // First Aid Steps
            if (recommendations['first_aid_steps'] != null) ...[
              const Text(
                'First Aid Steps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                (recommendations['first_aid_steps'] as List).length,
                (index) {
                  final step = (recommendations['first_aid_steps'] as List)[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(step.toString()),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            
            // Warning Signs
            if (recommendations['warning_signs'] != null &&
                (recommendations['warning_signs'] as List).isNotEmpty) ...[
              const Text(
                'Warning Signs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                (recommendations['warning_signs'] as List).length,
                (index) {
                  final sign = (recommendations['warning_signs'] as List)[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(sign.toString()),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Injury Tracker'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to injury history page
              Navigator.pushNamed(context, '/injury-history');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upload Wound Image',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Take or upload a photo of the wound for AI-powered analysis',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            _buildImageSection(),
            const SizedBox(height: 20),
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }
}
