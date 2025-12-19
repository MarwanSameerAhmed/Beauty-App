import 'package:flutter/material.dart';

class CustomHeaderUser extends StatelessWidget {
  const CustomHeaderUser({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title;
  final String subtitle; // النص الفرعي

  @override
  Widget build(BuildContext context) {
    // الحصول على ارتفاع status bar
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Padding(
      padding: EdgeInsets.only(
        top: statusBarHeight + 20.0, // status bar height + مسافة إضافية
        left: 16.0,
        right: 20.0,
        bottom: 15.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6), // مسافة بين العنوان والنص الفرعي
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    color: Colors.grey,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
