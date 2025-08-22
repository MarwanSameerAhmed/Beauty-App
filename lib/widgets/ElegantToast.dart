import 'package:flutter/material.dart';
import 'dart:async';

class ElegantToast extends StatefulWidget {
  final Color backgroundColor;
  final IconData icon;
  final String message;

  const ElegantToast({
    super.key,
    required this.backgroundColor,
    required this.icon,
    required this.message,
  });

  @override
  _ElegantToastState createState() => _ElegantToastState();
}

class _ElegantToastState extends State<ElegantToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _offsetAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white),
            const SizedBox(width: 12.0),
            Flexible(
              child: Text(
                widget.message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showElegantToast(
  BuildContext context,
  String message, {
  bool isSuccess = true,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).viewInsets.top + 20,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: ElegantToast(
          message: message,
          icon: isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          backgroundColor: isSuccess
              ? const Color(0xFF2E7D32) // Green for success
              : const Color(0xFFC62828), // Red for error
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Timer(const Duration(seconds: 3), () {
    overlayEntry.remove();
  });
}
