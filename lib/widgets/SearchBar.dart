import 'dart:ui';

import 'package:flutter/material.dart';

class Searchbar extends StatelessWidget {
  const Searchbar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18.0, 0.0, 20.0, 16.0),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF52002C), Color(0xFF942A59)],
                stops: [
                  0.7,
                  1.0, // اللون الثاني يغطي النهاية
                ],
              ),
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () {
                // Action for filter icon
              },
            ),
          ),

          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),

                child: TextField(
                  textDirection: TextDirection.rtl,

                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(color: Colors.black.withOpacity(1)),

                    filled: true,
                    fillColor: const Color.fromARGB(
                      255,
                      216,
                      213,
                      213,
                    ).withOpacity(0.2),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide(
                        color: Colors.black.withOpacity(0.4),
                        width: 1.0,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.4),
                        width: 1.0,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.0),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.6),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
