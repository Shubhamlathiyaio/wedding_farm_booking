import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/upi_payment_service.dart';
import 'screenshot_upload_screen.dart';

class UpiPaymentScreen extends StatefulWidget {
  final String bookingId;
  final String ownerId;
  final String farmId;
  final String paymentType;
  final double amount;

  const UpiPaymentScreen({
    super.key,
    required this.bookingId,
    required this.ownerId,
    required this.farmId,
    required this.paymentType,
    required this.amount,
  });

  @override
  State<UpiPaymentScreen> createState() => _UpiPaymentScreenState();
}

class _UpiPaymentScreenState extends State<UpiPaymentScreen> {
  final _upiService = UPIPaymentService();
  String? _upiId;
  String? _upiName;
  String? _upiQrUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOwnerDetails();
  }

  Future<void> _fetchOwnerDetails() async {
    try {
      final details = await _upiService.getOwnerUpiDetails(widget.ownerId);
      if (mounted) {
        setState(() {
          _upiId = details['upi_id'];
          _upiName = details['upi_name'];
          _upiQrUrl = details['upi_qr_url'];
          _isLoading = false;
        });
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch owner details');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String get _upiUrl {
    final upiId = _upiId ?? '';
    final upiName = _upiName ?? 'Urban Harvest';
    final encodedName = Uri.encodeComponent(upiName);
    final note = Uri.encodeComponent('Farm Booking ${widget.paymentType.capitalizeFirst}');
    return 'upi://pay?pa=$upiId&pn=$encodedName&am=${widget.amount}&cu=INR&tn=$note';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B5E3C);
    final currentUpiId = _upiId;
    final currentQrUrl = _upiQrUrl;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('UPI Payment', style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (currentUpiId == null || currentUpiId.isEmpty)
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        const Text(
                          "Owner hasn't set up UPI yet — please contact them directly",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Owner ID: ${widget.ownerId}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: () => Get.back(),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                              child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _fetchOwnerDetails,
                              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                              child: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Scan to Pay ${widget.paymentType == 'token' ? 'Token' : 'Balance'}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: currentQrUrl != null && currentQrUrl.isNotEmpty
                            ? FutureBuilder<String>(
                                future: _upiService.getScreenshotSignedUrl(currentQrUrl),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const SizedBox(
                                      height: 240,
                                      child: Center(child: CircularProgressIndicator()),
                                    );
                                  }
                                  if (snapshot.hasData && snapshot.data != null) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        snapshot.data!,
                                        height: 240,
                                        width: 240,
                                        fit: BoxFit.contain,
                                        errorBuilder: (context, error, stackTrace) {
                                          return QrImageView(
                                            data: _upiUrl,
                                            version: QrVersions.auto,
                                            size: 240.0,
                                            backgroundColor: Colors.white,
                                          );
                                        },
                                      ),
                                    );
                                  }
                                  return QrImageView(
                                    data: _upiUrl,
                                    version: QrVersions.auto,
                                    size: 240.0,
                                    backgroundColor: Colors.white,
                                  );
                                },
                              )
                            : QrImageView(
                                data: _upiUrl,
                                version: QrVersions.auto,
                                size: 240.0,
                                backgroundColor: Colors.white,
                              ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Owner UPI ID', style: TextStyle(color: Colors.grey)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currentUpiId,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20, color: primaryColor),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: currentUpiId));
                              Get.snackbar('Copied', 'UPI ID copied to clipboard', snackPosition: SnackPosition.BOTTOM);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Amount to Pay', style: TextStyle(color: Colors.grey)),
                      Text(
                        '₹${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
                      ),
                      const SizedBox(height: 40),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor.withAlpha(76)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: primaryColor),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Instructions: Pay this amount → come back → upload screenshot',
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            final user = _supabase.auth.currentUser;
                            if (user == null) {
                              Get.snackbar('Error', 'Please log in again');
                              return;
                            }
                            Get.to(() => ScreenshotUploadScreen(
                                  bookingId: widget.bookingId,
                                  customerId: user.id,
                                  ownerId: widget.ownerId,
                                  farmId: widget.farmId,
                                  paymentType: widget.paymentType,
                                  amount: widget.amount,
                                ));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "I've Paid — Upload Screenshot",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

final _supabase = Supabase.instance.client;
