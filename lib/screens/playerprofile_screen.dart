import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PlayerProfileScreen extends StatefulWidget {
  final String? userId; // If null, shows current user's profile
  
  const PlayerProfileScreen({Key? key, this.userId, required bool isDarkMode, required void Function(bool isDark) onThemeToggle}) : super(key: key);

  @override
  State<PlayerProfileScreen> createState() => _PlayerProfileScreenState();
}

class _PlayerProfileScreenState extends State<PlayerProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  Map<String, dynamic>? profileData;
  List<Map<String, dynamic>> achievements = [];
  List<Map<String, dynamic>> matchHistory = [];
  bool isLoading = true;
  bool isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    isOwnProfile = widget.userId == null || widget.userId == _auth.currentUser?.uid;
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      }

      // Load achievements
      final achievementsQuery = await _firestore
          .collection('achievements')
          .orderBy('unlock_order')
          .get();
      
      achievements = achievementsQuery.docs.map((doc) => {
        ...doc.data(),
        'is_unlocked': profileData?['unlocked_achievements']?.contains(doc.id) ?? false,
      }).toList();

      // Load recent match history
      if (profileData != null) {
        final matchQuery = await _firestore
            .collection('match_history')
            .where('players', arrayContainsAny: [{'user_id': userId}])
            .orderBy('completed_at', descending: true)
            .limit(10)
            .get();
        
        matchHistory = matchQuery.docs.map((doc) => doc.data()).toList();
      }

      setState(() => isLoading = false);
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF16213e)),
        ),
      );
    }

    if (profileData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: const Center(
          child: Text(
            'Profile not found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverFillRemaining(
            child: Column(
              children: [
                _buildProfileHeader(),
                _buildTabBar(),
                Expanded(
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
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF16213e),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF16213e), Color(0xFF1a1a2e)],
            ),
          ),
        ),
      ),
      actions: [
        if (isOwnProfile)
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _showEditProfileDialog,
          ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareProfile,
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final economy = profileData!['economy'] ?? {};
    final stats = profileData!['stats'] ?? {};
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Avatar and basic info
          Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileData!['display_name'] ?? 'Unknown Player',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      profileData!['title'] ?? 'Rookie',
                      style: const TextStyle(
                        color: Color(0xFFffa726),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildLevelProgress(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Economy info
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color(0xFF16213e),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildEconomyItem(
                  'Coins',
                  '${economy['coins'] ?? 0}',
                  Icons.monetization_on,
                  const Color(0xFFffa726),
                ),
                _buildEconomyItem(
                  'Gems',
                  '${economy['premium_currency'] ?? 0}',
                  Icons.diamond,
                  const Color(0xFF42a5f5),
                ),
                _buildEconomyItem(
                  'Level',
                  '${profileData!['level'] ?? 1}',
                  Icons.star,
                  const Color(0xFF66bb6a),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Quick stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat('Games', '${stats['total_games'] ?? 0}'),
              _buildQuickStat('Wins', '${stats['total_wins'] ?? 0}'),
              _buildQuickStat('Win Rate', '${(stats['win_rate'] ?? 0).toStringAsFixed(1)}%'),
              _buildQuickStat('Streak', '${stats['current_streak'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFffa726), width: 3),
      ),
      child: ClipOval(
        child: profileData!['avatar_url'] != null
            ? CachedNetworkImage(
                imageUrl: profileData!['avatar_url'],
                fit: BoxFit.cover,
                placeholder: (context, url) => const CircularProgressIndicator(),
                errorWidget: (context, url, error) => _buildDefaultAvatar(),
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: const Color(0xFF16213e),
      child: const Icon(
        Icons.person,
        size: 40,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLevelProgress() {
    final xp = profileData!['xp'] ?? 0;
    final xpToNext = profileData!['xp_to_next_level'] ?? 100;
    final progress = xpToNext > 0 ? (xp % xpToNext) / xpToNext : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'XP: $xp',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 5),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[800],
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66bb6a)),
        ),
      ],
    );
  }

  Widget _buildEconomyItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 30),
        const SizedBox(height: 5),
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
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
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
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFF16213e),
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFffa726),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        tabs: const [
          Tab(text: 'Stats'),
          Tab(text: 'Achievements'),
          Tab(text: 'History'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final stats = profileData!['stats'] ?? {};
    final vsComputer = stats['vs_computer'] ?? {};
    final localMultiplayer = stats['local_multiplayer'] ?? {};
    final onlineMultiplayer = stats['online_multiplayer'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsSection('Overall Statistics', {
            'Total Games': stats['total_games'] ?? 0,
            'Total Wins': stats['total_wins'] ?? 0,
            'Total Losses': stats['total_losses'] ?? 0,
            'Total Ties': stats['total_ties'] ?? 0,
            'Win Rate': '${(stats['win_rate'] ?? 0).toStringAsFixed(1)}%',
            'Best Streak': stats['best_win_streak'] ?? 0,
            'Playtime': '${((stats['total_playtime'] ?? 0) / 60).toStringAsFixed(1)} hours',
          }),
          
          const SizedBox(height: 20),
          
          _buildStatsSection('Choice Statistics', {
            'Rock Used': stats['rock_used'] ?? 0,
            'Paper Used': stats['paper_used'] ?? 0,
            'Scissors Used': stats['scissors_used'] ?? 0,
            'Rock Wins': stats['rock_wins'] ?? 0,
            'Paper Wins': stats['paper_wins'] ?? 0,
            'Scissors Wins': stats['scissors_wins'] ?? 0,
          }),
          
          const SizedBox(height: 20),
          
          _buildStatsSection('VS Computer', {
            'Games': vsComputer['games'] ?? 0,
            'Wins': vsComputer['wins'] ?? 0,
            'Losses': vsComputer['losses'] ?? 0,
            'Ties': vsComputer['ties'] ?? 0,
          }),
          
          const SizedBox(height: 20),
          
          _buildStatsSection('Local Multiplayer', {
            'Games': localMultiplayer['games'] ?? 0,
            'Wins': localMultiplayer['wins'] ?? 0,
            'Losses': localMultiplayer['losses'] ?? 0,
            'Ties': localMultiplayer['ties'] ?? 0,
          }),
          
          const SizedBox(height: 20),
          
          _buildStatsSection('Online Multiplayer', {
            'Games': onlineMultiplayer['games'] ?? 0,
            'Wins': onlineMultiplayer['wins'] ?? 0,
            'Losses': onlineMultiplayer['losses'] ?? 0,
            'Ties': onlineMultiplayer['ties'] ?? 0,
            'Rating': onlineMultiplayer['rating'] ?? 1000,
            'Rank': onlineMultiplayer['rank'] ?? 'Unranked',
          }),
        ],
      ),
    );
  }

  Widget _buildStatsSection(String title, Map<String, dynamic> stats) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
      ),
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
          const SizedBox(height: 15),
          ...stats.entries.map((entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
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
          )),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = achievement['is_unlocked'] ?? false;
        
        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isUnlocked ? const Color(0xFF16213e) : const Color(0xFF0f0f23),
            borderRadius: BorderRadius.circular(15),
            border: isUnlocked
                ? Border.all(color: _getRarityColor(achievement['rarity']), width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getAchievementIcon(achievement['icon']),
                size: 40,
                color: isUnlocked
                    ? _getRarityColor(achievement['rarity'])
                    : Colors.grey,
              ),
              const SizedBox(height: 10),
              Text(
                achievement['name'] ?? '',
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                achievement['description'] ?? '',
                style: TextStyle(
                  color: isUnlocked ? Colors.white70 : Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (isUnlocked && achievement['rewards'] != null) ...[
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (achievement['rewards']['coins'] != null) ...[
                      const Icon(Icons.monetization_on, color: Color(0xFFffa726), size: 16),
                      Text(
                        ' ${achievement['rewards']['coins']}',
                        style: const TextStyle(color: Color(0xFFffa726), fontSize: 12),
                      ),
                    ],
                    if (achievement['rewards']['xp'] != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.star, color: Color(0xFF66bb6a), size: 16),
                      Text(
                        ' ${achievement['rewards']['xp']}',
                        style: const TextStyle(color: Color(0xFF66bb6a), fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMatchHistoryTab() {
    if (matchHistory.isEmpty) {
      return const Center(
        child: Text(
          'No match history available',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: matchHistory.length,
      itemBuilder: (context, index) {
        final match = matchHistory[index];
        final isWinner = match['winner_id'] == (widget.userId ?? _auth.currentUser!.uid);
        final mode = match['mode'] ?? 'Unknown';
        final duration = match['duration'] ?? 0;
        final coinsEarned = match['players']
            ?.firstWhere((p) => p['user_id'] == (widget.userId ?? _auth.currentUser!.uid),
                orElse: () => {'coins_earned': 0})['coins_earned'] ?? 0;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF16213e),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isWinner ? const Color(0xFF66bb6a) : const Color(0xFFf44336),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isWinner ? 'VICTORY' : 'DEFEAT',
                    style: TextStyle(
                      color: isWinner ? const Color(0xFF66bb6a) : const Color(0xFFf44336),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatGameMode(mode),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Duration: ${_formatDuration(duration)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  if (coinsEarned > 0)
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, color: Color(0xFFffa726), size: 16),
                        Text(
                          ' +$coinsEarned',
                          style: const TextStyle(color: Color(0xFFffa726), fontSize: 12),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    if (!isOwnProfile) {
      return const Center(
        child: Text(
          'Settings not available for other players',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }
    
    final settings = profileData!['settings'] ?? {};
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildSettingsSection('Game Settings', [
          _buildSwitchTile(
            'Sound Effects',
            settings['sound_enabled'] ?? true,
            (value) => _updateSetting('sound_enabled', value),
          ),
          _buildSwitchTile(
            'Background Music',
            settings['music_enabled'] ?? true,
            (value) => _updateSetting('music_enabled', value),
          ),
          _buildSwitchTile(
            'Auto Rematch',
            settings['auto_rematch'] ?? false,
            (value) => _updateSetting('auto_rematch', value),
          ),
        ]),
        
        const SizedBox(height: 20),
        
        _buildSettingsSection('Privacy Settings', [
          _buildSwitchTile(
            'Show Online Status',
            settings['show_online_status'] ?? true,
            (value) => _updateSetting('show_online_status', value),
          ),
          _buildSwitchTile(
            'Push Notifications',
            settings['notifications_enabled'] ?? true,
            (value) => _updateSetting('notifications_enabled', value),
          ),
          _buildSwitchTile(
            'Coin Notifications',
            settings['coin_notifications'] ?? true,
            (value) => _updateSetting('coin_notifications', value),
          ),
        ]),
        
        const SizedBox(height: 20),
        
        _buildSettingsSection('Account', [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
            onTap: _signOut,
          ),
        ]),
      ],
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(15),
      ),
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
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.white)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFffa726),
    );
  }

  Color _getRarityColor(String? rarity) {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFffa726);
      case 'epic':
        return const Color(0xFF9c27b0);
      case 'rare':
        return const Color(0xFF2196f3);
      default:
        return const Color(0xFF66bb6a);
    }
  }

  IconData _getAchievementIcon(String? icon) {
    switch (icon) {
      case 'trophy_bronze':
        return Icons.emoji_events;
      case 'fire_streak':
        return Icons.local_fire_department;
      case 'rock_master':
        return Icons.landscape;
      default:
        return Icons.star;
    }
  }

  String _formatGameMode(String mode) {
    switch (mode) {
      case 'vs_computer':
        return 'VS Computer';
      case 'local_multiplayer':
        return 'Local Multiplayer';
      case 'online_multiplayer':
        return 'Online Multiplayer';
      default:
        return 'Unknown Mode';
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  void _showEditProfileDialog() {
    // Implement edit profile dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: const Text('Profile editing feature coming soon!',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFFffa726))),
          ),
        ],
      ),
    );
  }

  void _shareProfile() {
    // Implement profile sharing
    print('Sharing profile...');
  }

  Future<void> _updateSetting(String key, bool value) async {
    try {
      await _firestore
          .collection('player_profiles')
          .doc(_auth.currentUser!.uid)
          .update({'settings.$key': value});
      
      setState(() {
        profileData!['settings'][key] = value;
      });
    } catch (e) {
      print('Error updating setting: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Error signing out: $e');
    }
  }
}