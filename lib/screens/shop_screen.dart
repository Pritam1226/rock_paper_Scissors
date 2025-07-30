import 'package:flutter/material.dart';

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
  late int _currentCoins;
  late int _currentDiamonds;

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
  }

  @override
  void dispose() {
    _glowController?.dispose();
    _pulseController?.dispose();
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

  Widget _buildCurrencyHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade300,
            Colors.orange.shade400,
          ],
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
          Container(
            width: 2,
            height: 60,
            color: Colors.white.withOpacity(0.3),
          ),
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

  Widget _buildShopItem({
    required String title,
    required String description,
    required IconData icon,
    required List<Color> gradientColors,
    required int coinCost,
    required int diamondCost,
    required VoidCallback onPurchase,
  }) {
    final canAfford = _currentCoins >= coinCost && _currentDiamonds >= diamondCost;

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
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 32,
                          ),
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
                                  color: canAfford ? Colors.white : Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: canAfford ? Colors.white.withOpacity(0.9) : Colors.white60,
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
                                color: canAfford ? Colors.yellow.shade300 : Colors.grey.shade300,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$coinCost',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford ? Colors.white : Colors.white60,
                                ),
                              ),
                            ],
                            if (coinCost > 0 && diamondCost > 0)
                              const SizedBox(width: 16),
                            if (diamondCost > 0) ...[
                              Icon(
                                Icons.diamond,
                                color: canAfford ? Colors.cyan.shade300 : Colors.grey.shade300,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$diamondCost',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford ? Colors.white : Colors.white60,
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
                        gradientColors: [Colors.amber.shade400, Colors.orange.shade600],
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
                        gradientColors: [Colors.green.shade400, Colors.teal.shade600],
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
                        gradientColors: [Colors.purple.shade400, Colors.pink.shade600],
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
                        gradientColors: [Colors.indigo.shade400, Colors.blue.shade600],
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
                        gradientColors: [Colors.yellow.shade400, Colors.amber.shade600],
                        coinCost: 0,
                        diamondCost: 1,
                        onPurchase: () {
                          setState(() {
                            _currentCoins += 500;
                            _currentDiamonds -= 1;
                          });
                          widget.onCurrencyUpdate(_currentCoins, _currentDiamonds);
                        },
                      ),

                      _buildShopItem(
                        title: 'Diamond Pack',
                        description: 'Get 10 premium diamonds',
                        icon: Icons.diamond,
                        gradientColors: [Colors.cyan.shade400, Colors.blue.shade600],
                        coinCost: 1000,
                        diamondCost: 0,
                        onPurchase: () {
                          setState(() {
                            _currentCoins -= 1000;
                            _currentDiamonds += 10;
                          });
                          widget.onCurrencyUpdate(_currentCoins, _currentDiamonds);
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