import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/farm_controller.dart';
import '../../../../data/models/farm_model.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../../utils/helpers/image_utils.dart';
import '../../../widgets/custom_buttons.dart';
import '../../../widgets/custom_dropdown.dart';
import '../../../widgets/custom_input_field.dart';

class EditFarmScreen extends StatefulWidget {
  const EditFarmScreen({super.key});

  @override
  State<EditFarmScreen> createState() => _EditFarmScreenState();
}

class _EditFarmScreenState extends State<EditFarmScreen> {
  late FarmModel farm;

  final nameCtrl = TextEditingController();
  final locationCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final descriptionCtrl = TextEditingController();
  final capacityCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final tokenCtrl = TextEditingController();
  final upiIdCtrl = TextEditingController();
  final upiNameCtrl = TextEditingController();

  String selectedCategory = 'Lawn';
  bool isAvailable = true;

  final List<String> keptPhotoUrls = [];
  final List<File> selectedImages = [];

  final List<String> allAmenities = ['Parking', 'Catering', 'AC Hall', 'Generator', 'Swimming Pool', 'Mandap Setup', 'DJ', 'Garden', 'Accommodation', 'CCTV'];
  final Set<String> selectedAmenities = {};

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Assuming the farm model is passed as argument
    farm = Get.arguments as FarmModel;

    nameCtrl.text = farm.name;
    locationCtrl.text = farm.location;
    addressCtrl.text = farm.address;
    descriptionCtrl.text = farm.description;
    capacityCtrl.text = farm.capacity > 0 ? farm.capacity.toString() : '';
    priceCtrl.text = farm.pricePerDay > 0 ? farm.pricePerDay.toStringAsFixed(0) : '';
    tokenCtrl.text = farm.tokenAmount > 0 ? farm.tokenAmount.toStringAsFixed(0) : '';
    upiIdCtrl.text = farm.upiId ?? '';
    upiNameCtrl.text = farm.upiName ?? '';

    selectedCategory = farm.category.isNotEmpty ? farm.category : 'Lawn';
    isAvailable = farm.isAvailable;

    keptPhotoUrls.addAll(farm.photoUrls);
    selectedAmenities.addAll(farm.amenities);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    locationCtrl.dispose();
    addressCtrl.dispose();
    descriptionCtrl.dispose();
    capacityCtrl.dispose();
    priceCtrl.dispose();
    tokenCtrl.dispose();
    upiIdCtrl.dispose();
    upiNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<FarmController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Farm', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SECTION 1: Photos
              _buildSectionTitle('Farm Photos'),
              const SizedBox(height: 12),
              _buildImageSection(),
              const SizedBox(height: 24),

              // SECTION 2: Basic Info
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              TextInputField(
                type: InputType.name,
                controller: nameCtrl,
                hintLabel: 'Farm Name',
                prefixIcon: const Icon(Icons.yard_outlined),
                validator: (v) => v == null || v.isEmpty ? 'Farm name is required' : null,
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
                type: InputType.name,
                controller: locationCtrl,
                hintLabel: 'Location (Short city/area)',
                prefixIcon: const Icon(Icons.location_on_outlined),
                validator: (v) => v == null || v.isEmpty ? 'Location is required' : null,
              ),
              const SizedBox(height: 14),
              TextInputField(
                type: InputType.name,
                controller: addressCtrl,
                hintLabel: 'Full Address',
                prefixIcon: const Icon(Icons.map_outlined),
              ),
              const SizedBox(height: 14),
              TextInputField(
                type: InputType.multiline,
                controller: descriptionCtrl,
                hintLabel: 'Description',
                maxLines: 4,
                prefixIcon: const Icon(Icons.description_outlined),
              ),
              const SizedBox(height: 14),
              TextInputField(
                type: InputType.digits,
                controller: capacityCtrl,
                hintLabel: 'Capacity (Max guests)',
                prefixIcon: const Icon(Icons.group_outlined),
              ),
              const SizedBox(height: 24),

