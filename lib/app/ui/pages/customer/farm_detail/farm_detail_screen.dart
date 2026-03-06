import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../controllers/booking_controller.dart';
import '../../../../data/models/farm_model.dart';
import '../../../../data/services/farm_service.dart';
import '../../../../routes/app_routes.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../widgets/custom_buttons.dart';
import '../../../widgets/custom_image_view.dart';

class FarmDetailScreen extends StatelessWidget {
  const FarmDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arg = Get.arguments;

    if (arg is FarmModel) {
      return _FarmDetailBody(farm: arg);
    }

    final String farmId = arg.toString();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<FarmModel>(
        future: FarmService().getFarmById(farmId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Failed to load farm', style: GoogleFonts.poppins()),
            );
          }
          return _FarmDetailBody(farm: snapshot.data!);
        },
      ),
    );
  }
}

class _FarmDetailBody extends StatefulWidget {
  const _FarmDetailBody({required this.farm});
  final FarmModel farm;

  @override
  State<_FarmDetailBody> createState() => _FarmDetailBodyState();
}

class _FarmDetailBodyState extends State<_FarmDetailBody> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final farm = widget.farm;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.white,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: farm.photoUrls.length,
                        itemBuilder: (context, index) {
                          return Hero(
                            tag: index == 0 ? 'farm-${farm.id}' : 'farm-image-$index',
                            child: ImageView(
                              farm.photoUrls[index],
                              height: 300,
                              width: double.infinity,
                            ),
                          );
                        },
                      ),
                      if (farm.photoUrls.length > 1)
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              farm.photoUrls.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                height: 8,
                                width: _currentPage == index ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == index ? AppColors.primary : Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    if (_currentPage == index)
                                      BoxShadow(
                                        color: AppColors.primary.withOpacity(0.3),
                                        blurRadius: 4,
                                        spreadRadius: 1,
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
                leading: GestureDetector(
                  onTap: () => Get.back(),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 8)],
                    ),
                    child: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + Rating
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              farm.name,
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  farm.rating.toStringAsFixed(1),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.grey, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              farm.location,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Category chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.primary),
                          borderRadius: BorderRadius.circular(20),
                          color: AppColors.primaryLight,
                        ),
                        child: Text(
                          farm.category,
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      Text(
                        'About',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        farm.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Static map placeholder
                      Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.greyLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.location_pin, size: 42, color: AppColors.primary),
                            const SizedBox(height: 8),
                            Text(
                              farm.location,
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Price row
                      Row(
                        children: [
                          const Icon(Icons.currency_rupee, color: AppColors.primary, size: 22),
                          Text(
                            '${farm.pricePerDay.toStringAsFixed(0)} / day',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky bottom bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: const BoxDecoration(
                color: AppColors.white,
                boxShadow: [
                  BoxShadow(color: AppColors.cardShadow, blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    title: 'Pay Token to Book',
                    onPressed: () => _onBookTap(context, farm),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Token: ₹${farm.tokenAmount.toStringAsFixed(0)} (non-refundable)',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onBookTap(BuildContext context, FarmModel farm) async {
    final bookingCtrl = Get.find<BookingController>();

    // Date picker
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null) return;
    bookingCtrl.selectedDate.value = pickedDate;

    // Guest count dialog
    if (!context.mounted) return;
    final guestCountResult = await _showGuestCountDialog(context, bookingCtrl.guestCount.value);
    if (guestCountResult == null) return;
    bookingCtrl.guestCount.value = guestCountResult;

    Get.toNamed(
      AppRoutes.bookingConfirm,
      arguments: {
        'farm': farm,
        'date': pickedDate,
        'guestCount': guestCountResult,
      },
    );
  }

  Future<int?> _showGuestCountDialog(BuildContext context, int current) async {
    final ctrl = TextEditingController(text: current.toString());
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Guest Count', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Enter number of guests'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text) ?? current),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
