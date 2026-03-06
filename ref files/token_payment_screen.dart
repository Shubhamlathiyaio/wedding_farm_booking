// lib/screens/token_payment_screen.dart
// Screen shown when customer wants to lock a farm with token payment

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wedding_farm_booking/app/data/models/payment_service.dart';


class TokenPaymentScreen extends StatefulWidget {
  final String bookingId;
  final String farmId;
  final String farmName;
  final String? farmImageUrl;
  final double tokenAmount;      // non-refundable lock amount
  final double totalAmount;      // full booking value
  final DateTime bookingDate;

  const TokenPaymentScreen({
    super.key,
    required this.bookingId,
    required this.farmId,
    required this.farmName,
    this.farmImageUrl,
    required this.tokenAmount,
    required this.totalAmount,
    required this.bookingDate,
  });

  @override
  State<TokenPaymentScreen> createState() => _TokenPaymentScreenState();
}

class _TokenPaymentScreenState extends State<TokenPaymentScreen> {
  bool _isLoading = false;
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  double get _remainingAmount => widget.totalAmount - widget.tokenAmount;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: const Text('Confirm Booking'),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FarmCard(
              name: widget.farmName,
              imageUrl: widget.farmImageUrl,
              bookingDate: widget.bookingDate,
            ),
            const SizedBox(height: 24),
            _PaymentBreakdownCard(
              tokenAmount: widget.tokenAmount,
              totalAmount: widget.totalAmount,
              remainingAmount: _remainingAmount,
              currencyFmt: _currencyFmt,
            ),
            const SizedBox(height: 16),
            _TokenNoticeCard(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handlePayToken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5E3C),
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
                        'Pay Token ${_currencyFmt.format(widget.tokenAmount)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Secured by Stripe',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePayToken() async {
    setState(() => _isLoading = true);

    final result = await PaymentService.instance.payToken(
      bookingId: widget.bookingId,
      farmId: widget.farmId,
      farmName: widget.farmName,
      tokenAmount: widget.tokenAmount,
      totalAmount: widget.totalAmount,
      bookingDate: widget.bookingDate,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      _showSuccessSheet();
    } else if (result.isCancelled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment cancelled')),
      );
    } else {
      _showErrorDialog(result.errorMessage ?? 'Payment failed. Please try again.');
    }
  }

  void _showSuccessSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentSuccessSheet(
        farmName: widget.farmName,
        tokenAmount: widget.tokenAmount,
        remainingAmount: _remainingAmount,
        bookingDate: widget.bookingDate,
        currencyFmt: _currencyFmt,
        onDone: () {
          Navigator.of(context).pop(); // close sheet
          Navigator.of(context).pop(true); // return success to caller
        },
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
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _FarmCard extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final DateTime bookingDate;

  const _FarmCard({
    required this.name,
    this.imageUrl,
    required this.bookingDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 160,
                  child: Center(child: Icon(Icons.image_not_supported)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D1B0E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 16, color: Color(0xFF8B5E3C)),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy').format(bookingDate),
                      style: const TextStyle(
                        color: Color(0xFF8B5E3C),
                        fontWeight: FontWeight.w500,
                      ),
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
}

class _PaymentBreakdownCard extends StatelessWidget {
  final double tokenAmount;
  final double totalAmount;
  final double remainingAmount;
  final NumberFormat currencyFmt;

  const _PaymentBreakdownCard({
    required this.tokenAmount,
    required this.totalAmount,
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
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Breakdown',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D1B0E),
            ),
          ),
          const SizedBox(height: 16),
          _BreakdownRow(
            label: 'Total Booking Amount',
            value: currencyFmt.format(totalAmount),
            color: Colors.black87,
          ),
          const Divider(height: 24),
          _BreakdownRow(
            label: 'Token (Pay Now)',
            sublabel: 'Non-refundable · Locks your date',
            value: currencyFmt.format(tokenAmount),
            color: const Color(0xFF8B5E3C),
            isBold: true,
          ),
          const SizedBox(height: 12),
          _BreakdownRow(
            label: 'Remaining Amount',
            sublabel: 'Due on the agreed date',
            value: currencyFmt.format(remainingAmount),
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  final String label;
  final String? sublabel;
  final String value;
  final Color color;
  final bool isBold;

  const _BreakdownRow({
    required this.label,
    this.sublabel,
    required this.value,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  color: color,
                ),
              ),
              if (sublabel != null)
                Text(
                  sublabel!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TokenNoticeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFE082)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, color: Color(0xFFF9A825), size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'The token amount is non-refundable. It confirms and locks your booking date. '
              'The remaining amount can be paid via any method on the agreed date.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF5D4037)),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSuccessSheet extends StatelessWidget {
  final String farmName;
  final double tokenAmount;
  final double remainingAmount;
  final DateTime bookingDate;
  final NumberFormat currencyFmt;
  final VoidCallback onDone;

  const _PaymentSuccessSheet({
    required this.farmName,
    required this.tokenAmount,
    required this.remainingAmount,
    required this.bookingDate,
    required this.currencyFmt,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 48),
          ),
          const SizedBox(height: 16),
          const Text(
            'Farm Locked! 🎉',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '$farmName is reserved for ${DateFormat('d MMM yyyy').format(bookingDate)}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          _SummaryTile(
            icon: Icons.lock,
            label: 'Token Paid',
            value: currencyFmt.format(tokenAmount),
            color: const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 8),
          _SummaryTile(
            icon: Icons.pending_actions,
            label: 'Remaining Due',
            value: currencyFmt.format(remainingAmount),
            color: const Color(0xFF8B5E3C),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5E3C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('View My Bookings'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
