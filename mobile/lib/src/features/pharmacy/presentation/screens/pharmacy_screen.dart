import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../imports/imports.dart';
import '../../data/models/pharmacy_item.dart';
import '../../data/pharmacy_repository.dart';
import '../../data/turkey_data.dart';

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
  bool _showMap = false; // liste / harita toggle
  // İlçede sonuç bulunamazsa il geneline düşüldüğünü belirtir
  bool _fallbackToIl = false;
  bool _locationLoading = false;

  /// Kullanıcının cihaz konumu — harita merkezini belirlemek için saklanır.
  LatLng? _userLocation;

  // Dropdown seçim değerleri
  String? _selectedIl;
  String? _selectedIlce;
  // Seçili ile ait ilçe listesi (backendden çekilir)
  List<String> _districts = [];
  bool _districtsLoading = false;

  @override
  void initState() {
    super.initState();
    // İzin daha önce verilmişse ekran açıldığında konumu otomatik al.
    _autoDetectLocationIfGranted();
  }

  /// Konum izni zaten varsa `_getLocation()` çağırır; izin yoksa bekler.
  Future<void> _autoDetectLocationIfGranted() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      if (mounted) await _getLocation();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _search() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectedIl == null) {
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
      il: _selectedIl!,
      ilce: _selectedIlce ?? '',
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
        _fallbackToIl = response.fallbackToIl;
      }),
    );
  }

  Future<void> _callPharmacy(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri);
  }

  /// İl seçildiğinde eczaneler.gen.tr'deki gerçek ilçe listesini çeker.
  Future<void> _fetchDistricts(String il) async {
    setState(() {
      _districtsLoading = true;
      _districts = [];
    });
    final result = await PharmacyRepository.instance.getDistricts(il);
    if (!mounted) return;
    result.fold(
      (_) => setState(() => _districtsLoading = false),
      (districts) => setState(() {
        _districts = districts;
        _districtsLoading = false;
      }),
    );
  }

  /// Eczane adresini Google Maps'te açar (yol tarifi).
  Future<void> _openDirections(PharmacyItem pharmacy) async {
    final query = Uri.encodeComponent(
      '${pharmacy.name} ${pharmacy.address}'.trim(),
    );
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$query',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Cihaz konumunu alır; backend Nominatim ile il/ilçe adını tespit eder ve
  /// otomatik arama başlatır.
  Future<void> _getLocation() async {
    setState(() => _locationLoading = true);

    try {
      // İzin kontrolü ve isteği
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        // Kalıcı red: dialog göster ve ayarlar ekranına yönlendir
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('pharmacy.location_denied_forever_title'.tr()),
            content: Text('pharmacy.location_denied_forever_body'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('shared.cancel'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Geolocator.openAppSettings();
                },
                child: Text('pharmacy.location_open_settings'.tr()),
              ),
            ],
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        context.showTypedSnackBar(
          'pharmacy.location_denied'.tr(),
          type: SnackBarType.error,
        );
        return;
      }

      // Önce önbellekteki konum → anında gelir, GPS kilidi gerektirmez
      // Closure içinde null promotion kaybolmaz diye final non-null değişken kullan
      final Position position;
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        position = lastKnown;
      } else {
        // Dart .timeout() Android native çağrısında güvenilmez; AndroidSettings
        // içindeki timeLimit native katmanda uygulanır → gerçek zaman aşımı
        position = await Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.low, // ağ/WiFi tabanlı, GPS beklemiyor
            timeLimit: const Duration(seconds: 8),
          ),
        );
      }

      // Eski metin alanı kalıntısını temizle; harita merkezini kaydet.
      setState(() {
        _status = AppStatus.loading;
        _errorMessage = null;
        _userLocation = LatLng(position.latitude, position.longitude);
      });

      final result = await PharmacyRepository.instance.getNearbyPharmacies(
        lat: position.latitude,
        lon: position.longitude,
      );

      if (!mounted) return;

      result.fold(
        (failure) => setState(() {
          _status = AppStatus.failure;
          _errorMessage = failure.message;
        }),
        (response) {
          // Nominatim'den gelen il adını 81-il listesiyle eşleştir
          String? matchedIl;
          if (response.detectedIl.isNotEmpty) {
            matchedIl = kTurkeyIller
                .where(
                  (il) => il.toLowerCase() == response.detectedIl.toLowerCase(),
                )
                .firstOrNull;
            // Listede yoksa Nominatim sonucunu olduğu gibi kullan
            matchedIl ??= response.detectedIl;
          }
          // İlçe dropdownı için arka planda ilçeleri yükle (sonuçlar zaten gösteriyor)
          if (matchedIl != null) _fetchDistricts(matchedIl);
          setState(() {
            _selectedIl = matchedIl;
            _selectedIlce = null; // ilçeler yüklenince kullanıcı seçer
            _status = AppStatus.success;
            _pharmacies = response.pharmacies;
            _apiAvailable = response.apiAvailable;
            _fallbackToIl = response.fallbackToIl;
            // eczaneler.gen.tr lat/lon vermiyor → marker olmaz → liste göster
            _showMap = false;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      context.showTypedSnackBar(
        'pharmacy.location_error'.tr(),
        type: SnackBarType.error,
      );
    } finally {
      if (mounted) setState(() => _locationLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      // Klavye açıldığında form+liste layout'u sıkışmasın
      resizeToAvoidBottomInset: false,
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
        actions: [
          // Konum alma butonu
          if (_locationLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _getLocation,
              icon: const Icon(Icons.my_location_rounded),
              tooltip: 'pharmacy.get_location'.tr(),
            ),
          // Liste / Harita toggle
          IconButton(
            onPressed: () => setState(() => _showMap = !_showMap),
            icon: Icon(
              _showMap ? Icons.list_rounded : Icons.map_rounded,
            ),
            tooltip:
                _showMap ? 'pharmacy.list_view'.tr() : 'pharmacy.map_view'.tr(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Arama formu her iki görünümde de gösterilir
          Container(
            color: colorScheme.surfaceContainerLow,
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // İl dropdown’u
                DropdownButtonFormField<String>(
                  value: _selectedIl,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'pharmacy.il_label'.tr(),
                    isDense: true,
                    prefixIcon: const Icon(Icons.location_city_rounded),
                  ),
                  hint: Text('pharmacy.il_hint'.tr()),
                  items: kTurkeyIller
                      .map(
                        (il) => DropdownMenuItem(
                          value: il,
                          child: Text(il),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedIl = val;
                      // İl değişince ilçeyi sıfırla
                      _selectedIlce = null;
                      _districts = [];
                    });
                    if (val != null) _fetchDistricts(val);
                  },
                ),
                SizedBox(height: AppSpacing.sm),
                // İlçe dropdown’u (il seçildikten sonra aktif olur)
                DropdownButtonFormField<String>(
                  value: _selectedIlce,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'pharmacy.ilce_label'.tr(),
                    isDense: true,
                    prefixIcon: _districtsLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: Padding(
                              padding: EdgeInsets.all(3),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.map_outlined),
                  ),
                  hint: Text(
                    _selectedIl == null
                        ? 'pharmacy.il_first'.tr()
                        : _districtsLoading
                            ? 'pharmacy.districts_loading'.tr()
                            : 'pharmacy.ilce_optional'.tr(),
                  ),
                  // İl seçilmemişse veya yükleniyorsa devre dışı
                  onChanged: (_selectedIl == null || _districtsLoading)
                      ? null
                      : (val) => setState(() => _selectedIlce = val),
                  items: [
                    // "Tüm il" seçeneği her zaman başta
                    DropdownMenuItem<String>(
                      value: null,
                      child: Text('pharmacy.all_districts'.tr()),
                    ),
                    ..._districts.map(
                      (d) => DropdownMenuItem(value: d, child: Text(d)),
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
            child: _showMap
                ? _buildMapView(colorScheme)
                : _buildBody(colorScheme, textTheme),
          ),
        ],
      ),
    );
  }

  /// Harita görünümü — FlutterMap + eczane markerları.
  Widget _buildMapView(colorScheme) {
    // Koordinatı olan eczaneleri filtrele
    final mappable =
        _pharmacies.where((p) => p.lat != null && p.lon != null).toList();

    // Merkez önceliği: eczane konumu > kullanıcı konumu > Türkiye genel görünüm
    final center = mappable.isNotEmpty
        ? LatLng(mappable.first.lat!, mappable.first.lon!)
        : _userLocation ?? const LatLng(39, 35);
    final double zoom =
        mappable.isNotEmpty ? 13 : (_userLocation != null ? 11 : 5.5);

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
      ),
      children: [
        // OpenStreetMap karo katmanı
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.eczanem',
        ),
        // Kullanıcı konumu markeri (varsa)
        if (_userLocation != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _userLocation!,
                width: 20,
                height: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        // Eczane markerları
        MarkerLayer(
          markers: mappable.map((p) {
            return Marker(
              point: LatLng(p.lat!, p.lon!),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () => _showPharmacyBottomSheet(p),
                child: Icon(
                  Icons.local_pharmacy_rounded,
                  color: colorScheme.primary,
                  size: 36,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Markera tıklandığında eczane detaylarını gösterir.
  void _showPharmacyBottomSheet(PharmacyItem pharmacy) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final colorScheme = ctx.colors;
        final textTheme = ctx.textTheme;
        return Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pharmacy.name,
                style: textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (pharmacy.address.isNotEmpty) ...[
                SizedBox(height: AppSpacing.sm),
                Text(
                  pharmacy.address,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  if (pharmacy.phone.isNotEmpty)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _callPharmacy(pharmacy.phone);
                        },
                        icon: const Icon(Icons.call_rounded),
                        label: Text('pharmacy.call'.tr()),
                      ),
                    ),
                  if (pharmacy.phone.isNotEmpty && pharmacy.lat != null)
                    SizedBox(width: AppSpacing.sm),
                  if (pharmacy.lat != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          launchUrl(Uri.parse(
                            'https://www.google.com/maps/dir/?api=1'
                            '&destination=${pharmacy.lat},${pharmacy.lon}',
                          ));
                        },
                        icon: const Icon(Icons.directions_rounded),
                        label: Text('pharmacy.directions'.tr()),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
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

    return Column(
      children: [
        // İlçede nöbetçi eczane bulunamayınca il geneline düşüldüğünü bildir
        if (_fallbackToIl)
          Container(
            width: double.infinity,
            color: colorScheme.secondaryContainer,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: colorScheme.onSecondaryContainer,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'pharmacy.fallback_notice'.tr(args: [_selectedIlce ?? '']),
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(AppSpacing.lg),
            itemCount: _pharmacies.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _PharmacyTile(
              pharmacy: _pharmacies[i],
              onCall: _pharmacies[i].phone.isNotEmpty
                  ? () => _callPharmacy(_pharmacies[i].phone)
                  : null,
              onDirections: () => _openDirections(_pharmacies[i]),
            ),
          ),
        ),
      ],
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
                size: 80, color: colorScheme.primary.withValues(alpha: 0.4)),
            SizedBox(height: AppSpacing.lg),
            Text('pharmacy.initial_title'.tr(),
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            Text('pharmacy.initial_subtitle'.tr(),
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
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
                size: 64, color: colorScheme.primary.withValues(alpha: 0.5)),
            SizedBox(height: AppSpacing.lg),
            Text('pharmacy.no_results_title'.tr(),
                style:
                    textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            SizedBox(height: AppSpacing.sm),
            Text('pharmacy.no_results_subtitle'.tr(),
                style: textTheme.bodyMedium
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
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
  const _PharmacyTile({
    required this.pharmacy,
    this.onCall,
    this.onDirections,
  });

  final PharmacyItem pharmacy;
  final VoidCallback? onCall;
  final VoidCallback? onDirections;

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
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Yol tarifi butonu (her zaman göster — adresle Google Maps açar)
            if (onDirections != null)
              IconButton(
                icon: const Icon(Icons.directions_rounded),
                color: colorScheme.tertiary,
                tooltip: 'pharmacy.directions'.tr(),
                onPressed: onDirections,
              ),
            if (onCall != null)
              IconButton(
                icon: const Icon(Icons.call_rounded),
                color: colorScheme.primary,
                tooltip: 'pharmacy.call'.tr(),
                onPressed: onCall,
              ),
          ],
        ),
      ),
    );
  }
}
