import '../../../../imports/imports.dart';

/// İlaç bilgi detay ekranı — API'den dönen veriyi gösterir
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

          // Ne İçin Kullanılır
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

          // Kullanım Şekli
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

          // Uyarılar
          _ListCard(
            icon: Icons.error_outline,
            title: 'drug_detail.warnings'.tr(),
            items: _toStringList(drugData['uyarilar']),
            color: Colors.red,
          ),

          // Kimler Kullanmamalı
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

/// Tek satırlık bilgi kartı
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
            Text(content, style: context.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Liste öğesi içeren kart (yan etkiler, uyarılar vb.)
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
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: color)),
                      Expanded(child: Text(item)),
                    ],
                  ),
                )),
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
