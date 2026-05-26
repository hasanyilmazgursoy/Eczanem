import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

import '../../../../imports/imports.dart';

/// Ä°laÃ§ bilgi detay ekranÄ± â€” API'den dÃ¶nen veriyi gÃ¶sterir
class DrugDetailScreen extends StatelessWidget {
  final Map<String, dynamic> drugData;

  const DrugDetailScreen({super.key, required this.drugData});

  @override
  Widget build(BuildContext context) {
    final drugName =
        (drugData['ilac_adi'] ?? 'drug_detail.title'.tr()).toString();
    final activeIngredient = (drugData['etken_madde'] ?? '-').toString();

    return Scaffold(
      appBar: AppTopBar(title: drugName),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          _DrugHeroCard(
            drugName: drugName,
            activeIngredient: activeIngredient,
          ),
          SizedBox(height: AppSpacing.sm),
          // Gemini AI rozeti — bu bilgilerin yapay zeka tarafından üretildiğini vurgular
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6750A4), Color(0xFF9C27B0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'drug_detail.ai_badge'.tr(),
                    style: context.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Yapay Zeka',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          AppCard(
            showShadow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: 'drug_detail.reminder_cta'.tr(),
                  onPressed: () => context.push(
                    AppRoutes.medicationReminders,
                    extra: drugName,
                  ),
                  isFullWidth: true,
                  prefixIcon: const Icon(Icons.alarm_rounded),
                ),
                SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'drug_detail.interaction_cta'.tr(),
                  onPressed: () => context.push(
                    AppRoutes.drugInteraction,
                    extra: [drugName],
                  ),
                  isFullWidth: true,
                  prefixIcon: const Icon(Icons.compare_arrows_rounded),
                ),
                SizedBox(height: AppSpacing.sm),
                _InlineNaturalAlternatives(
                    drugName: drugName,
                    alternatives: (drugData['alternatifler'] as List?)
                        ?.cast<Map<String, dynamic>>()),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          // Sorumluluk reddi
          AppCard(
            color: context.colors.tertiaryContainer,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 20, color: context.colors.onTertiaryContainer),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    drugData['disclaimer'] ?? 'drug_detail.disclaimer'.tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),

          // Etken Madde
          _InfoCard(
            icon: Icons.science_outlined,
            title: 'drug_detail.active_ingredient'.tr(),
            content: activeIngredient,
            color: context.colors.primary,
          ),

          // Ne Ä°Ã§in KullanÄ±lÄ±r
          _InfoCard(
            icon: Icons.medical_information_outlined,
            title: 'drug_detail.usage'.tr(),
            content: drugData['ne_icin_kullanilir'] ?? '-',
            color: context.colors.secondary,
          ),

          // Dozaj Bilgisi
          _InfoCard(
            icon: Icons.straighten_outlined,
            title: 'drug_detail.dosage'.tr(),
            content: drugData['dozaj_bilgisi'] ?? '-',
            color: Colors.teal,
          ),

          // KullanÄ±m Åekli
          _InfoCard(
            icon: Icons.schedule_outlined,
            title: 'drug_detail.how_to_use'.tr(),
            content: drugData['kullanim_sekli'] ?? '-',
            color: Colors.indigo,
          ),

          // Yan Etkiler
          _ListCard(
            icon: Icons.warning_amber_outlined,
            title: 'drug_detail.side_effects'.tr(),
            items: _toStringList(drugData['yan_etkiler']),
            color: Colors.orange,
          ),

          // UyarÄ±lar
          _ListCard(
            icon: Icons.error_outline,
            title: 'drug_detail.warnings'.tr(),
            items: _toStringList(drugData['uyarilar']),
            color: Colors.red,
          ),

          // Kimler KullanmamalÄ±
          _ListCard(
            icon: Icons.block_outlined,
            title: 'drug_detail.contraindications'.tr(),
            items: _toStringList(drugData['kimler_kullanmamali']),
            color: Colors.red[800]!,
          ),

          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  List<String> _toStringList(dynamic data) {
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }
}

/// Tek satÄ±rlÄ±k bilgi kartÄ±
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        showShadow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            MarkdownBody(
              data: content,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(p: context.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

/// Liste Ã¶ÄŸesi iÃ§eren kart (yan etkiler, uyarÄ±lar vb.)
class _ListCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;

  const _ListCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        showShadow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: context.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            // Her madde '• item' olarak markdown'a dönüştürülüyor;
            // bu sayede içindeki bold/italic de düzgün render edilir
            MarkdownBody(
              data: items.map((item) => '\u2022 $item').join('  \n'),
              styleSheet:
                  MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                p: context.textTheme.bodyMedium,
                listBullet: TextStyle(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrugHeroCard extends StatelessWidget {
  const _DrugHeroCard({
    required this.drugName,
    required this.activeIngredient,
  });

  final String drugName;
  final String activeIngredient;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
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
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.onPrimary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.medication_liquid_outlined,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            drugName,
            style: context.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '${'drug_detail.active_ingredient'.tr()}: $activeIngredient',
              style: context.textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNaturalAlternatives extends StatelessWidget {
  final List<dynamic>? alternatives;
  final String drugName;
  const _InlineNaturalAlternatives({required this.drugName, this.alternatives});

  @override
  Widget build(BuildContext context) {
    final altList = alternatives ?? [];
    if (altList.isEmpty) return const SizedBox.shrink();

    return AppCard(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.eco_outlined, color: Colors.green),
              const SizedBox(width: 8),
              Text('drug_detail.natural_alternatives_cta'.tr(),
                  style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 16),
          ...altList.map((item) {
            final mapItem = Map<String, dynamic>.from(item as Map);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mapItem['ad']?.toString() ?? '-',
                      style: context.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(mapItem['aciklama']?.toString() ?? '-'),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
