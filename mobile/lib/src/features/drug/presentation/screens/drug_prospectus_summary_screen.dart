import '../../../../imports/imports.dart';

class DrugProspectusSummaryScreen extends StatelessWidget {
  const DrugProspectusSummaryScreen({
    super.key,
    required this.summaryData,
  });

  final Map<String, dynamic> summaryData;

  @override
  Widget build(BuildContext context) {
    final medicineName = summaryData['ilac_adi']?.toString().trim();

    return Scaffold(
      appBar: AppTopBar(
        title: medicineName?.isNotEmpty ?? false
            ? medicineName!
            : 'drug_search.prospectus_summary_title'.tr(),
      ),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.md),
        children: [
          AppCard(
            color: context.colors.tertiaryContainer,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: context.colors.onTertiaryContainer,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    summaryData['disclaimer'] ?? 'drug_detail.disclaimer'.tr(),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colors.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.md),
          _SummaryInfoCard(
            icon: Icons.description_outlined,
            title: 'drug_search.prospectus_type_title'.tr(),
            content: summaryData['prospektus_turu'] ?? '-',
            color: context.colors.primary,
          ),
          _SummaryInfoCard(
            icon: Icons.medical_information_outlined,
            title: 'drug_detail.usage'.tr(),
            content: summaryData['ne_icin_kullanilir'] ?? '-',
            color: context.colors.secondary,
          ),
          _SummaryListCard(
            icon: Icons.schedule_outlined,
            title: 'drug_search.prospectus_how_to_use_title'.tr(),
            items: _toStringList(summaryData['nasil_kullanilir']),
            color: Colors.indigo,
          ),
          _SummaryListCard(
            icon: Icons.warning_amber_outlined,
            title: 'drug_search.prospectus_precautions_title'.tr(),
            items: _toStringList(summaryData['dikkat_edilmesi_gerekenler']),
            color: Colors.orange,
          ),
          _SummaryListCard(
            icon: Icons.healing_outlined,
            title: 'drug_detail.side_effects'.tr(),
            items: _toStringList(summaryData['yan_etkiler']),
            color: Colors.redAccent,
          ),
          _SummaryListCard(
            icon: Icons.inventory_2_outlined,
            title: 'drug_search.prospectus_storage_title'.tr(),
            items: _toStringList(summaryData['saklama_kosullari']),
            color: Colors.teal,
          ),
          _SummaryListCard(
            icon: Icons.local_hospital_outlined,
            title: 'drug_search.prospectus_doctor_title'.tr(),
            items: _toStringList(summaryData['ne_zaman_doktora_basvurulmali']),
            color: Colors.deepOrange,
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  List<String> _toStringList(dynamic data) {
    if (data is List) {
      return data
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }
}

class _SummaryInfoCard extends StatelessWidget {
  const _SummaryInfoCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String content;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
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

class _SummaryListCard extends StatelessWidget {
  const _SummaryListCard({
    required this.icon,
    required this.title,
    required this.items,
    required this.color,
  });

  final IconData icon;
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: color)),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
