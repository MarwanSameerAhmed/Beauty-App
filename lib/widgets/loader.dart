import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'images/Sand Clock loader animation.json',
        width: 60,
        height: 60,
        fit: BoxFit.contain,
      ),
    );
  }
}
