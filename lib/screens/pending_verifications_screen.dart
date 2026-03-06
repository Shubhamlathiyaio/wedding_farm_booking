import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/upi_payment_service.dart';
import 'payment_verification_detail_screen.dart';

class PendingVerificationsScreen extends StatefulWidget {
  const PendingVerificationsScreen({super.key});

  @override
  State<PendingVerificationsScreen> createState() => _PendingVerificationsScreenState();
}

class _PendingVerificationsScreenState extends State<PendingVerificationsScreen> {
  final _upiService = UPIPaymentService();
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final data = await _upiService.getPendingVerifications(userId);
      setState(() {
        _requests = data;
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to fetch pending verifications');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF8B5E3C);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pending Verifications'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No pending verifications', style: TextStyle(color: Colors.grey, fontSize: 18)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchRequests,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _requests[index];
                      final farmName = (item['farms'] as Map<String, dynamic>?)?['name'] ?? 'Unknown Farm';
                      final customerName = (item['profiles'] as Map<String, dynamic>?)?['full_name'] ?? 'Unknown Customer';
                      final amount = item['amount'] ?? 0;
                      final type = (item['payment_type'] as String).capitalizeFirst;
                      final createdAt = DateTime.parse(item['created_at']);

                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          title: Text(farmName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer: $customerName'),
                              Text('Time: ${DateFormat('dd MMM, hh:mm a').format(createdAt)}'),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primaryColor.withAlpha(25), // ~0.1 opacity
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(type!, style: const TextStyle(fontSize: 10, color: primaryColor)),
                              ),
                            ],
                          ),
                          onTap: () async {
                            final result = await Get.to(() => PaymentVerificationDetailScreen(request: item));
                            if (result == true) {
                              _fetchRequests();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
