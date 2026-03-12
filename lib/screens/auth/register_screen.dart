import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../data/services/auth_provider.dart';
import '../../widgets/cv_widgets.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _jobController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  int _currentStep = 0; // 0: personal info, 1: credentials

  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _nameController.dispose();
    _jobController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Validate name fields
      if (_nameController.text.trim().isEmpty) {
        _showError('Please enter your full name');
        return;
      }
      _fadeController.reset();
      setState(() => _currentStep = 1);
      _fadeController.forward();
    }
  }

  void _prevStep() {
    _fadeController.reset();
    setState(() => _currentStep = 0);
    _fadeController.forward();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.dmSans(color: Colors.white)),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      jobTitle: _jobController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.accentPurple.withOpacity(0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  AppColors.gold.withOpacity(0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
              const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Form(
                key: _formKey,
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: _currentStep == 1
                            ? _prevStep
                            : () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: AppColors.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Progress indicator
                      Row(
                        children: [
                          _buildStepDot(0),
                          Expanded(
                            child: Container(
                              height: 2,
                              margin:
                              const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(1),
                                color: _currentStep >= 1
                                    ? AppColors.gold
                                    : AppColors.border,
                              ),
                            ),
                          ),
                          _buildStepDot(1),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Title
                      Text(
                        _currentStep == 0
                            ? 'Create Account'
                            : 'Set Credentials',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentStep == 0
                            ? 'Tell us about yourself'
                            : 'Secure your account',
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Step 0: Personal Info
                      if (_currentStep == 0) ...[
                        CVTextField(
                          label: 'Full Name',
                          hint: 'John Doe',
                          controller: _nameController,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: Validators.name,
                        ),
                        const SizedBox(height: 20),
                        CVTextField(
                          label: 'Job Title / Specialty',
                          hint: 'Flutter Developer',
                          controller: _jobController,
                          prefixIcon: Icons.work_outline_rounded,
                          validator: (v) =>
                              Validators.required(v, field: 'Job title'),
                        ),
                        const SizedBox(height: 40),
                        GoldButton(
                          label: 'Continue',
                          onPressed: _nextStep,
                          icon: Icons.arrow_forward_rounded,
                        ),
                      ],

                      // Step 1: Credentials
                      if (_currentStep == 1) ...[
                        CVTextField(
                          label: 'Email Address',
                          hint: 'your@email.com',
                          controller: _emailController,
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.email,
                        ),
                        const SizedBox(height: 20),
                        CVTextField(
                          label: 'Password',
                          hint: '••••••••',
                          controller: _passwordController,
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: Validators.password,
                        ),
                        const SizedBox(height: 12),
                        // Password strength hint
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Min 8 chars, 1 uppercase letter & 1 number',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        CVTextField(
                          label: 'Confirm Password',
                          hint: '••••••••',
                          controller: _confirmController,
                          prefixIcon: Icons.lock_outline_rounded,
                          isPassword: true,
                          validator: (v) => Validators.confirmPassword(
                              v, _passwordController.text),
                          textInputAction: TextInputAction.done,
                          onSubmit: _register,
                        ),

                        const SizedBox(height: 16),

                        // Terms text
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                            children: [
                              const TextSpan(
                                  text: 'By signing up, you agree to our '),
                              TextSpan(
                                text: 'Terms of Service',
                                style:
                                const TextStyle(color: AppColors.gold),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style:
                                const TextStyle(color: AppColors.gold),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Error
                        Consumer<AuthProvider>(
                          builder: (_, auth, __) =>
                          auth.errorMessage != null
                              ? Container(
                            margin:
                            const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                              AppColors.error.withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppColors.error
                                      .withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: AppColors.error,
                                    size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          )
                              : const SizedBox.shrink(),
                        ),

                        Consumer<AuthProvider>(
                          builder: (_, auth, __) => GoldButton(
                            label: 'Create Account',
                            onPressed: _register,
                            isLoading: auth.isLoading,
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Login link
                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Already have an account? ',
                              style: GoogleFonts.dmSans(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Text(
                                'Sign In',
                                style: GoogleFonts.dmSans(
                                  color: AppColors.gold,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step) {
    final isActive = step == _currentStep;
    final isDone = step < _currentStep;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isActive ? 32 : 24,
      height: 24,
      decoration: BoxDecoration(
        color: isDone
            ? AppColors.gold
            : isActive
            ? AppColors.gold
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive || isDone ? AppColors.gold : AppColors.border,
        ),
      ),
      child: Center(
        child: isDone
            ? const Icon(Icons.check, size: 12, color: AppColors.textOnGold)
            : Text(
          '${step + 1}',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isActive
                ? AppColors.textOnGold
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}