import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_screen.dart';
import 'game_multiplayer_screen.dart';
import 'game_online_multiplayer_screen.dart';
import 'settings_screen.dart';
import 'auth/login_screen.dart';
import 'playerprofile_screen.dart';
import 'shop_screen.dart'; // Add this import for the shop screen

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool isDark) onThemeToggle;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AnimationController? _glowController;
  AnimationController? _pulseController;
  AnimationController? _coinAnimationController;

  // Currency state
  int _coins = 150; // Regular coins
  int _diamonds = 25; // Premium diamonds

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _coinAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController?.dispose();
    _pulseController?.dispose();
    _coinAnimationController?.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        },
      );

      // Sign out from Firebase
      await _auth.signOut();

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Logged out successfully'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate to login screen and clear navigation stack
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              isDarkMode: widget.isDarkMode,
              onThemeToggle: widget.onThemeToggle,
            ),
          ),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Logout failed: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Currency Display Widget
  Widget _buildCurrencyDisplay() {
    return AnimatedBuilder(
      animation: _coinAnimationController!,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade300.withOpacity(0.9),
                Colors.orange.shade400.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(
                  0.3 + (_coinAnimationController!.value * 0.2),
                ),
                blurRadius: 15 + (_coinAnimationController!.value * 5),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Regular Coins
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.yellow.shade200.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 1.0 + (_coinAnimationController!.value * 0.1),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade600,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow.shade800.withOpacity(0.5),
                                blurRadius: 4,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.monetization_on,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_coins',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Coins',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Premium Diamonds
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.cyan.shade200.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.scale(
                        scale: 1.0 + (_coinAnimationController!.value * 0.15),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.cyan.shade400,
                                Colors.blue.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.cyan.shade800.withOpacity(0.5),
                                blurRadius: 6,
                                offset: const Offset(1, 1),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.diamond,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$_diamonds',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black26,
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Diamonds',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Square Game Mode Button Widget
  Widget _buildSquareGameButton({
    required String title,
    required IconData icon,
    required VoidCallback onPressed,
    required List<Color> gradientColors,
    required Color shadowColor,
    String? subtitle,
  }) {
    return AnimatedBuilder(
      animation: _glowController!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(
                  0.3 + (_glowController!.value * 0.3),
                ),
                blurRadius: 15 + (_glowController!.value * 5),
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 160,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(icon, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMenuButton() {
    return AnimatedBuilder(
      animation: _pulseController!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(
                  0.2 + (_pulseController!.value * 0.2),
                ),
                blurRadius: 8 + (_pulseController!.value * 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 28),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorfulDrawer() {
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple.shade800,
              Colors.indigo.shade700,
              Colors.blue.shade600,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade900, Colors.indigo.shade800],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DrawerHeader(
                decoration: const BoxDecoration(color: Colors.transparent),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Avatar moved here
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlayerProfileScreen(
                              isDarkMode: widget.isDarkMode,
                              onThemeToggle: widget.onThemeToggle,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 35,
                        backgroundColor: Colors.white.withOpacity(0.9),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '🎮 Game Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            offset: Offset(1, 1),
                            blurRadius: 3,
                            color: Colors.black26,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Welcome, ${_auth.currentUser?.email?.split('@')[0] ?? 'User'}!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(
              icon: Icons.shopping_bag,
              title: 'Shop',
              subtitle: 'Buy coins & items',
              colors: [Colors.purple.shade400, Colors.pink.shade500],
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShopScreen(
                      isDarkMode: widget.isDarkMode,
                      onThemeToggle: widget.onThemeToggle,
                      coins: _coins,
                      diamonds: _diamonds,
                      onCurrencyUpdate: (newCoins, newDiamonds) {
                        setState(() {
                          _coins = newCoins;
                          _diamonds = newDiamonds;
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings,
              title: 'Settings',
              subtitle: 'App preferences',
              colors: [Colors.orange.shade400, Colors.red.shade500],
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      isDarkMode: widget.isDarkMode,
                      onThemeToggle: widget.onThemeToggle,
                    ),
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.info,
              title: 'About',
              subtitle: 'App information',
              colors: [Colors.green.shade400, Colors.teal.shade500],
              onTap: () {
                Navigator.pop(context);
                _showInfoDialog(context);
              },
            ),
            _buildDrawerItem(
              icon: Icons.description,
              title: 'Terms & Privacy',
              subtitle: 'Legal information',
              colors: [Colors.indigo.shade400, Colors.purple.shade500],
              onTap: () {
                Navigator.pop(context);
                _showTermsDialog(context);
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Divider(color: Colors.white30, thickness: 1),
            ),
            _buildDrawerItem(
              icon: Icons.logout,
              title: 'Log Out',
              subtitle: 'Sign out of app',
              colors: [Colors.red.shade400, Colors.pink.shade500],
              onTap: () {
                Navigator.pop(context);
                _showLogoutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> colors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Compact Currency Widget for App Bar
  Widget _buildCompactCurrencyDisplay() {
    return AnimatedBuilder(
      animation: _coinAnimationController!,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade400.withOpacity(0.9),
                Colors.orange.shade500.withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(
                  0.3 + (_coinAnimationController!.value * 0.2),
                ),
                blurRadius: 8 + (_coinAnimationController!.value * 3),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Coins
              Transform.scale(
                scale: 1.0 + (_coinAnimationController!.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.yellow.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.yellow.shade800.withOpacity(0.5),
                        blurRadius: 2,
                        offset: const Offset(0.5, 0.5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_coins',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Diamonds
              Transform.scale(
                scale: 1.0 + (_coinAnimationController!.value * 0.15),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.cyan.shade400,
                        Colors.blue.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.shade800.withOpacity(0.5),
                        blurRadius: 2,
                        offset: const Offset(0.5, 0.5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$_diamonds',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      offset: Offset(1, 1),
                      blurRadius: 2,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          '🎮 Stone Paper Scissors',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: Offset(1, 1),
                blurRadius: 3,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        actions: [
          _buildCompactCurrencyDisplay(),
          _buildMenuButton(),
        ],
        centerTitle: true,
      ),
      endDrawer: _buildColorfulDrawer(),
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
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Game Mode Buttons in Square Grid
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),

                      // Game Mode Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                        children: [
                          _buildSquareGameButton(
                            title: '🤖 Play vs Computer',
                            subtitle: 'Challenge AI',
                            icon: Icons.computer,
                            gradientColors: [
                              Colors.cyan.shade400,
                              Colors.blue.shade600,
                            ],
                            shadowColor: Colors.cyan,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GameScreen(),
                                ),
                              );
                            },
                          ),

                          _buildSquareGameButton(
                            title: '👥 Local Multiplayer',
                            subtitle: 'Play with friends',
                            icon: Icons.group,
                            gradientColors: [
                              Colors.purple.shade400,
                              Colors.pink.shade600,
                            ],
                            shadowColor: Colors.purple,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GameMultiplayerScreen(),
                                ),
                              );
                            },
                          ),

                          _buildSquareGameButton(
                            title: '🌐 Online Multiplayer',
                            subtitle: 'Play online',
                            icon: Icons.wifi,
                            gradientColors: [
                              Colors.green.shade400,
                              Colors.teal.shade600,
                            ],
                            shadowColor: Colors.green,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const GameOnlineMultiplayerScreen(),
                                ),
                              );
                            },
                          ),

                          // Stats tile moved to grid
                          AnimatedBuilder(
                            animation: _glowController!,
                            builder: (context, child) {
                              return Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withOpacity(
                                        0.3 + (_glowController!.value * 0.3),
                                      ),
                                      blurRadius: 15 + (_glowController!.value * 5),
                                      spreadRadius: 2,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  height: 160,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade300,
                                        Colors.red.shade400,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.emoji_events,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        '🏆 Stats',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(1, 1),
                                              blurRadius: 3,
                                              color: Colors.black26,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Column(
                                            children: [
                                              Text(
                                                '0',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white.withOpacity(0.9),
                                                ),
                                              ),
                                              Text(
                                                'Games',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              Text(
                                                '0',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white.withOpacity(0.9),
                                                ),
                                              ),
                                              Text(
                                                'Wins',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.white.withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Log Out',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Are you sure you want to log out?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              if (_auth.currentUser?.email != null)
                Text(
                  'Signed in as: ${_auth.currentUser!.email}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade400, Colors.pink.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog first
                  _handleLogout(); // Then handle logout
                },
                child: const Text(
                  'Log Out',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.info, color: Colors.blue),
              SizedBox(width: 12),
              Text(
                'About',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🎮 Rock Paper Scissors',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Version 1.0.0',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              SizedBox(height: 16),
              Text(
                'A modern, colorful implementation of the classic Rock Paper Scissors game with single-player, local multiplayer, and online multiplayer modes.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade400, Colors.purple.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.description, color: Colors.purple),
              SizedBox(width: 12),
              Text(
                'Terms & Privacy',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms of Service',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• This app is provided for entertainment purposes only\n• Play responsibly and have fun\n• No personal data is collected or stored',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 16),
                Text(
                  'Privacy Policy',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  '• We respect your privacy\n• No data is shared with third parties\n• Game statistics are stored locally only',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.indigo.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'I Understand',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}