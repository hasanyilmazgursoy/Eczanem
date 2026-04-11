import '../../../../imports/imports.dart';

/// İlaç bilgi detay ekranı — API'den dönen veriyi gösterir
class DrugDetailScreen extends StatelessWidget {
  final Map<String, dynamic> drugData;

  const DrugDetailScreen({super.key, required this.drugData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppTopBar(title: drugData['ilac_adi'] ?? 'drug_detail.title'.tr()),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          // Sorumluluk reddi
          AppCard(
            color: context.colors.tertiaryContainer,
            child: Row(
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
            content: drugData['etken_madde'] ?? '-',
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 22),
              SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ]),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 22),
              SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: context.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ]),
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
