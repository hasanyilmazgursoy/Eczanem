import 'dart:io';

import '../../../../imports/imports.dart';

class DrugCameraCaptureScreen extends StatefulWidget {
  const DrugCameraCaptureScreen({super.key});

  @override
  State<DrugCameraCaptureScreen> createState() =>
      _DrugCameraCaptureScreenState();
}

class _DrugCameraCaptureScreenState extends State<DrugCameraCaptureScreen> {
  CameraController? _controller;
  bool _isInitializing = true;
  bool _isCapturing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      final permissionStatus = await Permission.camera.request();
      if (!permissionStatus.isGranted) {
        throw Exception('camera permission denied');
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception('camera unavailable');
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);

      if (!mounted) {
        await controller.dispose();
        return;
      }

      await _controller?.dispose();
      setState(() {
        _controller = controller;
        _isInitializing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _errorMessage = _mapErrorToMessage(error);
      });
    }
  }

  Future<void> _capturePhoto() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final capturedFile = await controller.takePicture();
      final optimizedFile = await MediaService.instance.optimizeImageForUpload(
        File(capturedFile.path),
      );

      if (!mounted) return;
      context.pop(optimizedFile);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _errorMessage = _mapErrorToMessage(error);
      });
    }
  }

  String _mapErrorToMessage(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('permission')) {
      return 'drug_search.camera_permission_required'.tr();
    }

    if (message.contains('unavailable') || message.contains('no camera')) {
      return 'drug_search.camera_unavailable'.tr();
    }

    return 'drug_search.camera_capture_error'.tr();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('drug_search.camera_screen_title'.tr()),
      ),
      body: SafeArea(
        child: _isInitializing
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage != null
                ? _CameraErrorState(
                    message: _errorMessage!,
                    onRetry: _initializeCamera,
                  )
                : controller == null || !controller.value.isInitialized
                    ? _CameraErrorState(
                        message: 'drug_search.camera_unavailable'.tr(),
                        onRetry: _initializeCamera,
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(controller),
                          IgnorePointer(
                            child: Center(
                              child: Container(
                                width: MediaQuery.sizeOf(context).width * 0.82,
                                height:
                                    MediaQuery.sizeOf(context).height * 0.34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.28),
                                      blurRadius: 24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: AppSpacing.lg,
                            right: AppSpacing.lg,
                            bottom: AppSpacing.xl,
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.46),
                                    borderRadius: AppBorders.card,
                                  ),
                                  child: Text(
                                    'drug_search.camera_screen_subtitle'.tr(),
                                    style:
                                        context.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.lg),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    GestureDetector(
                                      onTap:
                                          _isCapturing ? null : _capturePhoto,
                                      child: Container(
                                        width: 84,
                                        height: 84,
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 4,
                                          ),
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _isCapturing
                                                ? Colors.white54
                                                : Colors.white,
                                          ),
                                          child: _isCapturing
                                              ? const Padding(
                                                  padding: EdgeInsets.all(20),
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    color: Colors.black,
                                                  ),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ),
                                    ),
                                  ],
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

class _CameraErrorState extends StatelessWidget {
  const _CameraErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined,
                color: Colors.white, size: 48),
            SizedBox(height: AppSpacing.md),
            Text(
              message,
              style: context.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'drug_search.camera_retry'.tr(),
              onPressed: onRetry,
              isFullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}
