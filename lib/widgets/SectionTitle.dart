import 'package:flutter/material.dart';

class Sectiontitle extends StatelessWidget {
  final String Title;
  const Sectiontitle({super.key, required this.Title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 16,
          right: 24,
          top: 10,
          bottom: 10,
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Text(
            Title,
            style: const TextStyle(
              fontFamily: "Tajawal",
              fontSize: 22,
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
