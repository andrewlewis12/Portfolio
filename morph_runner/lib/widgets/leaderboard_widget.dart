import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';
import '../services/audio_service.dart';
import '../utils/game_data.dart';
import '../utils/rank_system.dart';

class LeaderboardWidget extends StatefulWidget {
  final bool isCompact;
  
  const LeaderboardWidget({
    Key? key,
    this.isCompact = true,
  }) : super(key: key);

  @override
  _LeaderboardWidgetState createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  bool _isLoading = false;
  List<LeaderboardEntry> _leaderboardData = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await LeaderboardService.instance.fetchLeaderboard();
      setState(() {
        _leaderboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load leaderboard';
        _isLoading = false;
      });
    }
  }

  void _showFullLeaderboard() {
    AudioService.instance.playUIClick();
    showDialog(
      context: context,
      builder: (context) => _FullLeaderboardDialog(
        leaderboardData: _leaderboardData,
      ),
    );
  }

  Future<void> _submitCurrentScore() async {
    if (!LeaderboardService.instance.canSubmitScore()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can only submit once per day'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final result = await LeaderboardService.instance.submitScore(GameData.highScore);
      
      if (result.success) {
        // Show rank up animation if there was a rank up
        if (result.rankUp != null) {
          _showRankUpAnimation(result.rankUp!);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        await _loadLeaderboard();
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting score'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRankUpAnimation(RankInfo newRank) {
    final oldRank = LeaderboardService.instance.getCurrentPlayerEntry()?.rank ?? 
                    RankSystem.getRankForScore(0);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RankUpAnimation(
        oldRank: oldRank,
        newRank: newRank,
        onComplete: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompact) {
      return _buildCompactLeaderboard();
    } else {
      return _buildFullLeaderboard();
    }
  }

  Widget _buildCompactLeaderboard() {
    final playerRank = LeaderboardService.instance.getCurrentPlayerRank();
    final globalPosition = LeaderboardService.instance.getGlobalRankPosition();
    final top3InRank = LeaderboardService.instance.getTop3InPlayerRank();
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.leaderboard, color: Colors.cyan, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Leaderboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _showFullLeaderboard,
                child: Icon(Icons.open_in_full, color: Colors.white70, size: 18),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Player's Rank Info
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  playerRank.color.withOpacity(0.2),
                  playerRank.color.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: playerRank.color.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                RankBadge(rank: playerRank, size: 40),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Rank: ${playerRank.title}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (globalPosition != null)
                        Text(
                          'Global Position: #$globalPosition',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 12),
          
          // Top 3 in Player's Rank
          if (_isLoading)
            Container(
              height: 60,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                  strokeWidth: 2,
                ),
              ),
            )
          else if (_error != null)
            Container(
              height: 60,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!, style: TextStyle(color: Colors.red, fontSize: 12)),
                  SizedBox(height: 5),
                  Text(
                    'Using cached data',
                    style: TextStyle(color: Colors.orange, fontSize: 10),
                  ),
                ],
              ),
            )
          else if (top3InRank.isEmpty)
            Container(
              height: 60,
              child: Center(
                child: Text(
                  'Be the first in ${playerRank.title} rank!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            )
          else ...[
            Text(
              'Top 3 in ${playerRank.title}',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 6),
            Column(
              children: top3InRank
                  .asMap()
                  .entries
                  .map((entry) => _buildLeaderboardEntry(
                        entry.value,
                        entry.key + 1,
                        isCompact: true,
                      ))
                  .toList(),
            ),
          ],
          
          SizedBox(height: 8),
          _buildSubmissionStatus(),
        ],
      ),
    );
  }

  Widget _buildSubmissionStatus() {
    final hasSubmitted = LeaderboardService.instance.hasSubmittedToday;
    final timeUntilNext = LeaderboardService.instance.timeUntilNextSubmission;
    final canSubmit = LeaderboardService.instance.canSubmitScore();
    final wouldImprove = LeaderboardService.instance.wouldImproveLeaderboard(GameData.highScore);
    
    return Column(
      children: [
        if (GameData.highScore > 0 && canSubmit)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () { 
                AudioService.instance.playUIClick();
                _submitCurrentScore(); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: Icon(Icons.upload, size: 16),
              label: Text(
                wouldImprove ? 'Submit Better Score' : 'Submit High Score',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        
        if (!hasSubmitted && canSubmit)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Text(
              'Ready to submit score',
              style: TextStyle(color: Colors.green, fontSize: 10),
            ),
          )
        else if (timeUntilNext != null)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.5)),
            ),
            child: Text(
              'Next submit: ${timeUntilNext.inHours}h ${timeUntilNext.inMinutes % 60}m',
              style: TextStyle(color: Colors.orange, fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildFullLeaderboard() {
    return Column(
      children: [
        Text(
          'Global Leaderboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 15),
        
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                  ),
                )
              : _leaderboardData.isEmpty
                  ? Center(
                      child: Text(
                        'No scores yet!\nBe the first!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _leaderboardData.length,
                      itemBuilder: (context, index) {
                        return _buildLeaderboardEntry(
                          _leaderboardData[index],
                          index + 1,
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardEntry(LeaderboardEntry entry, int rank, {bool isCompact = false}) {
    final isPlayerEntry = entry.playerName == LeaderboardService.instance.playerName;
    final rankColor = entry.rank.color;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: isCompact ? 2 : 4),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: isPlayerEntry 
            ? Colors.cyan.withOpacity(0.1)
            : rankColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: isPlayerEntry 
            ? Border.all(color: Colors.cyan.withOpacity(0.5))
            : Border.all(color: rankColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: isCompact ? 24 : 32,
            height: isCompact ? 24 : 32,
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    entry.rank.emblem,
                    color: rankColor,
                    size: isCompact ? 16 : 20,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 8),
          
          // Position
          Container(
            width: isCompact ? 20 : 30,
            child: Text(
              '$rank',
              style: TextStyle(
                color: Colors.white70,
                fontSize: isCompact ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          SizedBox(width: 8),
          
          // Player name
          Expanded(
            child: Text(
              entry.playerName,
              style: TextStyle(
                color: isPlayerEntry ? Colors.cyan : Colors.white,
                fontSize: isCompact ? 12 : 14,
                fontWeight: isPlayerEntry ? FontWeight.bold : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Score
          Text(
            RankSystem.formatScore(entry.score),
            style: TextStyle(
              color: isPlayerEntry ? Colors.cyan : rankColor,
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          if (isPlayerEntry)
            Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(
                Icons.person,
                color: Colors.cyan,
                size: isCompact ? 12 : 16,
              ),
            ),
        ],
      ),
    );
  }
}

class _FullLeaderboardDialog extends StatefulWidget {
  final List<LeaderboardEntry> leaderboardData;

  const _FullLeaderboardDialog({
    required this.leaderboardData,
  });

  @override
  _FullLeaderboardDialogState createState() => _FullLeaderboardDialogState();
}

class _FullLeaderboardDialogState extends State<_FullLeaderboardDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RankTier _selectedRank = RankTier.unranked;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    // Start with player's current rank
    final playerRank = LeaderboardService.instance.getCurrentPlayerRank();
    _selectedRank = playerRank.tier;
    
    _tabController = TabController(
      length: RankSystem.ranks.length,
      vsync: this,
      initialIndex: playerRank.tier.index,
    );
    
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedRank = RankTier.values[_tabController.index];
        });
      }
    });
    
    // Scroll to player position after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToPlayerPosition();
    });
  }

  void _scrollToPlayerPosition() {
    final entriesInRank = LeaderboardService.instance.getEntriesInRank(_selectedRank);
    final playerEntry = LeaderboardService.instance.getCurrentPlayerEntry();
    
    if (playerEntry != null && entriesInRank.contains(playerEntry)) {
      final index = entriesInRank.indexOf(playerEntry);
      final itemHeight = 60.0; // Approximate height of each entry
      final targetOffset = index * itemHeight;
      
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final entriesInRank = LeaderboardService.instance.getEntriesInRank(_selectedRank);
    final rankInfo = RankSystem.getRankInfo(_selectedRank);
    
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
                  'Global Leaderboard',
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
            
            // Rank Tabs
            Container(
              height: 60,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.transparent,
                tabs: RankSystem.ranks.map((rank) {
                  final isSelected = _selectedRank == rank.tier;
                  final entriesCount = LeaderboardService.instance.getEntriesInRank(rank.tier).length;
                  
                  return Tab(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? rank.color.withOpacity(0.3)
                            : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? rank.color
                              : Colors.white24,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(rank.emblem, color: rank.color, size: 20),
                          SizedBox(height: 2),
                          Text(
                            rank.title,
                            style: TextStyle(
                              color: isSelected ? rank.color : Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            SizedBox(height: 15),
            
            // Rank Info Bar
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: rankInfo.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: rankInfo.color.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Icon(rankInfo.emblem, color: rankInfo.color, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rankInfo.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${RankSystem.formatScore(rankInfo.minScore)} - ${RankSystem.formatScore(rankInfo.maxScore)} points',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${entriesInRank.length} players',
                    style: TextStyle(
                      color: rankInfo.color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 15),
            
            // Leaderboard List
            Expanded(
              child: entriesInRank.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            rankInfo.emblem,
                            color: rankInfo.color.withOpacity(0.3),
                            size: 64,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'No players in ${rankInfo.title} yet!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Be the first to reach this rank!',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: entriesInRank.length,
                      itemBuilder: (context, index) {
                        final entry = entriesInRank[index];
                        final globalRank = LeaderboardService.instance.getGlobalRankPosition(player: entry.playerName);
                        
                        return _buildRankEntry(entry, globalRank ?? 0);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankEntry(LeaderboardEntry entry, int globalRank) {
    final isPlayerEntry = entry.playerName == LeaderboardService.instance.playerName;
    final rankColor = entry.rank.color;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPlayerEntry 
            ? Colors.cyan.withOpacity(0.2)
            : rankColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isPlayerEntry 
              ? Colors.cyan
              : rankColor.withOpacity(0.3),
          width: isPlayerEntry ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Global rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: rankColor.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: rankColor),
            ),
            child: Center(
              child: Text(
                '#$globalRank',
                style: TextStyle(
                  color: rankColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          // Player name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.playerName,
                  style: TextStyle(
                    color: isPlayerEntry ? Colors.cyan : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.rank.title,
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Score
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                RankSystem.formatScore(entry.score),
                style: TextStyle(
                  color: isPlayerEntry ? Colors.cyan : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isPlayerEntry)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'YOU',
                    style: TextStyle(
                      color: Colors.cyan,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}