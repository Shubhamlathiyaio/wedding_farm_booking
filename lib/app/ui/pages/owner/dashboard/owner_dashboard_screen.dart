import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../controllers/auth_controller.dart';
import '../../../../controllers/owner_dashboard_controller.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../utils/constants/app_colors.dart';
import '../../../widgets/custom_buttons.dart';
import 'widgets/booking_details_sheet.dart';

class OwnerDashboardScreen extends StatelessWidget {
  const OwnerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<OwnerDashboardController>();
    final authCtrl = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadDashboard,
          ),
        ],
      ),
      body: Obx(() {
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadDashboard,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Greeting
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, 👋',
                          style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary),
                        ),
                        Text(
                          authCtrl.profile.value?.fullName.split(' ').first ?? 'Owner',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.person, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: Obx(() => _StatCard(
                          label: 'Booked',
                          value: controller.upcomingCount.value.toString(),
                          icon: Icons.calendar_month,
                          color: Colors.teal,
                          isSelected: controller.selectedTab.value == OwnerDashboardTab.booked,
                          onTap: () => controller.onTabChanged(OwnerDashboardTab.booked),
                        )),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(() => _StatCard(
                          label: 'Paid',
                          value: controller.activeCount.value.toString(),
                          icon: Icons.check_circle,
                          color: AppColors.primary,
                          isSelected: controller.selectedTab.value == OwnerDashboardTab.paid,
                          onTap: () => controller.onTabChanged(OwnerDashboardTab.paid),
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterTab(
                      label: 'Pending',
                      isSelected: controller.selectedTab.value == OwnerDashboardTab.pending,
                      onTap: () => controller.onTabChanged(OwnerDashboardTab.pending),
                    ),
                    _FilterTab(
                      label: 'Booked',
                      isSelected: controller.selectedTab.value == OwnerDashboardTab.booked,
                      onTap: () => controller.onTabChanged(OwnerDashboardTab.booked),
                    ),
                    _FilterTab(
                      label: 'Paid',
                      isSelected: controller.selectedTab.value == OwnerDashboardTab.paid,
                      onTap: () => controller.onTabChanged(OwnerDashboardTab.paid),
                    ),
                    _FilterTab(
                      label: 'All',
                      isSelected: controller.selectedTab.value == OwnerDashboardTab.all,
                      onTap: () => controller.onTabChanged(OwnerDashboardTab.all),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Date strip
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter by Date',
                    style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  if (controller.selectedDate.value != null)
                    TextButton(
                      onPressed: () => controller.onDateSelected(null),
                      child: Text('Clear', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary)),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDateStrip(controller),
              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${controller.selectedTab.value.name.capitalizeFirst} Weddings',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${controller.bookings.length} Total',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (controller.isLoading.value)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                )
              else if (controller.bookings.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_outlined, size: 48, color: AppColors.grey.withAlpha(50)),
                        const SizedBox(height: 16),
                        Text(
                          'No bookings found for this filter.',
                          style: GoogleFonts.poppins(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: controller.bookings
                      .map((b) => _BookingCard(
                            booking: b,
                            controller: controller,
                          ))
                      .toList(),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDateStrip(OwnerDashboardController controller) {
    final today = DateTime.now();
    final days = List.generate(14, (i) => today.add(Duration(days: i)));

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final day = days[i];
          final isSelected = controller.selectedDate.value != null &&
              controller.selectedDate.value!.year == day.year &&
              controller.selectedDate.value!.month == day.month &&
              controller.selectedDate.value!.day == day.day;

          final isToday = day.year == today.year && day.month == today.month && day.day == today.day;

          return InkWell(
            onTap: () => controller.onDateSelected(day),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 50,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isToday ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEE').format(day).substring(0, 3),
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    day.day.toString(),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (isToday)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
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
    this.onTap,
    this.isSelected = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(isSelected ? 0.5 : 0.2)),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 10)] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: isSelected ? Colors.white : color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: isSelected ? Colors.white : color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.controller});
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
      child: InkWell(
        onTap: () => _showDetailsSheet(context),
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
                _buildStatusTag(booking.status),
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
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: 'View Details',
                    type: AppButtonType.outline,
                    onPressed: () => _showDetailsSheet(context),
                  ),
                ),
                if (booking.customerPhone != null) ...[
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () => controller.makeCall(booking.customerPhone),
                    icon: const Icon(Icons.call, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      minimumSize: const Size(48, 48),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTag(BookingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.poppins(
          color: status.color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  void _showDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingDetailsSheet(
        booking: booking,
        controller: controller,
      ),
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
            boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))] : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
