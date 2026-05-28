import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../imports/imports.dart';
import '../../data/emergency_card_repository.dart';
import '../../data/models/emergency_card.dart';

/// Dropdown için standart kan grubu seçenekleri (Türkiye notasyonu).
const _kBloodTypes = [
  'A Rh+', 'A Rh-',
  'B Rh+', 'B Rh-',
  'AB Rh+', 'AB Rh-',
  '0 Rh+', '0 Rh-',
];

/// FAZ 7 — Acil Durum Kartı Ekranı.
///
/// İki mod arasında toggle yapar:
/// - Görüntüleme modu: Yüksek kontrast, büyük yazı, bilgiler ızgara/bölüm şeklinde
/// - Düzenleme modu: Form alanları, liste ekleme/çıkarma chip'leri
class EmergencyCardScreen extends StatefulWidget {
  const EmergencyCardScreen({super.key});

  @override
  State<EmergencyCardScreen> createState() => _EmergencyCardScreenState();
}

class _EmergencyCardScreenState extends State<EmergencyCardScreen> {
  EmergencyCard? _card;
  bool _isEditing = false;
  AppStatus _saveStatus = AppStatus.initial;

  // --- Form kontrolleri ---
  // Kan grubu dropdown seçimi (_kBloodTypes listesinden)
  String? _selectedBloodType;
  final _contactNameCtrl = TextEditingController();
  final _contactPhoneCtrl = TextEditingController();
  final _doctorNameCtrl = TextEditingController();
  final _doctorPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _newItemCtrl = TextEditingController();

