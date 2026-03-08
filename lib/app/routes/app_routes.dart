class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String auth = '/auth';

  // Customer routes
  static const String customerShell = '/customer';
  static const String farmDetail = '/customer/farm-detail';
  static const String bookingConfirm = '/customer/booking-confirm';

  // Owner routes
  static const String ownerShell = '/owner';
  static const String addFarm = '/owner/add-farm';
  static const String editFarm = '/owner/edit-farm';
}
