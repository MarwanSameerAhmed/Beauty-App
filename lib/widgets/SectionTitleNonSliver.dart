import 'package:flutter/material.dart';

class SectionTitleNonSliver extends StatelessWidget {
  final String title;
  const SectionTitleNonSliver({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 16,
        right: 24,
        top: 10,
        bottom: 10,
      ),
      child: Align(
        alignment: Alignment.centerRight,
        child: Text(
          title,
          style: const TextStyle(
            fontFamily: "Tajawal",
            fontSize: 22,
            color: Colors.black,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
