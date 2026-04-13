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
    final colorScheme = context.colors;
    final isProspectusMode = _scanMode == _DrugPhotoScanMode.prospectus;

    return Scaffold(
      appBar: AppTopBar(title: 'drug_search.photo_screen_title'.tr()),
      body: ListView(
        padding: EdgeInsets.all(AppSpacing.xl),
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.onPrimary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        Icons.document_scanner_outlined,
                        color: colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            isProspectusMode
                                ? 'drug_search.scan_mode_prospectus_badge'.tr()
                                : 'drug_search.scan_mode_medicine_badge'.tr(),
                            style: context.textTheme.labelLarge?.copyWith(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'drug_search.photo_screen_title'.tr(),
                  style: context.textTheme.headlineSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  isProspectusMode
                      ? 'drug_search.prospectus_mode_subtitle'.tr()
                      : 'drug_search.photo_screen_subtitle'.tr(),
                  style: context.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onPrimary.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppCard(
            showShadow: true,
            title: 'drug_search.scan_mode_title'.tr(),
            subtitle: 'drug_search.scan_mode_subtitle'.tr(),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                ChoiceChip(
                  label: Text('drug_search.scan_mode_medicine'.tr()),
                  selected: _scanMode == _DrugPhotoScanMode.medicine,
                  onSelected: (_) {
                    setState(() {
                      _scanMode = _DrugPhotoScanMode.medicine;
                      _imageError = null;
                    });
                  },
                ),
                ChoiceChip(
                  label: Text('drug_search.scan_mode_prospectus'.tr()),
                  selected: _scanMode == _DrugPhotoScanMode.prospectus,
                  onSelected: (_) {
                    setState(() {
                      _scanMode = _DrugPhotoScanMode.prospectus;
                      _imageError = null;
                    });
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppCard(
            showShadow: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FlowStepCard(
                    stepNumber: '1',
                    title: 'drug_search.flow_step_select_title'.tr(),
                    subtitle: 'drug_search.flow_step_select_subtitle'.tr(),
                    icon: Icons.add_a_photo_outlined,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _FlowStepCard(
                    stepNumber: '2',
                    title: 'drug_search.flow_step_analyze_title'.tr(),
                    subtitle: isProspectusMode
                        ? 'drug_search.flow_step_analyze_prospectus_subtitle'
                            .tr()
                        : 'drug_search.flow_step_analyze_medicine_subtitle'
                            .tr(),
                    icon: Icons.auto_awesome_outlined,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppCard(
            title: 'drug_search.photo_tips_title'.tr(),
            showShadow: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TipRow(text: 'drug_search.photo_tip_1'.tr()),
                SizedBox(height: AppSpacing.sm),
                _TipRow(text: 'drug_search.photo_tip_2'.tr()),
                SizedBox(height: AppSpacing.sm),
                _TipRow(text: 'drug_search.photo_tip_3'.tr()),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppCard(
            showShadow: true,
            title: isProspectusMode
                ? 'drug_search.prospectus_card_title'.tr()
                : 'drug_search.image_card_title'.tr(),
            subtitle: isProspectusMode
                ? 'drug_search.prospectus_card_subtitle'.tr()
                : 'drug_search.image_card_subtitle'.tr(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedImage != null)
                  _SelectedImagePreview(selectedImage: _selectedImage!)
                else
                  _ImageEmptyState(),
                SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: AppBorders.card,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: context.colors.primary,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isProspectusMode
                              ? 'drug_search.analysis_hint_prospectus'.tr()
                              : 'drug_search.analysis_hint_medicine'.tr(),
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_imageError != null) ...[
                  SizedBox(height: AppSpacing.md),
                  _ImageErrorBanner(message: _imageError!),
                ],
                SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'drug_search.take_photo'.tr(),
                  onPressed: _isImageLoading ? null : _openCameraCapture,
                  variant: ButtonVariant.outline,
                  prefixIcon: const Icon(Icons.photo_camera_outlined),
                  isFullWidth: true,
                ),
                SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'drug_search.pick_from_gallery'.tr(),
                  onPressed: _isImageLoading
                      ? null
                      : () => _pickImage(ImageSource.gallery),
                  variant: ButtonVariant.secondary,
                  prefixIcon: const Icon(Icons.photo_library_outlined),
                  isFullWidth: true,
                ),
                if (_selectedImage != null) ...[
                  SizedBox(height: AppSpacing.md),
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
                  SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: 'drug_search.clear_selected_image'.tr(),
                    onPressed: _isImageLoading ? null : _clearSelectedImage,
                    variant: ButtonVariant.ghost,
                    isFullWidth: true,
                    prefixIcon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipRow extends StatelessWidget {
  const _TipRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle_outline,
            size: 18, color: context.colors.primary),
        SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: context.textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class _ImageEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: AppBorders.card,
        border: Border.all(color: context.colors.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 40,
            color: context.colors.primary,
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            'drug_search.image_empty_title'.tr(),
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'drug_search.image_empty_subtitle'.tr(),
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
