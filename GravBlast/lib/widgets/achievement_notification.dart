// widgets/achievement_notification.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/achievement_models.dart';
import '../services/achievement_service.dart';
import '../services/audio_service.dart';

class AchievementNotificationOverlay extends StatefulWidget {
  const AchievementNotificationOverlay({Key? key}) : super(key: key);

  @override
  State<AchievementNotificationOverlay> createState() => _AchievementNotificationOverlayState();
}

class _AchievementNotificationOverlayState extends State<AchievementNotificationOverlay>
    with TickerProviderStateMixin {
  final List<AchievementNotificationItem> _notifications = [];
  final Duration _notificationDuration = const Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    
    // Listen for achievement unlocks
    context.read<AchievementService>().onAchievementUnlocked.listen((unlockedAchievement) {
      _showNotification(unlockedAchievement.achievement);
    });
  }

  void _showNotification(Achievement achievement) {
    final item = AchievementNotificationItem(
      achievement: achievement,
      controller: AnimationController(
        duration: const Duration(milliseconds: 800),
        vsync: this,
      ),
      onDismissed: () => _dismissNotification(achievement.id),
    );
    
    setState(() {
      _notifications.add(item);
    });
    
    // Auto-dismiss after duration
    Future.delayed(_notificationDuration, () {
      if (mounted) {
        _dismissNotification(achievement.id);
      }
    });
    
    // Start animation
    item.controller.forward();
  }

  void _dismissNotification(String achievementId) {
    final index = _notifications.indexWhere((item) => item.achievement.id == achievementId);
    if (index != -1) {
      final item = _notifications[index];
      item.controller.reverse().then((_) {
        if (mounted) {
          setState(() {
            _notifications.removeAt(index);
          });
          item.controller.dispose();
        }
      });
    }
  }

  @override
  void dispose() {
    for (final item in _notifications) {
      item.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 100,
      left: 16,
      right: 16,
      child: Column(
        children: _notifications.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AchievementNotificationWidget(
              item: item,
              onTap: () {
                context.read<AudioService>().playUIClick();
                _dismissNotification(item.achievement.id);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class AchievementNotificationItem {
  final Achievement achievement;
  final AnimationController controller;
  final VoidCallback onDismissed;

  AchievementNotificationItem({
    required this.achievement,
    required this.controller,
    required this.onDismissed,
  });
}

class AchievementNotificationWidget extends StatelessWidget {
  final AchievementNotificationItem item;
  final VoidCallback onTap;

  const AchievementNotificationWidget({
    Key? key,
    required this.item,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: item.controller,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -50 * (1 - item.controller.value)),
          child: Opacity(
            opacity: item.controller.value,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      item.achievement.rarityColor.withOpacity(0.9),
                      item.achievement.rarityColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: item.achievement.rarityColor.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Achievement icon with glow
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                      child: Icon(
                        item.achievement.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ).animate(autoPlay: true)
                      .scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .then()
                      .shimmer(
                        duration: 1500.ms,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    
                    const SizedBox(width: 16),
                    
                    // Achievement details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'ACHIEVEMENT UNLOCKED!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  item.achievement.rarityName.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 4),
                          
                          Text(
                            item.achievement.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          
                          const SizedBox(height: 2),
                          
                          Text(
                            item.achievement.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          const SizedBox(height: 6),
                          
                          Row(
                            children: [
                              Icon(
                                Icons.stars,
                                color: Colors.amber,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '+${item.achievement.pointsReward} points',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                'Tap to dismiss',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
}

// Compact achievement notification for in-game use
class CompactAchievementNotification extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismissed;

  const CompactAchievementNotification({
    Key? key,
    required this.achievement,
    this.onDismissed,
  }) : super(key: key);

  @override
  State<CompactAchievementNotification> createState() => _CompactAchievementNotificationState();
}

class _CompactAchievementNotificationState extends State<CompactAchievementNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _controller.forward();
    
    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismissed?.call();
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
        return Transform.scale(
          scale: _controller.value,
          child: Opacity(
            opacity: _controller.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.achievement.rarityColor.withOpacity(0.9),
                    widget.achievement.rarityColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.achievement.rarityColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.achievement.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${widget.achievement.pointsReward}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Achievement progress toast (for showing progress updates)
class AchievementProgressToast extends StatefulWidget {
  final Achievement achievement;
  final int previousProgress;
  final VoidCallback? onDismissed;

  const AchievementProgressToast({
    Key? key,
    required this.achievement,
    required this.previousProgress,
    this.onDismissed,
  }) : super(key: key);

  @override
  State<AchievementProgressToast> createState() => _AchievementProgressToastState();
}

class _AchievementProgressToastState extends State<AchievementProgressToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _controller.forward();
    
    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      widget.onDismissed?.call();
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
        return Transform.translate(
          offset: Offset(0, -30 * (1 - _controller.value)),
          child: Opacity(
            opacity: _controller.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.achievement.categoryColor.withOpacity(0.6),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.achievement.icon,
                    color: widget.achievement.categoryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${widget.achievement.currentProgress}/${widget.achievement.targetValue}',
                    style: TextStyle(
                      color: widget.achievement.categoryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: widget.achievement.progressPercentage,
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.achievement.categoryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}