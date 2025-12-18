import 'package:flutter/material.dart';

class AdLoadingSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final bool isRectangle;

  const AdLoadingSkeleton({
    Key? key,
    required this.width,
    required this.height,
    this.isRectangle = true,
  }) : super(key: key);

  @override
  State<AdLoadingSkeleton> createState() => _AdLoadingSkeletonState();
}

class _AdLoadingSkeletonState extends State<AdLoadingSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey[200],
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey[200]!,
                  Colors.grey[100]!,
                  Colors.white,
                  Colors.grey[100]!,
                  Colors.grey[200]!,
                ],
                stops: [
                  0.0,
                  _animation.value - 0.3,
                  _animation.value,
                  _animation.value + 0.3,
                  1.0,
                ],
              ),
            ),
            child: Stack(
              children: [
                // خلفية متدرجة جميلة
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF9D5D3).withOpacity(0.3),
                        const Color(0xFF52002C).withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                // أيقونة تحميل في المنتصف
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.image_outlined,
                      size: widget.isRectangle ? 40 : 30,
                      color: const Color(0xFF52002C).withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class AdImageWithLoading extends StatefulWidget {
  final String imageUrl;
  final double width;
  final double height;
  final bool isRectangle;
  final VoidCallback? onTap;

  const AdImageWithLoading({
    Key? key,
    required this.imageUrl,
    required this.width,
    required this.height,
    this.isRectangle = true,
    this.onTap,
  }) : super(key: key);

  @override
  State<AdImageWithLoading> createState() => _AdImageWithLoadingState();
}

class _AdImageWithLoadingState extends State<AdImageWithLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _imageLoaded = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _onImageLoaded() {
    if (!_imageLoaded && mounted) {
      setState(() {
        _imageLoaded = true;
      });
      _fadeController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              // مؤشر التحميل
              if (!_imageLoaded)
                AdLoadingSkeleton(
                  width: widget.width,
                  height: widget.height,
                  isRectangle: widget.isRectangle,
                ),
              // الصورة الفعلية
              AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Image.network(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                      width: widget.width,
                      height: widget.height,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          // الصورة تم تحميلها
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _onImageLoaded();
                          });
                          return child;
                        }
                        return const SizedBox.shrink();
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: widget.width,
                          height: widget.height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            color: Colors.grey[200],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.error_outline,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
