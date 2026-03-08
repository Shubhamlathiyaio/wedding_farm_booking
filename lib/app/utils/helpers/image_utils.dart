import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedding_farm_booking/app/utils/constants/app_colors.dart';

import '../../../gen/assets.gen.dart';
import '../../ui/widgets/custom_image_view.dart';

class ImageUtils {
  static Future<String?> pickImage(BuildContext context) async {
    final picker = ImagePicker();

    // Show bottom sheet to choose source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => showImagePickerSheet(
        context: context,
        onCameraTap: () => Get.back(result: ImageSource.camera),
        onGalleryTap: () => Get.back(result: ImageSource.gallery),
      ),
    );

    if (source == null) return null;

    // 🎯 No permission checks needed! image_picker handles it
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1800, // Optimize image size
      maxHeight: 1800,
      imageQuality: 85, // Balance quality vs file size
    );

    if (image == null) return null;

    return image.path;
  }

  static Widget showImagePickerSheet({
    required void Function() onCameraTap,
    required void Function() onGalleryTap,
    required BuildContext context,
    String? title,
  }) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Text(
                  title ?? 'Upload Photo',
                  style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              Divider(color: AppColors.divider, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 28),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onCameraTap,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(26)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 38),
                            child: Column(
                              children: [
                                ImageView(
                                  Assets.svg.icCamera,
                                  color: AppColors.primary,
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(height: 14),
                                FittedBox(
                                  child: Text(
                                    'Camera',
                                    style: GoogleFonts.poppins(fontSize: 18, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: GestureDetector(
                        onTap: onGalleryTap,
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: AppColors.greyLight, borderRadius: BorderRadius.circular(26)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                            child: Column(
                              children: [
                                ImageView(
                                  Assets.svg.icGallery,
                                  color: AppColors.primary,
                                  width: 36,
                                  height: 36,
                                ),
                                const SizedBox(height: 14),
                                FittedBox(
                                  child: Text(
                                    'Gallery',
                                    style: GoogleFonts.poppins(fontSize: 18, color: AppColors.textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Uploads an image to Supabase Storage and returns the public URL
  static Future<String?> uploadFarmImage(String imagePath) async {
    try {
      final file = File(imagePath);
      final fileName = 'farm_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storage = Supabase.instance.client.storage;

      await storage.from('farms').upload(
            fileName,
            file,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrl = storage.from('farms').getPublicUrl(fileName);
      return imageUrl;
    } catch (e) {
      Get.snackbar('Upload Failed', 'Could not upload image: $e', backgroundColor: AppColors.error, colorText: AppColors.white);
      return null;
    }
  }
}
