import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../screens/upi_payment_screen.dart';
import '../../../../../services/upi_payment_service.dart';
import '../../../../controllers/booking_controller.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../utils/constants/app_colors.dart';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen({super.key});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final controller = Get.find<BookingController>();
  late BookingModel booking;
  final _upiService = UPIPaymentService();

  @override
  void initState() {
    super.initState();
    booking = Get.arguments as BookingModel;
    controller.loadPaymentHistory(booking.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Booking Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFarmHeader(booking),
            const SizedBox(height: 24),
            _buildEventDetails(booking),
            const SizedBox(height: 24),
            _buildPaymentStatus(booking),
            const SizedBox(height: 24),
            Text('Payment History', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 12),
            _buildPaymentHistoryList(),
            const SizedBox(height: 100), // Space for button
          ],
        ),
      ),
      bottomNavigationBar: _buildActionButtons(context, booking),
    );
  }

  Widget _buildFarmHeader(BookingModel booking) {
    final farm = booking.farm;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (farm?.firstPhotoUrl != null)
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: farm!.firstPhotoUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                if (booking.ownerPhone != null)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      onPressed: () => controller.makeCall(booking.ownerPhone),
                      backgroundColor: Colors.white,
                      child: const Icon(Icons.call, color: AppColors.primary),
                    ),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm?.name ?? 'Unknown Farm',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      farm?.location ?? 'Location not specified',
                      style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetails(BookingModel booking) {
    return Column(
      children: [
        _buildSection(
          title: 'Event Information',
          icon: Icons.event,
          child: Column(
            children: [
              _infoTile(Icons.calendar_month, 'Event Date', DateFormat('EEEE, dd MMM yyyy').format(booking.eventDate)),
              _infoTile(Icons.people, 'Guest Count', '${booking.guestCount} People'),
              if (booking.notes != null && booking.notes!.isNotEmpty) _infoTile(Icons.notes, 'My Notes', booking.notes!),
            ],
          ),
        ),
        if (booking.ownerNote != null && booking.ownerNote!.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildSection(
            title: 'Note from Owner',
            icon: Icons.chat_bubble_outline,
            child: Text(
              booking.ownerNote!,
              style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPaymentStatus(BookingModel booking) {
    return _buildSection(
      title: 'Payment Summary',
      icon: Icons.account_balance_wallet,
      child: Column(
        children: [
          _infoTile(Icons.payments, 'Total Amount', '₹${booking.totalAmount.toStringAsFixed(2)}', isBold: true),
          _infoTile(Icons.confirmation_number, 'Token Amount', '₹${booking.tokenAmount.toStringAsFixed(2)}'),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
          Obx(() {
            final hasPending = controller.paymentHistory.any((p) => p['status'] == 'pending');
            String displayLabel = booking.status.label;
            Color statusColor = booking.status.color;

            if (hasPending) {
              displayLabel = 'Verifying Payment...';
              statusColor = Colors.orange;
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Booking Status', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    displayLabel.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentHistoryList() {
    return Obx(() {
      if (controller.paymentHistory.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.greyLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              const Icon(Icons.history, color: AppColors.grey, size: 40),
              const SizedBox(height: 12),
              Text('No payment history found', style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
        );
      }

      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: controller.paymentHistory.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final payment = controller.paymentHistory[index];
          return _buildPaymentHistoryTile(payment);
        },
      );
    });
  }

  Widget _buildPaymentHistoryTile(Map<String, dynamic> payment) {
    final status = payment['status'] as String;
    final type = payment['payment_type'] as String;
    final amount = payment['amount'];
    final date = DateTime.parse(payment['created_at']);
    final ref = payment['upi_ref_number'];

    Color statusColor = Colors.orange;
    if (status == 'confirmed') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${type.capitalizeFirst} Payment', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(DateFormat('dd MMM, hh:mm a').format(date), style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricSmall('Amount', '₹$amount'),
              const SizedBox(width: 24),
              if (ref != null) _buildMetricSmall('UTR', ref),
              const Spacer(),
              _buildScreenshotButton(payment['screenshot_url']),
            ],
          ),
          if (status == 'rejected' && payment['rejection_reason'] != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
              child: Text('Reason: ${payment['rejection_reason']}', style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricSmall(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildScreenshotButton(String path) {
    return InkWell(
      onTap: () => _viewScreenshot(path),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.image, size: 20, color: AppColors.primary),
      ),
    );
  }

  void _viewScreenshot(String path) async {
    Get.dialog(
      Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Proof of Payment', style: TextStyle(fontSize: 16)),
                automaticallyImplyLeading: false,
                actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back())],
              ),
              FutureBuilder<String>(
                future: _upiService.getScreenshotSignedUrl(path),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return const SizedBox(height: 300, child: Center(child: Text('Error loading image')));
                  }
                  return InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: snapshot.data!,
                      placeholder: (_, __) => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingModel booking) {
    return Obx(() {
      final hasPending = controller.paymentHistory.any((p) => p['status'] == 'pending');

      if (hasPending) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            border: const Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              const Icon(Icons.hourglass_empty, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your payment is being verified by the owner.',
                  style: GoogleFonts.poppins(color: Colors.blue, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }

      if (booking.status == BookingStatus.booked || (booking.status == BookingStatus.paid && !hasPending)) {
        final bool isRemaining = booking.status == BookingStatus.paid;
        return Container(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: ElevatedButton(
            onPressed: () => _showPaymentOptions(context, booking),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              isRemaining ? 'Pay Remaining Balance' : 'Pay Token Now',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        );
      }

      if (booking.status == BookingStatus.pending) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.05),
            border: const Border(top: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Awaiting review from the farm owner.',
                  style: GoogleFonts.poppins(color: Colors.orange, fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }

  Widget _buildSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Text(label, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions(BuildContext context, BookingModel booking) {
    final bool isRemaining = booking.status == BookingStatus.paid;
    final double amount = isRemaining ? (booking.totalAmount - booking.tokenAmount) : booking.tokenAmount;
    final String paymentType = isRemaining ? 'remaining' : 'token';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Options', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text(
              '${isRemaining ? "Remaining Balance" : "Token Amount"}: ₹${amount.toStringAsFixed(2)}',
              style: GoogleFonts.poppins(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: const EdgeInsets.all(12),
              tileColor: AppColors.greyLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.purple.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.qr_code_scanner, color: Colors.purple),
              ),
              title: Text('UPI Manual Transfer', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pay via QR and upload screenshot'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(ctx);
                Get.to(() => UpiPaymentScreen(
                      bookingId: booking.id,
                      ownerId: booking.farm!.ownerId,
                      farmId: booking.farmId,
                      paymentType: paymentType,
                      amount: amount,
                    ))?.then((_) => controller.loadPaymentHistory(booking.id));
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
