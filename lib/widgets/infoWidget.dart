import 'package:flutter/material.dart';
import 'package:glamify/utils/responsive_helper.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final String userName;
  final String email;
  final String imagePath;
  final VoidCallback? onCartPressed;
  final VoidCallback? onFavoritePressed;
  final int cartItemCount;

  const ProfileHeaderWidget({
    super.key,
    required this.userName,
    required this.email,
    required this.imagePath,
    this.onCartPressed,
    this.onFavoritePressed,
    required this.cartItemCount,
  });

  @override
  Widget build(BuildContext context) {
    // تهيئة الـ responsive helper
    ResponsiveHelper.init(context);

    // الأبعاد المتجاوبة
    final avatarRadius = ResponsiveHelper.avatarRadius;
    final iconsWidth = ResponsiveHelper.headerIconsWidth;
    final iconsHeight = ResponsiveHelper.headerIconsHeight;
    final iconSize = ResponsiveHelper.iconSize;
    final titleFontSize = ResponsiveHelper.bodyFontSize;
    final subtitleFontSize = ResponsiveHelper.smallFontSize;
    final horizontalPadding = ResponsiveHelper.horizontalPadding;
    final borderRadius = ResponsiveHelper.borderRadius;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 8.0,
          left: horizontalPadding,
          right: horizontalPadding,
          bottom: horizontalPadding,
        ),
        child: Row(
          children: [
            // صورة المستخدم
            CircleAvatar(
              radius: avatarRadius,
              backgroundColor: Colors.grey.shade200,
              child: CircleAvatar(
                radius: avatarRadius - 2,
                backgroundImage: AssetImage(imagePath),
              ),
            ),
            SizedBox(width: horizontalPadding * 0.75),
            
            // معلومات المستخدم
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(top: ResponsiveHelper.verticalSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "مرحباً بك،",
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.grey.shade600,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userName,
                      style: TextStyle(
                        fontSize: titleFontSize + 2,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'Tajawal',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            
            // أزرار المفضلة والسلة
            Padding(
              padding: const EdgeInsets.only(left: 2.0),
              child: Container(
                width: iconsWidth,
                height: iconsHeight,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF52002C), Color(0xFF942A59)],
                    stops: [0.7, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(borderRadius * 0.8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // زر المفضلة
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: iconSize,
                      ),
                      onPressed: onFavoritePressed,
                    ),
                    
                    // الفاصل العمودي
                    SizedBox(
                      height: iconsHeight * 0.5,
                      child: VerticalDivider(
                        color: Colors.white.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    
                    // زر السلة مع العداد
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: iconSize,
                          ),
                          onPressed: onCartPressed,
                        ),
                        if (cartItemCount > 0)
                          Positioned(
                            right: -4,
                            top: -4,
                            child: Container(
                              padding: EdgeInsets.all(ResponsiveHelper.isMobile ? 2 : 3),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: BoxConstraints(
                                minWidth: ResponsiveHelper.isMobile ? 16 : 20,
                                minHeight: ResponsiveHelper.isMobile ? 16 : 20,
                              ),
                              child: Text(
                                '$cartItemCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: ResponsiveHelper.isMobile ? 10 : 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
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
