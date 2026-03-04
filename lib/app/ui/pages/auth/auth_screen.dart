import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wedding_farm_booking/app/ui/widgets/custom_image_view.dart';
import 'package:wedding_farm_booking/gen/assets.gen.dart';

import '../../../controllers/auth_controller.dart';
import '../../../utils/constants/app_colors.dart';
import '../../widgets/custom_buttons.dart';
import '../../widgets/custom_input_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthController _authController = Get.find<AuthController>();

  // Sign Up fields
  final _signUpFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _signUpEmailCtrl = TextEditingController();
  final _signUpPasswordCtrl = TextEditingController();
  String _selectedRole = 'customer';

  // Log In fields
  final _loginFormKey = GlobalKey<FormState>();
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _signUpEmailCtrl.dispose();
    _signUpPasswordCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Logo & Branding
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: ImageView(Assets.images.logo.path),
              ),
              const SizedBox(height: 16),
              Text(
                'Wedding Farm',
                style: GoogleFonts.poppins(
                  color: AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Your dream wedding venue awaits',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 32),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  // padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                  unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
                  tabs: const [
                    Row(
                      children: [
                        Expanded(child: Tab(text: 'Sign Up')),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Tab(text: 'Log In'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Tab Content
              SizedBox(
                height: 600,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSignUpForm(),
                    _buildLoginForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Form(
      key: _signUpFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextInputField(
            type: InputType.name,
            controller: _nameCtrl,
            hintLabel: 'Full Name',
            prefixIcon: const Icon(Icons.person_outline),
            validator: (v) => v == null || v.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 14),
          TextInputField(
            type: InputType.phoneNumber,
            controller: _phoneCtrl,
            hintLabel: 'Phone Number',
            prefixIcon: const Icon(Icons.phone_outlined),
            validator: (v) => v == null || v.length < 10 ? 'Enter valid phone' : null,
          ),
          const SizedBox(height: 14),
          TextInputField(
            type: InputType.email,
            controller: _signUpEmailCtrl,
            hintLabel: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
          ),
          const SizedBox(height: 14),
          TextInputField(
            type: InputType.password,
            controller: _signUpPasswordCtrl,
            hintLabel: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 20),

          // Role Selector
          Text(
            'I am a...',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildRoleCard('customer', 'Customer', Icons.person_search_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _buildRoleCard('owner', 'Farm Owner', Icons.domain_outlined)),
            ],
          ),
          const SizedBox(height: 24),

          Obx(() => AppButton(
                title: 'Create Account',
                isLoading: _authController.isLoading.value,
                onPressed: _handleSignUp,
              )),
        ],
      ),
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.greyLight,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _loginFormKey,
      child: Column(
        children: [
          TextInputField(
            type: InputType.email,
            controller: _loginEmailCtrl,
            hintLabel: 'Email Address',
            prefixIcon: const Icon(Icons.email_outlined),
            validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
          ),
          const SizedBox(height: 14),
          TextInputField(
            type: InputType.password,
            controller: _loginPasswordCtrl,
            hintLabel: 'Password',
            prefixIcon: const Icon(Icons.lock_outline),
            validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
          ),
          const SizedBox(height: 28),
          Obx(() => AppButton(
                title: 'Log In',
                isLoading: _authController.isLoading.value,
                onPressed: _handleLogin,
              )),
        ],
      ),
    );
  }

  void _handleSignUp() {
    if (!_signUpFormKey.currentState!.validate()) return;
    _authController.signUp(
      email: _signUpEmailCtrl.text.trim(),
      password: _signUpPasswordCtrl.text.trim(),
      fullName: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      role: _selectedRole,
    );
  }

  void _handleLogin() {
    if (!_loginFormKey.currentState!.validate()) return;
    _authController.signIn(
      email: _loginEmailCtrl.text.trim(),
      password: _loginPasswordCtrl.text.trim(),
    );
  }
}