  // Düzenleme sırasında çalışan geçici listeler
  final List<String> _allergies = [];
  final List<String> _chronicConditions = [];
  final List<String> _currentMedications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _doctorNameCtrl.dispose();
    _doctorPhoneCtrl.dispose();
    _notesCtrl.dispose();
    _newItemCtrl.dispose();
    super.dispose();
  }

  void _load() {
    final card = EmergencyCardRepository.instance.getCard();
    setState(() {
      _card = card;
      // Kart yoksa düzenleme modunda başla
      _isEditing = card == null;
    });
    if (card != null) _populateControllers(card);
  }

  /// Form kontrollerini mevcut kart verileriyle doldurur.
  void _populateControllers(EmergencyCard card) {
    // Boşluk ve büyük/küçük harf farkı gözetmeden dropdown seçeneğiyle eşleştir
    _selectedBloodType = _kBloodTypes.where(
      (bt) =>
          bt.toLowerCase().replaceAll(' ', '') ==
          card.bloodType.toLowerCase().replaceAll(' ', ''),
    ).firstOrNull;
    _contactNameCtrl.text = card.emergencyContactName;
    _contactPhoneCtrl.text = card.emergencyContactPhone;
    _doctorNameCtrl.text = card.doctorName;
    _doctorPhoneCtrl.text = card.doctorPhone;
    _notesCtrl.text = card.notes;
    _allergies
      ..clear()
      ..addAll(card.allergies);
    _chronicConditions
      ..clear()
      ..addAll(card.chronicConditions);
    _currentMedications
      ..clear()
      ..addAll(card.currentMedications);
  }

  Future<void> _save() async {
    setState(() => _saveStatus = AppStatus.loading);

    final now = _card?.updatedAt ?? DateTime.now();
    final card = EmergencyCard(
      bloodType: _selectedBloodType ?? '',
      allergies: List.of(_allergies),
      chronicConditions: List.of(_chronicConditions),
      currentMedications: List.of(_currentMedications),
      emergencyContactName: _contactNameCtrl.text.trim(),
      emergencyContactPhone: _contactPhoneCtrl.text.trim(),
      doctorName: _doctorNameCtrl.text.trim(),
      doctorPhone: _doctorPhoneCtrl.text.trim(),
      notes: _notesCtrl.text.trim(),
      updatedAt: now,
    );

    final result = await EmergencyCardRepository.instance.saveCard(card);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() => _saveStatus = AppStatus.failure);
        context.showTypedSnackBar(failure.message, type: SnackBarType.error);
      },
      (saved) {
        setState(() {
          _card = saved;
          _isEditing = false;
          _saveStatus = AppStatus.success;
        });
        context.showTypedSnackBar(
          'emergency_card.saved_success'.tr(),
          type: SnackBarType.success,
        );
      },
    );
  }

  void _toggleEdit() {
    if (!_isEditing && _card != null) _populateControllers(_card!);
    setState(() => _isEditing = !_isEditing);
  }

  /// Acil kart verilerini QR kod olarak gösterir.
  ///
  /// Birinci yardım personeli aklıllı telefonuyla kodu okutarak bilgilere
  /// hızlıca erişebilir.
  void _showQrDialog() {
    final card = _card;
    if (card == null || card.isEmpty) return;

    // QR içeriği: okunabilir düz metin (JSON yapmak yerine basit format)
    final buf = StringBuffer();
    buf.writeln('ECZANEM ACIL KART');
    if (card.bloodType.isNotEmpty) buf.writeln('KAN:${card.bloodType}');
    for (final a in card.allergies) {
      buf.writeln('ALERJI:$a');
    }
    for (final c in card.chronicConditions) {
      buf.writeln('HASTALIK:$c');
    }
    for (final m in card.currentMedications) {
      buf.writeln('ILAC:$m');
    }
    if (card.emergencyContactName.isNotEmpty) {
      buf.writeln('ILETISIM:${card.emergencyContactName}');
    }
    if (card.emergencyContactPhone.isNotEmpty) {
      buf.writeln('TEL:${card.emergencyContactPhone}');
    }
    if (card.doctorName.isNotEmpty) buf.writeln('DOKTOR:${card.doctorName}');
    if (card.doctorPhone.isNotEmpty) {
      buf.writeln('DTEL:${card.doctorPhone}');
    }
    if (card.notes.isNotEmpty) buf.writeln('NOT:${card.notes}');

    final qrData = buf.toString().trim();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code_rounded, color: Color(0xFFB71C1C)),
            const SizedBox(width: 8),
            Text('emergency_card.qr_title'.tr()),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'emergency_card.qr_subtitle'.tr(),
              style: ctx.textTheme.bodySmall?.copyWith(
                color: ctx.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              // Koyu temada siyah modüller görünmez — beyaz arka plan şart
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFFB71C1C),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('shared.close'.tr()),
          ),
        ],
      ),
    );
  }

  /// Acil kart bilgilerini düz metin olarak paylaşır.
  void _shareCard() {
    final card = _card;
    if (card == null || card.isEmpty) return;

    final buffer = StringBuffer();
    buffer.writeln('🆘 ACİL DURUM KARTI');
    buffer.writeln('─' * 30);

    if (card.bloodType.isNotEmpty) {
      buffer.writeln('🩸 Kan Grubu: ${card.bloodType}');
    }
    if (card.allergies.isNotEmpty) {
      buffer.writeln('\n⚠️ Alerjiler:');
      for (final a in card.allergies) {
        buffer.writeln('  • $a');
      }
    }
    if (card.chronicConditions.isNotEmpty) {
      buffer.writeln('\n🫀 Kronik Hastalıklar:');
      for (final c in card.chronicConditions) {
        buffer.writeln('  • $c');
      }
    }
    if (card.currentMedications.isNotEmpty) {
      buffer.writeln('\n💊 Düzenli İlaçlar:');
      for (final m in card.currentMedications) {
        buffer.writeln('  • $m');
      }
    }
    if (card.emergencyContactName.isNotEmpty ||
        card.emergencyContactPhone.isNotEmpty) {
      buffer.writeln('\n📞 Acil İletişim:');
      if (card.emergencyContactName.isNotEmpty) {
        buffer.writeln('  ${card.emergencyContactName}');
      }
      if (card.emergencyContactPhone.isNotEmpty) {
        buffer.writeln('  ${card.emergencyContactPhone}');
      }
    }
    if (card.doctorName.isNotEmpty || card.doctorPhone.isNotEmpty) {
      buffer.writeln('\n🏥 Doktor:');
      if (card.doctorName.isNotEmpty) buffer.writeln('  ${card.doctorName}');
      if (card.doctorPhone.isNotEmpty) {
        buffer.writeln('  ${card.doctorPhone}');
      }
    }
    if (card.notes.isNotEmpty) {
      buffer.writeln('\n📝 Notlar:\n${card.notes}');
    }

    Share.share(buffer.toString(), subject: 'Acil Durum Kartım');
  }

  /// Chip listesine yeni öğe ekle (alerji, hastalık, ilaç).
  void _addItem(List<String> list) {
    final text = _newItemCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      list.add(text);
      _newItemCtrl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C), // kırmızı — acil rengi
        foregroundColor: Colors.white,
        title: Text(
          'emergency_card.title'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          // Görüntüleme modunda paylaş + QR butonları
          if (!_isEditing && _card != null && _card!.isNotEmpty) ...[
            IconButton(
              onPressed: _showQrDialog,
              icon: const Icon(Icons.qr_code_rounded, color: Colors.white),
              tooltip: 'emergency_card.qr_tooltip'.tr(),
            ),
            IconButton(
              onPressed: _shareCard,
              icon: const Icon(Icons.share_outlined, color: Colors.white),
              tooltip: 'emergency_card.share'.tr(),
            ),
          ],
          // Düzenleme modunda metin "İptal", görüntüleme modunda yalnızca ikon
          // (görüntülemede QR+Paylaş+Düzenle çok yer aldığından metin kaldırıldı)
          if (_isEditing)
            TextButton.icon(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              label: Text(
                'emergency_card.cancel'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _toggleEdit,
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              tooltip: 'emergency_card.edit'.tr(),
            ),
        ],
      ),
      body: _isEditing ? _buildEditForm() : _buildViewCard(),
    );
  }

  // ─────────────────────────── GÖRÜNTÜLEME MODU ──────────────────────────

  Widget _buildViewCard() {
    if (_card == null || _card!.isEmpty) {
      return _EmptyCardState(onEdit: _toggleEdit);
    }

    final card = _card!;
    const acilKirmizi = Color(0xFFB71C1C);

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kan grubu — en önemli alan, büyük ve belirgin
          _BigInfoTile(
            label: 'emergency_card.blood_type'.tr(),
            value: card.bloodType.isNotEmpty
                ? card.bloodType
                : 'emergency_card.not_set'.tr(),
            icon: Icons.water_drop_rounded,
            color: acilKirmizi,
          ),
          SizedBox(height: AppSpacing.lg),
          // Acil iletişim
          if (card.emergencyContactName.isNotEmpty ||
              card.emergencyContactPhone.isNotEmpty)
            _ContactTile(
              label: 'emergency_card.emergency_contact'.tr(),
              name: card.emergencyContactName,
              phone: card.emergencyContactPhone,
              icon: Icons.emergency_rounded,
              color: acilKirmizi,
            ),
          if (card.emergencyContactName.isNotEmpty ||
              card.emergencyContactPhone.isNotEmpty)
            SizedBox(height: AppSpacing.lg),
          // Doktor
          if (card.doctorName.isNotEmpty || card.doctorPhone.isNotEmpty)
            _ContactTile(
              label: 'emergency_card.doctor'.tr(),
              name: card.doctorName,
              phone: card.doctorPhone,
              icon: Icons.local_hospital_rounded,
              color: const Color(0xFF1565C0),
            ),
          if (card.doctorName.isNotEmpty || card.doctorPhone.isNotEmpty)
            SizedBox(height: AppSpacing.lg),
          // Alerjiler
          if (card.allergies.isNotEmpty)
            _ChipSection(
              label: 'emergency_card.allergies'.tr(),
              items: card.allergies,
              color: const Color(0xFFE65100),
              icon: Icons.warning_amber_rounded,
            ),
          if (card.allergies.isNotEmpty) SizedBox(height: AppSpacing.lg),
          // Kronik hastalıklar
          if (card.chronicConditions.isNotEmpty)
            _ChipSection(
              label: 'emergency_card.chronic_conditions'.tr(),
              items: card.chronicConditions,
              color: const Color(0xFF4A148C),
              icon: Icons.monitor_heart_rounded,
            ),
          if (card.chronicConditions.isNotEmpty)
            SizedBox(height: AppSpacing.lg),
          // Düzenli ilaçlar
          if (card.currentMedications.isNotEmpty)
            _ChipSection(
              label: 'emergency_card.current_medications'.tr(),
              items: card.currentMedications,
              color: const Color(0xFF1B5E20),
              icon: Icons.medication_rounded,
            ),
          if (card.currentMedications.isNotEmpty)
            SizedBox(height: AppSpacing.lg),
          // Notlar
          if (card.notes.isNotEmpty) ...[
            _SectionHeader(
              label: 'emergency_card.notes'.tr(),
              icon: Icons.notes_rounded,
              color: context.colors.primary,
            ),
            SizedBox(height: AppSpacing.sm),
            Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text(
                  card.notes,
                  style: context.textTheme.bodyLarge,
                ),
              ),
            ),
          ],
          SizedBox(height: AppSpacing.xl),
          // Son güncelleme
          Text(
            'emergency_card.last_updated'.tr(
              args: [_formatDate(card.updatedAt)],
            ),
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  // ────────────────────────── DÜZENLEME FORMU ────────────────────────────

  Widget _buildEditForm() {
    final textTheme = context.textTheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Kan grubu — dropdown, serbest metin yerine standart seçenekler
          DropdownButtonFormField<String>(
            value: _selectedBloodType,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'emergency_card.blood_type'.tr(),
              prefixIcon: const Icon(Icons.water_drop_rounded),
            ),
            hint: Text('emergency_card.blood_type_hint'.tr()),
            items: _kBloodTypes
                .map(
                  (bt) => DropdownMenuItem(
                    value: bt,
                    child: Text(bt),
                  ),
                )
                .toList(),
            onChanged: (val) => setState(() => _selectedBloodType = val),
          ),
          SizedBox(height: AppSpacing.xl),
          // Alerjiler
          _EditableChipSection(
            title: 'emergency_card.allergies'.tr(),
            hint: 'emergency_card.allergy_hint'.tr(),
            items: _allergies,
            controller: _newItemCtrl,
            onAdd: () => _addItem(_allergies),
            onRemove: (i) => setState(() => _allergies.removeAt(i)),
            color: const Color(0xFFE65100),
          ),
          SizedBox(height: AppSpacing.xl),
          // Kronik hastalıklar
          _EditableChipSection(
            title: 'emergency_card.chronic_conditions'.tr(),
            hint: 'emergency_card.condition_hint'.tr(),
            items: _chronicConditions,
            controller: TextEditingController(),
            onAdd: () {},
            onRemove: (i) => setState(() => _chronicConditions.removeAt(i)),
            color: const Color(0xFF4A148C),
            onAddWithText: (text) {
              if (text.isNotEmpty) {
                setState(() => _chronicConditions.add(text));
              }
            },
          ),
          SizedBox(height: AppSpacing.xl),
          // Düzenli ilaçlar
          _EditableChipSection(
            title: 'emergency_card.current_medications'.tr(),
            hint: 'emergency_card.medication_hint'.tr(),
            items: _currentMedications,
            controller: TextEditingController(),
            onAdd: () {},
            onRemove: (i) => setState(() => _currentMedications.removeAt(i)),
            color: const Color(0xFF1B5E20),
            onAddWithText: (text) {
              if (text.isNotEmpty) {
                setState(() => _currentMedications.add(text));
              }
            },
          ),
          SizedBox(height: AppSpacing.xl),
          // Acil iletişim
          Text(
            'emergency_card.emergency_contact'.tr(),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _contactNameCtrl,
            label: 'emergency_card.contact_name'.tr(),
            hint: 'emergency_card.contact_name_hint'.tr(),
            prefixIcon: const Icon(Icons.person_rounded),
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _contactPhoneCtrl,
            label: 'emergency_card.contact_phone'.tr(),
            hint: '0555 000 00 00',
            prefixIcon: const Icon(Icons.phone_rounded),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: AppSpacing.xl),
          // Doktor bilgileri
          Text(
            'emergency_card.doctor'.tr(),
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: _doctorNameCtrl,
            label: 'emergency_card.doctor_name'.tr(),
            hint: 'emergency_card.doctor_name_hint'.tr(),
            prefixIcon: const Icon(Icons.local_hospital_rounded),
          ),
          SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _doctorPhoneCtrl,
            label: 'emergency_card.doctor_phone'.tr(),
            hint: '0555 000 00 00',
            prefixIcon: const Icon(Icons.phone_rounded),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: AppSpacing.xl),
          // Notlar
          AppTextField(
            controller: _notesCtrl,
            label: 'emergency_card.notes'.tr(),
            hint: 'emergency_card.notes_hint'.tr(),
            prefixIcon: const Icon(Icons.notes_rounded),
            maxLines: 4,
          ),
          SizedBox(height: AppSpacing.xxl),
          // Kaydet butonu
          AppButton(
            onPressed: _saveStatus.isLoading ? null : _save,
            isLoading: _saveStatus.isLoading,
            label: 'emergency_card.save'.tr(),
            isFullWidth: true,
          ),
          SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}

