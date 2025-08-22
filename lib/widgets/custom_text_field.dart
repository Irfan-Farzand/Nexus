import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool filled;
  final Color? fillColor;
  final double borderRadius;
  final Color? labelColor;
  final Color? textColor;

  const CustomTextField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.filled = false,
    this.fillColor,
    this.borderRadius = 12,
    this.labelColor,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: textColor ?? Colors.blue[900]),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: labelColor ?? Colors.blue[800]),
        filled: filled,
        fillColor: fillColor ?? Colors.blue[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
        ),
      ),
    );
  }
}
