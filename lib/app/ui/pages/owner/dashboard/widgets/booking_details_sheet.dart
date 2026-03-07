import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../../services/upi_payment_service.dart';
import '../../../../../controllers/owner_dashboard_controller.dart';
import '../../../../../data/models/booking_model.dart';
import '../../../../../utils/constants/app_colors.dart';
import '../../../../widgets/custom_buttons.dart';

class BookingDetailsSheet extends StatefulWidget {
  final BookingModel booking;
  final OwnerDashboardController controller;

  const BookingDetailsSheet({
    super.key,
    required this.booking,
    required this.controller,
  });

  @override
  State<BookingDetailsSheet> createState() => _BookingDetailsSheetState();
}

class _BookingDetailsSheetState extends State<BookingDetailsSheet> {
  final _upiService = UPIPaymentService();
  final RxList<Map<String, dynamic>> _payments = <Map<String, dynamic>>[].obs;
  final RxBool _isLoadingPayments = false.obs;
  late TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.booking.ownerNote);
    _loadPayments();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    _isLoadingPayments.value = true;
    try {
      _payments.value = await _upiService.getPaymentHistory(widget.booking.id);
    } catch (e) {
      debugPrint('Error loading payments: $e');
    } finally {
      _isLoadingPayments.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCustomerInfo(),
                  const SizedBox(height: 20),
                  _buildBookingDetails(),
                  const SizedBox(height: 20),
                  _buildOwnerNoteSection(),
                  const SizedBox(height: 20),
                  _buildPaymentSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(context),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: ${widget.booking.id.substring(0, 8).toUpperCase()}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textSecondary,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        _buildStatusTag(widget.booking.status),
      ],
    );
  }

  Widget _buildStatusTag(BookingStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: GoogleFonts.poppins(
          color: status.color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              widget.booking.customerName?[0].toUpperCase() ?? 'U',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.booking.customerName ?? 'Unknown Customer',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (widget.booking.customerPhone != null)
                  Text(
                    widget.booking.customerPhone!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.booking.customerPhone != null)
            IconButton(
              onPressed: () => widget.controller.makeCall(widget.booking.customerPhone),
              icon: const Icon(Icons.call, color: AppColors.primary),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.primary.withAlpha(20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Information',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _detailRow(Icons.home_outlined, 'Farm', widget.booking.farm?.name ?? '—'),
              const Divider(height: 24),
              _detailRow(Icons.calendar_today_outlined, 'Event Date', DateFormat('EEEE, dd MMM yyyy').format(widget.booking.eventDate)),
              const Divider(height: 24),
              _detailRow(Icons.people_outline, 'Guests', '${widget.booking.guestCount} People'),
              if (widget.booking.notes?.isNotEmpty ?? false) ...[
                const Divider(height: 24),
                _detailRow(Icons.notes, 'Customer Notes', widget.booking.notes!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerNoteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'My Private Notes',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _noteController,
                  maxLines: 2,
                  style: GoogleFonts.poppins(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Add a private note...',
                    hintStyle: GoogleFonts.poppins(fontSize: 13, color: AppColors.grey),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => widget.controller.updateOwnerNote(widget.booking.id, _noteController.text),
                icon: const Icon(Icons.save_outlined, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Payment',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _paymentRow('Token Amount', '₹${widget.booking.tokenAmount.toStringAsFixed(0)}',
                  (widget.booking.status == BookingStatus.booked || widget.booking.status == BookingStatus.paid) ? Colors.green : Colors.orange),
              const Divider(height: 24),
              _paymentRow('Total Amount', '₹${widget.booking.totalAmount.toStringAsFixed(0)}', widget.booking.status == BookingStatus.paid ? Colors.green : Colors.grey),
              const SizedBox(height: 16),
              Obx(() {
                if (_isLoadingPayments.value) {
                  return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(strokeWidth: 2)));
                }
                if (_payments.isEmpty) {
                  return Text(
                    'No payment screenshots uploaded yet.',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Proofs',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _payments.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, i) {
                          final p = _payments[i];
                          return _buildScreenshotThumb(p);
                        },
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentRow(String label, String value, Color statusColor) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScreenshotThumb(Map<String, dynamic> payment) {
    final path = payment['screenshot_url'] as String;
    return InkWell(
      onTap: () => _viewScreenshot(path, payment),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            clipBehavior: Clip.antiAlias,
            child: FutureBuilder<String>(
              future: _upiService.getScreenshotSignedUrl(path),
              builder: (ctx, snapshot) {
                if (snapshot.hasData) {
                  return CachedNetworkImage(
                    imageUrl: snapshot.data!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return const Center(child: Icon(Icons.image, color: AppColors.grey));
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            payment['payment_type'].toString().toUpperCase(),
            style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _viewScreenshot(String path, Map<String, dynamic> payment) async {
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
                title: Text('${payment['payment_type'] == 'token' ? 'Token' : 'Full'} Payment Proof', style: const TextStyle(fontSize: 16)),
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
                  return ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: Get.height * 0.7),
                    child: InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: snapshot.data!,
                        placeholder: (_, __) => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
                        fit: BoxFit.contain,
                      ),
                    ),
                  );
                },
              ),
              if (payment['upi_ref_number'] != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('UTR: ${payment['upi_ref_number']}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
            ],
          ),
        ),
      ),
      useSafeArea: true,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    if (widget.booking.status == BookingStatus.pending) {
      return Column(
        children: [
          AppButton(
            title: 'Confirm Booking',
            onPressed: () {
              Navigator.pop(context);
              widget.controller.confirmBooking(widget.booking.id);
            },
          ),
          const SizedBox(height: 12),
          AppButton(
            title: 'Reject',
            type: AppButtonType.danger,
            onPressed: () {
              Navigator.pop(context);
              _showRejectDialog(context);
            },
          ),
        ],
      );
    }

    if (widget.booking.status == BookingStatus.booked) {
      return Row(
        children: [
          Expanded(
            child: AppButton(
              title: 'Mark as Paid',
              onPressed: () {
                Navigator.pop(context);
                widget.controller.markAsPaid(widget.booking.id);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppButton(
              title: 'Release Farm',
              type: AppButtonType.danger,
              onPressed: () {
                Navigator.pop(context);
                _showReleaseDialog(context);
              },
            ),
          ),
        ],
      );
    }

    if (widget.booking.status == BookingStatus.paid) {
      return AppButton(
        title: 'Release Farm',
        type: AppButtonType.danger,
        onPressed: () {
          Navigator.pop(context);
          _showReleaseDialog(context);
        },
      );
    }

    return const SizedBox.shrink();
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              widget.controller.releaseFarm(widget.booking.id);
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(ctx);
              widget.controller.rejectBooking(widget.booking.id);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }
}
