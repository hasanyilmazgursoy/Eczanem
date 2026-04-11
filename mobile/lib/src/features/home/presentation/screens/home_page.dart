import 'package:eczanem/src/imports/core_imports.dart';
import 'package:eczanem/src/imports/packages_imports.dart';

import 'package:eczanem/src/features/auth/presentation/providers/session_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  Future<void> _handleLogout() async {
    await ref.read(sessionProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final session = ref.watch(sessionProvider);
    final user = session.user;

    final pageTitle = _selectedIndex == 0
        ? 'home.home_title'.tr()
        : 'home.profile_title'.tr();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppTopBar(
        title: pageTitle,
        actions: _selectedIndex == 1
            ? [
                IconButton(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded),
                  tooltip: 'home.logout'.tr(),
                ),
              ]
            : null,
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: AppBorders.card,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: colorScheme.onPrimary,
                        child: Icon(
                          Icons.local_pharmacy_rounded,
                          color: colorScheme.primary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.md),
                      Text(
                        'home.quick_actions_title'.tr(),
                        style: textTheme.headlineSmall?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        'home.quick_actions_subtitle'.tr(),
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.88),
                        ),
                      ),
                      SizedBox(height: AppSpacing.lg),
                      Text(
                        user?.name ?? 'home.welcome_home'.tr(),
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        user?.email ?? 'home.home_subtitle'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimary.withValues(alpha: 0.84),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                _QuickActionCard(
                  icon: Icons.search_rounded,
                  title: 'home.search_action_title'.tr(),
                  subtitle: 'home.search_action_subtitle'.tr(),
                  accentColor: colorScheme.primary,
                  onTap: () => context.push(AppRoutes.drugSearch),
                ),
                SizedBox(height: AppSpacing.md),
                _QuickActionCard(
                  icon: Icons.document_scanner_outlined,
                  title: 'home.scan_action_title'.tr(),
                  subtitle: 'home.scan_action_subtitle'.tr(),
                  accentColor: colorScheme.tertiary,
                  onTap: () => context.push(AppRoutes.drugPhotoScan),
                ),
                SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.phase1_title'.tr(),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'home.phase1_subtitle'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.account_circle_rounded,
                  size: 72,
                  color: colorScheme.primary,
                ),
                SizedBox(height: AppSpacing.lg),
                Text(
                  user?.name ?? 'home.welcome_home'.tr(),
                  textAlign: TextAlign.center,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  user?.email ?? '-',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'home.phase1_title'.tr(),
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        'home.phase1_subtitle'.tr(),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: () => setState(() => _selectedIndex = 0),
                  icon: const Icon(Icons.search_rounded),
                  label: Text('home.start_search'.tr()),
                ),
                SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text('home.logout'.tr()),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.search_rounded),
            label: 'home.search_tab'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_rounded),
            label: 'home.profile_tab'.tr(),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: accentColor),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right_rounded, color: accentColor),
        ],
      ),
    );
  }
}
