import 'dart:ui';
import 'package:flutter/material.dart';

class GlassField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final IconData? prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;
  final Color textColor;

  const GlassField({
    super.key,
    required this.controller,
    this.hintText = "ابحث...",
    this.icon,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines,
    this.validator,
    this.textColor = Colors.black, // Default color is black
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: obscureText ? 1 : maxLines,
            textDirection: TextDirection.rtl,
            style: TextStyle(color: textColor),
            validator: validator,
            decoration: InputDecoration(
              errorStyle: const TextStyle(fontFamily: 'Tajawal'),
              errorMaxLines: 2,
              hintText: hintText,
              hintTextDirection: TextDirection.rtl,
              hintStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: Colors.black.withOpacity(0.7))
                  : null,
              suffixIcon: icon != null
                  ? Icon(icon, color: Colors.black.withOpacity(0.7))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
