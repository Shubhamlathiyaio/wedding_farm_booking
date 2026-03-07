import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../../screens/upi_payment_screen.dart';
import '../../../../controllers/booking_controller.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../utils/constants/app_colors.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Bookings'),
        automaticallyImplyLeading: false,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        if (controller.bookings.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadBookings,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.bookings.length,
            itemBuilder: (_, i) => _BookingCard(booking: controller.bookings[i]),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_outlined, size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          Text(
            'No bookings yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Book your first wedding venue today!',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});
  final BookingModel booking;

  Color _statusColor(BookingStatus status) {
    return status.color;
  }

  String _statusLabel(BookingStatus status) {
    return status.label;
  }

  @override
  Widget build(BuildContext context) {
    final farmName = booking.farm?.name ?? 'Unknown Farm';
    final farmLocation = booking.farm?.location ?? '';
    final photoUrl = booking.farm?.firstPhotoUrl ?? '';
    final statusColor = _statusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    width: 90,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 100,
                      color: AppColors.primaryLight,
                      child: const Icon(Icons.image_outlined, color: AppColors.primary),
                    ),
                  )
                : Container(
                    width: 90,
                    height: 100,
                    color: AppColors.primaryLight,
                    child: const Icon(Icons.image_outlined, color: AppColors.primary),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (farmLocation.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 12, color: AppColors.grey),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            farmLocation,
                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd MMM yyyy').format(booking.eventDate),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(booking.status),
                      style: GoogleFonts.poppins(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),

                  // Payment actions
                  if (booking.status == BookingStatus.booked || booking.status == BookingStatus.pending || booking.status == BookingStatus.paid) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _showPaymentSheet(context, booking),
                        child: Text(
                          booking.status == BookingStatus.paid ? 'Pay Balance' : 'Pay Token',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    )
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(BuildContext context, BookingModel booking) {
    final bool isRemaining = booking.status == BookingStatus.paid;
    final double amount = isRemaining ? (booking.totalAmount - booking.tokenAmount) : booking.tokenAmount;
    final String paymentType = isRemaining ? 'remaining' : 'token';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Method', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              '${isRemaining ? "Remaining" : "Token"} Amount: ₹${amount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.qr_code_scanner, color: AppColors.primary),
              title: Text('UPI Manual Transfer', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                Get.to(() => UpiPaymentScreen(
                      bookingId: booking.id,
                      ownerId: booking.farm!.ownerId,
                      farmId: booking.farmId,
                      paymentType: paymentType,
                      amount: amount,
                    ));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.credit_card, color: AppColors.primary),
              title: Text('Credit/Debit Card', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              onTap: () {
                Navigator.pop(ctx);
                Get.snackbar('Coming Soon', 'Stripe integration is pending implementation.');
              },
            ),
          ],
        ),
      ),
    );
  }
}
