import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/farm_controller.dart';
import '../../../controllers/owner_dashboard_controller.dart';
import '../customer/profile/customer_profile_screen.dart';
import '../owner/dashboard/owner_dashboard_screen.dart';
import '../owner/farms/owner_farms_screen.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({super.key});

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Get.put(OwnerDashboardController());
    Get.put(FarmController());
  }

  final _pages = const [
    OwnerDashboardScreen(),
    OwnerFarmsScreen(),
    CustomerProfileScreen(), // same profile screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.yard_outlined),
            activeIcon: Icon(Icons.yard),
            label: 'My Farms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
