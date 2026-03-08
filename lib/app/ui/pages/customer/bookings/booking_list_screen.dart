import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wedding_farm_booking/app/utils/helpers/extensions.dart';

import '../../../../../../screens/upi_payment_screen.dart';
import '../../../../controllers/booking_controller.dart';
import '../../../../data/models/booking_model.dart';
import '../../../../data/models/review_model.dart';
import '../../../../data/services/booking_service.dart';
import '../../../../utils/constants/app_colors.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<BookingController>();
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Bookings'),
          automaticallyImplyLeading: false,
          bottom: TabBar(
            isScrollable: true,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.grey,
            indicatorColor: AppColors.primary,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'Requested'),
              Tab(text: 'Booked'),
              Tab(text: 'Paid'),
              Tab(text: 'All'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (controller.bookings.isEmpty) {
            return _buildEmptyState();
          }

          final requestedBookings = controller.bookings.where((b) => b.status == BookingStatus.pending).toList();
          final bookedBookings = controller.bookings.where((b) => b.status == BookingStatus.booked).toList();
          final paidBookings = controller.bookings.where((b) => b.status == BookingStatus.paid).toList();

          return TabBarView(
            children: [
              _buildList(controller, requestedBookings),
              _buildList(controller, bookedBookings),
              _buildList(controller, paidBookings),
              _buildList(controller, controller.bookings),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildList(BookingController controller, List<BookingModel> bookings) {
    if (bookings.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: controller.loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (_, i) => _BookingCard(booking: bookings[i]),
      ),
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
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.calendar_month_outlined, size: 52, color: AppColors.primary),
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

class _BookingCard extends StatefulWidget {
  const _BookingCard({required this.booking});
  final BookingModel booking;

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  bool _isLoadingReview = false;
  ReviewModel? _review;
  final BookingService _bookingService = BookingService();

  @override
  void initState() {
    super.initState();
    _checkReviewStatus();
  }

  Future<void> _checkReviewStatus() async {
    // Only check if booking is paid and event was in the past
    if (widget.booking.status == BookingStatus.paid) {
      final isPast = widget.booking.eventDates.isNotEmpty ? widget.booking.eventDates.last.isBefore(DateTime.now()) : widget.booking.eventDate.isBefore(DateTime.now());

      if (isPast) {
        setState(() => _isLoadingReview = true);
        _review = await _bookingService.getReviewForBooking(widget.booking.id);
        setState(() => _isLoadingReview = false);
      }
    }
  }

  Color _statusColor(BookingStatus status) {
    return status.color;
  }

  String _statusLabel(BookingStatus status) {
    return status.label;
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final farmName = booking.farm?.name ?? 'Unknown Farm';
    final farmLocation = booking.farm?.location ?? '';
    final photoUrl = booking.farm?.firstPhotoUrl ?? '';
    final statusColor = _statusColor(booking.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: AppColors.cardShadow, blurRadius: 8, offset: const Offset(0, 2)),
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
                      child: Icon(Icons.image_outlined, color: AppColors.primary),
                    ),
                  )
                : Container(
                    width: 90,
                    height: 100,
                    color: AppColors.primaryLight,
                    child: Icon(Icons.image_outlined, color: AppColors.primary),
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
                        Icon(Icons.location_on_outlined, size: 12, color: AppColors.grey),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: booking.eventDates
                              .map((date) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.greyLight,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      DateFormat('dd MMM').format(date),
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.changeOpacity(0.12),
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
                  if (booking.status == BookingStatus.booked || booking.status == BookingStatus.pending) ...[
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
                          booking.status == BookingStatus.booked ? 'Pay Balance' : 'Pay Token',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                    )
                  ],

                  // Review actions
                  if (booking.status == BookingStatus.paid) ...[
                    Builder(builder: (context) {
                      final isPast = booking.eventDates.isNotEmpty ? booking.eventDates.last.isBefore(DateTime.now()) : booking.eventDate.isBefore(DateTime.now());

                      if (!isPast || _isLoadingReview) return const SizedBox.shrink();

                      if (_review != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Reviewed ${_review!.rating}★',
                                style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppColors.primary),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => _showReviewSheet(context, booking),
                            child: Text(
                              'Leave a Review',
                              style: GoogleFonts.poppins(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ),
                      );
                    })
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReviewSheet(BuildContext context, BookingModel booking) {
    int rating = 5;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Rate your experience', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      iconSize: 40,
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_outline,
                        color: Colors.amber,
                      ),
                      onPressed: () => setModalState(() => rating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: textController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Share your experience (optional)',
                    hintStyle: GoogleFonts.poppins(color: AppColors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.greyLight),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.divider),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      setState(() => _isLoadingReview = true);
                      try {
                        final session = Supabase.instance.client.auth.currentSession;
                        if (session == null) return;

                        final review = ReviewModel(
                          id: '', // Generated by Supabase
                          bookingId: booking.id,
                          farmId: booking.farmId,
                          customerId: session.user.id,
                          rating: rating,
                          reviewText: textController.text.trim().isEmpty ? null : textController.text.trim(),
                          createdAt: DateTime.now(),
                        );

                        final inserted = await _bookingService.insertReview(review);
                        setState(() => _review = inserted);
                        Get.snackbar('Success', 'Thank you for your review!', backgroundColor: Colors.green.withOpacity(0.1), colorText: Colors.green);
                      } catch (e) {
                        Get.snackbar('Error', 'Failed to submit review');
                      } finally {
                        setState(() => _isLoadingReview = false);
                      }
                    },
                    child: Text('Submit Review', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void _showPaymentSheet(BuildContext context, BookingModel booking) {
    final bool isRemaining = booking.status == BookingStatus.booked;
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
              leading: Icon(Icons.qr_code_scanner, color: AppColors.primary),
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
              leading: Icon(Icons.credit_card, color: AppColors.primary),
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
