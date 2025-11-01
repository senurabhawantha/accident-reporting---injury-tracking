import 'dart:io';
import 'package:cm/pages/contact_us.dart';
import 'package:cm/services/claims_service.dart';
import 'package:cm/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ReportCaseImages extends StatefulWidget {
  final ClaimFormData formData;

  const ReportCaseImages({required this.formData, super.key});

  @override
  State<ReportCaseImages> createState() => _ReportCaseImagesState();
}

class _ReportCaseImagesState extends State<ReportCaseImages> {
  List<File> imageFiles = [];
  List<String> imageFileNames = [];
  bool _isLoading = false;

  Future<void> _selectImage(ImageSource source) async {
    if (imageFiles.length >= 6) {
      _showSnackBar('Maximum 6 images allowed', isError: true);
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        // Save image to local storage
        final savedFile = await _saveImageLocally(File(pickedImage.path));
        
        setState(() {
          imageFiles.add(savedFile);
          imageFileNames.add(savedFile.path.split('/').last);
        });
        
        _showSnackBar('Image added successfully', isError: false);
      }
    } catch (e) {
      _showSnackBar('Error selecting image: $e', isError: true);
    }
  }

  Future<File> _saveImageLocally(File originalFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final claimImagesDir = Directory('${directory.path}/claim_images');
    
    if (!await claimImagesDir.exists()) {
      await claimImagesDir.create(recursive: true);
    }
    
    final fileName = 'claim_${DateTime.now().millisecondsSinceEpoch}_${path.basename(originalFile.path)}';
    final savedFile = File('${claimImagesDir.path}/$fileName');
    
    return await originalFile.copy(savedFile.path);
  }

  void _removeImage(int index) {
    setState(() {
      imageFiles.removeAt(index);
      imageFileNames.removeAt(index);
    });
    _showSnackBar('Image removed', isError: false);
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Select Image Source',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: AppTheme.primaryColor),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _selectImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _submitClaim() async {
    if (imageFiles.isEmpty) {
      _showSnackBar('Please add at least one image', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Update form data with image files
      final completeFormData = widget.formData.copyWith(
        imageFiles: imageFiles,
      );

      // Submit claim to Firebase
      final claimId = await ClaimsService().submitCompleteClaim(completeFormData);
      
      if (claimId != null) {
        _showSnackBar('Claim submitted successfully!', isError: false);
        
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('Claim Submitted'),
              ],
            ),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your claim has been submitted successfully!'),
                SizedBox(height: 12),
                Text('You can view your claim in the "Old Cases" section.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.popUntil(context, (route) => route.isFirst); // Back to home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showSnackBar('Failed to submit claim. Please try again.', isError: true);
      }
      
    } catch (e) {
      _showSnackBar('Error submitting claim: $e', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              'Step 4: Upload Images',
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
            // Progress indicator
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
                  children: [
                    Row(
                      children: [
                        Icon(Icons.camera_alt, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Upload Damage Photos',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add up to 6 photos showing the damage to your vehicle',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Image upload section
            const Text(
              'Damage Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Add Image Button
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: _showImageSourceDialog,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        '${imageFiles.length}/6 photos',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Image Grid
            if (imageFiles.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: imageFiles.length,
                itemBuilder: (context, index) {
                  return _buildImageTile(imageFiles[index], index);
                },
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
                  onPressed: _isLoading ? null : _submitClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Submit Claim',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.check, color: Colors.white, size: 20),
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

  Widget _buildImageTile(File imageFile, int index) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(imageFile),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeImage(index),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
            // Image index
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
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
          ],
        ),
      ),
    );
  }
}
