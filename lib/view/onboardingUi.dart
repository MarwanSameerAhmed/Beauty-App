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
        // Magical floating orbs with glow effects
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
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF52002C).withOpacity(0.4),
                          const Color(0xFFF9D5D3).withOpacity(0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF52002C).withOpacity(0.3),
                          blurRadius: (40.0).clamp(0.0, 100.0).abs(),
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFF9D5D3).withOpacity(0.8),
                            const Color(0xFFFFE4E1).withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Sparkling diamond shape with rotation
        Positioned(
          top: 180,
          right: 40,
          child: AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatingAnimation.value * 0.7),
                child: RotationTransition(
                  turns: _rotateAnimation,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF52002C).withOpacity(0.6),
                          const Color(0xFFD47FA6).withOpacity(0.4),
                          const Color(0xFFC15C5C).withOpacity(0.3),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD47FA6).withOpacity(0.5),
                          blurRadius: (25.0).clamp(0.0, 100.0).abs(),
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.3),
                          blurRadius: (10.0).clamp(0.0, 100.0).abs(),
                          offset: const Offset(-5, -5),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.4),
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
        ),

        // Glowing crystal with inner light
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
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.6),
                          const Color(0xFFF9D5D3).withOpacity(0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.4),
                          blurRadius: (30.0).clamp(0.0, 100.0).abs(),
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Additional floating particles
        Positioned(
          top: 300,
          left: 200,
          child: AnimatedBuilder(
            animation: _rotateAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value * 6.28,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF52002C).withOpacity(0.5),
                        const Color(0xFFD47FA6).withOpacity(0.3),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF52002C).withOpacity(0.3),
                        blurRadius: (15.0).clamp(0.0, 100.0).abs(),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Floating star particles
        Positioned(
          bottom: 350,
          right: 100,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.8),
                        const Color(0xFFF9D5D3).withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: (20.0).clamp(0.0, 100.0).abs(),
                        spreadRadius: 3,
                      ),
                    ],
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        children: [
          // Ethereal outer glow
          Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF52002C).withOpacity(0.3),
                  blurRadius: (80.0).clamp(0.0, 100.0).abs(),
                  spreadRadius: 20,
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.5),
                  blurRadius: (40.0).clamp(0.0, 100.0).abs(),
                  spreadRadius: 8,
                ),
              ],
            ),
          ),
          // Main navigation card
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.35),
                      const Color(0xFFF9D5D3).withOpacity(0.2),
                      const Color(0xFF52002C).withOpacity(0.1),
                      Colors.white.withOpacity(0.25),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width * 0.06,
                    vertical: MediaQuery.of(context).size.height * 0.02,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.transparent,
                        Colors.white.withOpacity(0.08),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      // Skip button
                      Expanded(
                        flex: 3,
                        child: OnboardingNavButton(
                          text: 'تخطي',
                          isPrimary: false,
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('onboarding_complete', true);
                            if (!mounted) return;
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignupUi(),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Dots indicator
                      Expanded(
                        flex: 2,
                        child: Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  MediaQuery.of(context).size.width * 0.015,
                              vertical:
                                  MediaQuery.of(context).size.height * 0.008,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.3),
                                  const Color(0xFFF9D5D3).withOpacity(0.2),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.3),
                                  blurRadius: (10.0).clamp(0.0, 100.0).abs(),
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  demoData.length,
                                  (index) => DotIndicator(
                                    isActive: index == _pageIndex,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Next/Start button
                      Expanded(
                        flex: 3,
                        child: OnboardingNavButton(
                          text: _pageIndex == demoData.length - 1
                              ? 'لنبدأ'
                              : 'التالي',
                          onPressed: () async {
                            if (_pageIndex == demoData.length - 1) {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await prefs.setBool('onboarding_complete', true);
                              if (!mounted) return;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginUi(),
                                ),
                              );
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeInOutCubic,
                              );
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
                        blurRadius: (30.0).clamp(0.0, 100.0).abs(),
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

        // Magical floating content card with ethereal effects
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Stack(
            children: [
              // Outer glow effect
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(45),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF52002C).withOpacity(0.2),
                      blurRadius: (60.0).clamp(0.0, 100.0).abs(),
                      spreadRadius: 15,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.4),
                      blurRadius: (30.0).clamp(0.0, 100.0).abs(),
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),
              // Main card with layered effects
              ClipRRect(
                borderRadius: BorderRadius.circular(45),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(45),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.4),
                          const Color(0xFFF9D5D3).withOpacity(0.25),
                          const Color(0xFF52002C).withOpacity(0.08),
                          Colors.white.withOpacity(0.15),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.6),
                        width: 2.5,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(40.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(42),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.transparent,
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: _buildAnimatedContent(),
                    ),
                  ),
                ),
              ),
              // Floating light particles
              Positioned(
                top: 20,
                right: 30,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: (15.0).clamp(0.0, 100.0).abs(),
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 30,
                left: 40,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFF9D5D3).withOpacity(0.9),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF9D5D3).withOpacity(0.5),
                        blurRadius: (12.0).clamp(0.0, 100.0).abs(),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
            style: TextStyle(
              fontSize: (MediaQuery.of(context).size.width * 0.07).clamp(
                16.0,
                32.0,
              ),
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              color: const Color(0xFF52002C),
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: (15.0).clamp(0.0, 100.0).abs(),
                  offset: const Offset(0, 3),
                ),
                Shadow(
                  color: const Color(0xFF52002C).withOpacity(0.2),
                  blurRadius: (8.0).clamp(0.0, 100.0).abs(),

                  offset: const Offset(2, 2),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.height * 0.025),
        _buildAnimatedWidget(
          delay: const Duration(milliseconds: 500),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
            ),
            child: Text(
              widget.content.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (MediaQuery.of(context).size.width * 0.045).clamp(
                  14.0,
                  20.0,
                ),
                fontFamily: 'Tajawal',
                color: const Color(0xFF52002C).withOpacity(0.85),
                height: 2.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: (8.0).clamp(0.0, 100.0).abs(),
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFF52002C)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withOpacity(0.8),
          width: 1,
        ),
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
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width * 0.04,
              vertical: MediaQuery.of(context).size.height * 0.018,
            ),
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.055,
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
              borderRadius: BorderRadius.circular(
                MediaQuery.of(context).size.width * 0.08,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF52002C).withOpacity(0.4),
                  blurRadius: (20.0).clamp(0.0, 100.0).abs(),
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: (10.0).clamp(0.0, 100.0).abs(),
                  offset: const Offset(0, -3),
                ),
                BoxShadow(
                  color: const Color(0xFFD47FA6).withOpacity(0.3),
                  blurRadius: (15.0).clamp(0.0, 100.0).abs(),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: (MediaQuery.of(context).size.width * 0.038).clamp(
                  12.0,
                  17.0,
                ),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontFamily: 'Tajawal',
                letterSpacing: 0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: (4.0).clamp(0.0, 100.0).abs(),

                    offset: const Offset(0, 2),
                  ),
                  Shadow(
                    color: const Color(0xFF52002C).withOpacity(0.3),
                    blurRadius: (8.0).clamp(0.0, 100.0).abs(),
                    offset: const Offset(1, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: onPressed,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.04,
            vertical: MediaQuery.of(context).size.height * 0.016,
          ),
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height * 0.055,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(
              MediaQuery.of(context).size.width * 0.06,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: (10.0).clamp(0.0, 100.0).abs(),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF52002C).withOpacity(0.8),
                fontSize: (MediaQuery.of(context).size.width * 0.037).clamp(
                  11.0,
                  16.0,
                ),
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.white.withOpacity(0.6),
                    blurRadius: (3.0).clamp(0.0, 100.0).abs(),
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
