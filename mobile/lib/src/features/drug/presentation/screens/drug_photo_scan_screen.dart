import 'dart:io';

import '../../../../imports/imports.dart';
import '../../data/drug_history_repository.dart';
import '../../data/drug_repository.dart';

enum _DrugPhotoScanMode { medicine, prospectus }

class DrugPhotoScanScreen extends ConsumerStatefulWidget {
  const DrugPhotoScanScreen({super.key});

  @override
  ConsumerState<DrugPhotoScanScreen> createState() =>
      _DrugPhotoScanScreenState();
}

class _DrugPhotoScanScreenState extends ConsumerState<DrugPhotoScanScreen> {
  bool _isImageLoading = false;
  String? _imageError;
  File? _selectedImage;
  _DrugPhotoScanMode _scanMode = _DrugPhotoScanMode.medicine;

  String _mapImageFailureToMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return 'drug_search.network_error'.tr();
    }

    final message = failure.message.toLowerCase();

    if (message.contains('camera permission denied') ||
        message.contains('photos permission denied') ||
        message.contains('permission denied')) {
      return 'drug_search.image_permission_error'.tr();
    }

    if (message.contains('yalnızca görsel') || message.contains('image/')) {
      return 'drug_search.image_invalid_error'.tr();
    }

    if (message.contains('boş olamaz') || message.contains('empty')) {
      return 'drug_search.image_empty_error'.tr();
    }

    if (message.contains('timed out') || message.contains('timeout')) {
      return 'drug_search.timeout_error'.tr();
    }

    if (message.contains('unable to reach the server') ||
        message.contains('connection') ||
        message.contains('socketexception')) {
      return 'drug_search.network_error'.tr();
    }

    if (failure.message.trim().isEmpty ||
        failure.message == 'An unexpected error occurred') {
      return 'drug_search.image_analysis_error'.tr();
    }

    return failure.message;
  }

  Future<void> _pickImage(ImageSource source) async {
    final result = await MediaService.instance.pickImage(
      source: source,
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 85,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        final message = _mapImageFailureToMessage(failure);
        setState(() => _imageError = message);
        context.showTypedSnackBar(message, type: SnackBarType.error);
      },
      (file) {
        if (file == null) {
          context.showTypedSnackBar('drug_search.image_pick_cancelled'.tr());
          return;
        }

        setState(() {
          _selectedImage = file;
          _imageError = null;
        });
        context.showTypedSnackBar(
          'drug_search.image_ready'.tr(),
          type: SnackBarType.success,
        );
      },
    );
  }

  Future<void> _openCameraCapture() async {
    final capturedImage =
        await context.push<File?>(AppRoutes.drugCameraCapture);

    if (!mounted || capturedImage == null) {
      return;
    }

    setState(() {
      _selectedImage = capturedImage;
      _imageError = null;
    });

    context.showTypedSnackBar(
      'drug_search.image_ready'.tr(),
      type: SnackBarType.success,
    );
  }

  Future<void> _analyzeSelectedImage() async {
    final selectedImage = _selectedImage;
    if (selectedImage == null) {
      final message = 'drug_search.image_select_first'.tr();
      setState(() => _imageError = message);
      context.showTypedSnackBar(message, type: SnackBarType.warning);
      return;
    }

    setState(() {
      _isImageLoading = true;
      _imageError = null;
    });

    final result = _scanMode == _DrugPhotoScanMode.medicine
        ? await DrugRepository.instance.analyzeDrugImage(selectedImage)
        : await DrugRepository.instance.summarizeProspectus(selectedImage);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _imageError = _mapImageFailureToMessage(failure);
          _isImageLoading = false;
        });
      },
      (data) {
        setState(() => _isImageLoading = false);

        DrugHistoryRepository.instance.saveScanResult(
          mode: _scanMode == _DrugPhotoScanMode.prospectus
              ? DrugScanHistoryMode.prospectus
              : DrugScanHistoryMode.medicine,
          payload: data,
        );

        if (_scanMode == _DrugPhotoScanMode.prospectus) {
          context.push(AppRoutes.drugProspectusSummary, extra: data);
          return;
        }

        final candidates = _resolveCandidates(data);
        if (candidates.isNotEmpty) {
          context.push(AppRoutes.drugImageCandidates, extra: data);
          return;
        }

        context.push(AppRoutes.drugDetail, extra: data);
      },
    );
  }

  List<String> _resolveCandidates(Map<String, dynamic> data) {
    final rawCandidates = data['aday_ilaclar'];
    if (rawCandidates is! List) {
      return [];
    }

    final primaryName =
        (data['ilac_adi'] ?? '').toString().trim().toLowerCase();

    final normalized = rawCandidates
        .map((candidate) => candidate.toString().trim())
        .where((candidate) => candidate.isNotEmpty)
        .where((candidate) => candidate.toLowerCase() != primaryName)
        .toSet()
        .toList();

    return normalized;
  }

  void _clearSelectedImage() {
    setState(() {
      _selectedImage = null;
      _imageError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isProspectusMode = _scanMode == _DrugPhotoScanMode.prospectus;
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppTopBar(title: 'drug_search.photo_screen_title'.tr()),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mod Seçimi (Devasa Butonlar halinde)
              Container(
                decoration: BoxDecoration(
                  color:
                      colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _scanMode = _DrugPhotoScanMode.medicine;
                          _imageError = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: !isProspectusMode
                                ? colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow:
                                !isProspectusMode ? AppShadows.card : null,
                          ),
                          child: Center(
                            child: Text(
                              'drug_search.scan_mode_medicine'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                color: !isProspectusMode
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _scanMode = _DrugPhotoScanMode.prospectus;
                          _imageError = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isProspectusMode
                                ? colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow:
                                isProspectusMode ? AppShadows.card : null,
                          ),
                          child: Center(
                            child: Text(
                              'drug_search.scan_mode_prospectus'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                color: isProspectusMode
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSpacing.xxl),

              if (_selectedImage != null) ...[
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_selectedImage!, fit: BoxFit.cover),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: IconButton.filled(
                            onPressed: _clearSelectedImage,
                            icon: const Icon(Icons.close_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_imageError != null) ...[
                  SizedBox(height: AppSpacing.md),
                  _ImageErrorBanner(message: _imageError!),
                ],
                SizedBox(height: AppSpacing.xl),
                AppButton(
                  label: _isImageLoading
                      ? isProspectusMode
                          ? 'drug_search.analyzing_prospectus'.tr()
                          : 'drug_search.analyzing_image'.tr()
                      : isProspectusMode
                          ? 'drug_search.summarize_prospectus'.tr()
                          : 'drug_search.analyze_image'.tr(),
                  onPressed: _isImageLoading ? null : _analyzeSelectedImage,
                  isLoading: _isImageLoading,
                  isFullWidth: true,
                  prefixIcon: const Icon(Icons.auto_awesome_outlined),
                ),
              ] else ...[
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.document_scanner_rounded,
                        size: 80,
                        color: colorScheme.primary.withValues(alpha: 0.3),
                      ),
                      SizedBox(height: AppSpacing.xl),
                      Text(
                        isProspectusMode
                            ? 'drug_search.prospectus_mode_subtitle'.tr()
                            : 'Fotoğraf seçin veya yeni bir fotoğraf çekin.',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Dev Butonlar
                OutlinedButton.icon(
                  onPressed: _isImageLoading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 28),
                  label: Text('drug_search.pick_from_gallery'.tr(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _isImageLoading ? null : _openCameraCapture,
                  icon: const Icon(Icons.camera_alt_rounded, size: 28),
                  label: Text('drug_search.take_photo'.tr(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedImagePreview extends StatelessWidget {
  const _SelectedImagePreview({required this.selectedImage});

  final File selectedImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'drug_search.image_preview_title'.tr(),
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppBorders.card,
          child: Image.file(
            selectedImage,
            height: 240.h,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
      ],
    );
  }
}

class _FlowStepCard extends StatelessWidget {
  const _FlowStepCard({
    required this.stepNumber,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String stepNumber;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: AppBorders.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: context.colors.primary,
                child: Text(
                  stepNumber,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Icon(icon, color: context.colors.primary),
            ],
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: context.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageErrorBanner extends StatelessWidget {
  const _ImageErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.errorContainer,
        borderRadius: AppBorders.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: context.colors.onErrorContainer),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
