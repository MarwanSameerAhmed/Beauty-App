import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glamify/controller/update_service.dart';

/// عرض dialog التحديث
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateInfo updateInfo,
) async {
  final isForce = updateInfo.status == UpdateStatus.forceUpdate;

  await showGeneralDialog(
    context: context,
    barrierDismissible: !isForce,
    barrierLabel: 'Update Dialog',
    barrierColor: Colors.black.withOpacity(0.5),
    transitionDuration: const Duration(milliseconds: 600),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.15),
          end: Offset.zero,
        ).animate(curvedAnimation),
        child: FadeTransition(opacity: curvedAnimation, child: child),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return PopScope(
        canPop: !isForce,
        child: Center(
          child: _UpdateDialogContent(updateInfo: updateInfo, isForce: isForce),
        ),
      );
    },
  );
}

class _UpdateDialogContent extends StatefulWidget {
  final UpdateInfo updateInfo;
  final bool isForce;

  const _UpdateDialogContent({required this.updateInfo, required this.isForce});

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent> {
  Future<void> _openStore() async {
    final url = widget.updateInfo.storeUrl;
    if (url.isNotEmpty) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF9FC), // لون وردي أفتح بكثير (قريب للأبيض)
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF48FB1).withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF942A59).withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // الأيقونة (شعار التطبيق)
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF942A59).withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'images/android/play_store_512.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.system_update_rounded,
                        color: Color(0xFF942A59),
                        size: 32,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // العنوان
              Text(
                widget.isForce ? 'تحديث مطلوب' : 'تحديث جديد متاح',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              
              // رقم النسخة
              Text(
                'الإصدار ${widget.updateInfo.latestVersion}',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF942A59),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // الرسالة
              Text(
                widget.updateInfo.message,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              
              // رسالة الإجبار أو عدد الأيام المتبقية
              if (widget.isForce) ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'يجب التحديث للاستمرار في استخدام التطبيق',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (widget.updateInfo.remainingDays > 0) ...[
                Text(
                  'متبقي ${widget.updateInfo.remainingDays} يوم قبل التحديث الإجباري',
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8D6E00),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],
              
              // الأزرار
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _openStore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF942A59),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تحديث الآن',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              
              if (!widget.isForce) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'ليس الآن',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
