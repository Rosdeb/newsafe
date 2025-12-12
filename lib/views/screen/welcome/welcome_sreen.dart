import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:saferader/utils/app_color.dart';
import 'package:saferader/utils/app_icon.dart';
import 'package:saferader/utils/app_utils.dart';
import 'package:saferader/views/base/AppText/appText.dart';
import 'package:saferader/views/base/Ios_effect/iosTapEffect.dart';
import 'package:saferader/views/base/borderButton/borderbuton.dart';
import 'package:saferader/views/screen/auth/signinPage/signIn_screen.dart';
import '../../../controller/welcome/welcome.dart';
import '../../base/animationsWrapper/animations_wrapper.dart';
import '../../base/gradientbutton/gradientButton.dart';


class WelcomeSreen extends StatelessWidget {
  WelcomeSreen({super.key});

  final WelcomeController controller = Get.put(WelcomeController());

  final apputils = AppUtils();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:const  SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Color(0xff202020),
        body: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 45),
              SvgPicture.asset(AppIcons.miniSafeRadar),
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              const AnimatedAppText(
                "Welcome to SafeRadar",
                fontSize: 30,
                fontWeight: FontWeight.w700,
                color: Color(0xFFEDC602),
              ),
              SizedBox(height: 18),
              const AnimatedAppText(
                "Join a community that cares. When you need help, we're here.When others need help, you can be their hero.",
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.colorSubheading,
                duration: Duration(milliseconds: 800),
                delay: Duration(milliseconds: 300),
              ),
              const SizedBox(height: 10),
              SimpleAnimatedContainersList(),
              const SizedBox(height: 24),
              EnhancedAnimatedWrapper(
                duration:const  Duration(milliseconds: 800),
                delay:const  Duration(milliseconds: 500),
                direction: AnimationDirection.top,
                curve: Curves.elasticOut, // Better curve for bounce effect
                child: Gradientbutton1(
                  text: 'GET STARTED',
                  ontap: () {
                    apputils.logInfo("Get started");
                    // Navigation is handled internally with better transitions
                    Navigator.push(context, MaterialPageRoute(builder: (builder)=>SigninScreen()));

                  },
                ),
              ),

              const SizedBox(height: 24),

              EnhancedAnimatedWrapper(
                duration:Duration(milliseconds: 800),
                delay:const Duration(milliseconds: 500),
                direction: AnimationDirection.bottom,
                curve: Curves.elasticOut,
                child: Borderbuton(
                  text: 'Create account',
                  onTap: () {
                    apputils.logInfo("Get started");
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SigninScreen()),
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
// Replace your HeroGradientButton with this simpler version for testing
class SimpleHeroButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final String heroTag;
  final Widget destinationScreen;

  const SimpleHeroButton({
    Key? key,
    required this.text,
    required this.onTap,
    required this.heroTag,
    required this.destinationScreen,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: heroTag,
      child: GestureDetector(
        onTap: () {
          print("🔥 SIMPLE HERO BUTTON TAPPED!"); // Debug
          onTap();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => destinationScreen),
          );
        },
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF4A90E2), Color(0xFF7B68EE)],
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SimpleAnimatedContainersList extends StatelessWidget {
  SimpleAnimatedContainersList({Key? key}) : super(key: key);

  final WelcomeController controller = Get.put(WelcomeController());

  final List<Map<String, dynamic>> items = [
    {
      "icon": AppIcons.alart,
      "title": "Emergency Panic button",
      "subtitle": "Get instant help when you need it most",
      "role":"seeker"
    },
    {
      "icon": AppIcons.flat_handshake,
      "title": "Community Support",
      "subtitle": "Connect with helpers in your area",
      "role":"giver"
    },
    {
      "icon": "assets/image/locations.png",
      "title": "Real-time Location",
      "subtitle": "Share your location safely with helpers",
      "role": "both"
    },
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: List.generate(items.length, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 600 + (index * 200)),
          // Staggered timing
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            final item = items[index];
            return Obx(() {
              final selectedIndex = controller.selectedIndex.value == index;
              return IosTapEffect(
                onTap: () => controller.tapSelected(index),
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * -100), // Slide from top
                  child: Opacity(
                    opacity: value,
                    child: Column(
                      children: [
                        Container(
                          height: 74,
                          padding: EdgeInsets.symmetric(
                            horizontal: size.width * 0.035,
                            vertical: size.width * 0.020,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: const Color(0xFF505050).withOpacity(0.50),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  gradient: LinearGradient(
                                    begin: Alignment.topRight,
                                    end: Alignment.bottomLeft,
                                    colors: [
                                      Color(0xffffe4a7),
                                      Color(0xfffbd96f),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Builder(
                                    builder: (_) {
                                      String path =
                                          item['icon']; // your dynamic path
                                      if (path.endsWith(".svg")) {
                                        return SvgPicture.asset(
                                          path,
                                          width: 24,
                                          height: 24,
                                        );
                                      } else {
                                        return Image.asset(
                                          path,
                                          width: 24,
                                          height: 24,
                                          fit: BoxFit.contain,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(width: size.width * 0.016),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    item["title"],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: AppColors.colorWhite,
                                  ),
                                  AppText(
                                    item["subtitle"],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (index < 2) const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            });
          },
        );
      }),
    );
  }
}

class AnimatedAppText extends StatelessWidget {
  final String text;
  final double fontSize;
  final FontWeight fontWeight;
  final Color color;
  final TextStyle? style;

  final Duration duration;
  final Duration delay;
  final double? height;

  const AnimatedAppText(
    this.text, {
    Key? key,
    required this.fontSize,
    required this.fontWeight,
    required this.color,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) {
        final delayedValue =
            (value - (delay.inMilliseconds / duration.inMilliseconds)).clamp(
              0.0,
              1.0,
            );
        return Transform.translate(
          offset: Offset(0, (1 - delayedValue) * -50),
          child: Opacity(
            opacity: delayedValue,
            child: AppText(
              text,
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: color,
              height: height,
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }
}
// Enhanced Hero Button with better transitions
class EnhancedAnimatedWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final AnimationDirection direction;
  final Curve curve;
  final bool enableHeroTransition;

  const EnhancedAnimatedWrapper({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 800),
    this.delay = Duration.zero,
    this.direction = AnimationDirection.top,
    this.curve = Curves.easeOutBack,
    this.enableHeroTransition = true,
  }) : super(key: key);

  @override
  State<EnhancedAnimatedWrapper> createState() => _EnhancedAnimatedWrapperState();
}

class _EnhancedAnimatedWrapperState extends State<EnhancedAnimatedWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Define slide direction based on AnimationDirection
    Offset startOffset;
    switch (widget.direction) {
      case AnimationDirection.top:
        startOffset = const Offset(0.0, -1.0);
        break;
      case AnimationDirection.bottom:
        startOffset = const Offset(0.0, 1.0);
        break;
      case AnimationDirection.left:
        startOffset = const Offset(-1.0, 0.0);
        break;
      case AnimationDirection.right:
        startOffset = const Offset(1.0, 0.0);
        break;
    }

    _slideAnimation = Tween<Offset>(
      begin: startOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    // Start animation after delay
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}


// Enhanced Hero Button with better transitions
class HeroGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onTap;
  final String heroTag;
  final Widget destinationScreen;
  final Duration animationDuration;

  const HeroGradientButton({
    Key? key,
    required this.text,
    required this.onTap,
    required this.heroTag,
    required this.destinationScreen,
    this.animationDuration = const Duration(milliseconds: 600),
  }) : super(key: key);

  @override
  State<HeroGradientButton> createState() => _HeroGradientButtonState();
}

class _HeroGradientButtonState extends State<HeroGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pressController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
    _navigateWithCustomTransition();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  void _navigateWithCustomTransition() {
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => widget.destinationScreen,
        transitionDuration: widget.animationDuration,
        reverseTransitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide and fade transition
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;

          var tween = Tween(begin: begin, end: end);
          var offsetAnimation = animation.drive(tween.chain(CurveTween(curve: curve)));

          var fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          );

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      ),(route)=>false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: widget.heroTag,
      flightShuttleBuilder: (
          BuildContext flightContext,
          Animation<double> animation,
          HeroFlightDirection flightDirection,
          BuildContext fromHeroContext,
          BuildContext toHeroContext,
          ) {
        // Custom hero flight animation
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 + (animation.value * 0.1), // Slight scale during flight
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Color.lerp(Colors.blue, Colors.purple, animation.value)!,
                      Color.lerp(Colors.purple, Colors.blue, animation.value)!,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2 * animation.value),
                      blurRadius: 20 * animation.value,
                      spreadRadius: 5 * animation.value,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16 + (animation.value * 4), // Grow text during flight
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: IosTapEffect(
              onTap: () {  // Use onTap instead of onTapDown/onTapUp
                print("Button tapped!"); // Debug line
                _navigateWithCustomTransition();
              },
              child: Container(
                // Replace GradientButton with a simple container
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xfff7d481), Color(0xffffc91d)],
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.text,
                    style:  TextStyle(
                      color: AppColors.color2Box,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
}

// Sample Gradient Button Widget
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isLoading;


  const GradientButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors:isLoading ? [Color(0xfff7d481).withOpacity(0.6), Color(0xffffc91d).withOpacity(0.6)]
              :const [Color(0xfff7d481), Color(0xffffc91d)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: isLoading ? null : onTap,
          child: Center(
            child:isLoading ?
            const CupertinoActivityIndicator(
              color: Color(0xFF202020),
              radius: 12,
            )
            :Text(
              text,
              style:const TextStyle(
                color: AppColors.color2Box,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}