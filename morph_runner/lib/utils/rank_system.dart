import 'package:flutter/material.dart';

// ============================================================================
// RANK SYSTEM DEFINITIONS
// ============================================================================

enum RankTier {
  unranked,
  wood,
  stone,
  carbon,
  iron,
  gold,
  emerald,
  diamond,
  sapphire,
  himothy,
}

class RankInfo {
  final RankTier tier;
  final String title;
  final int minScore;
  final int maxScore;
  final IconData emblem;
  final Color color;
  final Color glowColor;

  const RankInfo({
    required this.tier,
    required this.title,
    required this.minScore,
    required this.maxScore,
    required this.emblem,
    required this.color,
    required this.glowColor,
  });
}

class RankSystem {
  static const List<RankInfo> ranks = [
    RankInfo(
      tier: RankTier.unranked,
      title: 'Unranked',
      minScore: 0,
      maxScore: 4999,
      emblem: Icons.help_outline,
      color: Color(0xFF6B7280),
      glowColor: Color(0xFF9CA3AF),
    ),
    RankInfo(
      tier: RankTier.wood,
      title: 'Wood',
      minScore: 5000,
      maxScore: 24999,
      emblem: Icons.nature,
      color: Color(0xFF8B4513),
      glowColor: Color(0xFFD2691E),
    ),
    RankInfo(
      tier: RankTier.stone,
      title: 'Stone',
      minScore: 25000,
      maxScore: 49999,
      emblem: Icons.landscape,
      color: Color(0xFF708090),
      glowColor: Color(0xFFB0C4DE),
    ),
    RankInfo(
      tier: RankTier.carbon,
      title: 'Carbon',
      minScore: 50000,
      maxScore: 99999,
      emblem: Icons.grain,
      color: Color(0xFF2C2C2C),
      glowColor: Color(0xFF505050),
    ),
    RankInfo(
      tier: RankTier.iron,
      title: 'Iron',
      minScore: 100000,
      maxScore: 499999,
      emblem: Icons.shield,
      color: Color(0xFF778899),
      glowColor: Color(0xFFC0C0C0),
    ),
    RankInfo(
      tier: RankTier.gold,
      title: 'Gold',
      minScore: 500000,
      maxScore: 999999,
      emblem: Icons.star,
      color: Color(0xFFFFD700),
      glowColor: Color(0xFFFFF44F),
    ),
    RankInfo(
      tier: RankTier.emerald,
      title: 'Emerald',
      minScore: 1000000,
      maxScore: 1999999,
      emblem: Icons.diamond,
      color: Color(0xFF50C878),
      glowColor: Color(0xFF7FFFD4),
    ),
    RankInfo(
      tier: RankTier.diamond,
      title: 'Diamond',
      minScore: 2000000,
      maxScore: 4999999,
      emblem: Icons.auto_awesome,
      color: Color(0xFFB9F2FF),
      glowColor: Color(0xFFE0FFFF),
    ),
    RankInfo(
      tier: RankTier.sapphire,
      title: 'Sapphire',
      minScore: 5000000,
      maxScore: 49999999,
      emblem: Icons.water_drop,
      color: Color(0xFF0F52BA),
      glowColor: Color(0xFF4169E1),
    ),
    RankInfo(
      tier: RankTier.himothy,
      title: 'Himothy',
      minScore: 50000000,
      maxScore: 999999999999999999,
      emblem: Icons.emoji_events,
      color: Color(0xFFFF1493),
      glowColor: Color(0xFFFF69B4),
    ),
  ];

  /// Get rank info for a given score
  static RankInfo getRankForScore(int score) {
    for (int i = ranks.length - 1; i >= 0; i--) {
      if (score >= ranks[i].minScore) {
        return ranks[i];
      }
    }
    return ranks[0]; // Default to Unranked
  }

  /// Get rank info by tier
  static RankInfo getRankInfo(RankTier tier) {
    return ranks.firstWhere((r) => r.tier == tier);
  }

  /// Check if there's a rank up between two scores
  static RankInfo? checkRankUp(int oldScore, int newScore) {
    final oldRank = getRankForScore(oldScore);
    final newRank = getRankForScore(newScore);
    
    if (newRank.tier.index > oldRank.tier.index) {
      return newRank;
    }
    return null;
  }

  /// Get progress to next rank (0.0 to 1.0)
  static double getProgressToNextRank(int score) {
    final currentRank = getRankForScore(score);
    
    // If at max rank, return 1.0
    if (currentRank.tier == RankTier.himothy) {
      return 1.0;
    }
    
    final nextRankIndex = currentRank.tier.index + 1;
    if (nextRankIndex >= ranks.length) {
      return 1.0;
    }
    
    final nextRank = ranks[nextRankIndex];
    final rangeSize = nextRank.minScore - currentRank.minScore;
    final progress = (score - currentRank.minScore) / rangeSize;
    
    return progress.clamp(0.0, 1.0);
  }

