import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:glamify/controller/update_service.dart';

/// عرض dialog التحديث
Future<void> showUpdateDialog(BuildContext context, UpdateInfo updateInfo) async {
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
        child: FadeTransition(
          opacity: curvedAnimation,
          child: child,
        ),
      );
    },
    pageBuilder: (context, animation, secondaryAnimation) {
      return PopScope(
        canPop: !isForce,
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
  late AnimationController _floatController;
  late AnimationController _shimmerController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _floatAnimation = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    _shimmerController.dispose();
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
    final dialogWidth = screenWidth * 0.88;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: dialogWidth > 400 ? 400 : dialogWidth,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.97),
                      const Color(0xFFFDF2F8).withOpacity(0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF52002C).withOpacity(0.08),
                      blurRadius: 40,
                      spreadRadius: 0,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildElegantHeader(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                      child: Column(
                        children: [
                          // العنوان
                          Text(
                            widget.isForce
                                ? 'تحديث مطلوب'
                                : 'نسخة جديدة متاحة ✨',
                            style: const TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D1B33),
                              letterSpacing: -0.3,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 10),

                          // الرسالة
                          Text(
                            widget.updateInfo.message,
                            style: TextStyle(
                              fontFamily: 'Tajawal',
                              fontSize: 14,
                              color: const Color(0xFF2D1B33).withOpacity(0.6),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 20),

                          // شريط النسخة
                          _buildVersionStrip(),

                          const SizedBox(height: 16),

                          // عداد الأيام أو تحذير
                          if (!widget.isForce &&
                              widget.updateInfo.remainingDays > 0)
                            _buildSoftDaysCounter(),
                          if (widget.isForce) _buildSoftForceWarning(),

                          const SizedBox(height: 24),

                          // الأزرار
                          _buildElegantButtons(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildElegantHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: widget.isForce
              ? [
                  const Color(0xFF3D0A24),
                  const Color(0xFF6B1D47),
                  const Color(0xFF942A59),
                ]
              : [
                  const Color(0xFF6B1D47).withOpacity(0.9),
                  const Color(0xFFA93670).withOpacity(0.85),
                  const Color(0xFFD4608C).withOpacity(0.8),
                ],
        ),
      ),
      child: AnimatedBuilder(
        animation: _floatAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Column(
              children: [
                // أيقونة دائرية مع تأثير توهج
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isForce
                        ? Icons.security_update_warning_rounded
                        : Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),

                const SizedBox(height: 12),

                // نقاط زخرفية صغيرة
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == 1 ? 20 : 6,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(i == 1 ? 0.6 : 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVersionStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F0F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE8D5E0),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildVersionLabel(
            'نسختك',
            widget.updateInfo.currentVersion,
            const Color(0xFF9E9E9E),
          ),
          // سهم متحرك
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              final value = _shimmerController.value;
              return Opacity(
                opacity: 0.4 + (sin(value * pi * 2) * 0.3),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF942A59),
                  size: 20,
                ),
              );
            },
          ),
          _buildVersionLabel(
            'الجديدة',
            widget.updateInfo.latestVersion,
            const Color(0xFF942A59),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionLabel(String label, String version, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Tajawal',
            fontSize: 11,
            color: color.withOpacity(0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'v$version',
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSoftDaysCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFE082).withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFF9A825).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: Color(0xFFF9A825),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'متبقي ${widget.updateInfo.remainingDays} يوم قبل التحديث الإجباري',
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Color(0xFF8D6E00),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoftForceWarning() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFF48FB1).withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFFE91E63).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFC62828),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Flexible(
            child: Text(
              'يجب التحديث للاستمرار في استخدام التطبيق',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 12,
                color: Color(0xFFC62828),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantButtons() {
    return Column(
      children: [
        // زر التحديث الرئيسي
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF52002C), Color(0xFF942A59)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF52002C).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: _openStore,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.upgrade_rounded, size: 22, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'تحديث الآن',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // زر لاحقاً (اختياري فقط)
        if (!widget.isForce) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'تذكيري لاحقاً',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                color: const Color(0xFF2D1B33).withOpacity(0.45),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
