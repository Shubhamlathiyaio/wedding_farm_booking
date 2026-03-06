import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../app/utils/constants/app_colors.dart';
import '../services/upi_payment_service.dart';

class PaymentVerificationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> request;

  const PaymentVerificationDetailScreen({super.key, required this.request});

  @override
  State<PaymentVerificationDetailScreen> createState() => _PaymentVerificationDetailScreenState();
}

class _PaymentVerificationDetailScreenState extends State<PaymentVerificationDetailScreen> {
  final _upiService = UPIPaymentService();
  String? _signedUrl;
  bool _isLoadingUrl = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchSignedUrl();
  }

  Future<void> _fetchSignedUrl() async {
    try {
      final url = await _upiService.getScreenshotSignedUrl(widget.request['screenshot_url']);
      setState(() {
        _signedUrl = url;
        _isLoadingUrl = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch screenshot');
      setState(() => _isLoadingUrl = false);
    }
  }

  void _showSuccess(String message) {
    Get.snackbar('Success', message, backgroundColor: Colors.green, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM);
  }

  void _showError(String message) {
    Get.snackbar('Error', message);
  }

  Future<void> _confirm() async {
    setState(() => _isProcessing = true);
    try {
      await _upiService.confirmPayment(
        requestId: widget.request['id'],
      );
      Get.back(result: true);
      _showSuccess('Payment confirmed successfully!');
    } catch (e) {
      _showError('Failed to confirm: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reason for Rejection', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'e.g. Incorrect amount, Blurred screenshot...',
                filled: true,
                fillColor: AppColors.greyLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _reject(reasonController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Reject Payment', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _reject(String reason) async {
    if (reason.isEmpty) {
      Get.snackbar('Error', 'Please provide a reason');
      return;
    }
    Navigator.pop(context); // Close bottom sheet
    setState(() => _isProcessing = true);
    try {
      await _upiService.rejectPayment(
        requestId: widget.request['id'],
        reason: reason,
      );
      Get.back(result: true);
      Get.snackbar('Rejected', 'Payment rejected and customer notified', snackPosition: SnackPosition.BOTTOM);
    } catch (e) {
      Get.snackbar('Error', 'Failed to reject: ${e.toString()}');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmName = (widget.request['farms'] as Map<String, dynamic>?)?['name'] ?? 'Unknown Farm';
    final customerName = (widget.request['profiles'] as Map<String, dynamic>?)?['full_name'] ?? 'Unknown Customer';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Payment Verification', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildRequestSummary(farmName, customerName),
                      const SizedBox(height: 24),
                      _buildScreenshotSection(),
                      const SizedBox(height: 120), // Space for action buttons
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            ),
        ],
      ),
      bottomSheet: _buildActionButtons(),
    );
  }

  Widget _buildRequestSummary(String farmName, String customerName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(farmName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    Text(customerName, style: GoogleFonts.poppins(fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text((widget.request['payment_type'] as String).toUpperCase(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetric('Amount', '₹${widget.request['amount']}', isBold: true),
              _buildMetric('UTR/Ref', widget.request['upi_ref_number'] ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.poppins(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildScreenshotSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Transaction Screenshot', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const Row(
              children: [
                Icon(Icons.zoom_in, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Text('Pinch to zoom', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: MediaQuery.of(context).size.height * 0.5,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _isLoadingUrl
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _signedUrl == null
                    ? const Center(child: Text('Failed to load image', style: TextStyle(color: Colors.white)))
                    : InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: _signedUrl!,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white)),
                          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white),
                          fit: BoxFit.contain,
                        ),
                      ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.greyLight, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isProcessing ? null : _showRejectDialog,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Confirm', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
