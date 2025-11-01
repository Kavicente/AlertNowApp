import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();

  Future<Uint8List?> pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      if (image != null) {
        return await image.readAsBytes();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return null;
  }

  Image imageFromBase64(String base64) {
    try {
      return Image.memory(base64Decode(base64));
    } catch (e) {
      print('Error decoding base64 image: $e');
      return Image.asset('assets/placeholder.png');
    }
  }

  String classifyImage(String base64) {
    // Placeholder: Replace with TensorFlow Lite or server-side ML model
    return ['fire', 'road_accident'][DateTime.now().millisecond % 2];
  }
}