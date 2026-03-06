import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../services/upi_payment_service.dart';

class ScreenshotUploadScreen extends StatefulWidget {
  final String bookingId;
  final String customerId;
  final String ownerId;
  final String farmId;
  final String paymentType;
  final double amount;

  const ScreenshotUploadScreen({
    super.key,
    required this.bookingId,
    required this.customerId,
    required this.ownerId,
    required this.farmId,
    required this.paymentType,
    required this.amount,
  });

  @override
  State<ScreenshotUploadScreen> createState() => _ScreenshotUploadScreenState();
}

class _ScreenshotUploadScreenState extends State<ScreenshotUploadScreen> {
  final _upiService = UPIPaymentService();
  final _utrController = TextEditingController();
  File? _image;
  bool _isUploading = false;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Camera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_image == null) {
      Get.snackbar('Error', 'Please pick a screenshot of your payment');
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _upiService.submitUpiPaymentRequest(
        bookingId: widget.bookingId,
        customerId: widget.customerId,
        ownerId: widget.ownerId,
        farmId: widget.farmId,
        paymentType: widget.paymentType,
        amount: widget.amount,
        upiRefNumber: _utrController.text.trim().isEmpty ? null : _utrController.text.trim(),
        screenshotFile: _image!,
      );

      Get.offAllNamed('/home'); // Or wherever appropriate
      Get.snackbar('Success', 'Payment request submitted! Waiting for owner confirmation.', backgroundColor: const Color(0xFF2E7D32), colorText: Colors.white);

      // Optionally show a "Waiting for confirmation" screen
      // For now, let's just go home and show snackbar.
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B5E3C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Screenshot'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Upload Payment Proof',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please upload a clear screenshot of your successful UPI transaction.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => _showImageSourceActionSheet(context),
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: _image != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_image!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                              SizedBox(height: 12),
                              Text('Tap to pick screenshot', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                  ),
                ),
                if (_image != null)
                  TextButton.icon(
                    onPressed: () => _showImageSourceActionSheet(context),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Change Image'),
                    style: TextButton.styleFrom(foregroundColor: primaryColor),
                  ),
                const SizedBox(height: 32),
                const Text(
                  'UTR / Reference Number (Optional)',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _utrController,
                  decoration: InputDecoration(
                    hintText: 'Enter 12-digit UTR number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryColor, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      'Submit for Verification',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    SizedBox(height: 16),
                    Text('Uploading screenshot...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
