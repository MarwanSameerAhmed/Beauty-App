import 'dart:io';
import 'package:image/image.dart';

void main() {
  print('Loading original logo...');
  final logoBytes = File('images/splash/ios/Glamify-logo-transparent.png').readAsBytesSync();
  final logo = decodeImage(logoBytes)!;

  // 1. Create App Icon (512x512)
  print('Creating App Icon 512x512...');
  final icon = Image(width: 512, height: 512);
  fill(icon, color: ColorRgb8(255, 255, 255)); // White background
  
  // Resize logo to fit nicely in the icon
  final logoForIcon = copyResize(logo, width: 380);
  compositeImage(icon, logoForIcon, dstX: (512 - logoForIcon.width) ~/ 2, dstY: (512 - logoForIcon.height) ~/ 2);
  
  File('android/app_icon_512.png').writeAsBytesSync(encodePng(icon));
  print('✅ Saved: android/app_icon_512.png');

  // 2. Create Feature Graphic (1024x500)
  print('Creating Feature Graphic 1024x500...');
  final feature = Image(width: 1024, height: 500);
  // Very soft pink/white background
  fill(feature, color: ColorRgb8(255, 248, 250)); 
  
  // Resize logo to fit nicely in the feature graphic
  final logoForFeature = copyResize(logo, height: 350);
  compositeImage(feature, logoForFeature, dstX: (1024 - logoForFeature.width) ~/ 2, dstY: (500 - logoForFeature.height) ~/ 2);

  File('android/feature_graphic_1024.png').writeAsBytesSync(encodePng(feature));
  print('✅ Saved: android/feature_graphic_1024.png');
}
