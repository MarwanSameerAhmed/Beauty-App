import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/view/auth_Ui/login_ui.dart';
import 'package:test_pro/view/auth_Ui/signup_ui.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:simple_animations/simple_animations.dart';
import 'dart:async';

class OnboardingContent {
  final String image, title, description;

  OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
  });
}

final List<OnboardingContent> demoData = [
  OnboardingContent(
    image: 'images/Browsing.json',
    title: 'اكتشفي عالم الجمال',
    description: 'تصفحي أحدث المنتجات والعروض الحصرية التي تناسب أسلوبك.',
  ),
  OnboardingContent(
    image: 'images/Online Sales.json',
    title: 'إدارة منتجاتك بسهولة',
    description: 'أضيفي وعدّلي منتجاتك بكل سهولة مع واجهات استخدام بسيطة.',
  ),
  OnboardingContent(
    image: 'images/You.json',
    title: 'انضمي إلى مجتمعنا',
    description: 'كوني جزءًا من مجتمعنا وشاركي إبداعاتك في عالم المكياج.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _floatingController;
  late AnimationController _pulseController;
  late AnimationController _rotateController;
  Timer? _autoAdvanceTimer;
  
  int _pageIndex = 0;
  bool _enableAutoAdvance = false;

  // Optimized animation curves
  static const _floatingCurve = Curves.easeInOut;
  static const _pulseCurve = Curves.easeInOut;
  static const _pageTransitionCurve = Curves.easeInOutCubicEmphasized;
  static const _pageTransitionDuration = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0,
    );

    // Optimized animations with reduced frequency
    _floatingController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 25),
      vsync: this,
    )..repeat();

    // Auto-advance timer (optional, can be disabled)
    if (_enableAutoAdvance) {
      _startAutoAdvanceTimer();
    }
  }

  void _startAutoAdvanceTimer() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = Timer(const Duration(seconds: 5), () {
      if (_pageIndex < demoData.length - 1 && mounted) {
        _goToNextPage();
      }
    });
  }

  void _goToNextPage() {
    if (_pageIndex < demoData.length - 1) {
      HapticFeedback.lightImpact();
      _pageController.nextPage(
        duration: _pageTransitionDuration,
        curve: _pageTransitionCurve,
      );
    }
  }

  void _goToPreviousPage() {
    if (_pageIndex > 0) {
      HapticFeedback.lightImpact();
      _pageController.previousPage(
        duration: _pageTransitionDuration,
        curve: _pageTransitionCurve,
      );
    }
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _pageController.dispose();
    _floatingController.dispose();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlowerBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: GestureDetector(
          // Enhanced gesture support
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity != null) {
              if (details.primaryVelocity! < -500) {
                // Swipe left (next page in RTL)
                _goToNextPage();
              } else if (details.primaryVelocity! > 500) {
                // Swipe right (previous page in RTL)
                _goToPreviousPage();
              }
            }
          },
          child: Stack(
            children: [
              // Optimized animated background
              RepaintBoundary(
                child: _buildAnimatedBackground(),
              ),

              // Main content with safe area
              SafeArea(
                child: Column(
                  children: [
                    // Skip button at top
                    _buildTopSkipButton(),
                    
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: demoData.length,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) {
                          setState(() {
                            _pageIndex = index;
                          });
                          HapticFeedback.selectionClick();
                          if (_enableAutoAdvance) {
                            _startAutoAdvanceTimer();
                          }
                        },
                        itemBuilder: (context, index) {
                          return RepaintBoundary(
                            child: OnboardingSlide(
                              content: demoData[index],
                              pageController: _pageController,
                              pageIndex: index,
                              floatingController: _floatingController,
                              pulseController: _pulseController,
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Enhanced glass morphism bottom navigation
                    _buildGlassMorphismBottomNav(),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSkipButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Auto-advance toggle (for premium feel)
          IconButton(
            onPressed: () {
              setState(() {
                _enableAutoAdvance = !_enableAutoAdvance;
              });
              HapticFeedback.mediumImpact();
              if (_enableAutoAdvance) {
                _startAutoAdvanceTimer();
              } else {
                _autoAdvanceTimer?.cancel();
              }
            },
            icon: Icon(
              _enableAutoAdvance ? Icons.play_circle_fill : Icons.play_circle_outline,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_pageIndex + 1} / ${demoData.length}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          
          // Skip spacer
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  // Optimized background with fewer but more impactful animations
  Widget _buildAnimatedBackground() {
    final animation1 = Tween<double>(begin: -12.0, end: 12.0).animate(
      CurvedAnimation(parent: _floatingController, curve: _floatingCurve),
    );
    
    final animation2 = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: _pulseCurve),
    );

    return Stack(
      children: [
        // Main floating orb - optimized
        _buildFloatingOrb(
          animation: animation1,
          scaleAnimation: animation2,
          top: 80,
          left: 30,
          size: 110,
        ),

        // Rotating diamond shape
        _buildRotatingDiamond(
          animation: animation1,
          top: 180,
          right: 40,
        ),

        // Bottom glowing crystal
        _buildGlowingCrystal(
          animation: animation1,
          scaleAnimation: animation2,
          bottom: 200,
          left: 80,
        ),

        // Small decorative particle
        _buildDecorativeParticle(
          bottom: 350,
          right: 100,
          scaleAnimation: animation2,
        ),
      ],
    );
  }

  Widget _buildFloatingOrb({
    required Animation<double> animation,
    required Animation<double> scaleAnimation,
    double? top,
    double? left,
    double? bottom,
    double? right,
    required double size,
  }) {
    return Positioned(
      top: top,
      left: left,
      bottom: bottom,
      right: right,
      child: AnimatedBuilder(
        animation: Listenable.merge([animation, scaleAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, animation.value),
            child: Transform.scale(
              scale: scaleAnimation.value,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF52002C).withOpacity(0.35),
                      const Color(0xFFF9D5D3).withOpacity(0.25),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.65, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF52002C).withOpacity(0.25),
                      blurRadius: 35,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF9D5D3).withOpacity(0.7),
                        const Color(0xFFFFE4E1).withOpacity(0.5),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRotatingDiamond({
    required Animation<double> animation,
    double? top,
    double? right,
  }) {
    return Positioned(
      top: top,
      right: right,
      child: AnimatedBuilder(
        animation: Listenable.merge([animation, _rotateController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -animation.value * 0.6),
            child: Transform.rotate(
              angle: _rotateController.value * 6.28,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF52002C),
                      Color(0xFFD47FA6),
                      Color(0xFFC15C5C),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD47FA6).withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.35),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGlowingCrystal({
    required Animation<double> animation,
    required Animation<double> scaleAnimation,
    double? bottom,
    double? left,
  }) {
    return Positioned(
      bottom: bottom,
      left: left,
      child: AnimatedBuilder(
        animation: Listenable.merge([animation, scaleAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, animation.value * 0.4),
            child: Transform.scale(
              scale: scaleAnimation.value,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withOpacity(0.5),
                      const Color(0xFFF9D5D3).withOpacity(0.35),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.35),
                      blurRadius: 25,
                      spreadRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDecorativeParticle({
    double? bottom,
    double? right,
    required Animation<double> scaleAnimation,
  }) {
    return Positioned(
      bottom: bottom,
      right: right,
      child: AnimatedBuilder(
        animation: scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: scaleAnimation.value,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.7),
                    const Color(0xFFF9D5D3).withOpacity(0.35),
                    Colors.transparent,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Enhanced bottom navigation with better UX
  Widget _buildGlassMorphismBottomNav() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLastPage = _pageIndex == demoData.length - 1;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Optimized outer glow
          Container(
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(45),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF52002C).withOpacity(0.25),
                  blurRadius: 60,
                  spreadRadius: 15,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          
          // Main navigation card
          ClipRRect(
            borderRadius: BorderRadius.circular(45),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(45),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.38),
                      const Color(0xFFF9D5D3).withOpacity(0.22),
                      const Color(0xFF52002C).withOpacity(0.08),
                      Colors.white.withOpacity(0.28),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.55),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Back/Skip button
                      Expanded(
                        flex: 3,
                        child: _OnboardingNavButton(
                          text: _pageIndex > 0 ? 'رجوع' : 'تخطي',
                          isPrimary: false,
                          icon: _pageIndex > 0 ? Icons.arrow_forward : null,
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            if (_pageIndex > 0) {
                              _goToPreviousPage();
                            } else {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('onboarding_complete', true);
                              if (!mounted) return;
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      const SignupUi(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return FadeTransition(opacity: animation, child: child);
                                  },
                                  transitionDuration: const Duration(milliseconds: 400),
                                ),
                              );
                            }
                          },
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Enhanced dots indicator
                      Expanded(
                        flex: 2,
                        child: _buildDotsIndicator(),
                      ),

                      const SizedBox(width: 10),

                      // Next/Start button
                      Expanded(
                        flex: 3,
                        child: _OnboardingNavButton(
                          text: isLastPage ? 'لنبدأ' : 'التالي',
                          isPrimary: true,
                          icon: isLastPage ? Icons.rocket_launch : Icons.arrow_back,
                          onPressed: () async {
                            HapticFeedback.mediumImpact();
                            if (isLastPage) {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setBool('onboarding_complete', true);
                              if (!mounted) return;
                              Navigator.pushReplacement(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) =>
                                      const LoginUi(),
                                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                    return ScaleTransition(
                                      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                      child: FadeTransition(opacity: animation, child: child),
                                    );
                                  },
                                  transitionDuration: const Duration(milliseconds: 500),
                                ),
                              );
                            } else {
                              _goToNextPage();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotsIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.32),
            const Color(0xFFF9D5D3).withOpacity(0.22),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withOpacity(0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          demoData.length,
          (index) => _DotIndicator(
            isActive: index == _pageIndex,
            onTap: () {
              HapticFeedback.lightImpact();
              _pageController.animateToPage(
                index,
                duration: _pageTransitionDuration,
                curve: _pageTransitionCurve,
              );
            },
          ),
        ),
      ),
    );
  }
}

// Optimized Onboarding Slide with better performance
class OnboardingSlide extends StatefulWidget {
  const OnboardingSlide({
    super.key,
    required this.content,
    required this.pageController,
    required this.pageIndex,
    required this.floatingController,
    required this.pulseController,
  });

  final OnboardingContent content;
  final PageController pageController;
  final int pageIndex;
  final AnimationController floatingController;
  final AnimationController pulseController;

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide> 
    with AutomaticKeepAliveClientMixin {
  double _parallaxOffset = 0;
  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    _floatingAnimation = Tween<double>(begin: -10.0, end: 10.0).animate(
      CurvedAnimation(
        parent: widget.floatingController,
        curve: Curves.easeInOut,
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(
        parent: widget.pulseController,
        curve: Curves.easeInOut,
      ),
    );
    
    widget.pageController.addListener(_updateParallax);
  }

  void _updateParallax() {
    if (mounted && widget.pageController.hasClients) {
      final page = widget.pageController.page ?? widget.pageIndex.toDouble();
      setState(() {
        _parallaxOffset = (page - widget.pageIndex).clamp(-1.0, 1.0);
      });
    }
  }

  @override
  void dispose() {
    widget.pageController.removeListener(_updateParallax);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Animated Lottie with parallax effect
        AnimatedBuilder(
          animation: Listenable.merge([_floatingAnimation, _pulseAnimation]),
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _parallaxOffset * -80,
                _floatingAnimation.value,
              ),
              child: Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD47FA6).withOpacity(0.35),
                        blurRadius: 28,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    widget.content.image,
                    height: screenHeight * 0.35,
                    width: screenWidth * 0.8,
                    fit: BoxFit.contain,
                    // Optimize Lottie performance
                    frameRate: FrameRate.max,
                    repeat: true,
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: screenHeight * 0.06),

        // Enhanced content card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: _buildContentCard(screenWidth),
        ),
      ],
    );
  }

  Widget _buildContentCard(double screenWidth) {
    return Stack(
      children: [
        // Outer glow effect - optimized
        Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF52002C).withOpacity(0.18),
                blurRadius: 50,
                spreadRadius: 12,
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.35),
                blurRadius: 25,
                spreadRadius: 4,
              ),
            ],
          ),
        ),
        
        // Main card with glass morphism
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.42),
                    const Color(0xFFF9D5D3).withOpacity(0.28),
                    const Color(0xFF52002C).withOpacity(0.1),
                    Colors.white.withOpacity(0.2),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.62),
                  width: 2.2,
                ),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.08,
                  vertical: 32,
                ),
                child: _buildAnimatedContent(),
              ),
            ),
          ),
        ),
        
        // Decorative particles
        _buildDecorativeParticle(top: 18, right: 28, size: 7),
        _buildDecorativeParticle(bottom: 28, left: 35, size: 5, isPink: true),
      ],
    );
  }

  Widget _buildDecorativeParticle({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    bool isPink = false,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isPink
              ? const Color(0xFFF9D5D3).withOpacity(0.85)
              : Colors.white.withOpacity(0.75),
          boxShadow: [
            BoxShadow(
              color: isPink
                  ? const Color(0xFFF9D5D3).withOpacity(0.45)
                  : Colors.white.withOpacity(0.55),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }

  // Enhanced animated content with better typography
  Widget _buildAnimatedContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAnimatedWidget(
          delay: const Duration(milliseconds: 250),
          child: Text(
            widget.content.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: (screenWidth * 0.068).clamp(18.0, 30.0),
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              color: const Color(0xFF52002C),
              letterSpacing: 0.4,
              height: 1.3,
              shadows: const [
                Shadow(
                  color: Colors.white,
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
                Shadow(
                  color: Color(0xFF52002C),
                  blurRadius: 6,
                  offset: Offset(1, 1),
                ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: screenHeight * 0.022),
        
        _buildAnimatedWidget(
          delay: const Duration(milliseconds: 400),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            child: Text(
              widget.content.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (screenWidth * 0.042).clamp(15.0, 19.0),
                fontFamily: 'Tajawal',
                color: const Color(0xFF52002C).withOpacity(0.88),
                height: 1.9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.25,
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.65),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Optimized animated widget with smooth entrance
  Widget _buildAnimatedWidget({
    required Duration delay,
    required Widget child,
  }) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      delay: delay,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Transform.scale(
              scale: 0.85 + (0.15 * value),
              child: _child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

// Enhanced dot indicator with tap support
class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.isActive,
    this.onTap,
  });

  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 3.0),
        height: isActive ? 9 : 7,
        width: isActive ? 26 : 7,
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [
                    Color(0xFF52002C),
                    Color(0xFFD47FA6),
                  ],
                )
              : null,
          color: isActive ? null : Colors.white.withOpacity(0.48),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: Colors.white.withOpacity(isActive ? 0.85 : 0.65),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: const Color(0xFF52002C).withOpacity(0.35),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

// Enhanced navigation button with better interaction
class _OnboardingNavButton extends StatefulWidget {
  const _OnboardingNavButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
    this.icon,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;
  final IconData? icon;

  @override
  State<_OnboardingNavButton> createState() => _OnboardingNavButtonState();
}

class _OnboardingNavButtonState extends State<_OnboardingNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.isPrimary
            ? _buildPrimaryButton(screenWidth)
            : _buildSecondaryButton(screenWidth),
      ),
    );
  }

  Widget _buildPrimaryButton(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.035,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF52002C),
            Color(0xFFD47FA6),
            Color(0xFFC15C5C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withOpacity(0.45),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF52002C).withOpacity(_isPressed ? 0.3 : 0.4),
            blurRadius: _isPressed ? 12 : 16,
            spreadRadius: _isPressed ? 1 : 2,
            offset: Offset(0, _isPressed ? 4 : 8),
          ),
          BoxShadow(
            color: const Color(0xFFD47FA6).withOpacity(0.25),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: (screenWidth * 0.037).clamp(13.0, 16.0),
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Tajawal',
              letterSpacing: 0.4,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.035,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(_isPressed ? 0.25 : 0.32),
            Colors.white.withOpacity(_isPressed ? 0.12 : 0.18),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withOpacity(0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(_isPressed ? 0.15 : 0.22),
            blurRadius: _isPressed ? 6 : 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.icon != null) ...[
            Icon(
              widget.icon,
              color: const Color(0xFF52002C).withOpacity(0.75),
              size: 15,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            widget.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF52002C).withOpacity(0.82),
              fontSize: (screenWidth * 0.036).clamp(12.0, 15.0),
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
              letterSpacing: 0.3,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
