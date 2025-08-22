import 'package:flutter/material.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String email;
  final String imagePath;
  final VoidCallback? onCartPressed;
  final VoidCallback? onFavoritePressed; // Add this

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    required this.email,
    required this.imagePath,
    this.onCartPressed,
    this.onFavoritePressed, // Add this
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey.shade200,
              child: CircleAvatar(
                radius: 28,
                backgroundImage: AssetImage(imagePath),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "مرحباً بك،",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Container(
                width: 100, // Increased width for two icons
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF52002C), Color(0xFF942A59)],
                    stops: [0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly, // Space out icons
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: onFavoritePressed,
                    ),
                    SizedBox(
                      height: 24, // Divider height
                      child: VerticalDivider(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      onPressed: onCartPressed,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
