import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/controllers/auth_controller.dart';
import 'app/global/app_config.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/utils/themes/app_theme.dart';
import 'gen/locales.g.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  // Register global AuthController before app starts
  Get.put(AuthController());

  runApp(const WeddingFarmApp());
}

class WeddingFarmApp extends StatelessWidget {
  const WeddingFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Wedding Farm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      getPages: AppPages.routes,
      initialRoute: AppRoutes.splash,
      defaultTransition: Transition.fadeIn,
      translations: AppTranslation(),
      locale: const Locale('en', 'US'), // Default locale
      fallbackLocale: const Locale('en', 'US'),
    );
  }
}
