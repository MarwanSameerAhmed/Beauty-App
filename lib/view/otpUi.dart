import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:test_pro/widgets/buttonsWidgets.dart';

class OtpScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;

  const OtpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final pinController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(fontSize: 22, color: Colors.black),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return FlowerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('التحقق من الرمز', style: TextStyle(color: Colors.black87, fontFamily: 'Tajawal')),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: PlayAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'الرجاء إدخال الرمز المكون من 6 أرقام',
                    style: TextStyle(fontSize: 18, fontFamily: 'Tajawal', color: Colors.black87),
                  ),
                  Text(
                    'تم إرساله إلى الرقم ${widget.phoneNumber}',
                    style: const TextStyle(fontSize: 14, fontFamily: 'Tajawal', color: Colors.black54),
                  ),
                  const SizedBox(height: 40),
                  Pinput(
                    length: 6,
                    controller: pinController,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        border: Border.all(color: const Color(0xFFC15C5C)),
                      ),
                    ),
                    onCompleted: (pin) => print(pin),
                  ),
                  const SizedBox(height: 40),
                  GradientElevatedButton(
                    text: 'تحقق',
                    onPressed: () {
                      // TODO: Implement OTP verification logic
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement resend OTP logic
                    },
                    child: const Text(
                      'إعادة إرسال الرمز',
                      style: TextStyle(
                        color: Color(0xFFC15C5C),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
