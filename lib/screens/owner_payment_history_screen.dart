import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../app/utils/constants/app_colors.dart';
import 'payment_verification_detail_screen.dart';

class OwnerPaymentHistoryScreen extends StatefulWidget {
  const OwnerPaymentHistoryScreen({super.key});

  @override
  State<OwnerPaymentHistoryScreen> createState() => _OwnerPaymentHistoryScreenState();
}

class _OwnerPaymentHistoryScreenState extends State<OwnerPaymentHistoryScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase.from('upi_payment_requests').select('*, farms(name), profiles:customer_id(full_name)').eq('owner_id', userId).order('created_at', ascending: false);

      setState(() {
        _history = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch history');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Verification History', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _history.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _history[index];
                      return _buildHistoryCard(item);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No transaction history yet',
            style: GoogleFonts.poppins(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final status = item['status'] as String;
    final farmName = (item['farms'] as Map<String, dynamic>?)?['name'] ?? 'Unknown Farm';
    final customerName = (item['profiles'] as Map<String, dynamic>?)?['full_name'] ?? 'Unknown Customer';
    final amount = item['amount'] ?? 0;
    final type = (item['payment_type'] as String).capitalizeFirst;
    final date = DateTime.parse(item['created_at']);

    Color statusColor = Colors.orange;
    if (status == 'confirmed') statusColor = Colors.green;
    if (status == 'rejected') statusColor = Colors.red;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: AppColors.cardShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(farmName, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Customer: $customerName', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹$amount', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('$type - ${status.toUpperCase()}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
            ),
          ],
        ),
        onTap: () => Get.to(() => PaymentVerificationDetailScreen(request: item)),
      ),
    );
  }
}
