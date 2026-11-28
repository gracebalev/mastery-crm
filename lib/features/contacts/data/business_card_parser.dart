import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

import '../domain/business_card_draft.dart';

class BusinessCardParser {
  BusinessCardParser({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'us-east1');

  final FirebaseFunctions _functions;

  Future<BusinessCardDraft> parse(String ocrText) async {
    final text = ocrText.trim();
    if (text.isEmpty) throw StateError('No text was found on the card.');
    try {
      final response = await _functions
          .httpsCallable('parseBusinessCard')
          .call<Map<Object?, Object?>>({'ocrText': text});
      final data = response.data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return BusinessCardDraft.fromFunctionData(data, rawText: text);
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Could not parse the business card.');
    }
  }

  Future<BusinessCardDraft> parseImage(
    Uint8List bytes, {
    required String mimeType,
  }) async {
    if (bytes.isEmpty) throw StateError('The selected image is empty.');
    try {
      final response = await _functions
          .httpsCallable('parseBusinessCardImage')
          .call<Map<Object?, Object?>>({
            'imageBase64': base64Encode(bytes),
            'mimeType': mimeType,
          });
      final data = response.data.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      return BusinessCardDraft.fromFunctionData(data, rawText: '');
    } on FirebaseFunctionsException catch (error) {
      throw StateError(
        error.message ?? 'Could not parse the business card image.',
      );
    }
  }
}
