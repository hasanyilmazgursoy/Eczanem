import 'package:eczanem/src/features/auth/presentation/providers/auth_provider.dart';
import 'package:eczanem/src/imports/core_imports.dart';
import 'package:eczanem/src/imports/packages_imports.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider);

    final cs = context.theme.colorScheme;
    final tt = context.theme.textTheme;

    Future<void> handleLogin() async {
      if (!(formKey.currentState?.validate() ?? false)) {
        return;
      }

      ref.read(authControllerProvider.notifier).login(
            context: context,
            email: emailController.text,
            password: passwordController.text,
          );
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: AppSpacing.xxxl.h),
                // Uygulama logosu + marka kimliği
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_pharmacy_rounded,
                    size: 44,
                    color: cs.primary,
                  ),
                ).animate().scale(duration: const Duration(milliseconds: 400), curve: Curves.easeOut),
                SizedBox(height: AppSpacing.md.h),
                Text(
                  'Eczanem',
                  style: tt.titleLarge?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ).animate().fadeIn(delay: const Duration(milliseconds: 100)),
                SizedBox(height: AppSpacing.xl.h),
                Text(
                  'auth.log_in'.tr(),
                  style:
                      tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ).animate().fadeIn().slideY(begin: 0.2),
                SizedBox(height: AppSpacing.sm.h),
                Text(
                  'auth.log_in_subtitle'.tr(),
                  textAlign: TextAlign.center,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ).animate().fadeIn().slideY(begin: 0.2),
                SizedBox(height: AppSpacing.xxl.h),
                // Form
                Form(
                  key: formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: emailController,
                        enabled: !isLoading,
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
                        controller: passwordController,
                        enabled: !isLoading,
                        label: 'auth.password'.tr(),
                        obscureText: obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
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
                      SizedBox(height: AppSpacing.sm.h),
                      // Şifremi Unuttum — primary renk, tıklanabilir görünüm
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                          ),
                          onPressed: () {
                            context.push(AppRoutes.forgotPassword);
                          },
                          child: Text(
                            'auth.forgot_password'.tr(),
                            style: tt.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg.h),
                      AppButton(
                        label: 'auth.login'.tr(),
                        isLoading: isLoading,
                        onPressed: isLoading ? null : handleLogin,
                        isFullWidth: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl.h),
                InkWell(
                  onTap: () {
                    context.push(AppRoutes.signup);
                  },
                  child: RichText(
                    text: TextSpan(
                      text: 'auth.dont_have_account'.tr(),
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
