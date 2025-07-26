import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool isDark) onThemeToggle;

  const SplashScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  AnimationController? _pulseController;
  AnimationController? _rotationController;
  AnimationController? _scaleController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _rotationController?.dispose();
    _scaleController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade900,
              Colors.indigo.shade800,
              Colors.blue.shade700,
              Colors.cyan.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _pulseController!,
                    _rotationController!,
                    _scaleController!,
                  ]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: 1.0 + (_scaleController!.value * 0.1),
                      child: Transform.rotate(
                        angle: _rotationController!.value * 2 * 3.14159,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.shade400,
                                Colors.blue.shade600,
                                Colors.purple.shade500,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.withOpacity(
                                  0.4 + (_pulseController!.value * 0.3),
                                ),
                                blurRadius: 30 + (_pulseController!.value * 20),
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🎮', style: TextStyle(fontSize: 80)),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // App Title
                AnimatedBuilder(
                  animation: _pulseController!,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.8 + (_pulseController!.value * 0.2),
                      child: const Column(
                        children: [
                          Text(
                            'STONE PAPER SCISSORS',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2),
                                  blurRadius: 4,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'The Ultimate Gaming Experience',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),

                // Loading Indicator
                AnimatedBuilder(
                  animation: _pulseController!,
                  builder: (context, child) {
                    return Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 3,
                            ),
                          ),
                          child: CircularProgressIndicator(
                            color: Colors.white.withOpacity(
                              0.7 + (_pulseController!.value * 0.3),
                            ),
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white.withOpacity(
                              0.7 + (_pulseController!.value * 0.3),
                            ),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 100),

                // Bottom Decorative Elements
                AnimatedBuilder(
                  animation: _scaleController!,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDecorativeIcon('✂️', _scaleController!.value),
                        const SizedBox(width: 40),
                        _buildDecorativeIcon('📄', 1 - _scaleController!.value),
                        const SizedBox(width: 40),
                        _buildDecorativeIcon('🗿', _scaleController!.value),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeIcon(String icon, double animationValue) {
    return Transform.scale(
      scale: 0.8 + (animationValue * 0.3),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1 + (animationValue * 0.1)),
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
      ),
    );
  }
}
