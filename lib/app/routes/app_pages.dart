import 'package:get/get.dart';

import '../ui/pages/auth/auth_screen.dart';
import '../ui/pages/customer/booking_confirm/booking_confirm_screen.dart';
import '../ui/pages/customer/customer_shell.dart';
import '../ui/pages/customer/farm_detail/farm_detail_screen.dart';
import '../ui/pages/owner/farms/add_farm_screen.dart';
import '../ui/pages/owner/farms/edit_farm_screen.dart';
import '../ui/pages/owner/owner_shell.dart';
import '../ui/pages/splash/splash_page.dart';
import 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashPage(),
    ),
    GetPage(
      name: AppRoutes.auth,
      page: () => const AuthScreen(),
    ),
    GetPage(
      name: AppRoutes.customerShell,
      page: () => const CustomerShell(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.farmDetail,
      page: () => const FarmDetailScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.bookingConfirm,
      page: () => const BookingConfirmScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.ownerShell,
      page: () => const OwnerShell(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.addFarm,
      page: () => const AddFarmScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.editFarm,
      page: () => const EditFarmScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}
