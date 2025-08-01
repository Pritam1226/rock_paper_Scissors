import 'package:flutter/material.dart';
import 'dart:math';

class ShopScreen extends StatefulWidget {
  final bool isDarkMode;
  final void Function(bool isDark) onThemeToggle;
  final int coins;
  final int diamonds;
  final void Function(int newCoins, int newDiamonds) onCurrencyUpdate;

  const ShopScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
    required this.coins,
    required this.diamonds,
    required this.onCurrencyUpdate,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> with TickerProviderStateMixin {
  AnimationController? _glowController;
  AnimationController? _pulseController;
  AnimationController? _spinController;
  AnimationController? _scratchController;
  late int _currentCoins;
  late int _currentDiamonds;

  // Daily rewards state
  bool _dailySpinUsed = false;
  bool _scratchCardUsed = false;
  DateTime? _lastSpinDate;
  DateTime? _lastScratchDate;

  @override
  void initState() {
    super.initState();
    _currentCoins = widget.coins;
    _currentDiamonds = widget.diamonds;

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _scratchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _checkDailyRewards();
  }

  void _checkDailyRewards() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Check if daily rewards are available (reset daily)
    if (_lastSpinDate != null) {
      final lastSpinDay = DateTime(
        _lastSpinDate!.year,
        _lastSpinDate!.month,
        _lastSpinDate!.day,
      );
      _dailySpinUsed = lastSpinDay.isAtSameMomentAs(today);
    }

    if (_lastScratchDate != null) {
      final lastScratchDay = DateTime(
        _lastScratchDate!.year,
        _lastScratchDate!.month,
        _lastScratchDate!.day,
      );
      _scratchCardUsed = lastScratchDay.isAtSameMomentAs(today);
    }
  }

  @override
  void dispose() {
    _glowController?.dispose();
    _pulseController?.dispose();
    _spinController?.dispose();
    _scratchController?.dispose();
    super.dispose();
  }

  void _purchaseItem({
    required String itemName,
    required int coinCost,
    required int diamondCost,
    required String description,
  }) {
    if (_currentCoins >= coinCost && _currentDiamonds >= diamondCost) {
      setState(() {
        _currentCoins -= coinCost;
        _currentDiamonds -= diamondCost;
      });

      widget.onCurrencyUpdate(_currentCoins, _currentDiamonds);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Purchased $itemName successfully!')),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Text('Insufficient funds!'),
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

  void _showDailySpinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DailySpinDialog(
        onRewardWon: (coins, diamonds) {
          setState(() {
            _currentCoins += coins;
            _currentDiamonds += diamonds;
            _dailySpinUsed = true;
            _lastSpinDate = DateTime.now();
          });
          widget.onCurrencyUpdate(_currentCoins, _currentDiamonds);
        },
      ),
    );
  }