// ══════════════════════════════ YARDIMCI WİDGET'LAR ══════════════════════════

/// Görüntüleme modundaki büyük bilgi kartı (kan grubu için).
class _BigInfoTile extends StatelessWidget {
  const _BigInfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color, width: 2),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 40),
            SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: context.textTheme.labelLarge?.copyWith(color: color),
                  ),
                  Text(
                    value,
                    style: context.textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
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

/// Görüntüleme modunda iletişim bilgisi + arama butonu.
class _ContactTile extends StatelessWidget {
  const _ContactTile({
    required this.label,
    required this.name,
    required this.phone,
    required this.icon,
    required this.color,
  });

  final String label;
  final String name;
  final String phone;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          label,
          style: context.textTheme.labelMedium?.copyWith(color: color),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (name.isNotEmpty)
              Text(name,
                  style: context.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            if (phone.isNotEmpty)
              Text(phone, style: context.textTheme.bodyLarge),
          ],
        ),
        isThreeLine: name.isNotEmpty && phone.isNotEmpty,
        trailing: phone.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.call_rounded, color: color),
                onPressed: () async {
                  final uri = Uri.parse('tel:$phone');
                  await launchUrl(uri);
                },
              )
            : null,
      ),
    );
  }
}

/// Görüntüleme modundaki chip listesi bölümü (alerjiler, hastalıklar).
class _ChipSection extends StatelessWidget {
  const _ChipSection({
    required this.label,
    required this.items,
    required this.color,
    required this.icon,
  });

