import 'package:eczanem/src/imports/core_imports.dart';
import 'package:eczanem/src/imports/packages_imports.dart';

import 'package:eczanem/src/features/auth/presentation/providers/auth_provider.dart';

// ConsumerStatefulWidget: Controller'lar build() içinde değil State'te tutulur;
// böylece her rebuild'de kullanıcı girişi korunur ve dispose çağrılır.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    ref.read(authControllerProvider.notifier).signUp(
          context: context,
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xl.h),
                Text(
                  'auth.create_account'.tr(),
                  style:
                      tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ).animate().fadeIn().slideY(begin: 0.2),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  'auth.create_account_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ).animate().fadeIn().slideY(begin: 0.2),
                SizedBox(height: AppSpacing.xxxl.h),
                // Form Card
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _nameController,
                        enabled: !isLoading,
                        label: 'auth.name'.tr(),
                        prefixIcon: const Icon(Icons.person_outline),
                        validator: (v) => AppUtils.isBlank(v)
                            ? 'auth.name_required'.tr()
                            : null,
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: _emailController,
                        enabled: !isLoading,
                        keyboardType: TextInputType.emailAddress,
                        label: 'auth.email'.tr(),
                        prefixIcon: const Icon(Icons.email_outlined),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'auth.email_required'.tr();
                          }
                          if (!AppUtils.isValidEmail(v!)) {
                            return 'auth.email_invalid'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: _passwordController,
                        enabled: !isLoading,
                        label: 'auth.password'.tr(),
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'auth.password_required'.tr();
                          }
                          if (v!.length < 6) {
                            return 'auth.password_too_short'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.md.h),
                      AppTextField(
                        controller: _confirmPasswordController,
                        enabled: !isLoading,
                        label: 'auth.confirm_password'.tr(),
                        obscureText: _obscureConfirmPassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                        validator: (v) {
                          if (AppUtils.isBlank(v)) {
                            return 'auth.confirm_password_required'.tr();
                          }
                          if (v != _passwordController.text) {
                            return 'auth.passwords_do_not_match'.tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: AppSpacing.lg.h),
                      AppButton(
                        label: 'auth.create_account'.tr(),
                        isLoading: isLoading,
                        onPressed: isLoading ? null : _handleSignup,
                        width: ButtonSize.large,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xxxl.h),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 20.w,
                      children: [
                        SizedBox(
                          width: 50.w,
                          height: 50.w,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFEA4335)
                                  .withValues(alpha: 0.8),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppBorders.button,
                              ),
                            ),
                            child: SvgPicture.asset(AppAssets.googleIcon),
                          ),
                        ),
                        SizedBox(
                          width: 50.w,
                          height: 50.w,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppBorders.button,
                              ),
                            ),
                            child: SvgPicture.asset(AppAssets.facebookIcon),
                          ),
                        ),
                        SizedBox(
                          width: 50.w,
                          height: 50.w,
                          child: TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF000000),
                              padding: EdgeInsets.symmetric(horizontal: 10.w),
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppBorders.button,
                              ),
                            ),
                            child: SvgPicture.asset(AppAssets.appleIcon),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.xl.h),
                  ],
                ),
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'auth.already_have_account'.tr(),
                      style:
                          tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      children: [
                        TextSpan(
                          text: 'auth.sign_up'.tr(),
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
