import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/farm_controller.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../../utils/helpers/image_utils.dart';
import '../../../widgets/custom_buttons.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/custom_input_field.dart';

class AddFarmScreen extends StatefulWidget {
  const AddFarmScreen({super.key});

  @override
  State<AddFarmScreen> createState() => _AddFarmScreenState();
}

class _AddFarmScreenState extends State<AddFarmScreen> {
  final nameCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final tokenCtrl = TextEditingController();
  final photoUrlCtrl = TextEditingController();
  String selectedCategory = 'Lawn';
  File? selectedImage;

  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    nameCtrl.dispose();
    locationCtrl.dispose();
    descriptionCtrl.dispose();
    priceCtrl.dispose();
    tokenCtrl.dispose();
    photoUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FarmController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Add New Farm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farm Information',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildImagePicker(),
              const SizedBox(height: 24),
              TextInputField(
                type: InputType.name,
                controller: nameCtrl,
                hintLabel: 'Farm Name',
                prefixIcon: const Icon(Icons.yard_outlined),
                validator: (v) => v == null || v.isEmpty ? 'Farm name is required' : null,
              ),
              const SizedBox(height: 14),
              TextInputField(
                type: InputType.name,
                controller: locationCtrl,
                hintLabel: 'Location / Address',
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 14),
              Text(
                'Category',
                style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              CustomDropdown(
                list: const ['Lawn', 'Banquet', 'Resort'],
                initialValue: selectedCategory,
                title: 'Select Category',
                onSelect: (val) {
                  setState(() {
                    selectedCategory = val;
                  });
                },
              ),
              const SizedBox(height: 14),
              TextInputField(
                type: InputType.digits,
                controller: priceCtrl,
                hintLabel: 'Price per Day (₹)',
                prefixIcon: const Icon(Icons.currency_rupee),
                validator: (v) => v == null || v.isEmpty ? 'Price is required' : null,
              ),
              const SizedBox(height: 14),
              TextInputField(
                type: InputType.digits,
                controller: tokenCtrl,
                hintLabel: 'Token Amount (₹)',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                validator: (v) => v == null || v.isEmpty ? 'Token amount is required' : null,
              ),
              const SizedBox(height: 14),
              TextInputField(
                type: InputType.multiline,
                controller: descriptionCtrl,
                hintLabel: 'Description',
                maxLines: 4,
                prefixIcon: const Icon(Icons.description_outlined),
                validator: (v) => v == null || v.isEmpty ? 'Description is required' : null,
              ),
              const SizedBox(height: 14),
              TextInputField(
                type: InputType.name,
                controller: photoUrlCtrl,
                hintLabel: 'Photo URL (optional)',
                prefixIcon: const Icon(Icons.photo_outlined),
              ),
              const SizedBox(height: 32),
              Obx(() => AppButton(
                    title: 'Add Farm',
                    isLoading: controller.isAdding.value,
                    icon: Icons.check_circle_outline,
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        controller.addFarm(
                          name: nameCtrl.text.trim(),
                          location: locationCtrl.text.trim(),
                          description: descriptionCtrl.text.trim(),
                          category: selectedCategory,
                          pricePerDay: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                          tokenAmount: double.tryParse(tokenCtrl.text.trim()) ?? 0.0,
                          photoUrl: photoUrlCtrl.text.trim(),
                          imageFile: selectedImage,
                        );
                      }
                    },
                  )),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farm Image',
          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.greyLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: selectedImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => selectedImage = null),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 40, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to add farm photo',
                        style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final path = await ImageUtils.pickImage(context);
    if (path != null) {
      setState(() {
        selectedImage = File(path);
      });
    }
  }
}
