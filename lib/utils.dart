import 'dart:convert';
import 'package:flutter/material.dart';

class Utils {
  static Image imageFromBase64(String base64) {
    try {
      return Image.memory(
        base64Decode(base64),
        fit: BoxFit.cover,
      );
    } catch (e) {
      print('Error decoding base64 image: $e');
      return Image.asset('assets/placeholder.png');
    }
  }
}