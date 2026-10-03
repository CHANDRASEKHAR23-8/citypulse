import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_theme.dart';

class PickedPhoto {
  final Uint8List bytes;
  final String name;

  PickedPhoto({required this.bytes, required this.name});
}

class ImagePickerService {
  static final ImagePicker _picker = ImagePicker();

  static Future<PickedPhoto?> pickImage({
    required BuildContext context,
    required ImageSource source,
  }) async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1280,
      );

      if (xFile == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image selection was cancelled.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return null;
      }

      // Read bytes asynchronously - 100% web compatible, mobile compatible, desktop compatible
      final bytes = await xFile.readAsBytes();
      final name = xFile.name.isNotEmpty
          ? xFile.name
          : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo attached successfully.'),
            backgroundColor: AppTheme.statusResolved,
            duration: Duration(seconds: 2),
          ),
        );
      }

      return PickedPhoto(bytes: bytes, name: name);
    } on PlatformException catch (e) {
      if (context.mounted) {
        String friendlyMessage = 'Unable to access image source.';
        final err = e.code.toLowerCase() + ' ' + (e.message?.toLowerCase() ?? '');

        if (err.contains('camera_access_denied') || err.contains('permission')) {
          friendlyMessage = 'Camera permission denied. Please enable camera access in your device settings.';
        } else if (err.contains('no_available_camera') || err.contains('camera')) {
          friendlyMessage = 'No camera found on this device. Please choose an image from gallery instead.';
        } else {
          friendlyMessage = 'Camera/gallery error: ${e.message ?? e.code}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyMessage),
            backgroundColor: AppTheme.priorityHigh,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not attach image: $e'),
            backgroundColor: AppTheme.priorityHigh,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return null;
    }
  }
}
