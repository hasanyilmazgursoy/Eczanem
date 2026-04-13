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
    final colorScheme = context.colors;
    final session = ref.watch(sessionProvider);
    final user = session.user;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _HomeTab(
            userName: user?.name ?? 'home.welcome_home'.tr(),
            userEmail: user?.email ?? '',
          ),
          _DrugGuideTab(),
          _ScanTab(),
          _ProfileTab(
            userName: user?.name ?? 'home.welcome_home'.tr(),
            userEmail: user?.email ?? '-',
            onLogout: _handleLogout,
            onSwitchTab: (i) => setState(() => _selectedIndex = i),
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
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: 'home.tab_home'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon: const Icon(Icons.medication_rounded),
            label: 'home.tab_drug_guide'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.document_scanner_outlined),
            selectedIcon: const Icon(Icons.document_scanner_rounded),
            label: 'home.tab_scan'.tr(),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outlined),
            selectedIcon: const Icon(Icons.person_rounded),
            label: 'home.tab_profile'.tr(),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB 0 â€” ANA SAYFA
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.userName, required this.userEmail});

  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return CustomScrollView(
      slivers: [
        // Eczane temalÄ± expandable app bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          flexibleSpace: FlexibleSpaceBar(
            background: _PharmacyHeroBanner(
              userName: userName,
              userEmail: userEmail,
            ),
          ),
          title: Text(
            'home.app_name'.tr(),
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          centerTitle: false,
        ),

        SliverPadding(
          padding: EdgeInsets.all(AppSpacing.lg),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _QuickSearchBar(),
              SizedBox(height: AppSpacing.xl),
              Text(
                'home.quick_actions_title'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'home.quick_actions_subtitle'.tr(),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              SizedBox(height: AppSpacing.md),
              _QuickActionsGrid(),
              SizedBox(height: AppSpacing.xl),
              _PharmacyOnDutyCard(),
              SizedBox(height: AppSpacing.xl),
              _HealthTipCard(),
              SizedBox(height: AppSpacing.lg),
            ]),
          ),
        ),
      ],
    );
  }
}

// â”€â”€ Eczane Hero Banner â”€â”€
class _PharmacyHeroBanner extends StatelessWidget {
  const _PharmacyHeroBanner({required this.userName, required this.userEmail});

