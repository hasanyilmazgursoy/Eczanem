import 'package:eczanem/src/features/auth/domain/entities/user.dart';
import 'package:eczanem/src/features/auth/presentation/providers/session_provider.dart';

import '../../../../imports/imports.dart';

/// Hesap ayarları ekranı — kullanıcı bilgisi, şifre değiştirme ve çıkış işlemleri.
class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSaving = true);

    final result = await AuthService.instance.changePassword(
      currentPassword: _currentPasswordCtrl.text,
      newPassword: _newPasswordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    result.fold(
      (failure) => context.showTypedSnackBar(
        failure.message,
        type: SnackBarType.error,
      ),
      (_) {
        _currentPasswordCtrl.clear();
        _newPasswordCtrl.clear();
        _confirmPasswordCtrl.clear();
        context.showTypedSnackBar(
          'account_settings.password_changed'.tr(),
          type: SnackBarType.success,
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('account_settings.logout_confirm_title'.tr()),
        content: Text('account_settings.logout_confirm_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('shared.cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: context.colors.error,
            ),
            child: Text('account_settings.logout'.tr()),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await AuthService.instance.logout();
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    // Kullanıcı adı ve e-posta üst bölümde gösterilir
    final user = ref.watch(sessionProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text('account_settings.title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Kullanıcı bilgisi kartı — isim ve e-posta gösterimi
                _UserInfoHeader(user: user),
                SizedBox(height: AppSpacing.xl),
                Text(
                  'account_settings.change_password'.tr(),
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _currentPasswordCtrl,
                  label: 'account_settings.current_password'.tr(),
                  obscureText: _obscureCurrent,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrent ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'account_settings.field_required'.tr()
                      : null,
                ),
                SizedBox(height: AppSpacing.ms),
                AppTextField(
                  controller: _newPasswordCtrl,
                  label: 'account_settings.new_password'.tr(),
                  obscureText: _obscureNew,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return 'account_settings.field_required'.tr();
                    }
                    if (v.length < 6) {
                      return 'account_settings.password_min_length'.tr();
                    }
                    return null;
                  },
                ),
                SizedBox(height: AppSpacing.ms),
                AppTextField(
                  controller: _confirmPasswordCtrl,
                  label: 'account_settings.confirm_password'.tr(),
                  obscureText: _obscureConfirm,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: (v) => v != _newPasswordCtrl.text
                      ? 'account_settings.passwords_mismatch'.tr()
                      : null,
                ),
                SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: 'account_settings.save'.tr(),
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _changePassword,
                  isFullWidth: true,
                ),
                SizedBox(height: AppSpacing.xxl),
                const Divider(),
                SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'account_settings.logout'.tr(),
                  variant: ButtonVariant.danger,
                  onPressed: _logout,
                  isFullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kullanıcı adı ve e-posta adresini ekranın üstünde gösterir.
class _UserInfoHeader extends StatelessWidget {
  const _UserInfoHeader({required this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final cs = context.colors;
    final tt = context.textTheme;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.person_rounded,
            size: 28,
            color: cs.onPrimaryContainer,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.name ?? '',
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
              if (user?.email != null)
                Text(
                  user!.email,
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
