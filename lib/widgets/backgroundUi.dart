import 'package:flutter/material.dart';

class FlowerBackground extends StatelessWidget {
  final Widget child;

  const FlowerBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: const Color.fromARGB(255, 249, 237, 237),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                margin: const EdgeInsets.all(0),
                decoration: BoxDecoration(),
              ),
            ),

            Positioned(
              top: -170,
              right: -135,
              width: 700,
              child: Image.asset('images/rose petals.png', fit: BoxFit.contain),
            ),

            Positioned(
              bottom: -180,
              left: -135,
              width: 400,
              child: Image.asset('images/rose petas2.png', fit: BoxFit.contain),
            ),

            Positioned(
              bottom: -45,
              right: -40,
              width: 180,
              child: Image.asset('images/chamomille.png', fit: BoxFit.contain),
            ),

            child,
          ],
        ),
      ),
    );
  }
}
