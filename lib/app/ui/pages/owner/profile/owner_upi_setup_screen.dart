import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../services/upi_payment_service.dart';
import '../../../../controllers/auth_controller.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../widgets/custom_buttons.dart';

class OwnerUpiSetupScreen extends StatefulWidget {
  const OwnerUpiSetupScreen({super.key});

  @override
  State<OwnerUpiSetupScreen> createState() => _OwnerUpiSetupScreenState();
}

class _OwnerUpiSetupScreenState extends State<OwnerUpiSetupScreen> {
  final _upiService = UPIPaymentService();
  final _upiIdController = TextEditingController();
  final _upiNameController = TextEditingController();
  File? _qrCodeImage;
  bool _isLoading = false;
  String? _existingQrUrl;

  @override
  void initState() {
    super.initState();
    _loadExistingDetails();
  }

  Future<void> _loadExistingDetails() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      final details = await _upiService.getOwnerUpiDetails(userId);
      _upiIdController.text = details['upi_id'] ?? '';
      _upiNameController.text = details['upi_name'] ?? '';
      _existingQrUrl = details['upi_qr_url'];
    } catch (e) {
      Get.snackbar('Error', 'Failed to load UPI details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _qrCodeImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveDetails() async {
    if (_upiIdController.text.isEmpty || _upiNameController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all details');
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isLoading = true);
    try {
      await _upiService.updateOwnerUpiDetails(
        ownerId: userId,
        upiId: _upiIdController.text.trim(),
        upiName: _upiNameController.text.trim(),
        qrCodeFile: _qrCodeImage,
      );

      // Refresh auth profile
      await Get.find<AuthController>().reloadProfile();

      Get.back();
      Get.snackbar('Success', 'UPI details updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('UPI Payment Setup')),
      body: _isLoading && _upiIdController.text.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UPI Details',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Customers will use these details to pay the token and final amount via UPI.',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // UPI ID
                  _buildLabel('UPI ID (e.g., name@okaxis)'),
                  TextField(
                    controller: _upiIdController,
                    decoration: _inputDecoration('Enter UPI ID'),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // UPI Name
                  _buildLabel('Account Holder Name'),
                  TextField(
                    controller: _upiNameController,
                    decoration: _inputDecoration('Enter name as in UPI'),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // QR Code
                  Text(
                    'UPI QR Code',
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload your UPI QR code image from PhonePe, GPay, or Paytm.',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),

                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider, width: 2, style: BorderStyle.solid),
                        ),
                        child: _qrCodeImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(_qrCodeImage!, fit: BoxFit.cover),
                              )
                            : _existingQrUrl != null
                                ? FutureBuilder<String>(
                                    future: _upiService.getScreenshotSignedUrl(_existingQrUrl!),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator());
                                      }
                                      if (snapshot.hasData) {
                                        return ClipRRect(
                                          borderRadius: BorderRadius.circular(14),
                                          child: Image.network(snapshot.data!, fit: BoxFit.cover),
                                        );
                                      }
                                      return const Center(child: Icon(Icons.qr_code, size: 50));
                                    },
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Upload QR Code',
                                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  AppButton(
                    title: 'Save Details',
                    isLoading: _isLoading,
                    onPressed: _saveDetails,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.greyLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
