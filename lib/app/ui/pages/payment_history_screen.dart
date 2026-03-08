// lib/screens/payment_history_screen.dart
// Full payment history for both customers and owners

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wedding_farm_booking/app/data/models/payment_model.dart';
import 'package:wedding_farm_booking/app/data/models/payment_service.dart';
import 'package:wedding_farm_booking/app/utils/helpers/extensions.dart';

enum _HistoryTab { customer, owner }

class PaymentHistoryScreen extends StatefulWidget {
  /// isOwner: if true, shows owner's received payments tab by default
  final bool isOwner;

  const PaymentHistoryScreen({super.key, this.isOwner = false});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  List<PaymentModel> _customerPayments = [];
  List<PaymentModel> _ownerPayments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.isOwner ? 1 : 0,
    );
    _loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        PaymentService.instance.getMyPayments(),
        PaymentService.instance.getOwnerPayments(),
      ]);
      if (!mounted) return;
      setState(() {
        _customerPayments = results[0];
        _ownerPayments = results[1];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EE),
      appBar: AppBar(
        title: const Text('Payment History'),
        backgroundColor: const Color(0xFF8B5E3C),
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Payments'),
            Tab(text: 'Received'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadPayments,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _loadPayments)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _PaymentList(
                      payments: _customerPayments,
                      currencyFmt: _currencyFmt,
                      emptyMessage: 'No payments yet.\nBook a farm to get started!',
                      isOwnerView: false,
                    ),
                    _PaymentList(
                      payments: _ownerPayments,
                      currencyFmt: _currencyFmt,
                      emptyMessage: 'No payments received yet.',
                      isOwnerView: true,
                    ),
                  ],
                ),
    );
  }
}

// ─── Payment List ─────────────────────────────────────────────────────────────

class _PaymentList extends StatelessWidget {
  final List<PaymentModel> payments;
  final NumberFormat currencyFmt;
  final String emptyMessage;
  final bool isOwnerView;

  const _PaymentList({
    required this.payments,
    required this.currencyFmt,
    required this.emptyMessage,
    required this.isOwnerView,
  });

  // Group payments by booking_id for cleaner display
  Map<String, List<PaymentModel>> get _grouped {
    final map = <String, List<PaymentModel>>{};
    for (final p in payments) {
      map.putIfAbsent(p.bookingId, () => []).add(p);
    }
    return map;
  }

  double get _totalSucceeded => payments.where((p) => p.status == PaymentStatus.succeeded).fold(0.0, (sum, p) => sum + p.amount);

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
            ),
          ],
        ),
      );
    }

    final grouped = _grouped;
    final bookingIds = grouped.keys.toList();

    return RefreshIndicator(
      onRefresh: () async {},
      child: CustomScrollView(
        slivers: [
          // Summary banner
          SliverToBoxAdapter(
            child: _SummaryBanner(
              totalAmount: _totalSucceeded,
              paymentCount: payments.where((p) => p.status == PaymentStatus.succeeded).length,
              currencyFmt: currencyFmt,
              isOwnerView: isOwnerView,
            ),
          ),
          // Booking groups
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final id = bookingIds[index];
                final group = grouped[id]!;
                return _BookingPaymentGroup(
                  bookingPayments: group,
                  currencyFmt: currencyFmt,
                  isOwnerView: isOwnerView,
                );
              },
              childCount: bookingIds.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─── Summary Banner ───────────────────────────────────────────────────────────

class _SummaryBanner extends StatelessWidget {
  final double totalAmount;
  final int paymentCount;
  final NumberFormat currencyFmt;
  final bool isOwnerView;

  const _SummaryBanner({
    required this.totalAmount,
    required this.paymentCount,
    required this.currencyFmt,
    required this.isOwnerView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B5E3C), Color(0xFFB07D54)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOwnerView ? 'Total Received' : 'Total Paid',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFmt.format(totalAmount),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '$paymentCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Payments',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Booking Payment Group ────────────────────────────────────────────────────

class _BookingPaymentGroup extends StatelessWidget {
  final List<PaymentModel> bookingPayments;
  final NumberFormat currencyFmt;
  final bool isOwnerView;

  const _BookingPaymentGroup({
    required this.bookingPayments,
    required this.currencyFmt,
    required this.isOwnerView,
  });

  @override
  Widget build(BuildContext context) {
    final first = bookingPayments.first;
    final farmName = first.farmName ?? 'Farm';
    final bookingDate = first.bookingDate;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.changeOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farm header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5E3C).changeOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.villa, color: Color(0xFF8B5E3C)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF2D1B0E),
                        ),
                      ),
                      if (bookingDate != null)
                        Text(
                          DateFormat('d MMM yyyy').format(bookingDate),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isOwnerView && first.metadata['customer_name'] != null)
                  Text(
                    first.metadata['customer_name'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Individual payment rows
          ...bookingPayments.map(
            (p) => _PaymentRow(payment: p, currencyFmt: currencyFmt),
          ),
        ],
      ),
    );
  }
}

// ─── Payment Row ──────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final PaymentModel payment;
  final NumberFormat currencyFmt;

  const _PaymentRow({required this.payment, required this.currencyFmt});

  Color get _statusColor {
    switch (payment.status) {
      case PaymentStatus.succeeded:
        return const Color(0xFF4CAF50);
      case PaymentStatus.failed:
        return const Color(0xFFE53935);
      case PaymentStatus.cancelled:
        return Colors.orange;
      case PaymentStatus.pending:
        return Colors.grey;
    }
  }

  IconData get _typeIcon => payment.paymentType == PaymentType.token ? Icons.lock : Icons.check_circle_outline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _statusColor.changeOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_typeIcon, size: 18, color: _statusColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.paymentTypeLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      payment.paidAt != null ? DateFormat('d MMM, h:mm a').format(payment.paidAt!) : DateFormat('d MMM').format(payment.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    if (payment.stripePaymentMethod != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '· ${_methodLabel(payment.stripePaymentMethod!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                currencyFmt.format(payment.amount),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _statusColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.changeOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  payment.statusLabel,
                  style: TextStyle(
                    fontSize: 10,
                    color: _statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _methodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'card':
        return '💳 Card';
      case 'upi':
        return '📱 UPI';
      case 'netbanking':
        return '🏦 NetBanking';
      default:
        return method;
    }
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade300),
            const SizedBox(height: 12),
            const Text(
              'Failed to load payments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5E3C),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
