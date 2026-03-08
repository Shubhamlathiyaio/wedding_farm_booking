// lib/screens/final_payment_screen.dart
// Screen for paying the remaining balance — shown when final payment is due

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wedding_farm_booking/app/data/models/payment_service.dart';
import 'package:wedding_farm_booking/app/utils/helpers/extensions.dart';

class FinalPaymentScreen extends StatefulWidget {
  final String bookingId;
  final String farmName;
  final String? farmImageUrl;
  final double totalAmount;
  final double tokenPaid;
  final DateTime bookingDate;
  final DateTime? dueDate;

  const FinalPaymentScreen({
    super.key,
    required this.bookingId,
    required this.farmName,
    this.farmImageUrl,
    required this.totalAmount,
    required this.tokenPaid,
    required this.bookingDate,
    this.dueDate,
  });

  @override
  State<FinalPaymentScreen> createState() => _FinalPaymentScreenState();
}

class _FinalPaymentScreenState extends State<FinalPaymentScreen> {
  bool _isLoading = false;
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  double get _remainingAmount => widget.totalAmount - widget.tokenPaid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: const Text('Final Payment'),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking summary
            _BookingSummaryCard(
              farmName: widget.farmName,
              farmImageUrl: widget.farmImageUrl,
              bookingDate: widget.bookingDate,
            ),
            const SizedBox(height: 20),

            // Final payment breakdown
            _FinalBreakdownCard(
              totalAmount: widget.totalAmount,
              tokenPaid: widget.tokenPaid,
              remainingAmount: _remainingAmount,
              currencyFmt: _currencyFmt,
            ),
            const SizedBox(height: 20),

            // Payment methods info
            _PaymentMethodsCard(),
            const SizedBox(height: 32),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleFinalPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        'Pay ${_currencyFmt.format(_remainingAmount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Secured by Stripe · UPI, Cards, NetBanking accepted',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFinalPayment() async {
    setState(() => _isLoading = true);

    final result = await PaymentService.instance.payFinal(
      bookingId: widget.bookingId,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _showSuccessDialog();
    } else if (result.isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled')),
      );
    } else {
      _showErrorDialog(result.errorMessage ?? 'Payment failed');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 64),
            const SizedBox(height: 12),
            const Text(
              'Booking Confirmed!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Full payment of ${_currencyFmt.format(widget.totalAmount)} received.\n'
              '${widget.farmName} is confirmed for ${DateFormat('d MMM yyyy').format(widget.bookingDate)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // dialog
                Navigator.of(context).pop(true); // screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _BookingSummaryCard extends StatelessWidget {
  final String farmName;
  final String? farmImageUrl;
  final DateTime bookingDate;

  const _BookingSummaryCard({
    required this.farmName,
    this.farmImageUrl,
    required this.bookingDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.changeOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (farmImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                farmImageUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF8B5E3C).changeOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.villa, color: Color(0xFF8B5E3C)),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farmName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF2D1B0E),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.event, size: 14, color: Color(0xFF8B5E3C)),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM yyyy').format(bookingDate),
                      style: const TextStyle(
                        color: Color(0xFF8B5E3C),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).changeOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '✓ Token Paid',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalBreakdownCard extends StatelessWidget {
  final double totalAmount;
  final double tokenPaid;
  final double remainingAmount;
  final NumberFormat currencyFmt;

  const _FinalBreakdownCard({
    required this.totalAmount,
    required this.tokenPaid,
    required this.remainingAmount,
    required this.currencyFmt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.changeOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Final Payment Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B0E),
            ),
          ),
          const SizedBox(height: 16),
          _Row(
            label: 'Total Booking Amount',
            value: currencyFmt.format(totalAmount),
          ),
          const SizedBox(height: 10),
          _Row(
            label: 'Token Already Paid',
            value: '- ${currencyFmt.format(tokenPaid)}',
            valueColor: const Color(0xFF4CAF50),
          ),
          const Divider(height: 24),
          _Row(
            label: 'Amount Due Now',
            value: currencyFmt.format(remainingAmount),
            isBold: true,
            valueColor: const Color(0xFF2E7D32),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _Row({
    required this.label,
    required this.value,
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            color: isBold ? Colors.black87 : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC8E6C9)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Accepted Payment Methods',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2E7D32),
              fontSize: 13,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              _MethodChip(label: '💳 Cards'),
              SizedBox(width: 8),
              _MethodChip(label: '📱 UPI'),
              SizedBox(width: 8),
              _MethodChip(label: '🏦 NetBanking'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  const _MethodChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA5D6A7)),
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
