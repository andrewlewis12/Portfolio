import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/achievements_service.dart';
import '../services/audio_service.dart';

class AchievementsWidget extends StatefulWidget {
  final bool isCompact;
  
  const AchievementsWidget({
    Key? key,
    this.isCompact = true,
  }) : super(key: key);

  @override
  _AchievementsWidgetState createState() => _AchievementsWidgetState();
}

class _AchievementsWidgetState extends State<AchievementsWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  AchievementCategory _selectedCategory = AchievementCategory.gameplay;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AchievementCategory.values.length,
      vsync: this,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AchievementsService.instance,
      builder: (context, child) {
        if (widget.isCompact) {
          return _buildCompactAchievements();
        } else {
          return _buildFullAchievements();
        }
      },
    );
  }

  Widget _buildCompactAchievements() {
    final service = AchievementsService.instance;
    final recentUnlocked = service.unlockedAchievements
        .where((a) => a.unlockedAt != null)
        .toList()
        ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!))
        ..take(3).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // FIXED: Align to start
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.emoji_events, color: Colors.yellow.shade600, size: 20),
                    SizedBox(width: 6),
                    if (service.recentNotifications.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                        ),
                        child: Text(
                          '${service.recentNotifications.length} new',
                          style: TextStyle(color: Colors.green, fontSize: 10),
                        ),
                      ),
                      SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        'Achievements',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min, // FIXED: Use min size
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.yellow.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.yellow, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '${service.totalAchievementPoints}',
                          style: TextStyle(color: Colors.yellow, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _showFullAchievements(),
                    child: Icon(Icons.open_in_full, color: Colors.white70, size: 18),
                  ),
                ],
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Progress overview - FIXED: Better layout
          Column( // FIXED: Use Column instead of Row for better space management
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${service.unlockedCount}/${service.totalCount} Unlocked',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${(service.completionPercentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              LinearProgressIndicator(
                value: service.completionPercentage,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow.shade600),
              ),
            ],
          ),
          
          if (recentUnlocked.isNotEmpty) ...[
            SizedBox(height: 10),
            Text(
              'Recent Achievements',
              style: TextStyle(color: Colors.white70, fontSize: 10),
            ),
            SizedBox(height: 6),
            ...recentUnlocked.map((achievement) => _buildCompactAchievementItem(achievement)),
          ],
          
        ],
      ),
    );
  }

  Widget _buildCompactAchievementItem(Achievement achievement) {
    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AchievementsService.getRarityColor(achievement.rarity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AchievementsService.getRarityColor(achievement.rarity).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon (top-left)
              Text(
                achievement.icon,
                style: TextStyle(fontSize: 20),
              ),
              Spacer(),
              // Points (top-right)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 14, color: Colors.yellow),
                  SizedBox(width: 4),
                  Text(
                    '+${achievement.rewardPoints}',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            achievement.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2),
          Text(
            achievement.description,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFullAchievements() {
    return Column(
      children: [
        _buildAchievementsHeader(),
        SizedBox(height: 16),
        _buildCategoryTabs(),
        SizedBox(height: 16),
        Expanded(child: _buildAchievementsList()),
      ],
    );
  }

  Widget _buildAchievementsHeader() {
    final service = AchievementsService.instance;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.yellow.shade600.withOpacity(0.2),
            Colors.orange.shade600.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.yellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon and Points
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.emoji_events, color: Colors.yellow.shade600, size: 32),
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.yellow.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.yellow, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '${service.totalAchievementPoints}',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Points',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),

          // Title
          Text(
            'Achievements',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),

          // Unlock status
          Text(
            '${service.unlockedCount} of ${service.totalCount} unlocked',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),

          // Progress bar
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: service.completionPercentage,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow.shade600),
                  minHeight: 8,
                ),
              ),
              SizedBox(width: 12),
              Text(
                '${(service.completionPercentage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      height: 64, // Increased height to avoid vertical overflow
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: AchievementCategory.values.length,
        itemBuilder: (context, index) {
          final category = AchievementCategory.values[index];
          final isSelected = _selectedCategory == category;
          final service = AchievementsService.instance;
          final categoryAchievements = service.getAchievementsByCategory(category);
          final unlockedInCategory = categoryAchievements.where((a) => a.isUnlocked).length;

          return GestureDetector(
            onTap: () {
              AudioService.instance.playUIClick();
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.yellow.withOpacity(0.2)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? Colors.yellow.withOpacity(0.5)
                      : Colors.white24,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Let it shrink-wrap vertically
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        AchievementsService.getCategoryIcon(category),
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(width: 4),
                      Text(
                        AchievementsService.getCategoryName(category),
                        style: TextStyle(
                          color: isSelected ? Colors.yellow : Colors.white70,
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    '$unlockedInCategory/${categoryAchievements.length}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.yellow.shade300
                          : Colors.white60,
                      fontSize: 10,
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

  Widget _buildAchievementsList() {
    final service = AchievementsService.instance;
    final achievements = service.getAchievementsByCategory(_selectedCategory);
    
    if (achievements.isEmpty) {
      return Center(
        child: Text(
          'No achievements in this category',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(achievements[index]);
      },
    );
  }

Widget _buildAchievementCard(Achievement achievement) {
  final isUnlocked = achievement.isUnlocked;
  final rarityColor = AchievementsService.getRarityColor(achievement.rarity);

  return Container(
    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AudioService.instance.playUIClick();
          _showAchievementDetails(achievement);
          if (isUnlocked) HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isUnlocked
                ? rarityColor.withOpacity(0.15)
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isUnlocked ? rarityColor.withOpacity(0.5) : Colors.white24,
              width: isUnlocked ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Icon and Points
              Column(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? rarityColor.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.2),
                      border: Border.all(
                        color: isUnlocked ? rarityColor : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        isUnlocked || !achievement.isSecret
                            ? achievement.icon
                            : '❓',
                        style: TextStyle(
                          fontSize: 24,
                          color: isUnlocked ? Colors.white : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellow.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Colors.yellow, size: 14),
                        SizedBox(width: 2),
                        Text(
                          '${achievement.rewardPoints}',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isUnlocked) ...[
                    SizedBox(height: 6),
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ],
              ),

              SizedBox(width: 14),

              // Right Column: Title, rarity, description, etc.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      isUnlocked || !achievement.isSecret
                          ? achievement.title
                          : 'Secret Achievement',
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    SizedBox(height: 6),

                    // Rarity Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: rarityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: rarityColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        AchievementsService.getRarityName(achievement.rarity),
                        style: TextStyle(
                          color: rarityColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 1,
                      ),
                    ),

                    SizedBox(height: 8),

                    // Description
                    Text(
                      isUnlocked || !achievement.isSecret
                          ? achievement.description
                          : achievement.secretHint ?? 'Complete certain conditions to unlock...',
                      style: TextStyle(
                        color: isUnlocked ? Colors.white70 : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Progress bar
                    if (achievement.maxProgress > 1) ...[
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: achievement.progressPercentage,
                              backgroundColor: Colors.white24,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isUnlocked ? rarityColor : Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '${achievement.currentProgress}/${achievement.maxProgress}',
                            style: TextStyle(
                              color: isUnlocked ? Colors.white70 : Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],

                    if (isUnlocked && achievement.unlockedAt != null) ...[
                      SizedBox(height: 6),
                      Text(
                        'Unlocked ${_formatDate(achievement.unlockedAt!)}',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
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
  );
}

  void _showFullAchievements() {
    AudioService.instance.playUIClick();
    showDialog(
      context: context,
      builder: (context) => _FullAchievementsDialog(),
    );
  }

  void _showNotifications() {
    AudioService.instance.playUIClick();
    showDialog(
      context: context,
      builder: (context) => _AchievementNotificationsDialog(),
    );
  }

  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder: (context) => _AchievementDetailsDialog(achievement: achievement),
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _FullAchievementsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.deepPurple.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'All Achievements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () { 
                    AudioService.instance.playUIClick();
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            SizedBox(height: 15),
            Expanded(
              child: AchievementsWidget(isCompact: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementNotificationsDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final service = AchievementsService.instance;
    
    return Dialog(
      backgroundColor: Colors.deepPurple.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.6,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Achievements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        AudioService.instance.playUIClick();
                        service.clearNotifications();
                      },
                      child: Text('Clear', style: TextStyle(color: Colors.white70)),
                    ),
                    IconButton(
                      onPressed: () { 
                        AudioService.instance.playUIClick();
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 15),
            Expanded(
              child: service.recentNotifications.isEmpty
                  ? Center(
                      child: Text(
                        'No recent achievements',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: service.recentNotifications.length,
                      itemBuilder: (context, index) {
                        final notification = service.recentNotifications[index];
                        return _buildNotificationItem(notification, index);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(AchievementNotification notification, int index) {
    final achievement = notification.achievement;
    final rarityColor = AchievementsService.getRarityColor(achievement.rarity);
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AudioService.instance.playUIClick();
            AchievementsService.instance.markNotificationAsRead(index);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isNew 
                  ? rarityColor.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notification.isNew 
                    ? rarityColor.withOpacity(0.5)
                    : Colors.white24,
              ),
            ),
            child: Row(
              children: [
                Text(
                  achievement.icon,
                  style: TextStyle(fontSize: 32),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        achievement.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Unlocked ${DateTime.now().difference(notification.timestamp).inMinutes}m ago',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.yellow.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.yellow, size: 14),
                          SizedBox(width: 2),
                          Text(
                            '+${achievement.rewardPoints}',
                            style: TextStyle(
                              color: Colors.yellow,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (notification.isNew) ...[
                      SizedBox(height: 4),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AchievementDetailsDialog extends StatelessWidget {
  final Achievement achievement;
  
  const _AchievementDetailsDialog({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final rarityColor = AchievementsService.getRarityColor(achievement.rarity);
    
    return Dialog(
      backgroundColor: Colors.deepPurple.shade800,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: achievement.isUnlocked 
                    ? rarityColor.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
                border: Border.all(
                  color: achievement.isUnlocked ? rarityColor : Colors.grey,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  achievement.isUnlocked || !achievement.isSecret 
                      ? achievement.icon
                      : '❓',
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Title and rarity
            Text(
              achievement.isUnlocked || !achievement.isSecret 
                  ? achievement.title
                  : 'Secret Achievement',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 8),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: rarityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: rarityColor.withOpacity(0.5)),
              ),
              child: Text(
                '${AchievementsService.getRarityName(achievement.rarity)} • ${AchievementsService.getCategoryName(achievement.category)}',
                style: TextStyle(
                  color: rarityColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Description
            Text(
              achievement.isUnlocked || !achievement.isSecret
                  ? achievement.description
                  : achievement.secretHint ?? 'Complete certain conditions to unlock...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 20),
            
            // Progress (if applicable)
            if (achievement.maxProgress > 1) ...[
              Text(
                'Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: achievement.progressPercentage,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(rarityColor),
                minHeight: 8,
              ),
              SizedBox(height: 4),
              Text(
                '${achievement.currentProgress} / ${achievement.maxProgress}',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 20),
            ],
            
            // Reward
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.yellow.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.yellow, size: 18),
                  SizedBox(width: 4),
                  Text(
                    '${achievement.rewardPoints} Achievement Points',
                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            if (achievement.isUnlocked && achievement.unlockedAt != null) ...[
              SizedBox(height: 16),
              Text(
                'Unlocked on ${achievement.unlockedAt!.month}/${achievement.unlockedAt!.day}/${achievement.unlockedAt!.year}',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            
            SizedBox(height: 24),
            
            // Close button
            ElevatedButton(
              onPressed: () {
                AudioService.instance.playUIClick();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}

class AchievementNotificationOverlay extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;
  
  const AchievementNotificationOverlay({
    Key? key,
    required this.achievement,
    required this.onDismiss,
  }) : super(key: key);

  @override
  _AchievementNotificationOverlayState createState() => _AchievementNotificationOverlayState();
}

class _AchievementNotificationOverlayState extends State<AchievementNotificationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, -1.5), // FIXED: Start further up to clear any UI
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05, // FIXED: Reduced pulse intensity
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
    _pulseController.repeat(reverse: true);
    
    // Auto dismiss after 4 seconds
    Future.delayed(Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rarityColor = AchievementsService.getRarityColor(widget.achievement.rarity);
    
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: GestureDetector(
          onTap: _dismiss,
          child: Container(
            // FIXED: Constrained height and better padding
            constraints: BoxConstraints(
              maxHeight: 80,
              minHeight: 70,
            ),
            margin: EdgeInsets.symmetric(horizontal: 8), // FIXED: Margin for edge spacing
            padding: EdgeInsets.all(12), // FIXED: Consistent padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  rarityColor.withOpacity(0.95),
                  rarityColor.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12), // FIXED: Smaller radius
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: rarityColor.withOpacity(0.6),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon container - FIXED: Consistent size
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      widget.achievement.icon,
                      style: TextStyle(fontSize: 20), // FIXED: Appropriate icon size
                    ),
                  ),
                ),
                SizedBox(width: 12),
                // Text content - FIXED: Proper expansion and text sizing
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center, // FIXED: Center vertically
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Achievement Unlocked!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10, // FIXED: Smaller subtitle
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        widget.achievement.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14, // FIXED: Main title size
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.achievement.description.length <= 30) // FIXED: Only show description if short
                        Text(
                          widget.achievement.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 10, // FIXED: Small description
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Points and rarity - FIXED: Compact column
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Colors.white, size: 12),
                          SizedBox(width: 2),
                          Text(
                            '+${widget.achievement.rewardPoints}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      AchievementsService.getRarityName(widget.achievement.rarity),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 8, // FIXED: Very small rarity text
                        fontWeight: FontWeight.w600,
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
  }

  @override
  void dispose() {
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }
}
