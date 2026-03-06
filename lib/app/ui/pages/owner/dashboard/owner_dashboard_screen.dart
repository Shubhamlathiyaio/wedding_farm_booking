import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/owner_dashboard_controller.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../widgets/custom_buttons.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OwnerDashboardController>();
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadDashboard,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Greeting
              Text(
                'Welcome back, ${authCtrl.profile.value?.fullName.split(' ').first ?? 'Owner'}! 👋',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.celebration_outlined,
                      label: 'Upcoming\nWeddings',
                      value: controller.upcomingCount.value.toString(),
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.event_available_outlined,
                      label: 'Active\nBookings',
                      value: controller.activeCount.value.toString(),
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Date strip
              _buildDateStrip(controller),
              const SizedBox(height: 24),

              // Pending requests
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pending Requests',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() => Text(
                          '${controller.pendingBookings.length}',
                          style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Obx(() {
                if (controller.pendingBookings.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No pending requests 🎉',
                        style: GoogleFonts.poppins(color: AppColors.textSecondary),
                      ),
                    ),
                  );
                }
                return Column(
                  children: controller.pendingBookings
                      .map((b) => _PendingRequestCard(
                            booking: b,
                            controller: controller,
                          ))
                      .toList(),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDateStrip(OwnerDashboardController controller) {
    final today = DateTime.now();
    final days = List.generate(7, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = days[i];
          final isToday = i == 0;
          final hasBooking = controller.pendingBookings.any(
            (b) => b.eventDate.year == day.year && b.eventDate.month == day.month && b.eventDate.day == day.day,
          );

          return Container(
            width: 50,
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : AppColors.greyLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday ? AppColors.primary : AppColors.divider,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('EEE').format(day).substring(0, 3),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: isToday ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                Text(
                  day.day.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isToday ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (hasBooking)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isToday ? Colors.white : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingRequestCard extends StatelessWidget {
  const _PendingRequestCard({required this.booking, required this.controller});
  final BookingModel booking;
  final OwnerDashboardController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.customerName ?? 'Unknown Customer',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.pending.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Pending',
                  style: GoogleFonts.poppins(
                    color: AppColors.pending,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.home_outlined, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(
                booking.farm?.name ?? 'Unknown Farm',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd MMM yyyy').format(booking.eventDate),
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.people_outline, size: 14, color: AppColors.grey),
              const SizedBox(width: 4),
              Text(
                '${booking.guestCount} guests',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppButton(
            title: 'View Details',
            type: AppButtonType.outline,
            onPressed: () => _showDetailsSheet(context),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (booking.status == 'pending') ...[
                Expanded(
                  child: AppButton(
                    title: 'Approve',
                    isLoading: controller.isLoading.value,
                    onPressed: () => controller.approveBooking(booking.id),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppButton(
                    title: 'Reject',
                    type: AppButtonType.danger,
                    isLoading: controller.isLoading.value,
                    onPressed: () => _showRejectDialog(context),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: AppButton(
                    title: 'Release Farm',
                    type: AppButtonType.danger,
                    isLoading: controller.isReleasing.value,
                    onPressed: () => _showReleaseDialog(context),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking Details', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _detailRow('Customer', booking.customerName ?? '—'),
            _detailRow('Farm', booking.farm?.name ?? '—'),
            _detailRow('Event Date', DateFormat('dd MMM yyyy').format(booking.eventDate)),
            _detailRow('Guest Count', '${booking.guestCount} guests'),
            _detailRow('Token Amount', '₹${booking.tokenAmount.toStringAsFixed(0)}'),
            _detailRow('Total Amount', '₹${booking.totalAmount.toStringAsFixed(0)}'),
            if (booking.notes != null && booking.notes!.isNotEmpty) _detailRow('Notes', booking.notes!),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.poppins(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showReleaseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Release Farm?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'This will release the farm and cancel the booking. This action cannot be undone.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              controller.releaseFarm(booking.id);
            },
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Booking?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'This will reject the booking and cancel the request. This action cannot be undone.',
          style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              controller.rejectBooking(booking.id);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
