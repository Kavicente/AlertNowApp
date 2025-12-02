// lib/widgets/custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final OutlinedBorder? shape;
  final BorderSide? side; // Added to support border
  final double? width; // Added for width
  final double? height; // Added for height
  final double? elevation; // Added for shadow
  final Color? shadowColor; // Added for shadow color

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.fontSize,
    this.padding,
    this.shape,
    this.side, // Added
    this.width, // Added
    this.height, // Added
    this.elevation, // Added
    this.shadowColor, // Added
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor ?? const Color(0xFFDEEAEE),
        foregroundColor: foregroundColor ?? Colors.black,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        textStyle: TextStyle(fontSize: fontSize ?? 16),
        shape: shape,
        side: side,
        fixedSize: (width != null && height != null) ? Size(width!, height!) : null,
        elevation: elevation, // Apply shadow
        shadowColor: shadowColor, // Apply shadow color
      ),
      child: Text(text),
    );
  }
}