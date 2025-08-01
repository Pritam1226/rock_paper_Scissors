import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's profile
  final bool isDarkMode;
  final void Function(bool isDark) onThemeToggle;

  const PlayerProfileScreen({
    Key? key,
    this.userId,
    required this.isDarkMode,
    required this.onThemeToggle,
  }) : super(key: key);

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _glowController;
  late AnimationController _badgeController;
  late AnimationController _rankController;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? profileData;
  List<Map<String, dynamic>> achievements = [];
  List<Map<String, dynamic>> matchHistory = [];
  bool isLoading = true;
  bool isOwnProfile = false;

  // Default avatars data
  final List<Map<String, dynamic>> defaultAvatars = [
    {
      'id': 'default_1',
      'name': 'Space Explorer',
      'icon': Icons.rocket_launch,
      'gradient': [Colors.purple, Colors.blue],
    },
    {
      'id': 'default_2',
      'name': 'Gaming Hero',
      'icon': Icons.videogame_asset,
      'gradient': [Colors.green, Colors.teal],
    },
    {
      'id': 'default_3',
      'name': 'Ninja Master',
      'icon': Icons.sports_martial_arts,
      'gradient': [Colors.red, Colors.orange],
    },
    {
      'id': 'default_4',
      'name': 'Tech Wizard',
      'icon': Icons.computer,
      'gradient': [Colors.cyan, Colors.blue],
    },
    {
      'id': 'default_5',
      'name': 'Champion',
      'icon': Icons.emoji_events,
      'gradient': [Colors.amber, Colors.orange],
    },
    {
      'id': 'default_6',
      'name': 'Lightning Fast',
      'icon': Icons.flash_on,
      'gradient': [Colors.yellow, Colors.red],
    },
    {
      'id': 'default_7',
      'name': 'Ice Cool',
      'icon': Icons.ac_unit,
      'gradient': [Colors.lightBlue, Colors.cyan],
    },
    {
      'id': 'default_8',
      'name': 'Fire Spirit',
      'icon': Icons.local_fire_department,
      'gradient': [Colors.deepOrange, Colors.red],
    },
  ];

  // Avatar frames data
  final List<Map<String, dynamic>> avatarFrames = [
    {
      'id': 'none',
      'name': 'No Frame',
      'colors': [Colors.transparent, Colors.transparent],
      'width': 0.0,
      'pattern': 'solid',
    },
    {
      'id': 'bronze',
      'name': 'Bronze Frame',
      'colors': [Colors.brown.shade400, Colors.orange.shade700],
      'width': 4.0,
      'pattern': 'solid',
    },
    {
      'id': 'silver',
      'name': 'Silver Frame',
      'colors': [Colors.grey.shade400, Colors.grey.shade600],
      'width': 4.0,
      'pattern': 'solid',
    },
    {
      'id': 'gold',
      'name': 'Gold Frame',
      'colors': [Colors.yellow.shade400, Colors.orange.shade600],
      'width': 4.0,
      'pattern': 'solid',
    },
    {
      'id': 'rainbow',
      'name': 'Rainbow Frame',
      'colors': [
        Colors.red,
        Colors.orange,
        Colors.yellow,
        Colors.green,
        Colors.blue,
        Colors.purple
      ],
      'width': 5.0,
      'pattern': 'rainbow',
    },
    {
      'id': 'diamond',
      'name': 'Diamond Frame',
      'colors': [Colors.cyan.shade400, Colors.blue.shade600],
      'width': 4.0,
      'pattern': 'dashed',
    },
    {
      'id': 'legendary',
      'name': 'Legendary Frame',
      'colors': [Colors.purple.shade400, Colors.pink.shade600],
      'width': 5.0,
      'pattern': 'glow',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    isOwnProfile =
        widget.userId == null || widget.userId == _auth.currentUser?.uid;

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rankController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _glowController.dispose();
    _badgeController.dispose();
    _rankController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      setState(() => isLoading = true);

      final userId = widget.userId ?? _auth.currentUser!.uid;

      // Load profile data
      final profileDoc = await _firestore
          .collection('player_profiles')
          .doc(userId)
          .get();

      if (profileDoc.exists) {
        profileData = profileDoc.data();
      } else {
        // Create default profile data if not exists
        profileData = {
          'display_name': _auth.currentUser?.email?.split('@')[0] ?? 'Player',
          'user_id': userId.substring(0, 8).toUpperCase(),
          'level': 1,
          'xp': 0,
          'xp_to_next_level': 100,
          'rank': 'Bronze',
          'rank_points': 1000,
          'title': 'Rookie',
          'avatar_url': null,
          'avatar_type': 'default',
          'selected_avatar': 'default_1',
          'selected_frame': 'none',
          'economy': {'coins': 150, 'premium_currency': 25},
          'stats': {
            'total_games': 0,
            'total_wins': 0,
            'total_losses': 0,
            'total_ties': 0,
            'win_rate': 0.0,
            'current_streak': 0,
            'best_win_streak': 0,
            'total_playtime': 0,
            'rock_used': 0,
            'paper_used': 0,
            'scissors_used': 0,
            'rock_wins': 0,
            'paper_wins': 0,
            'scissors_wins': 0,
          },
          'unlocked_achievements': [],
          'settings': {
            'sound_enabled': true,
            'music_enabled': true,
            'auto_rematch': false,
            'show_online_status': true,
            'notifications_enabled': true,
            'coin_notifications': true,
          },
        };
      }

      // Load achievements
      achievements = [
        {
          'id': 'first_win',
          'name': 'First Victory',
          'description': 'Win your first game',
          'icon': 'trophy_bronze',
          'rarity': 'common',
          'is_unlocked': (profileData?['stats']['total_wins'] ?? 0) > 0,
          'rewards': {'coins': 50, 'xp': 100},
        },
        {
          'id': 'win_streak_5',
          'name': 'Hot Streak',
          'description': 'Win 5 games in a row',
          'icon': 'fire_streak',
          'rarity': 'rare',
          'is_unlocked': (profileData?['stats']['best_win_streak'] ?? 0) >= 5,
          'rewards': {'coins': 100, 'xp': 200},
        },
        {
          'id': 'rock_master',
          'name': 'Rock Master',
          'description': 'Win 10 games with Rock',
          'icon': 'rock_master',
          'rarity': 'epic',
          'is_unlocked': (profileData?['stats']['rock_wins'] ?? 0) >= 10,
          'rewards': {'coins': 200, 'xp': 300},
        },
        {
          'id': 'legendary_player',
          'name': 'Legendary Player',
          'description': 'Reach level 10',
          'icon': 'legendary',
          'rarity': 'legendary',
          'is_unlocked': (profileData?['level'] ?? 1) >= 10,
          'rewards': {'coins': 500, 'xp': 1000},
        },
      ];

      // Generate match history data
      matchHistory = [
        {
          'opponent': 'AI Bot',
          'result': 'Win',
          'your_choice': 'Rock',
          'opponent_choice': 'Scissors',
          'date': DateTime.now().subtract(const Duration(hours: 2)),
          'coins_earned': 10,
        },
        {
          'opponent': 'Player123',
          'result': 'Loss',
          'your_choice': 'Paper',
          'opponent_choice': 'Scissors',
          'date': DateTime.now().subtract(const Duration(days: 1)),
          'coins_earned': 0,
        },
      ];

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => isLoading = false);
    }
  }

  void _showAvatarEditor() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurple.shade800,
                  Colors.indigo.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(18),
                      topRight: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Customize Avatar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        // Tab Bar
                        Container(
                          color: Colors.white.withOpacity(0.05),
                          child: const TabBar(
                            indicatorColor: Color(0xFFffa726),
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white60,
                            tabs: [
                              Tab(text: 'Avatars'),
                              Tab(text: 'Frames'),
                            ],
                          ),
                        ),

                        // Tab Views
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildAvatarSelection(),
                              _buildFrameSelection(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.amber.shade400, Colors.orange.shade500],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _saveAvatarChanges();
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatarSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.8,
        ),
        itemCount: defaultAvatars.length,
        itemBuilder: (context, index) {
          final avatar = defaultAvatars[index];
          final isSelected = profileData?['selected_avatar'] == avatar['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                profileData?['selected_avatar'] = avatar['id'];
                profileData?['avatar_type'] = 'default';
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [Colors.amber.shade400, Colors.orange.shade500]
                      : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? Colors.amber
                      : Colors.white.withOpacity(0.3),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: avatar['gradient'],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        avatar['icon'],
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    flex: 1,
                    child: Text(
                      avatar['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: Colors.amber,
                      size: 16,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFrameSelection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: avatarFrames.length,
        itemBuilder: (context, index) {
          final frame = avatarFrames[index];
          final isSelected = profileData?['selected_frame'] == frame['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                profileData?['selected_frame'] = frame['id'];
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isSelected
                      ? [Colors.amber.shade400, Colors.orange.shade500]
                      : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected
                      ? Colors.amber
                      : Colors.white.withOpacity(0.3),
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildFramePreview(frame),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    frame['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFramePreview(Map<String, dynamic> frame) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: frame['id'] == 'none'
            ? null
            : frame['pattern'] == 'rainbow'
                ? _buildRainbowBorder(frame['width'])
                : Border.all(
                    color: frame['colors'].length >= 2
                        ? frame['colors'][0]
                        : Colors.grey,
                    width: frame['width'],
                  ),
        gradient: frame['id'] != 'none' && frame['pattern'] != 'rainbow'
            ? LinearGradient(
                colors: frame['colors'].length >= 2
                    ? [frame['colors'][0], frame['colors'][1]]
                    : [Colors.grey, Colors.grey.shade600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Container(
        margin: EdgeInsets.all(frame['width']),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white24,
        ),
        child: const Icon(
          Icons.person,
          color: Colors.white54,
          size: 24,
        ),
      ),
    );
  }

  BoxBorder _buildRainbowBorder(double width) {
    return Border.all(
      width: width,
      color: Colors.transparent,
    );
  }

  void _saveAvatarChanges() {
    // Here you would typically save to Firebase
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avatar updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Helper methods for rank colors and icons
  List<Color> _getRankColors(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze':
        return [Colors.brown.shade400, Colors.orange.shade700];
      case 'silver':
        return [Colors.grey.shade400, Colors.grey.shade600];
      case 'gold':
        return [Colors.yellow.shade400, Colors.orange.shade600];
      case 'platinum':
        return [Colors.cyan.shade400, Colors.blue.shade600];
      case 'diamond':
        return [Colors.blue.shade400, Colors.purple.shade600];
      case 'master':
        return [Colors.purple.shade400, Colors.pink.shade600];
      case 'grandmaster':
        return [Colors.pink.shade400, Colors.red.shade600];
      default:
        return [Colors.brown.shade400, Colors.orange.shade700];
    }
  }

  IconData _getRankIcon(String rank) {
    switch (rank.toLowerCase()) {
      case 'bronze':
        return Icons.emoji_events;
      case 'silver':
        return Icons.military_tech;
      case 'gold':
        return Icons.workspace_premium;
      case 'platinum':
        return Icons.diamond;
      case 'diamond':
        return Icons.auto_awesome;
      case 'master':
        return Icons.star;
      case 'grandmaster':
        return Icons.stars;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey.shade500;
      case 'rare':
        return Colors.blue.shade500;
      case 'epic':
        return Colors.purple.shade500;
      case 'legendary':
        return Colors.orange.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  List<Color> _getRarityGradient(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return [Colors.grey.shade400, Colors.grey.shade600];
      case 'rare':
        return [Colors.blue.shade400, Colors.indigo.shade600];
      case 'epic':
        return [Colors.purple.shade400, Colors.pink.shade600];
      case 'legendary':
        return [Colors.orange.shade400, Colors.red.shade600];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  IconData _getAchievementIcon(String iconName) {
    switch (iconName) {
      case 'trophy_bronze':
        return Icons.emoji_events;
      case 'fire_streak':
        return Icons.local_fire_department;
      case 'rock_master':
        return Icons.gesture;
      case 'legendary':
        return Icons.auto_awesome;
      default:
        return Icons.emoji_events;
    }
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(
      text: profileData?['display_name'] ?? '',
    );

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
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 12),
              Text(
                'Edit Profile',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.person),
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
                  colors: [Colors.blue.shade400, Colors.purple.shade500],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () {
                  // Update profile logic here
                  setState(() {
                    profileData?['display_name'] = nameController.text;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text(
                  'Save',
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

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile sharing feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFffa726),
              strokeWidth: 3,
            ),
          ),
        ),
      );
    }

    if (profileData == null) {
      return Scaffold(
        body: Container(
          decoration: _buildGradientBackground(),
          child: const Center(
            child: Text(
              'Profile not found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: _buildGradientBackground(),
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildPlayerCard(),
                  _buildStatsCards(),
                  _buildAchievementBadges(),
                  _buildTabSection(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildGradientBackground() {
    return BoxDecoration(
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
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 100,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          '👤 Player Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
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
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.3), Colors.transparent],
            ),
          ),
        ),
      ),
      actions: [
        if (isOwnProfile)
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit, color: Colors.white),
              onPressed: _showEditProfileDialog,
            ),
          ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: _shareProfile,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard() {
    final stats = profileData!['stats'] ?? {};
    final economy = profileData!['economy'] ?? {};

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.2),
                Colors.white.withOpacity(0.1),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(
                  0.1 + (_glowController.value * 0.2),
                ),
                blurRadius: 20 + (_glowController.value * 10),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Avatar and Basic Info Row
              Row(
                children: [
                  _buildAnimatedAvatar(),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profileData!['display_name'] ?? 'Unknown Player',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
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
                        const SizedBox(height: 4),
                        _buildUserIdChip(),
                        const SizedBox(height: 8),
                        _buildRankBadge(),
                        const SizedBox(height: 12),
                        _buildLevelProgress(),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Currency Display
              Row(
                children: [
                  Expanded(
                    child: _buildCurrencyCard(
                      'Coins',
                      '${economy['coins'] ?? 0}',
                      Icons.monetization_on,
                      [Colors.amber.shade400, Colors.orange.shade500],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCurrencyCard(
                      'Diamonds',
                      '${economy['premium_currency'] ?? 0}',
                      Icons.diamond,
                      [Colors.cyan.shade400, Colors.blue.shade500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimatedAvatar() {
    final selectedFrame = profileData?['selected_frame'] ?? 'none';
    final selectedAvatar = profileData?['selected_avatar'] ?? 'default_1';
    final avatarType = profileData?['avatar_type'] ?? 'default';
    
    final frameData = avatarFrames.firstWhere(
      (frame) => frame['id'] == selectedFrame,
      orElse: () => avatarFrames[0],
    );

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Stack(
          children: [
            // Avatar with frame
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: selectedFrame == 'none'
                    ? null
                    : selectedFrame == 'rainbow'
                        ? _buildAnimatedRainbowBorder()
                        : Border.all(
                            color: frameData['colors'].isNotEmpty
                                ? frameData['colors'][0]
                                : Colors.transparent,
                            width: frameData['width'],
                          ),
                gradient: selectedFrame != 'none' && selectedFrame != 'rainbow'
                    ? LinearGradient(
                        colors: frameData['colors'].length >= 2
                            ? [frameData['colors'][0], frameData['colors'][1]]
                            : [Colors.grey, Colors.grey.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                boxShadow: selectedFrame == 'legendary'
                    ? [
                        BoxShadow(
                          color: Colors.purple.withOpacity(
                            0.4 + (_glowController.value * 0.3),
                          ),
                          blurRadius: 20 + (_glowController.value * 10),
                          spreadRadius: 3,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.amber.withOpacity(
                            0.3 + (_glowController.value * 0.2),
                          ),
                          blurRadius: 15 + (_glowController.value * 5),
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Container(
                margin: EdgeInsets.all(selectedFrame == 'none' ? 0 : frameData['width']),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: ClipOval(
                  child: avatarType == 'custom' && profileData!['avatar_url'] != null
                      ? CachedNetworkImage(
                          imageUrl: profileData!['avatar_url'],
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(),
                          errorWidget: (context, url, error) =>
                              _buildDefaultAvatarIcon(selectedAvatar),
                        )
                      : _buildDefaultAvatarIcon(selectedAvatar),
                ),
              ),
            ),
            
            // Edit button (only for own profile)
            if (isOwnProfile)
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _showAvatarEditor,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade400, Colors.orange.shade500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  BoxBorder _buildAnimatedRainbowBorder() {
    return Border.all(
      width: 5,
      color: HSVColor.fromAHSV(
        1.0,
        (_glowController.value * 360) % 360,
        1.0,
        1.0,
      ).toColor(),
    );
  }

  Widget _buildDefaultAvatarIcon(String avatarId) {
    final avatar = defaultAvatars.firstWhere(
      (a) => a['id'] == avatarId,
      orElse: () => defaultAvatars[0],
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: avatar['gradient'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(
        avatar['icon'],
        size: 50,
        color: Colors.white,
      ),
    );
  }

  Widget _buildUserIdChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.fingerprint, color: Colors.cyan, size: 16),
          const SizedBox(width: 6),
          Text(
            'ID: ${profileData!['user_id'] ?? 'UNKNOWN'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge() {
    final rank = profileData!['rank'] ?? 'Bronze';
    final rankPoints = profileData!['rank_points'] ?? 1000;

    return AnimatedBuilder(
      animation: _rankController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _getRankColors(rank),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _getRankColors(
                  rank,
                ).first.withOpacity(0.3 + (_rankController.value * 0.2)),
                blurRadius: 8 + (_rankController.value * 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getRankIcon(rank), color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$rankPoints RP',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelProgress() {
    final level = profileData!['level'] ?? 1;
    final xp = profileData!['xp'] ?? 0;
    final xpToNext = profileData!['xp_to_next_level'] ?? 100;
    final progress = xpToNext > 0 ? (xp % xpToNext) / xpToNext : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $level',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$xp / $xpToNext XP',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyCard(
    String label,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    final stats = profileData!['stats'] ?? {};

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Games',
              '${stats['total_games'] ?? 0}',
              Icons.gamepad,
              [Colors.purple.shade400, Colors.indigo.shade500],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Wins',
              '${stats['total_wins'] ?? 0}',
              Icons.emoji_events,
              [Colors.green.shade400, Colors.teal.shade500],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Win Rate',
              '${(stats['win_rate'] ?? 0).toStringAsFixed(1)}%',
              Icons.trending_up,
              [Colors.orange.shade400, Colors.red.shade500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    List<Color> colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadges() {
    final unlockedAchievements = achievements
        .where((a) => a['is_unlocked'] == true)
        .toList();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              const Text(
                '🏆 Achievement Badges',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${unlockedAchievements.length}/${achievements.length}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (unlockedAchievements.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: const Center(
                child: Text(
                  '🎯 No achievements unlocked yet!\nStart playing to earn badges!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: unlockedAchievements.map((achievement) {
                return _buildAchievementBadge(achievement);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildAchievementBadge(Map<String, dynamic> achievement) {
    return AnimatedBuilder(
      animation: _badgeController,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => _showAchievementDetails(achievement),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _getRarityGradient(achievement['rarity']),
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: _getRarityColor(
                    achievement['rarity'],
                  ).withOpacity(0.3 + (_badgeController.value * 0.2)),
                  blurRadius: 8 + (_badgeController.value * 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getAchievementIcon(achievement['icon']),
                  size: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Text(
                  achievement['name'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getRarityGradient(achievement['rarity']),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getAchievementIcon(achievement['icon']),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  achievement['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                achievement['description'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _getRarityGradient(achievement['rarity']),
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  achievement['rarity'].toString().toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Rewards:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '• ${achievement['rewards']['coins']} Coins\n• ${achievement['rewards']['xp']} XP',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _getRarityGradient(achievement['rarity']),
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

  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFFffa726),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Stats'),
                Tab(text: 'Achievements'),
                Tab(text: 'History'),
                Tab(text: 'Settings'),
              ],
            ),
          ),
          Container(
            height: 300,
            padding: const EdgeInsets.all(16),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatsTab(),
                _buildAchievementsTab(),
                _buildMatchHistoryTab(),
                _buildSettingsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final stats = profileData!['stats'] ?? {};

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDetailedStatsCard('Overall Statistics', {
            'Total Games': stats['total_games'] ?? 0,
            'Total Wins': stats['total_wins'] ?? 0,
            'Total Losses': stats['total_losses'] ?? 0,
            'Total Ties': stats['total_ties'] ?? 0,
            'Win Rate': '${(stats['win_rate'] ?? 0).toStringAsFixed(1)}%',
            'Current Streak': stats['current_streak'] ?? 0,
            'Best Streak': stats['best_win_streak'] ?? 0,
            'Playtime':
                '${((stats['total_playtime'] ?? 0) / 60).toStringAsFixed(1)} hours',
          }),
          const SizedBox(height: 16),
          _buildDetailedStatsCard('Choice Statistics', {
            'Rock Used': stats['rock_used'] ?? 0,
            'Paper Used': stats['paper_used'] ?? 0,
            'Scissors Used': stats['scissors_used'] ?? 0,
            'Rock Wins': stats['rock_wins'] ?? 0,
            'Paper Wins': stats['paper_wins'] ?? 0,
            'Scissors Wins': stats['scissors_wins'] ?? 0,
          }),
        ],
      ),
    );
  }

  Widget _buildDetailedStatsCard(String title, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return SingleChildScrollView(
      child: Column(
        children: achievements.map((achievement) {
          final isUnlocked = achievement['is_unlocked'] == true;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isUnlocked
                    ? _getRarityColor(achievement['rarity']).withOpacity(0.5)
                    : Colors.grey.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isUnlocked
                        ? LinearGradient(
                            colors: _getRarityGradient(achievement['rarity']),
                          )
                        : LinearGradient(
                            colors: [
                              Colors.grey.shade400,
                              Colors.grey.shade600,
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getAchievementIcon(achievement['icon']),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement['name'] ?? '',
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white54,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement['description'] ?? '',
                        style: TextStyle(
                          color: isUnlocked ? Colors.white70 : Colors.white38,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              gradient: isUnlocked
                                  ? LinearGradient(
                                      colors: _getRarityGradient(
                                        achievement['rarity'],
                                      ),
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.shade400,
                                        Colors.grey.shade600,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              achievement['rarity'].toString().toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isUnlocked)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 20,
                            )
                          else
                            const Icon(
                              Icons.lock,
                              color: Colors.grey,
                              size: 20,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMatchHistoryTab() {
    if (matchHistory.isEmpty) {
      return const Center(
        child: Text(
          '🎮 No matches played yet!\nStart playing to see your history here.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: matchHistory.map((match) {
          final isWin = match['result'] == 'Win';
          final isTie = match['result'] == 'Tie';

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isWin
                    ? Colors.green.withOpacity(0.5)
                    : isTie
                    ? Colors.orange.withOpacity(0.5)
                    : Colors.red.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isWin
                        ? Colors.green.withOpacity(0.2)
                        : isTie
                        ? Colors.orange.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isWin
                        ? Icons.emoji_events
                        : isTie
                        ? Icons.handshake
                        : Icons.close,
                    color: isWin
                        ? Colors.green
                        : isTie
                        ? Colors.orange
                        : Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'vs ${match['opponent']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            match['result'],
                            style: TextStyle(
                              color: isWin
                                  ? Colors.green
                                  : isTie
                                  ? Colors.orange
                                  : Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${match['your_choice']} vs ${match['opponent_choice']}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDate(match['date']),
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          if (match['coins_earned'] > 0)
                            Text(
                              '+${match['coins_earned']} coins',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildSettingsTab() {
    final settings = profileData!['settings'] ?? {};

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSettingTile(
            'Sound Effects',
            'Enable game sound effects',
            Icons.volume_up,
            settings['sound_enabled'] ?? true,
            (value) {
              setState(() {
                profileData!['settings']['sound_enabled'] = value;
              });
            },
          ),
          _buildSettingTile(
            'Background Music',
            'Enable background music',
            Icons.music_note,
            settings['music_enabled'] ?? true,
            (value) {
              setState(() {
                profileData!['settings']['music_enabled'] = value;
              });
            },
          ),
          _buildSettingTile(
            'Auto Rematch',
            'Automatically start rematch',
            Icons.refresh,
            settings['auto_rematch'] ?? false,
            (value) {
              setState(() {
                profileData!['settings']['auto_rematch'] = value;
              });
            },
          ),
          _buildSettingTile(
            'Show Online Status',
            'Display your online status',
            Icons.circle,
            settings['show_online_status'] ?? true,
            (value) {
              setState(() {
                profileData!['settings']['show_online_status'] = value;
              });
            },
          ),
          _buildSettingTile(
            'Notifications',
            'Enable push notifications',
            Icons.notifications,
            settings['notifications_enabled'] ?? true,
            (value) {
              setState(() {
                profileData!['settings']['notifications_enabled'] = value;
              });
            },
          ),
          _buildSettingTile(
            'Coin Notifications',
            'Notify when earning coins',
            Icons.monetization_on,
            settings['coin_notifications'] ?? true,
            (value) {
              setState(() {
                profileData!['settings']['coin_notifications'] = value;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.purple.shade500],
              ),
              borderRadius: BorderRadius.circular(12),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.grey,
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }
}