// screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/achievement_models.dart';
import '../services/achievement_service.dart';
import '../services/audio_service.dart';
import 'dart:math' as math;

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundController;
  late AnimationController _heroController;
  late TabController _tabController;
  
  AchievementCategory _selectedCategory = AchievementCategory.score;
  String _searchQuery = '';
  bool _showOnlyUnlocked = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _tabController = TabController(length: 6, vsync: this);
  }

  void _setupAnimations() {
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    )..repeat();

    _heroController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _heroController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Stats summary
                _buildStatsHeader(),
                
                // Category tabs
                _buildCategoryTabs(),
                
                // Achievements list
                Expanded(
                  child: _buildAchievementsList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Colors.grey.shade900,
                Colors.purple.shade900.withOpacity(0.3),
                Colors.black,
              ],
              stops: [
                0.0,
                0.3 + _backgroundController.value * 0.1,
                0.7 + _backgroundController.value * 0.1,
                1.0,
              ],
            ),
          ),
          child: CustomPaint(
            painter: AchievementBackgroundPainter(
              animation: _backgroundController,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              context.read<AudioService>().playUIClick();
              Navigator.of(context).pop();
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.purple.withOpacity(0.5), width: 2),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.purple,
                size: 24,
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber,
                      size: 28,
                    ).animate(controller: _heroController)
                      .scale(duration: 600.ms, curve: Curves.elasticOut)
                      .then()
                      .shimmer(duration: 2000.ms, color: Colors.amber.withOpacity(0.5)),
                    
                    const SizedBox(width: 12),
                    
                    const Text(
                      'ACHIEVEMENTS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ).animate(controller: _heroController)
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideX(begin: -0.3, end: 0),
                  ],
                ),
                
                const Text(
                  'Track your progress and unlock rewards',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ).animate(controller: _heroController)
                  .fadeIn(delay: 400.ms, duration: 400.ms),
              ],
            ),
          ),
          
          // Filter button
          IconButton(
            onPressed: () => _showFilterDialog(),
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.cyan.withOpacity(0.5), width: 2),
              ),
              child: Icon(
                _showOnlyUnlocked ? Icons.filter_alt : Icons.filter_alt_outlined,
                color: Colors.cyan,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.purple.shade800.withOpacity(0.8),
                Colors.blue.shade800.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.purple.withOpacity(0.5), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Unlocked',
                  '${achievementService.unlockedCount}/${achievementService.totalCount}',
                  Icons.lock_open,
                  Colors.green,
                ),
              ),
              
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              
              Expanded(
                child: _buildStatItem(
                  'Points',
                  '${achievementService.totalPoints}',
                  Icons.stars,
                  Colors.amber,
                ),
              ),
              
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.3),
              ),
              
              Expanded(
                child: _buildStatItem(
                  'Progress',
                  '${(achievementService.completionPercentage * 100).toInt()}%',
                  Icons.trending_up,
                  Colors.cyan,
                ),
              ),
            ],
          ),
        ).animate(controller: _heroController)
          .fadeIn(delay: 600.ms, duration: 600.ms)
          .slideY(begin: 0.3, end: 0);
      },
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
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
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withOpacity(0.3), width: 1),
      ),
      child: TabBar(
        controller: _tabController,
        onTap: (index) {
          context.read<AudioService>().playUIClick();
          setState(() {
            _selectedCategory = AchievementCategory.values[index];
          });
        },
        isScrollable: true,
        indicator: BoxDecoration(
          color: Colors.purple.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        tabs: AchievementCategory.values.map((category) {
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getCategoryIcon(category), size: 16),
                const SizedBox(width: 6),
                Text(_getCategoryName(category)),
              ],
            ),
          );
        }).toList(),
      ),
    ).animate(controller: _heroController)
      .fadeIn(delay: 800.ms, duration: 400.ms);
  }

  Widget _buildAchievementsList() {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        var achievements = achievementService.getAchievementsByCategory(_selectedCategory);
        
        // Apply filters
        if (_showOnlyUnlocked) {
          achievements = achievements.where((a) => a.isUnlocked).toList();
        }
        
        if (_searchQuery.isNotEmpty) {
          achievements = achievements.where((a) => 
            a.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            a.description.toLowerCase().contains(_searchQuery.toLowerCase())
          ).toList();
        }
        
        // Sort: unlocked first, then by rarity
        achievements.sort((a, b) {
          if (a.isUnlocked != b.isUnlocked) {
            return a.isUnlocked ? -1 : 1;
          }
          return a.rarity.index.compareTo(b.rarity.index);
        });

        if (achievements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: Colors.white30,
                ),
                const SizedBox(height: 16),
                Text(
                  _showOnlyUnlocked 
                    ? 'No unlocked achievements in this category yet'
                    : 'No achievements found',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return _buildAchievementCard(achievement, index);
          },
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: achievement.isUnlocked
            ? [
                achievement.rarityColor.withOpacity(0.3),
                achievement.rarityColor.withOpacity(0.1),
              ]
            : [
                Colors.grey.shade800.withOpacity(0.3),
                Colors.grey.shade900.withOpacity(0.1),
              ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked 
            ? achievement.rarityColor.withOpacity(0.6)
            : Colors.grey.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: achievement.isUnlocked ? [
          BoxShadow(
            color: achievement.rarityColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showAchievementDetails(achievement),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Achievement icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: achievement.isUnlocked 
                      ? achievement.rarityColor.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: achievement.isUnlocked 
                        ? achievement.rarityColor
                        : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    achievement.isSecret && !achievement.isUnlocked 
                      ? Icons.help_outline
                      : achievement.icon,
                    color: achievement.isUnlocked 
                      ? achievement.rarityColor
                      : Colors.grey,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Achievement info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.isSecret && !achievement.isUnlocked 
                                ? 'Secret Achievement'
                                : achievement.title,
                              style: TextStyle(
                                color: achievement.isUnlocked ? Colors.white : Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          
                          // Rarity badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: achievement.rarityColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: achievement.rarityColor,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              achievement.rarityName.toUpperCase(),
                              style: TextStyle(
                                color: achievement.rarityColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        achievement.isSecret && !achievement.isUnlocked 
                          ? achievement.secretHint ?? 'Complete specific actions to unlock'
                          : achievement.description,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Progress bar
                      if (!achievement.isUnlocked) ...[
                        Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: achievement.progressPercentage,
                                backgroundColor: Colors.white.withOpacity(0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  achievement.categoryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${achievement.currentProgress}/${achievement.targetValue}',
                              style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '+${achievement.pointsReward} pts',
                              style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(delay: Duration(milliseconds: 100 + (index * 50)), duration: 400.ms)
      .slideX(begin: -0.3, end: 0);
  }

  void _showAchievementDetails(Achievement achievement) {
    context.read<AudioService>().playUIClick();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: achievement.rarityColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: achievement.rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: achievement.rarityColor,
                  width: 2,
                ),
              ),
              child: Icon(
                achievement.isSecret && !achievement.isUnlocked 
                  ? Icons.help_outline
                  : achievement.icon,
                color: achievement.rarityColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.isSecret && !achievement.isUnlocked 
                      ? 'Secret Achievement'
                      : achievement.title,
                    style: TextStyle(
                      color: achievement.rarityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    achievement.rarityName,
                    style: TextStyle(
                      color: achievement.rarityColor.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              achievement.isSecret && !achievement.isUnlocked 
                ? achievement.secretHint ?? 'Complete specific actions to unlock this achievement'
                : achievement.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (achievement.isUnlocked) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Achievement Unlocked!',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Earned ${achievement.pointsReward} points on ${_formatDate(achievement.unlockedAt!)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Reward: ${achievement.pointsReward} points',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    if (!achievement.isSecret) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: achievement.progressPercentage,
                              backgroundColor: Colors.white.withOpacity(0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                achievement.categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${achievement.currentProgress} / ${achievement.targetValue}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AudioService>().playUIClick();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.cyan, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    context.read<AudioService>().playUIClick();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.cyan.withOpacity(0.5), width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.filter_alt, color: Colors.cyan, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Filter Achievements',
              style: TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CheckboxListTile(
                  title: const Text(
                    'Show only unlocked',
                    style: TextStyle(color: Colors.white),
                  ),
                  value: _showOnlyUnlocked,
                  onChanged: (value) {
                    setDialogState(() {
                      _showOnlyUnlocked = value ?? false;
                    });
                    // Also update the main widget state
                    setState(() {
                      _showOnlyUnlocked = value ?? false;
                    });
                  },
                  activeColor: Colors.cyan,
                  checkColor: Colors.black,
                ),
                // You can add more filter options here if needed
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AudioService>().playUIClick();
              Navigator.of(context).pop();
            },
            child: const Text(
              'Close',
              style: TextStyle(color: Colors.cyan),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.score:
        return Icons.stars;
      case AchievementCategory.lines:
        return Icons.view_headline;
      case AchievementCategory.combo:
        return Icons.whatshot;
      case AchievementCategory.level:
        return Icons.trending_up;
      case AchievementCategory.gameplay:
        return Icons.videogame_asset;
      case AchievementCategory.special:
        return Icons.diamond;
    }
  }

  String _getCategoryName(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.score:
        return 'Score';
      case AchievementCategory.lines:
        return 'Lines';
      case AchievementCategory.combo:
        return 'Combo';
      case AchievementCategory.level:
        return 'Level';
      case AchievementCategory.gameplay:
        return 'Play';
      case AchievementCategory.special:
        return 'Special';
    }
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
}

class AchievementBackgroundPainter extends CustomPainter {
  final Animation<double> animation;

  AchievementBackgroundPainter({required this.animation})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final time = animation.value * 2 * math.pi;
    
    // Draw floating achievement icons
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (int i = 0; i < 20; i++) {
      final x = (i * 83 + time * 15) % size.width;
      final y = (i * 71 + time * 12) % size.height;
      final radius = 2.0 + (i % 4) * 0.5;
      final alpha = (math.sin(time + i * 0.7) + 1) * 0.15;
      
      paint.color = Colors.purple.withOpacity(alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
    
    // Draw subtle grid
    final gridPaint = Paint()
      ..color = Colors.purple.withOpacity(0.05)
      ..strokeWidth = 1;
    
    final spacing = 60.0;
    final offset = (time * 8) % spacing;
    
    for (double x = -offset; x < size.width + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    
    for (double y = -offset; y < size.height + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}