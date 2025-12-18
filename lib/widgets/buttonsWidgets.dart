import 'package:flutter/material.dart';
import 'package:glamify/widgets/loader.dart';

class GradientElevatedButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isSecondary;

  const GradientElevatedButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = const LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF52002C), Color(0xFF942A59)],
      stops: [0.7, 1.0],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: isSecondary ? null : gradient,
        borderRadius: BorderRadius.circular(15),
        border: isSecondary ? Border.all(color: const Color(0xFF942A59), width: 2) : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const Loader()
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isSecondary ? const Color(0xFF52002C) : Colors.white,
                ),
              ),
      ),
    );
  }
}