              // SECTION 3: Pricing
              _buildSectionTitle('Pricing'),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),

              // SECTION 4: Amenities
              _buildSectionTitle('Amenities'),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allAmenities.map((amenity) {
                  final isSelected = selectedAmenities.contains(amenity);
                  return ChoiceChip(
                    label: Text(amenity),
                    labelStyle: GoogleFonts.poppins(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontSize: 12,
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.divider,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedAmenities.add(amenity);
                        } else {
                          selectedAmenities.remove(amenity);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // SECTION 5: Availability
              _buildSectionTitle('Availability'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Farm is Available',
                    style: GoogleFonts.poppins(fontSize: 15, color: AppColors.textPrimary),
                  ),
                  Switch(
                    value: isAvailable,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        isAvailable = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // SECTION 6: UPI Details
              _buildSectionTitle('UPI Details'),
              const SizedBox(height: 4),
              Text(
                'Used for receiving token payments',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextInputField(
                type: InputType.name,
                controller: upiIdCtrl,
                hintLabel: 'UPI ID',
                prefixIcon: const Icon(Icons.qr_code_outlined),
              ),
              const SizedBox(height: 14),
              TextInputField(
                type: InputType.name,
                controller: upiNameCtrl,
                hintLabel: 'UPI Name',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.white, boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 10,
            offset: const Offset(0, -2),
          )
        ]),
        child: Obx(() => AppButton(
              title: 'Save Changes',
              isLoading: controller.isAdding.value,
              icon: Icons.save_outlined,
              onPressed: () {
                if (keptPhotoUrls.isEmpty && selectedImages.isEmpty) {
                  Get.snackbar('Photos Required', 'Please ensure at least one farm photo exists.', backgroundColor: Colors.orange, colorText: Colors.white);
                  return;
                }
                if (formKey.currentState!.validate()) {
                  controller.updateExistingFarm(
                    existingFarm: farm,
                    name: nameCtrl.text.trim(),
                    location: locationCtrl.text.trim(),
                    address: addressCtrl.text.trim(),
                    description: descriptionCtrl.text.trim(),
                    category: selectedCategory,
                    pricePerDay: double.tryParse(priceCtrl.text.trim()) ?? 0.0,
                    tokenAmount: double.tryParse(tokenCtrl.text.trim()) ?? 0.0,
                    capacity: int.tryParse(capacityCtrl.text.trim()) ?? 0,
                    amenities: selectedAmenities.toList(),
                    keptPhotoUrls: keptPhotoUrls,
                    newImageFiles: selectedImages,
                    isAvailable: isAvailable,
                    upiId: upiIdCtrl.text.trim(),
                    upiName: upiNameCtrl.text.trim(),
                  );
                }
              },
            )),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildImageSection() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Existing kept photos
          ...List.generate(keptPhotoUrls.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildNetworkPhotoTile(keptPhotoUrls[index], () {
                setState(() {
                  keptPhotoUrls.removeAt(index);
                });
              }),
            );
          }),
          // Newly selected photos
          ...List.generate(selectedImages.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildFilePhotoTile(selectedImages[index], () {
                setState(() {
                  selectedImages.removeAt(index);
                });
              }),
            );
          }),
          // Add Photo button
          _buildAddPhotoButton(),
        ],
      ),
    );
  }

  Widget _buildNetworkPhotoTile(String url, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(url, width: 120, height: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 120, height: 120, color: AppColors.greyLight)),
        ),
        _buildRemoveButton(onRemove),
      ],
    );
  }

  Widget _buildFilePhotoTile(File file, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.file(file, width: 120, height: 120, fit: BoxFit.cover),
        ),
        _buildRemoveButton(onRemove),
      ],
    );
  }

  Widget _buildRemoveButton(VoidCallback onRemove) {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onRemove,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
          child: const Icon(Icons.close, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.greyLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
            const SizedBox(height: 4),
            Text('Add Photo', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final path = await ImageUtils.pickImage(context);
    if (path != null) {
      setState(() {
        selectedImages.add(File(path));
      });
    }
  }
}
