import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/business_card_draft.dart';
import 'business_card_ocr.dart';
import 'business_card_parser.dart';

class BusinessCardImageImporter {
  BusinessCardImageImporter({
    BusinessCardParser? parser,
    ImagePicker? imagePicker,
  }) : _parser = parser ?? BusinessCardParser(),
       _imagePicker = imagePicker ?? ImagePicker();

  static const _maxImageBytes = 8 * 1024 * 1024;

  final BusinessCardParser _parser;
  final ImagePicker _imagePicker;

  Future<BusinessCardDraft?> pickFromGallery() async {
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 90,
    );
    if (image == null) return null;

    if (await image.length() > _maxImageBytes) {
      throw StateError(
        'The selected image is too large. Choose an image under 8 MB.',
      );
    }
    if (kIsWeb) {
      return _parser.parseImage(
        await image.readAsBytes(),
        mimeType: _mimeType(image),
      );
    }

    final text = await recognizeBusinessCardText(image.path);
    if (text.isEmpty) {
      throw StateError('No text was found in the selected image.');
    }
    try {
      return await _parser.parse(text);
    } on StateError {
      return BusinessCardDraft.offline(text);
    }
  }

  String _mimeType(XFile image) {
    final detected = image.mimeType?.toLowerCase();
    if (detected != null && detected.startsWith('image/')) return detected;
    final path = image.name.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic')) return 'image/heic';
    if (path.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }
}
