import 'dart:ui';
import 'package:flutter/material.dart';

class CustomAdminHeader extends StatelessWidget {
  final String title;
  final String subtitle; // النص الفرعي

  const CustomAdminHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

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

          // زر الرجوع
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFF9D5D3).withOpacity(0.5),

                  borderRadius: BorderRadius.circular(15.0),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.2,
                  ),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
