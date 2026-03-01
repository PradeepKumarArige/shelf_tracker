import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/responsive.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppColors.splashGradientDark
              : AppColors.splashGradient,
        ),
        child: Stack(
          children: [
            _buildPatternBackground(),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildLogo(isTablet),
                          SizedBox(height: isTablet ? 32 : 24),
                          _buildAppName(isTablet),
                          SizedBox(height: isTablet ? 12 : 8),
                          _buildTagline(isTablet),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: _buildLoader(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.08,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 24,
            crossAxisSpacing: 24,
          ),
          itemBuilder: (context, index) {
            final icons = [
              Icons.restaurant_rounded,
              Icons.shopping_basket_rounded,
              Icons.medical_services_rounded,
              Icons.face_rounded,
              Icons.local_grocery_store_rounded,
              Icons.medication_rounded,
            ];
            return Icon(
              icons[index % icons.length],
              color: Colors.white,
              size: 40,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogo(bool isTablet) {
    final size = isTablet ? 180.0 : 120.0;
    final barHeight = isTablet ? 18.0 : 12.0;
    final gap = isTablet ? 10.0 : 6.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 40 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildShelfLine(barHeight, 0.5, gap),
          SizedBox(height: gap),
          _buildShelfLine(barHeight, 0.7, gap),
          SizedBox(height: gap),
          _buildShelfLine(barHeight, 0.9, gap),
        ],
      ),
    );
  }

  Widget _buildShelfLine(double height, double widthFactor, double gap) {
    return FractionallySizedBox(
      widthFactor: widthFactor * 0.7,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF29B6F6),
              Color(0xFF0288D1),
              Color(0xFF01579B),
            ],
          ),
          borderRadius: BorderRadius.circular(height / 4),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF01579B),
              offset: Offset(0, height / 3),
              blurRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              offset: Offset(0, height / 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: height / 4,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF4FC3F7),
                      Color(0xFF29B6F6),
                    ],
                  ),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(height / 4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppName(bool isTablet) {
    return Text(
      'Shelf Tracker',
      style: TextStyle(
        fontFamily: 'Montserrat',
        fontSize: isTablet ? 52 : 36,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: -0.5,
        shadows: [
          Shadow(
            color: Colors.black.withOpacity(0.2),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildTagline(bool isTablet) {
    return Text(
      'Track freshness, reduce waste',
      style: TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: isTablet ? 20 : 16,
        fontWeight: FontWeight.w500,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.white.withOpacity(0.8),
          ),
        ),
      ),
    );
  }
}
