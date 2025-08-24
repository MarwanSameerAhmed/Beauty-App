import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class Loader extends StatelessWidget {
  final double width;
  final double height;

  const Loader({super.key, this.width = 60, this.height = 60});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'images/Sandy Loading.json',
        width: width,
        height: height,
        fit: BoxFit.contain,
      ),
    );
  }
}
