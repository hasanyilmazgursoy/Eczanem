import re

with open('mobile/lib/src/features/drug/presentation/screens/drug_photo_scan_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

replacement = '''
  @override
  Widget build(BuildContext context) {
    final isProspectusMode = _scanMode == _DrugPhotoScanMode.prospectus;
    final colorScheme = context.colors;
    final textTheme = context.textTheme;

    return Scaffold(
      appBar: AppTopBar(title: 'drug_search.photo_screen_title'.tr()),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mod Seçimi (Devasa Butonlar halinde)
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
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
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: !isProspectusMode ? colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !isProspectusMode ? AppShadows.card : null,
                          ),
                          child: Center(
                            child: Text(
                              'drug_search.scan_mode_medicine'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                color: !isProspectusMode ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
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
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isProspectusMode ? colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isProspectusMode ? AppShadows.card : null,
                          ),
                          child: Center(
                            child: Text(
                              'drug_search.scan_mode_prospectus'.tr(),
                              style: textTheme.titleMedium?.copyWith(
                                color: isProspectusMode ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
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
              const SizedBox(height: AppSpacing.xxl),
              
              if (_selectedImage != null) ...[
                Expanded(
                  child: ClipRReRect(
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
                  const SizedBox(height: AppSpacing.md),
                  _ImageErrorBanner(message: _imageError!),
                ],
                const SizedBox(height: AppSpacing.xl),
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
                      const SizedBox(height: AppSpacing.xl),
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
                  onPressed: _isImageLoading ? null : () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_rounded, size: 28),
                  label: Text('drug_search.pick_from_gallery'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FilledButton.icon(
                  onPressed: _isImageLoading ? null : _openCameraCapture,
                  icon: const Icon(Icons.camera_alt_rounded, size: 28),
                  label: Text('drug_search.take_photo'.tr(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
'''

# Identify the start of Widget build(BuildContext context) in _DrugPhotoScanScreenState and everything until the next class definition
# To be safe, we split by class _SelectedImagePreview extends StatelessWidget
parts = text.split('class _SelectedImagePreview extends StatelessWidget {')
first_part = parts[0]

# In first_part, substitute the last build method
# Which belongs to _DrugPhotoScanScreenState
new_first_part = re.sub(r'  @override\n  Widget build\(BuildContext context\) \{.*\}\n\}[\s\n]*$', replacement, first_part, flags=re.DOTALL)

# Recombine, but we don't need _SelectedImagePreview or _ImageEmptyState anymore since we replaced them in the UI inline
# So we can just take everything but replace the build method.
# Wait, _ImageErrorBanner is still needed!
# Let's just find exactly what to replace. The build method inside _DrugPhotoScanScreenState.

text = re.sub(r'  @override\n  Widget build\(BuildContext context\) \{.*?(?=\nclass _SelectedImagePreview)', replacement, text, flags=re.DOTALL)

# We still need _ImageErrorBanner so we keep parts of the file. To avoid issues with unused classes we just let flutter analyze tell us.
# Let's do it safely:

with open('mobile/lib/src/features/drug/presentation/screens/drug_photo_scan_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
