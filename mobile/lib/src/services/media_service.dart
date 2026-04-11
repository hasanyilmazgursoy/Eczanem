import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/utils.dart';

/// A service to handle media selection (images, videos, files).
class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from gallery or camera.
  FutureEither<File?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    return runTask(() async {
      if (!await _ensureImagePermission(source)) {
        final message = source == ImageSource.camera
            ? 'Camera permission denied'
            : 'Photos permission denied';
        throw Exception(message);
      }

      final XFile? file = await _imagePicker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      if (file == null) {
        return null;
      }

      return _optimizeImage(File(file.path));
    });
  }

  /// Kamera ekranı gibi özel akışlardan gelen görselleri de yükleme öncesi optimize eder.
  Future<File> optimizeImageForUpload(File file) {
    return _optimizeImage(file);
  }

  /// Pick multiple images from gallery.
  FutureEither<List<File>> pickMultiImage({
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
  }) async {
    return runTask(() async {
      if (!await _ensureImagePermission(ImageSource.gallery)) {
        throw Exception('Photos permission denied');
      }

      final List<XFile> files = await _imagePicker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );

      final optimizedFiles = <File>[];
      for (final file in files) {
        optimizedFiles.add(await _optimizeImage(File(file.path)));
      }
      return optimizedFiles;
    });
  }

  /// Pick a video from gallery or camera.
  FutureEither<File?> pickVideo({
    required ImageSource source,
    Duration? maxDuration,
  }) async {
    return runTask(() async {
      if (!await _ensureImagePermission(source)) {
        final message = source == ImageSource.camera
            ? 'Camera permission denied'
            : 'Photos permission denied';
        throw Exception(message);
      }
      if (source == ImageSource.camera && !await _ensureCameraPermission()) {
        throw Exception('Camera permission denied');
      }

      if (source == ImageSource.gallery && !await _ensureGalleryPermission()) {
        throw Exception('Photos permission denied');
      }

      final XFile? file = await _imagePicker.pickVideo(
        source: source,
        maxDuration: maxDuration,
      );

      return file != null ? File(file.path) : null;
    });
  }

  /// Pick one or more files from the device.
  FutureEither<List<File>> pickFiles({
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    bool allowMultiple = false,
  }) async {
    return runTask(() async {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          // Note: On Android 13+, storage permission might be handled differently (media-specific)
          // but permission_handler usually handles the abstraction.
        }
      }

      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
      );

      if (result == null || result.files.isEmpty) return [];

      return result.paths
          .where((path) => path != null)
          .map((path) => File(path!))
          .toList();
    });
  }

  Future<bool> _ensureImagePermission(ImageSource source) async {
    if (source == ImageSource.camera) {
      return _ensureCameraPermission();
    }

    return _ensureGalleryPermission();
  }

  Future<bool> _ensureCameraPermission() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return true;
    }

    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> _ensureGalleryPermission() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      return true;
    }

    if (Platform.isAndroid) {
      final storageStatus = await Permission.storage.request();
      if (storageStatus.isGranted) {
        return true;
      }

      final photosStatus = await Permission.photos.request();
      return photosStatus.isGranted || photosStatus.isLimited;
    }

    final status = await Permission.photos.request();
    return status.isGranted || status.isLimited;
  }

  /// Yükleme öncesi görselleri küçültür; böylece ağ maliyeti ve backend yükü azalır.
  Future<File> _optimizeImage(
    File file, {
    int maxDimension = 1600,
    int quality = 82,
  }) async {
    final originalBytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(originalBytes);

    if (decodedImage == null) {
      return file;
    }

    final shouldResize =
        decodedImage.width > maxDimension || decodedImage.height > maxDimension;

    final processedImage = shouldResize
        ? img.copyResize(
            decodedImage,
            width:
                decodedImage.width >= decodedImage.height ? maxDimension : null,
            height:
                decodedImage.height > decodedImage.width ? maxDimension : null,
            interpolation: img.Interpolation.average,
          )
        : decodedImage;

    final tempDirectory = await getTemporaryDirectory();
    final optimizedDirectory = Directory(
      '${tempDirectory.path}${Platform.pathSeparator}eczanem_uploads',
    );
    if (!await optimizedDirectory.exists()) {
      await optimizedDirectory.create(recursive: true);
    }

    final optimizedFile = File(
      '${optimizedDirectory.path}${Platform.pathSeparator}${DateTime.now().microsecondsSinceEpoch}.jpg',
    );

    await optimizedFile.writeAsBytes(
      img.encodeJpg(processedImage, quality: quality),
      flush: true,
    );

    return optimizedFile;
  }
}
