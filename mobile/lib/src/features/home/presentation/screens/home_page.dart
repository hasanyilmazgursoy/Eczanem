import 'package:eczanem/src/imports/core_imports.dart';
import 'package:eczanem/src/imports/packages_imports.dart';

import 'package:eczanem/src/features/auth/presentation/providers/session_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Future<void> _handleLogout() async {
    await ref.read(sessionProvider.notifier).logout();
  }

  void _showProfileSheet() {
    final session = ref.read(sessionProvider);
    final user = session.user;
    final textTheme = context.textTheme;
    final colorScheme = context.colors;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    size: 40,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  user?.name ?? 'home.welcome_home'.tr(),
                  style: textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  user?.email ?? '',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                ListTile(
                  leading: Icon(Icons.history_rounded,
                      color: colorScheme.primary, size: 28),
                  title: Text('home.profile_my_drugs'.tr(),
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.drugSearchHistory);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.document_scanner_rounded,
                      color: colorScheme.primary, size: 28),
                  title: Text('home.profile_scan_history'.tr(),
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.drugScanHistory);
                  },
                ),
                SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: () {
                    context.pop();
                    _handleLogout();
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text('home.logout'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;
    final session = ref.watch(sessionProvider);
    final user = session.user;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        centerTitle: false,
        title: Text(
          'home.app_name'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showProfileSheet,
            icon: const Icon(Icons.person_rounded),
            iconSize: 32,
            tooltip: 'home.tab_profile'.tr(),
          ),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.md),
              Text(
                'home.greeting'.tr(args: [user?.name ?? '']),
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                'Size nasıl yardımcı olabilirim?',
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xxl),
              _HugeActionCard(
                icon: Icons.search_rounded,
                title: 'home.action_search'.tr(),
                subtitle: 'home.search_placeholder'.tr(),
                color: colorScheme.primary,
                onTap: () => context.push(AppRoutes.drugSearch),
              ),
              SizedBox(height: AppSpacing.xl),
              _HugeActionCard(
                icon: Icons.camera_alt_rounded,
                title: 'home.action_scan'.tr(),
                subtitle: 'home.scan_all_in_one_title'.tr(),
                color: colorScheme.tertiary,
                onTap: () => context.push(AppRoutes.drugPhotoScan),
              ),
              SizedBox(height: AppSpacing.xl),
              _HugeActionCard(
                icon: Icons.alarm_rounded,
                title: 'home.action_reminder'.tr(),
                subtitle: 'Doz saatlerini ve stok bilgilerinizi takip edin.',
                color: const Color(0xFFFF8F00),
                onTap: () => context.push(AppRoutes.medicationReminders),
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _HugeActionCard extends StatelessWidget {
  const _HugeActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Material(
      color: color.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.xl,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: color,
                        fontSize: 24, // Even larger
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 36,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