  final String userName;
  final String userEmail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl + 16,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_pharmacy_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home.greeting'.tr(args: [userName]),
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          'home.greeting_subtitle'.tr(),
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ HÄ±zlÄ± Arama BarÄ± â”€â”€
class _QuickSearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return GestureDetector(
      onTap: () => context.push(AppRoutes.drugSearch),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                'home.search_placeholder'.tr(),
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'AI',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ HÄ±zlÄ± Ä°ÅŸlemler Grid â”€â”€
class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 0.95,
      children: [
        _QuickActionTile(
          icon: Icons.search_rounded,
          label: 'home.action_search'.tr(),
          color: colorScheme.primary,
          onTap: () => context.push(AppRoutes.drugSearch),
        ),
        _QuickActionTile(
          icon: Icons.document_scanner_outlined,
          label: 'home.action_scan'.tr(),
          color: colorScheme.tertiary,
          onTap: () => context.push(AppRoutes.drugPhotoScan),
        ),
        _QuickActionTile(
          icon: Icons.local_pharmacy_outlined,
          label: 'home.action_on_duty'.tr(),
          color: const Color(0xFFE53935),
          isComingSoon: true,
          onTap: () {
            context.showSnackBar('home.coming_soon'.tr());
          },
        ),
        _QuickActionTile(
          icon: Icons.alarm_rounded,
          label: 'home.action_reminder'.tr(),
          color: const Color(0xFFFF8F00),
          isComingSoon: true,
          onTap: () {
            context.showSnackBar('home.coming_soon'.tr());
          },
        ),
        _QuickActionTile(
          icon: Icons.compare_arrows_rounded,
          label: 'home.action_interaction'.tr(),
          color: const Color(0xFF5C6BC0),
          isComingSoon: true,
          onTap: () {
            context.showSnackBar('home.coming_soon'.tr());
          },
        ),
        _QuickActionTile(
          icon: Icons.family_restroom_rounded,
          label: 'home.action_family'.tr(),
          color: const Color(0xFF26A69A),
          isComingSoon: true,
          onTap: () {
            context.showSnackBar('home.coming_soon'.tr());
          },
        ),
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isComingSoon = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          padding: EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isComingSoon)
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.xs),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'home.coming_soon_badge'.tr(),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(height: AppSpacing.lg),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// â”€â”€ NÃ¶betÃ§i Eczane Teaser KartÄ± â”€â”€
class _PharmacyOnDutyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return AppCard(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_pharmacy_rounded,
                  color: Color(0xFFE53935),
                  size: 24,
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'home.on_duty_title'.tr(),
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xxs),
                    Text(
                      'home.on_duty_subtitle'.tr(),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'home.on_duty_coming'.tr(),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ SaÄŸlÄ±k Ä°pucu KartÄ± â”€â”€
class _HealthTipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withValues(alpha: 0.4),
            colorScheme.primaryContainer.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.lightbulb_outline_rounded,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'home.health_tip_title'.tr(),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'home.health_tip_content'.tr(),
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB 1 â€” Ä°LAÃ‡ REHBERÄ°
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _DrugGuideTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppTopBar(title: 'home.tab_drug_guide'.tr()),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _QuickSearchBar(),
            SizedBox(height: AppSpacing.xl),
            _GuideActionCard(
              icon: Icons.search_rounded,
              iconColor: colorScheme.primary,
              title: 'home.search_action_title'.tr(),
              subtitle: 'home.search_action_subtitle'.tr(),
              onTap: () => context.push(AppRoutes.drugSearch),
            ),
            SizedBox(height: AppSpacing.md),
            _GuideActionCard(
              icon: Icons.document_scanner_outlined,
              iconColor: colorScheme.tertiary,
              title: 'home.scan_action_title'.tr(),
              subtitle: 'home.scan_action_subtitle'.tr(),
              onTap: () => context.push(AppRoutes.drugPhotoScan),
            ),
            SizedBox(height: AppSpacing.xl),
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.health_and_safety_outlined,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'home.safety_note_title'.tr(),
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xs),
                        Text(
                          'home.safety_note_content'.tr(),
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideActionCard extends StatelessWidget {
  const _GuideActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      showShadow: true,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
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
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB 2 â€” TARAMA
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _ScanTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppTopBar(title: 'home.tab_scan'.tr()),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ScanOptionCard(
              icon: Icons.medication_outlined,
              title: 'home.scan_medicine_title'.tr(),
              subtitle: 'home.scan_medicine_subtitle'.tr(),
              gradient: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.7),
              ],
              onTap: () => context.push(AppRoutes.drugPhotoScan),
            ),
            SizedBox(height: AppSpacing.lg),
            _ScanOptionCard(
              icon: Icons.description_outlined,
              title: 'home.scan_prospectus_title'.tr(),
              subtitle: 'home.scan_prospectus_subtitle'.tr(),
              gradient: [
                colorScheme.secondary,
                colorScheme.secondary.withValues(alpha: 0.7),
              ],
              onTap: () => context.push(AppRoutes.drugPhotoScan),
            ),
            SizedBox(height: AppSpacing.xl),
            Text(
              'home.scan_tips_title'.tr(),
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            _ScanTipRow(
              icon: Icons.wb_sunny_outlined,
              text: 'home.scan_tip_1'.tr(),
            ),
            SizedBox(height: AppSpacing.sm),
            _ScanTipRow(
              icon: Icons.crop_free_rounded,
              text: 'home.scan_tip_2'.tr(),
            ),
            SizedBox(height: AppSpacing.sm),
            _ScanTipRow(
              icon: Icons.filter_1_rounded,
              text: 'home.scan_tip_3'.tr(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanOptionCard extends StatelessWidget {
  const _ScanOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              SizedBox(height: AppSpacing.lg),
              Text(
                title,
                style: context.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Text(
                    'home.scan_start'.tr(),
                    style: context.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanTipRow extends StatelessWidget {
  const _ScanTipRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: context.colors.onSurfaceVariant),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// TAB 3 â€” PROFÄ°L
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.userName,
    required this.userEmail,
    required this.onLogout,
    required this.onSwitchTab,
  });

  final String userName;
  final String userEmail;
  final VoidCallback onLogout;
  final ValueChanged<int> onSwitchTab;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppTopBar(
        title: 'home.profile_title'.tr(),
        actions: [
          IconButton(
            onPressed: onLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'home.logout'.tr(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
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
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              userName,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              userEmail,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            _ProfileMenuItem(
              icon: Icons.medication_rounded,
              title: 'home.profile_my_drugs'.tr(),
              onTap: () => context.push(AppRoutes.drugSearchHistory),
            ),
            _ProfileMenuItem(
              icon: Icons.document_scanner_rounded,
              title: 'home.profile_scan_history'.tr(),
              onTap: () => context.push(AppRoutes.drugPhotoScan),
            ),
            _ProfileMenuItem(
              icon: Icons.settings_outlined,
              title: 'home.profile_settings'.tr(),
              isComingSoon: true,
              onTap: () {
                context.showSnackBar('home.coming_soon'.tr());
              },
            ),
            SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: Text('home.logout'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isComingSoon = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isComingSoon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.primary, size: 22),
      ),
      title: Text(title),
      trailing: isComingSoon
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'home.coming_soon_badge'.tr(),
                style: context.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Icon(
              Icons.chevron_right_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
      onTap: onTap,
    );
  }
}
