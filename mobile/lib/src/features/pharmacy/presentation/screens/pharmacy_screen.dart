import '../../../../imports/imports.dart';
import '../../data/pharmacy_repository.dart';
import '../../data/models/pharmacy_item.dart';

/// Nöbetçi eczane listesi ekranı (FAZ 6).
///
/// Kullanıcının konumunu alır, backend `/api/pharmacy/nearby` endpoint'ini
/// çağırır ve sonuçları mesafeye göre sıralı liste olarak gösterir.
class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  AppStatus _status = AppStatus.initial;
  List<PharmacyItem> _pharmacies = const [];
  String? _errorMessage;
  bool _apiAvailable = true;

  final _ilCtrl = TextEditingController();
  final _ilceCtrl = TextEditingController();

  @override
  void dispose() {
    _ilCtrl.dispose();
    _ilceCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_ilCtrl.text.trim().isEmpty) {
      context.showTypedSnackBar(
        'pharmacy.il_required'.tr(),
        type: SnackBarType.error,
      );
      return;
    }

    setState(() {
      _status = AppStatus.loading;
      _errorMessage = null;
    });

    final result = await PharmacyRepository.instance.getNearbyPharmacies(
      il: _ilCtrl.text.trim(),
      ilce: _ilceCtrl.text.trim(),
    );

    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _status = AppStatus.failure;
        _errorMessage = failure.message;
      }),
      (response) => setState(() {
        _status = AppStatus.success;
        _pharmacies = response.pharmacies;
        _apiAvailable = response.apiAvailable;
      }),
    );
  }

  Future<void> _callPharmacy(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Text(
          'pharmacy.title'.tr(),
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: colorScheme.surfaceContainerLow,
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ilCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'pharmacy.il_label'.tr(),
                          hintText: 'pharmacy.il_hint'.tr(),
                          isDense: true,
                          prefixIcon: const Icon(Icons.location_city_rounded),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _ilceCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'pharmacy.ilce_label'.tr(),
                          hintText: 'pharmacy.ilce_hint'.tr(),
                          isDense: true,
                          prefixIcon: const Icon(Icons.map_outlined),
                        ),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _status.isLoading ? null : _search,
                  icon: _status.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.search_rounded),
                  label: Text('pharmacy.search_button'.tr()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(colorScheme, textTheme) {
    if (_status.isInitial) return _InitialState();
    if (_status.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_status.isFailure) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: context.colors.error, size: 48),
              SizedBox(height: AppSpacing.md),
              Text(
                _errorMessage ?? 'pharmacy.error_generic'.tr(),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.lg),
              OutlinedButton(
                onPressed: _search,
                child: Text('shared.try_again'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    if (!_apiAvailable || _pharmacies.isEmpty) return _ApiUnavailableState();

    return ListView.separated(
      padding: EdgeInsets.all(AppSpacing.lg),
      itemCount: _pharmacies.length,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) => _PharmacyTile(
        pharmacy: _pharmacies[i],
        onCall: _pharmacies[i].phone.isNotEmpty
            ? () => _callPharmacy(_pharmacies[i].phone)
            : null,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// İlk durum
// ---------------------------------------------------------------------------

class _InitialState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_pharmacy_rounded,
                size: 80,
                color: colorScheme.primary.withValues(alpha: 0.4)),
            SizedBox(height: AppSpacing.lg),
            Text('pharmacy.initial_title'.tr(),
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            Text('pharmacy.initial_subtitle'.tr(),
                style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// API yapılandırılmamış durumu
// ---------------------------------------------------------------------------

class _ApiUnavailableState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline_rounded,
                size: 64,
                color: colorScheme.primary.withValues(alpha: 0.5)),
            SizedBox(height: AppSpacing.lg),
            Text('pharmacy.no_results_title'.tr(),
                style: textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            Text('pharmacy.no_results_subtitle'.tr(),
                style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Eczane tile bileşeni
// ---------------------------------------------------------------------------

class _PharmacyTile extends StatelessWidget {
  const _PharmacyTile({required this.pharmacy, this.onCall});

  final PharmacyItem pharmacy;
  final VoidCallback? onCall;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.local_pharmacy_rounded,
              color: colorScheme.onPrimaryContainer),
        ),
        title: Text(
          pharmacy.name,
          style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pharmacy.address.isNotEmpty)
              Text(
                pharmacy.address,
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (pharmacy.distanceKm != null)
              Padding(
                padding: EdgeInsets.only(top: AppSpacing.xxs),
                child: Row(
                  children: [
                    Icon(Icons.place_rounded,
                        size: 14, color: colorScheme.primary),
                    SizedBox(width: AppSpacing.xxs),
                    Text(
                      'pharmacy.distance'.tr(
                        args: [pharmacy.distanceKm!.toStringAsFixed(1)],
                      ),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: onCall != null
            ? IconButton(
                icon: const Icon(Icons.call_rounded),
                color: colorScheme.primary,
                tooltip: 'pharmacy.call'.tr(),
                onPressed: onCall,
              )
            : null,
      ),
    );
  }
}
