import 'package:eczanem/src/features/auth/presentation/providers/session_provider.dart';
import 'package:eczanem/src/imports/core_imports.dart';
import 'package:eczanem/src/imports/packages_imports.dart';

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
          child: SingleChildScrollView(
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
                const Divider(),
                ListTile(
                  leading: Icon(Icons.family_restroom_rounded,
                      color: colorScheme.primary, size: 28),
                  title: Text('family.title'.tr(),
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.familyMembers);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.manage_accounts_rounded,
                      color: colorScheme.primary, size: 28),
                  title: Text('account_settings.title'.tr(),
                      style: textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  onTap: () {
                    context.pop();
                    context.push(AppRoutes.accountSettings);
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
        // AppBar surface ile uyumlu; başlık primary rengiyle vurgulanır.
        // Dark mode'da açık yeşil primary arka plan ile kontrast düşüklüğü oluşuyordu.
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.primary,
        centerTitle: false,
        title: Text(
          'home.app_name'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
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
          padding: EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.xs),
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
                'home.welcome_subtitle'.tr(),
                style: textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),
              // AI özellikler en üstte — görünürlüğü artırmak için öne alındı
              _AiFeaturedCard(
                icon: Icons.smart_toy_rounded,
                title: 'home.action_ai_chat'.tr(),
                subtitle: 'home.action_ai_chat_subtitle'.tr(),
                onTap: () => context.push(AppRoutes.aiChat),
              ),
              SizedBox(height: AppSpacing.md),
              _HugeActionCard(
                // AI destekli; mavi ton klinik/bilişsel çağrışım taşır
                icon: Icons.psychology_rounded,
                title: 'home.action_symptom_analysis'.tr(),
                subtitle: 'home.action_symptom_analysis_subtitle'.tr(),
                color: const Color(0xFF1565C0),
                onTap: () => context.push(AppRoutes.symptomAnalysis),
              ),
              SizedBox(height: AppSpacing.md),
              _HugeActionCard(
                icon: Icons.search_rounded,
                title: 'home.action_search'.tr(),
                subtitle: 'home.search_placeholder'.tr(),
                color: colorScheme.primary,
                onTap: () => context.push(AppRoutes.drugSearch),
              ),
              SizedBox(height: AppSpacing.md),
              _HugeActionCard(
                icon: Icons.camera_alt_rounded,
                title: 'home.action_scan'.tr(),
                subtitle: 'home.scan_all_in_one_title'.tr(),
                color: const Color(0xFF0277BD),
                onTap: () => context.push(AppRoutes.drugPhotoScan),
              ),
              SizedBox(height: AppSpacing.md),
              _HugeActionCard(
                icon: Icons.alarm_rounded,
                title: 'home.action_reminder'.tr(),
                subtitle: 'home.action_reminder_subtitle'.tr(),
                color: const Color(0xFFFF8F00),
                onTap: () => context.push(AppRoutes.medicationReminders),
              ),
              SizedBox(height: AppSpacing.md),
              _HugeActionCard(
                icon: Icons.family_restroom_rounded,
                title: 'home.action_family'.tr(),
                subtitle: 'family.empty_subtitle'.tr(),
                color: const Color(0xFF00897B),
                onTap: () => context.push(AppRoutes.familyMembers),
              ),
              SizedBox(height: AppSpacing.md),
              _HugeActionCard(
                icon: Icons.local_pharmacy_rounded,
                title: 'home.action_pharmacy'.tr(),
                subtitle: 'pharmacy.initial_subtitle'.tr(),
                color: const Color(0xFF5E35B1),
                onTap: () => context.push(AppRoutes.pharmacyNearby),
              ),
              SizedBox(height: AppSpacing.md),
              _HugeActionCard(
                icon: Icons.emergency_rounded,
                title: 'home.action_emergency_card'.tr(),
                subtitle: 'home.action_emergency_card_subtitle'.tr(),
                color: const Color(0xFFB71C1C),
                onTap: () => context.push(AppRoutes.emergencyCard),
              ),
              SizedBox(height: AppSpacing.md),
              _HugeActionCard(
                // Notlar için defter ikonu ve kahverengi ton — not/günlük çağrışımı
                icon: Icons.note_alt_rounded,
                title: 'home.action_health_notes'.tr(),
                subtitle: 'home.action_health_notes_subtitle'.tr(),
                color: const Color(0xFF5D4037),
                onTap: () => context.push(AppRoutes.healthNotes),
              ),
              SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI özelliğini ön plana çıkarmak için gradient şeritli özel kart.
/// Gemini marka rengi olan koyu mor / indigo gradyanıyla dikkat çekicidir.
class _AiFeaturedCard extends StatelessWidget {
  const _AiFeaturedCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  static const _primaryColor = Color(0xFF6750A4);
  static const _secondaryColor = Color(0xFF9C27B0);

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Material(
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, _secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.all(Radius.circular(28)),
          ),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: Colors.white, size: 40),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "AI Destekli" rozeti
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      margin: EdgeInsets.only(bottom: AppSpacing.xs),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Yapay Zeka',
                            style: textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 28,
              ),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Use solid backgrounds for extreme contrast.
    final backgroundColor = isDarkMode
        ? color.withValues(alpha: 0.15)
        : color.withValues(alpha: 0.08);
    final borderColor = isDarkMode
        ? color.withValues(alpha: 0.3)
        : color.withValues(alpha: 0.5);
    final titleColor = isDarkMode ? color : color.withValues(alpha: 1);
    final iconContainerColor = color;
    const iconColor = Colors.white;
    final chevronColor = isDarkMode ? color : color;

    // Ensure subtitle contrast
    final subtitleColor = isDarkMode
        ? context.colors.onSurfaceVariant.withValues(alpha: 0.9)
        : context.colors.onSurfaceVariant;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: color.withValues(alpha: 0.2),
        highlightColor: color.withValues(alpha: 0.1),
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: borderColor,
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
                    color: iconContainerColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ]),
                child: Icon(icon, color: iconColor, size: 40),
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
                        color: titleColor,
                        fontSize: 20,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        color: subtitleColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: chevronColor,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