  void _showScratchCardDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ScratchCardDialog(
        onRewardWon: (coins, diamonds) {
          setState(() {
            _currentCoins += coins;
            _currentDiamonds += diamonds;
            _scratchCardUsed = true;
            _lastScratchDate = DateTime.now();
          });
          widget.onCurrencyUpdate(_currentCoins, _currentDiamonds);
        },
      ),
    );
  }

  Widget _buildCurrencyHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.amber.shade300, Colors.orange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_currentCoins',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Coins',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 2, height: 60, color: Colors.white.withOpacity(0.3)),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.cyan.shade400, Colors.blue.shade600],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$_currentDiamonds',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  'Diamonds',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRewardsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎁 Daily Rewards',
            style: TextStyle(
              fontSize: 24,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDailyRewardCard(
                  title: 'Daily Spin',
                  subtitle: 'Win up to 1000 coins!',
                  icon: Icons.rotate_right,
                  gradient: [Colors.purple.shade400, Colors.pink.shade600],
                  isAvailable: !_dailySpinUsed,
                  onTap: _dailySpinUsed ? null : _showDailySpinDialog,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDailyRewardCard(
                  title: 'Scratch Card',
                  subtitle: 'Reveal hidden prizes!',
                  icon: Icons.star,
                  gradient: [Colors.orange.shade400, Colors.red.shade600],
                  isAvailable: !_scratchCardUsed,
                  onTap: _scratchCardUsed ? null : _showScratchCardDialog,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRewardCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required bool isAvailable,
    required VoidCallback? onTap,
  }) {
    return AnimatedBuilder(
      animation: _pulseController!,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withOpacity(
                  isAvailable ? 0.3 + (_pulseController!.value * 0.2) : 0.1,
                ),
                blurRadius: isAvailable
                    ? 12 + (_pulseController!.value * 3)
                    : 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: isAvailable
                        ? gradient
                        : [Colors.grey.shade400, Colors.grey.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(isAvailable ? 0.3 : 0.1),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAvailable ? subtitle : 'Come back tomorrow!',
                      style: TextStyle(
                        fontSize: 12,
                        color: isAvailable
                            ? Colors.white.withOpacity(0.9)
                            : Colors.white60,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopItem({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required int coinCost,
    required int diamondCost,
    required VoidCallback onPurchase,
  }) {
    final canAfford =
        _currentCoins >= coinCost && _currentDiamonds >= diamondCost;

    return AnimatedBuilder(
      animation: _glowController!,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withOpacity(
                  canAfford ? 0.3 + (_glowController!.value * 0.2) : 0.1,
                ),
                blurRadius: canAfford ? 15 + (_glowController!.value * 5) : 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canAfford ? onPurchase : null,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: canAfford
                        ? gradientColors
                        : [Colors.grey.shade400, Colors.grey.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(canAfford ? 0.3 : 0.1),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(icon, color: Colors.white, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford
                                      ? Colors.white
                                      : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: canAfford
                                      ? Colors.white.withOpacity(0.9)
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (coinCost > 0) ...[
                              Icon(
                                Icons.monetization_on,
                                color: canAfford
                                    ? Colors.yellow.shade300
                                    : Colors.grey.shade300,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$coinCost',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                              ),
                            ],
                            if (coinCost > 0 && diamondCost > 0)
                              const SizedBox(width: 16),
                            if (diamondCost > 0) ...[
                              Icon(
                                Icons.diamond,
                                color: canAfford
                                    ? Colors.cyan.shade300
                                    : Colors.grey.shade300,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$diamondCost',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford
                                      ? Colors.white
                                      : Colors.white60,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: canAfford
                                ? Colors.white.withOpacity(0.2)
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            canAfford ? 'BUY' : 'LOCKED',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: canAfford ? Colors.white : Colors.white60,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
          '🛍️ Shop',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.purple.shade900,
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
              _buildCurrencyHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDailyRewardsSection(),
                      const SizedBox(height: 20),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '💎 Premium Items',
                          style: TextStyle(
                            fontSize: 24,
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
                      ),
                      const SizedBox(height: 16),

                      _buildShopItem(
                        title: 'Golden Theme',
                        description: 'Unlock exclusive golden game theme',
                        icon: Icons.palette,
                        gradientColors: [
                          Colors.amber.shade400,
                          Colors.orange.shade600,
                        ],
                        coinCost: 100,
                        diamondCost: 5,
                        onPurchase: () => _purchaseItem(
                          itemName: 'Golden Theme',
                          coinCost: 100,
                          diamondCost: 5,
                          description: 'Exclusive golden theme unlocked!',
                        ),
                      ),

                      _buildShopItem(
                        title: 'Double XP Boost',
                        description: 'Earn 2x experience points for 24 hours',
                        icon: Icons.speed,
                        gradientColors: [
                          Colors.green.shade400,
                          Colors.teal.shade600,
                        ],
                        coinCost: 50,
                        diamondCost: 2,
                        onPurchase: () => _purchaseItem(
                          itemName: 'Double XP Boost',
                          coinCost: 50,
                          diamondCost: 2,
                          description: 'Double XP boost activated!',
                        ),
                      ),

                      _buildShopItem(
                        title: 'Premium Avatar Pack',
                        description: 'Unlock 10 exclusive avatar designs',
                        icon: Icons.face,
                        gradientColors: [
                          Colors.purple.shade400,
                          Colors.pink.shade600,
                        ],
                        coinCost: 200,
                        diamondCost: 10,
                        onPurchase: () => _purchaseItem(
                          itemName: 'Premium Avatar Pack',
                          coinCost: 200,
                          diamondCost: 10,
                          description: 'Premium avatars unlocked!',
                        ),
                      ),

                      _buildShopItem(
                        title: 'Lucky Coin',
                        description: 'Increases win rate by 5% for 1 hour',
                        icon: Icons.stars,
                        gradientColors: [
                          Colors.indigo.shade400,
                          Colors.blue.shade600,
                        ],
                        coinCost: 75,
                        diamondCost: 3,
                        onPurchase: () => _purchaseItem(
                          itemName: 'Lucky Coin',
                          coinCost: 75,
                          diamondCost: 3,
                          description: 'Lucky coin activated!',
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          '🪙 Currency Packs',
                          style: TextStyle(
                            fontSize: 24,
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
                      ),
                      const SizedBox(height: 16),

                      _buildShopItem(
                        title: 'Coin Pack Small',
                        description: 'Get 500 bonus coins instantly',
                        icon: Icons.monetization_on,
                        gradientColors: [
                          Colors.yellow.shade400,
                          Colors.amber.shade600,
                        ],
                        coinCost: 0,
                        diamondCost: 1,
                        onPurchase: () {
                          setState(() {
                            _currentCoins += 500;
                            _currentDiamonds -= 1;
                          });
                          widget.onCurrencyUpdate(
                            _currentCoins,
                            _currentDiamonds,
                          );
                        },
                      ),

                      _buildShopItem(
                        title: 'Diamond Pack',
                        description: 'Get 10 premium diamonds',
                        icon: Icons.diamond,
                        gradientColors: [
                          Colors.cyan.shade400,
                          Colors.blue.shade600,
                        ],
                        coinCost: 1000,
                        diamondCost: 0,
                        onPurchase: () {
                          setState(() {
                            _currentCoins -= 1000;
                            _currentDiamonds += 10;
                          });
                          widget.onCurrencyUpdate(
                            _currentCoins,
                            _currentDiamonds,
                          );
                        },
                      ),

                      const SizedBox(height: 40),
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
}

// Daily Spin Dialog
class DailySpinDialog extends StatefulWidget {
  final Function(int coins, int diamonds) onRewardWon;

  const DailySpinDialog({super.key, required this.onRewardWon});

  @override
  State<DailySpinDialog> createState() => _DailySpinDialogState();
}

class _DailySpinDialogState extends State<DailySpinDialog>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  bool _isSpinning = false;
  bool _hasSpun = false;
  int _selectedIndex = 0;

  final List<SpinReward> _rewards = [
    SpinReward(coins: 50, diamonds: 0, color: Colors.blue),
    SpinReward(coins: 100, diamonds: 1, color: Colors.green),
    SpinReward(coins: 25, diamonds: 0, color: Colors.orange),
    SpinReward(coins: 200, diamonds: 0, color: Colors.purple),
    SpinReward(coins: 75, diamonds: 2, color: Colors.red),
    SpinReward(coins: 500, diamonds: 0, color: Colors.amber),
    SpinReward(coins: 150, diamonds: 1, color: Colors.teal),
    SpinReward(coins: 1000, diamonds: 5, color: Colors.pink),
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _spinAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _spinController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning || _hasSpun) return;

    setState(() {
      _isSpinning = true;
      _selectedIndex = Random().nextInt(_rewards.length);
    });

    _spinController.forward().then((_) {
      setState(() {
        _isSpinning = false;
        _hasSpun = true;
      });

      // Award the prize
      final reward = _rewards[_selectedIndex];
      widget.onRewardWon(reward.coins, reward.diamonds);

      // Show result for 2 seconds then close
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.of(context).pop();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade800, Colors.blue.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎯 Daily Spin',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 250,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _spinAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle:
                            _spinAnimation.value * 2 * pi * 5 +
                            (_selectedIndex * 2 * pi / _rewards.length),
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: CustomPaint(
                            painter: SpinWheelPainter(_rewards),
                          ),
                        ),
                      );
                    },
                  ),
                  // Pointer
                  Positioned(
                    top: 10,
                    child: Container(
                      width: 0,
                      height: 0,
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            width: 15,
                            color: Colors.transparent,
                          ),
                          right: BorderSide(
                            width: 15,
                            color: Colors.transparent,
                          ),
                          top: BorderSide(width: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_hasSpun) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎉 You Won!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_rewards[_selectedIndex].coins > 0) ...[
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.yellow,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_rewards[_selectedIndex].coins}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        if (_rewards[_selectedIndex].coins > 0 &&
                            _rewards[_selectedIndex].diamonds > 0)
                          const SizedBox(width: 16),
                        if (_rewards[_selectedIndex].diamonds > 0) ...[
                          const Icon(
                            Icons.diamond,
                            color: Colors.cyan,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_rewards[_selectedIndex].diamonds}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: _spin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple.shade800,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Text(
                  _isSpinning ? 'Spinning...' : 'SPIN!',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (!_hasSpun) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Maybe Later',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Scratch Card Dialog
class ScratchCardDialog extends StatefulWidget {
  final Function(int coins, int diamonds) onRewardWon;

  const ScratchCardDialog({super.key, required this.onRewardWon});

  @override
  State<ScratchCardDialog> createState() => _ScratchCardDialogState();
}

class _ScratchCardDialogState extends State<ScratchCardDialog> {
  final List<bool> _scratched = List.filled(9, false);
  bool _hasWon = false;
  int _matchingSymbol = -1;
  final List<int> _symbols = [];

  @override
  void initState() {
    super.initState();
    _generateSymbols();
  }

  void _generateSymbols() {
    final random = Random();

    // Ensure at least 3 matching symbols for a guaranteed win
    final winningSymbol = random.nextInt(4); // 0-3 (4 different symbols)
    final winningPositions = <int>[];

    // Pick 3 random positions for winning symbols
    while (winningPositions.length < 3) {
      final pos = random.nextInt(9);
      if (!winningPositions.contains(pos)) {
        winningPositions.add(pos);
      }
    }

    // Fill the grid
    for (int i = 0; i < 9; i++) {
      if (winningPositions.contains(i)) {
        _symbols.add(winningSymbol);
      } else {
        _symbols.add(random.nextInt(4));
      }
    }
  }

  void _scratch(int index) {
    if (_scratched[index] || _hasWon) return;

    setState(() {
      _scratched[index] = true;
    });

    _checkForWin();
  }

  void _checkForWin() {
    final symbolCounts = <int, int>{};

    for (int i = 0; i < 9; i++) {
      if (_scratched[i]) {
        symbolCounts[_symbols[i]] = (symbolCounts[_symbols[i]] ?? 0) + 1;
      }
    }

    for (final entry in symbolCounts.entries) {
      if (entry.value >= 3) {
        setState(() {
          _hasWon = true;
          _matchingSymbol = entry.key;
        });

        // Award prize based on symbol
        final rewards = [
          [100, 1], // Symbol 0: 100 coins, 1 diamond
          [200, 2], // Symbol 1: 200 coins, 2 diamonds
          [500, 3], // Symbol 2: 500 coins, 3 diamonds
          [1000, 5], // Symbol 3: 1000 coins, 5 diamonds
        ];

        widget.onRewardWon(
          rewards[_matchingSymbol][0],
          rewards[_matchingSymbol][1],
        );

        // Auto close after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.of(context).pop();
        });
        break;
      }
    }
  }

  Widget _buildScratchCard(int index) {
    final symbols = ['🍒', '🍋', '💎', '⭐'];

    return GestureDetector(
      onTap: () => _scratch(index),
      child: Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Revealed content
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade100],
                  ),
                ),
                child: Center(
                  child: Text(
                    symbols[_symbols[index]],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              // Scratch overlay
              if (!_scratched[index])
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blueGrey, Colors.blueGrey.shade400],
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange.shade800, Colors.red.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '🎫 Scratch Card',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find 3 matching symbols to win!',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                ),
                itemCount: 9,
                itemBuilder: (context, index) => _buildScratchCard(index),
              ),
            ),
            const SizedBox(height: 20),
            if (_hasWon) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      '🎉 Congratulations!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You found 3 matching symbols!',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Helper classes
class SpinReward {
  final int coins;
  final int diamonds;
  final Color color;

  SpinReward({
    required this.coins,
    required this.diamonds,
    required this.color,
  });
}

class SpinWheelPainter extends CustomPainter {
  final List<SpinReward> rewards;

  SpinWheelPainter(this.rewards);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectionAngle = 2 * pi / rewards.length;

    for (int i = 0; i < rewards.length; i++) {
      final paint = Paint()
        ..color = rewards[i].color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sectionAngle - pi / 2,
        sectionAngle,
        true,
        paint,
      );

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sectionAngle - pi / 2,
        sectionAngle,
        true,
        borderPaint,
      );

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${rewards[i].coins}c\n${rewards[i].diamonds}d',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final textAngle = i * sectionAngle + sectionAngle / 2 - pi / 2;
      final textRadius = radius * 0.7;
      final textOffset = Offset(
        center.dx + cos(textAngle) * textRadius - textPainter.width / 2,
        center.dy + sin(textAngle) * textRadius - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
