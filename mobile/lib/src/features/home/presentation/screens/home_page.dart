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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.xl,
                  AppSpacing.lg,
                  AppSpacing.xl,
                  AppSpacing.sm,
                ),
                child: AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.medication_liquid_rounded,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.name ?? 'home.welcome_home'.tr(),
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: AppSpacing.xs),
                            Text(
                              user?.email ?? 'home.home_subtitle'.tr(),
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
              ),
              const Expanded(
                child: DrugSearchContent(showHeader: false),
              ),
            ],
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