  /// Get next rank info
  static RankInfo? getNextRank(int score) {
    final currentRank = getRankForScore(score);
    final nextRankIndex = currentRank.tier.index + 1;
    
    if (nextRankIndex >= ranks.length) {
      return null;
    }
    
    return ranks[nextRankIndex];
  }

  /// Format score with commas
  static String formatScore(int score) {
    return score.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}

// ============================================================================
// RANK BADGE WIDGET
// ============================================================================

class RankBadge extends StatelessWidget {
  final RankInfo rank;
  final double size;
  final bool showTitle;
  final bool showGlow;

  const RankBadge({
    Key? key,
    required this.rank,
    this.size = 40,
    this.showTitle = false,
    this.showGlow = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: rank.color,
            boxShadow: showGlow
                ? [
                    BoxShadow(
                      color: rank.glowColor.withOpacity(0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Icon(
            rank.emblem,
            color: Colors.white,
            size: size * 0.6,
          ),
        ),
        if (showTitle) ...[
          SizedBox(height: 4),
          Text(
            rank.title,
            style: TextStyle(
              color: rank.color,
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// RANK UP ANIMATION WIDGET
// ============================================================================

class RankUpAnimation extends StatefulWidget {
  final RankInfo oldRank;
  final RankInfo newRank;
  final VoidCallback onComplete;

  const RankUpAnimation({
    Key? key,
    required this.oldRank,
    required this.newRank,
    required this.onComplete,
  }) : super(key: key);

  @override
  _RankUpAnimationState createState() => _RankUpAnimationState();
}

class _RankUpAnimationState extends State<RankUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _breakController;
  late AnimationController _riseController;
  late AnimationController _glowController;
  
  late Animation<double> _breakAnimation;
  late Animation<double> _riseAnimation;
  late Animation<double> _glowAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _breakController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _riseController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _breakAnimation = CurvedAnimation(
      parent: _breakController,
      curve: Curves.easeInOut,
    );
    
    _riseAnimation = CurvedAnimation(
      parent: _riseController,
      curve: Curves.elasticOut,
    );
    
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    
    _startAnimation();
  }
  
  void _startAnimation() async {
    await Future.delayed(Duration(milliseconds: 300));
    await _breakController.forward();
    await Future.delayed(Duration(milliseconds: 200));
    _riseController.forward();
    _glowController.forward();
    await Future.delayed(Duration(milliseconds: 2000));
    widget.onComplete();
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: Center(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Breaking old rank
              AnimatedBuilder(
                animation: _breakAnimation,
                builder: (context, child) {
                  final breakProgress = _breakAnimation.value;
                  final opacity = 1.0 - breakProgress;
                  final scale = 1.0 + (breakProgress * 0.5);
                  
                  return Opacity(
                    opacity: opacity,
                    child: Transform.scale(
                      scale: scale,
                      child: Transform.rotate(
                        angle: breakProgress * 0.5,
                        child: RankBadge(
                          rank: widget.oldRank,
                          size: 100,
                          showGlow: true,
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              SizedBox(height: 40),
              
              // Rising new rank
              AnimatedBuilder(
                animation: Listenable.merge([_riseAnimation, _glowAnimation]),
                builder: (context, child) {
                  final riseProgress = _riseAnimation.value;
                  final glowProgress = _glowAnimation.value;
                  final offset = (1.0 - riseProgress) * 100;
                  final opacity = riseProgress;
                  final glowIntensity = glowProgress * 2.0;
                  
                  return Transform.translate(
                    offset: Offset(0, offset),
                    child: Opacity(
                      opacity: opacity.clamp(0.0, 1.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.newRank.glowColor.withOpacity((glowIntensity * 0.5).clamp(0.0, 1.0)),
                                  blurRadius: 40 * glowIntensity,
                                  spreadRadius: 10 * glowIntensity,
                                ),
                              ],
                            ),
                            child: RankBadge(
                              rank: widget.newRank,
                              size: 120,
                              showGlow: true,
                            ),
                          ),
                          SizedBox(height: 24),
                          Text(
                            'RANK UP!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              shadows: [
                                Shadow(
                                  color: widget.newRank.glowColor,
                                  blurRadius: 20,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            widget.newRank.title.toUpperCase(),
                            style: TextStyle(
                              color: widget.newRank.color,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              shadows: [
                                Shadow(
                                  color: widget.newRank.glowColor,
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
    
  @override
  void dispose() {
    _breakController.dispose();
    _riseController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}