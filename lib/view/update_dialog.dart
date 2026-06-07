import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glamify/controller/update_service.dart';

/// عرض dialog التحديث
Future<void> showUpdateDialog(BuildContext context, UpdateInfo updateInfo) async {
  final isForce = updateInfo.status == UpdateStatus.forceUpdate;

  await showGeneralDialog(
    context: context,
    barrierDismissible: !isForce, // إجباري = ما يقفل
    barrierLabel: 'Update Dialog',
    barrierColor: Colors.black.withOpacity(0.6),
    transitionDuration: const Duration(milliseconds: 500),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return PopScope(
        canPop: !isForce, // إجباري = ما يرجع بزر الباك
        child: Center(
          child: _UpdateDialogContent(
            updateInfo: updateInfo,
            isForce: isForce,
          ),
        ),
      );
    },
  );
}

class _UpdateDialogContent extends StatefulWidget {
  final UpdateInfo updateInfo;
  final bool isForce;

  const _UpdateDialogContent({
    required this.updateInfo,
    required this.isForce,
  });

  @override
  State<_UpdateDialogContent> createState() => _UpdateDialogContentState();
}

class _UpdateDialogContentState extends State<_UpdateDialogContent>
    with TickerProviderStateMixin {
  late AnimationController _iconController;
  late AnimationController _pulseController;
  late Animation<double> _iconAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _iconAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

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
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth * 0.85;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: dialogWidth > 380 ? 380 : dialogWidth,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9EDED).withOpacity(0.95),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF52002C).withOpacity(0.15),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // الهيدر مع الأيقونة
                  _buildHeader(),

                  // المحتوى
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      children: [
                        // العنوان
                        Text(
                          widget.isForce
                              ? 'تحديث مطلوب'
                              : 'تحديث جديد متاح! 🎉',
                          style: const TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF52002C),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 12),

                        // الرسالة
                        Text(
                          widget.updateInfo.message,
                          style: TextStyle(
                            fontFamily: 'Tajawal',
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.7),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // معلومات النسخة
                        _buildVersionInfo(),

                        const SizedBox(height: 8),

                        // عداد الأيام (للاختياري فقط)
                        if (!widget.isForce &&
                            widget.updateInfo.remainingDays > 0)
                          _buildDaysCounter(),

                        // تحذير الإجبار
                        if (widget.isForce) _buildForceWarning(),

                        const SizedBox(height: 20),

                        // الأزرار
                        _buildButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.isForce
              ? [
                  const Color(0xFF52002C),
                  const Color(0xFF8B1A4A),
                ]
              : [
                  const Color(0xFF52002C).withOpacity(0.85),
                  const Color(0xFF942A59).withOpacity(0.85),
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: AnimatedBuilder(
        animation: _iconAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _iconAnimation.value),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    widget.isForce
                        ? Icons.system_update_alt_rounded
                        : Icons.rocket_launch_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'v${widget.updateInfo.latestVersion}',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF52002C).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF52002C).withOpacity(0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildVersionChip(
            'الحالية',
            widget.updateInfo.currentVersion,
            const Color(0xFF999999),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.arrow_forward_rounded,
              color: const Color(0xFF52002C).withOpacity(0.5),
              size: 20,
            ),
          ),
          _buildVersionChip(
            'الجديدة',
            widget.updateInfo.latestVersion,
            const Color(0xFF52002C),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionChip(String label, String version, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            color: color.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'v$version',
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 15,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDaysCounter() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3CD).withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFFFD93D).withOpacity(0.4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.timer_outlined,
              color: Color(0xFFB8860B),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'باقي ${widget.updateInfo.remainingDays} يوم للتحديث الإجباري',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Color(0xFFB8860B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForceWarning() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFE0E0).withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFFEF5350).withOpacity(0.3),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFD32F2F),
              size: 18,
            ),
            SizedBox(width: 8),
            Flexible(
              child: Text(
                'يجب تحديث التطبيق للمتابعة',
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: Color(0xFFD32F2F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        // زر التحديث
        ScaleTransition(
          scale: _pulseAnimation,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _openStore,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF52002C),
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: const Color(0xFF52002C).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.system_update_rounded, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'تحديث الآن',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // زر لاحقاً (اختياري فقط)
        if (!widget.isForce) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            ),
            child: Text(
              'لاحقاً',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