  final String label;
  final List<String> items;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(label: label, icon: icon, color: color),
        SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => Chip(
                  label: Text(
                    item,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                  labelStyle: TextStyle(color: color),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// Düzenleme modunda listeye öğe ekleyip çıkarabilen bölüm.
///
/// Her bölümün kendi [TextEditingController]'ı vardır ki listeler arası
/// metin karışmasın.
class _EditableChipSection extends StatefulWidget {
  const _EditableChipSection({
    required this.title,
    required this.hint,
    required this.items,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
    required this.color,
    this.onAddWithText,
  });

  final String title;
  final String hint;
  final List<String> items;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;
  final Color color;
  final void Function(String text)? onAddWithText;

  @override
  State<_EditableChipSection> createState() => _EditableChipSectionState();
}

class _EditableChipSectionState extends State<_EditableChipSection> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    // onAddWithText varsa kendi controller'ını kullan
    _ctrl = widget.onAddWithText != null
        ? TextEditingController()
        : widget.controller;
  }

  @override
  void dispose() {
    if (widget.onAddWithText != null) _ctrl.dispose();
    super.dispose();
  }

  void _handleAdd() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    if (widget.onAddWithText != null) {
      widget.onAddWithText!(text);
    } else {
      widget.onAdd();
    }
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        // Mevcut öğeler
        if (widget.items.isNotEmpty)
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: widget.items.asMap().entries.map((entry) {
              return Chip(
                label: Text(entry.value),
                backgroundColor: widget.color.withValues(alpha: 0.1),
                side: BorderSide(color: widget.color.withValues(alpha: 0.4)),
                labelStyle: TextStyle(color: widget.color),
                deleteIcon:
                    Icon(Icons.close_rounded, size: 16, color: widget.color),
                onDeleted: () => widget.onRemove(entry.key),
              );
            }).toList(),
          ),
        if (widget.items.isNotEmpty) SizedBox(height: AppSpacing.sm),
        // Yeni öğe ekle satırı
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                onSubmitted: (_) => _handleAdd(),
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              onPressed: _handleAdd,
              icon: const Icon(Icons.add_rounded),
              style: IconButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Bölüm başlığı — görüntüleme modunda kullanılır.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Kart henüz oluşturulmamışken gösterilen boş durum ekranı.
class _EmptyCardState extends StatelessWidget {
  const _EmptyCardState({required this.onEdit});

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.credit_card_off_rounded,
              size: 80,
              color: Color(0xFFB71C1C),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'emergency_card.empty_title'.tr(),
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'emergency_card.empty_subtitle'.tr(),
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.xxl),
            AppButton(
              onPressed: onEdit,
              label: 'emergency_card.create_card'.tr(),
              color: const Color(0xFFB71C1C),
              prefixIcon: const Icon(Icons.add_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
