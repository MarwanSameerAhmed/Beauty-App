import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';

// Enum to define animation types for the dialog
enum _AniProps { opacity, scale }

/// A reusable function to show a custom, elegant dialog with a frosted glass effect.
Future<T?> showElegantDialog<T>({
  required BuildContext context,
  required Widget child,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    transitionDuration: const Duration(milliseconds: 200), // Even Faster
    pageBuilder: (context, animation1, animation2) => child,
    transitionBuilder: (context, a1, a2, widget) {
      final tween = MovieTween()
        ..tween(
          _AniProps.opacity,
          Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 100), // Even Faster
          curve: Curves.easeOut,
        )
        ..tween(
          _AniProps.scale,
          Tween(begin: 0.8, end: 1.0), // Slightly more pop
          duration: const Duration(milliseconds: 200), // Even Faster
          curve: Curves.elasticOut,
        );

      return PlayAnimationBuilder<Movie>(
        tween: tween,
        duration: tween.duration,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.get(_AniProps.opacity),
            child: Transform.scale(
              scale: value.get(_AniProps.scale),
              child: child,
            ),
          );
        },
        child: widget,
      );
    },
  );
}

/// A base widget for creating dialogs with a consistent frosted glass look.
class _ElegantDialogBase extends StatelessWidget {
  final Widget child;
  final String title;
  final IconData icon;

  const _ElegantDialogBase({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    color: Colors.white.withOpacity(0.1),
                    child: Row(
                      children: [
                        Icon(icon, color: Colors.white, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(padding: const EdgeInsets.all(20.0), child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A dialog for confirming an action, like deletion.
class ConfirmActionDialog extends StatelessWidget {
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  const ConfirmActionDialog({
    super.key,
    required this.message,
    required this.onConfirm,
    this.confirmText = 'تأكيد',
    this.cancelText = 'إلغاء',
  });

  @override
  Widget build(BuildContext context) {
    return _ElegantDialogBase(
      title: 'تأكيد الإجراء',
      icon: Icons.warning_amber_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 25),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Pushes buttons to the ends
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),

                child: Padding(
                  padding: const EdgeInsets.only(left: 30.0),
                  child: Text(
                    cancelText,
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Pop the dialog first to ensure the context is correct for the push.
                  Navigator.of(context).pop();
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF52002C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  confirmText,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A dialog for proposing a new price.
class ProposePriceDialog extends StatefulWidget {
  final Function(double) onPropose;

  const ProposePriceDialog({super.key, required this.onPropose});

  @override
  State<ProposePriceDialog> createState() => _ProposePriceDialogState();
}

class _ProposePriceDialogState extends State<ProposePriceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final price = double.tryParse(_priceController.text);
      if (price != null) {
        widget.onPropose(price);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ElegantDialogBase(
      title: 'اقتراح سعر جديد',
      icon: Icons.price_change_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'السعر المقترح',
                labelStyle: const TextStyle(
                  color: Colors.white70,
                  fontFamily: 'Tajawal',
                ),
                prefixIcon: const Icon(
                  Icons.attach_money,
                  color: Colors.white70,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color(0xFF52002C),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(
                    color: Colors.red.shade400,
                    width: 1.5,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'الرجاء إدخال سعر';
                }
                if (double.tryParse(value) == null) {
                  return 'الرجاء إدخال رقم صحيح';
                }
                return null;
              },
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52002C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 14,
                ),
              ),
              child: const Text(
                'إرسال الاقتراح',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
