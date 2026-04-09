import 'package:flutter/material.dart';

class DrugDetailScreen extends StatelessWidget {
  final Map<String, dynamic> drugData;

  const DrugDetailScreen({super.key, required this.drugData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(drugData['ilac_adi'] ?? 'İlaç Bilgisi'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Tıbbi uyarı banner'ı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    drugData['disclaimer'] ??
                        'Bu bilgiler genel bilgilendirme amaçlıdır. Tıbbi tavsiye niteliği taşımaz.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Etken madde
          _InfoCard(
            icon: Icons.science_outlined,
            title: 'Etken Madde',
            content: drugData['etken_madde'] ?? '-',
            color: theme.colorScheme.primary,
          ),

          // Ne için kullanılır
          _InfoCard(
            icon: Icons.medical_information_outlined,
            title: 'Ne İçin Kullanılır',
            content: drugData['ne_icin_kullanilir'] ?? '-',
            color: theme.colorScheme.secondary,
          ),

          // Dozaj
          _InfoCard(
            icon: Icons.straighten_outlined,
            title: 'Dozaj Bilgisi',
            content: drugData['dozaj_bilgisi'] ?? '-',
            color: Colors.teal,
          ),

          // Kullanım şekli
          _InfoCard(
            icon: Icons.schedule_outlined,
            title: 'Kullanım Şekli',
            content: drugData['kullanim_sekli'] ?? '-',
            color: Colors.indigo,
          ),

          // Yan etkiler
          _ListCard(
            icon: Icons.warning_amber_outlined,
            title: 'Yan Etkiler',
            items: _toStringList(drugData['yan_etkiler']),
            color: Colors.orange,
          ),

          // Uyarılar
          _ListCard(
            icon: Icons.error_outline,
            title: 'Uyarılar',
            items: _toStringList(drugData['uyarilar']),
            color: Colors.red,
          ),

          // Kimler kullanmamalı
          _ListCard(
            icon: Icons.block_outlined,
            title: 'Kimler Kullanmamalı',
            items: _toStringList(drugData['kimler_kullanmamali']),
            color: Colors.red[800]!,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  List<String> _toStringList(dynamic data) {
    if (data is List) return data.map((e) => e.toString()).toList();
    return [];
  }
}

/// Tekil bilgi kartı
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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Liste halinde bilgi kartı (yan etkiler, uyarılar vb.)
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
