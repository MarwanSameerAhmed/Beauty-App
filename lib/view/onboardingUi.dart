import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_pro/view/auth_Ui/loginUi.dart';
import 'package:test_pro/view/auth_Ui/signupUi.dart';
import 'package:test_pro/widgets/backgroundUi.dart';
import 'package:simple_animations/simple_animations.dart';

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

  late Animation<double> _floatingAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotateAnimation;

  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Initialize animations
    _floatingController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _floatingAnimation = Tween<double>(begin: -15.0, end: 15.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotateController);
  }

  @override
  void dispose() {
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
        body: Stack(
          children: [
            // Animated background elements
            _buildAnimatedBackground(),

            // Main content
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: demoData.length,
                    onPageChanged: (index) {
                      setState(() {
                        _pageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return OnboardingSlide(
                        content: demoData[index],
                        pageController: _pageController,
                        pageIndex: index,
                        floatingAnimation: _floatingAnimation,
                        pulseAnimation: _pulseAnimation,
                      );
                    },
                  ),
                ),
                // Glass morphism bottom navigation
                _buildGlassMorphismBottomNav(),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Stack(
      children: [
        // Floating circles with different sizes and animations
        Positioned(
          top: 80,
          left: 30,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value),
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFF9D5D3).withOpacity(0.3),
                          const Color(0xFFFFE4E1).withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          top: 200,
          right: 50,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatingAnimation.value * 0.7),
                child: RotationTransition(
                  turns: _rotateAnimation,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFD47FA6).withOpacity(0.4),
                          const Color(0xFFC15C5C).withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          bottom: 200,
          left: 80,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatingAnimation.value * 0.5),
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.2),
                          Colors.white.withOpacity(0.1),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGlassMorphismBottomNav() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9D5D3).withOpacity(0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              OnboardingNavButton(
                text: 'تخطي',
                isPrimary: false,
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('onboarding_complete', true);
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupUi()),
                  );
                },
              ),

              // Animated dots indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: List.generate(
                    demoData.length,
                    (index) => DotIndicator(isActive: index == _pageIndex),
                  ),
                ),
              ),

              OnboardingNavButton(
                text: _pageIndex == demoData.length - 1 ? 'لنبدأ' : 'التالي',
                onPressed: () async {
                  if (_pageIndex == demoData.length - 1) {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('onboarding_complete', true);
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginUi()),
                    );
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeInOutCubic,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingSlide extends StatefulWidget {
  const OnboardingSlide({
    super.key,
    required this.content,
    required this.pageController,
    required this.pageIndex,
    required this.floatingAnimation,
    required this.pulseAnimation,
  });

  final OnboardingContent content;
  final PageController pageController;
  final int pageIndex;
  final Animation<double> floatingAnimation;
  final Animation<double> pulseAnimation;

  @override
  State<OnboardingSlide> createState() => _OnboardingSlideState();
}

class _OnboardingSlideState extends State<OnboardingSlide> {
  double _parallaxOffset = 0;

  @override
  void initState() {
    super.initState();
    widget.pageController.addListener(() {
      if (mounted) {
        setState(() {
          _parallaxOffset = (widget.pageController.page! - widget.pageIndex);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: widget.floatingAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(
                _parallaxOffset * -100,
                widget.floatingAnimation.value,
              ),
              child: ScaleTransition(
                scale: widget.pulseAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD47FA6).withOpacity(0.4),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Lottie.asset(
                    widget.content.image,
                    height: 320,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 50),

        // Enhanced glass morphism content container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(35),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFFF9D5D3).withOpacity(0.8),
                    const Color(0xFFFFE4E1).withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 7,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: _buildAnimatedContent(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedContent() {
    return Column(
      children: [
        _buildAnimatedWidget(
          delay: const Duration(milliseconds: 300),
          child: Text(
            widget.content.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildAnimatedWidget(
          delay: const Duration(milliseconds: 500),
          child: Text(
            widget.content.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Colors.black.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedWidget({
    required Duration delay,
    required Widget child,
  }) {
    return PlayAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      delay: delay,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, value, _child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - value)),
            child: Transform.scale(
              scale: (0.8 + (0.2 * value)).clamp(0.1, 2.0),
              child: _child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}

class DotIndicator extends StatelessWidget {
  const DotIndicator({super.key, this.isActive = false});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      height: isActive ? 12 : 8,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                colors: [Color(0xFFD47FA6), Color(0xFFC15C5C)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isActive ? null : Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: const Color(0xFFD47FA6).withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
    );
  }
}

class OnboardingNavButton extends StatelessWidget {
  const OnboardingNavButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    if (isPrimary) {
      return LoopAnimationBuilder<double>(
        tween: Tween(begin: 1.0, end: 1.08),
        duration: const Duration(seconds: 3),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFD47FA6), Color(0xFFC15C5C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD47FA6).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Tajawal',
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
        ),
        child: GestureDetector(
          onTap: onPressed,
          child: Text(
            text,
            style: TextStyle(
              color: Colors.black.withOpacity(0.7),
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      );
    }
  }
}
