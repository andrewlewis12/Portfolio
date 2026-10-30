import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:convert';
import 'achievements_service.dart';
import 'package:uuid/uuid.dart';
// Import the rank system
import '../utils/rank_system.dart';

class LeaderboardEntry {
  final String id;
  final String playerName;
  final int score;
  final DateTime timestamp;
  final String deviceId;
  final RankInfo rank; // Added rank info

  LeaderboardEntry({
    required this.id,
    required this.playerName,
    required this.score,
    required this.timestamp,
    required this.deviceId,
    required this.rank,
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map, String id) {
    final score = map['score'] ?? 0;
    return LeaderboardEntry(
      id: id,
      playerName: map['playerName'] ?? 'Anonymous',
      score: score,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      deviceId: map['deviceId'] ?? '',
      rank: RankSystem.getRankForScore(score),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'score': score,
      'timestamp': Timestamp.fromDate(timestamp),
      'deviceId': deviceId,
    };
  }

  // For local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'playerName': playerName,
      'score': score,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'deviceId': deviceId,
    };
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final score = json['score'] ?? 0;
    return LeaderboardEntry(
      id: json['id'] ?? '',
      playerName: json['playerName'] ?? 'Anonymous',
      score: score,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      deviceId: json['deviceId'] ?? '',
      rank: RankSystem.getRankForScore(score),
    );
  }
}

class LeaderboardService {
  static LeaderboardService? _instance;
  static LeaderboardService get instance => _instance ??= LeaderboardService._();
  LeaderboardService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'morph_leaderboard';
  
  // Local cache
  List<LeaderboardEntry> _cachedLeaderboard = [];
  DateTime? _lastLeaderboardFetch;
  DateTime? _lastScoreSubmission;
  String? _deviceId;
  String? _playerName;
  bool _hasValidUsername = false;
  bool _isAnonymous = false;
  
  // Track previous rank for rank-up detection
  RankInfo? _previousRank;

  final uuid = Uuid();

  // Constants
  static const int _maxEntriesPerRank = 250; // CHANGED: Entries per rank tier
  static const Duration _leaderboardCacheDuration = Duration(hours: 24);
  static const Duration _submissionCooldown = Duration(hours: 24);
  
  /// Initialize the service
  Future<void> initialize() async {
    await _loadLocalData();
    await _generateDeviceId();
    await _loadCachedLeaderboard();
    await _loadPreviousRank();
  }

  /// Load previous rank for rank-up detection
  Future<void> _loadPreviousRank() async {
    final prefs = await SharedPreferences.getInstance();
    final rankIndex = prefs.getInt('previous_rank_tier');
    if (rankIndex != null && rankIndex < RankSystem.ranks.length) {
      _previousRank = RankSystem.ranks[rankIndex];
    }
  }

  /// Save current rank
  Future<void> _savePreviousRank(RankInfo rank) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('previous_rank_tier', rank.tier.index);
    _previousRank = rank;
  }

  /// Get current player's rank
  RankInfo getCurrentPlayerRank() {
    final entry = getCurrentPlayerEntry();
    if (entry != null) {
      return entry.rank;
    }
    return RankSystem.getRankForScore(0);
  }

  /// Get global rank position (out of all players)
  int? getGlobalRankPosition({String? player}) {
    if (!_hasValidUsername) return null;

    final targetPlayer = player ?? _playerName;
    if (targetPlayer == null) return null;

    for (int i = 0; i < _cachedLeaderboard.length; i++) {
      if (_cachedLeaderboard[i].playerName == targetPlayer) {
        return i + 1;
      }
    }
    return null;
  }

  /// Get entries in a specific rank tier
  List<LeaderboardEntry> getEntriesInRank(RankTier tier) {
    final rankInfo = RankSystem.getRankInfo(tier);
    return _cachedLeaderboard
        .where((entry) => 
            entry.score >= rankInfo.minScore && 
            entry.score <= rankInfo.maxScore)
        .toList();
  }

  /// Get top 3 in player's current rank tier
  List<LeaderboardEntry> getTop3InPlayerRank() {
    final playerRank = getCurrentPlayerRank();
    return getEntriesInRank(playerRank.tier).take(3).toList();
  }

  /// Get player's position within their rank tier
  int? getPositionInRank() {
    if (!_hasValidUsername || _playerName == null) return null;
    
    final playerRank = getCurrentPlayerRank();
    final entriesInRank = getEntriesInRank(playerRank.tier);
    
    for (int i = 0; i < entriesInRank.length; i++) {
      if (entriesInRank[i].playerName == _playerName) {
        return i + 1;
      }
    }
    return null;
  }

  // [Keep all existing methods from original leaderboard_service.dart]
  // I'll include the key ones and mark where others continue...

  Future<void> _loadLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    
    final lastFetchMs = prefs.getInt('leaderboard_last_fetch');
    if (lastFetchMs != null) {
      _lastLeaderboardFetch = DateTime.fromMillisecondsSinceEpoch(lastFetchMs);
    }
    
    final lastSubmissionMs = prefs.getInt('leaderboard_last_submission');
    if (lastSubmissionMs != null) {
      _lastScoreSubmission = DateTime.fromMillisecondsSinceEpoch(lastSubmissionMs);
    }
    
    _playerName = prefs.getString('player_name');
    _hasValidUsername = prefs.getBool('has_valid_username') ?? false;
    _isAnonymous = prefs.getBool('is_anonymous') ?? false;
    _deviceId = prefs.getString('device_id');
  }

  Future<void> _loadCachedLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_leaderboard');
      
      if (cachedData != null) {
        final List<dynamic> jsonList = json.decode(cachedData);
        _cachedLeaderboard = jsonList
            .map((json) => LeaderboardEntry.fromJson(json))
            .toList();
        
        if (kDebugMode) {
          print('Loaded ${_cachedLeaderboard.length} cached leaderboard entries');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading cached leaderboard: $e');
      }
      _cachedLeaderboard = [];
    }
  }

  Future<void> _saveCachedLeaderboard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _cachedLeaderboard.map((entry) => entry.toJson()).toList();
      await prefs.setString('cached_leaderboard', json.encode(jsonList));
      
      await prefs.setInt('leaderboard_last_fetch', DateTime.now().millisecondsSinceEpoch);
      _lastLeaderboardFetch = DateTime.now();
      
      if (kDebugMode) {
        print('Saved ${_cachedLeaderboard.length} leaderboard entries to cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving cached leaderboard: $e');
      }
    }
  }

  Future<void> _generateDeviceId() async {
    if (_deviceId == null) {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = _generateRandomId();
      await prefs.setString('device_id', _deviceId!);
    }
  }

  String _generateRandomId() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(16, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  bool _shouldFetchLeaderboard() {
    if (_lastLeaderboardFetch == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastLeaderboardFetch!);
    return difference >= _leaderboardCacheDuration;
  }

  bool canSubmitScore() {
    if (_lastScoreSubmission == null) return true;
    final now = DateTime.now();
    final difference = now.difference(_lastScoreSubmission!);
    return difference >= _submissionCooldown;
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final cleanUsername = _cleanUsername(username);
      if (cleanUsername.isEmpty) return false;
      
      final doc = await _firestore.collection(_collectionName).doc(cleanUsername.toLowerCase()).get();
      return !doc.exists;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking username availability: $e');
      }
      return false;
    }
  }

  String _cleanUsername(String username) {
    final cleaned = username
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '')
        .toLowerCase()
        .trim();
    
    if (cleaned.length < 3 || cleaned.length > 20) return '';
    return cleaned;
  }

  Future<bool> setPlayerName(String name) async {
    final cleanName = _cleanUsername(name);
    
    if (cleanName.isEmpty) {
      return false;
    }
    
    if (_playerName != cleanName) {
      final isAvailable = await isUsernameAvailable(cleanName);
      if (!isAvailable) {
        return false;
      }
    }
    
    _playerName = cleanName;
    _hasValidUsername = true;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('player_name', _playerName!.toLowerCase());
    await prefs.setBool('has_valid_username', true);
    
    await submitScore(0);
    return true;
  }

  Future<void> setAnonymousMode() async {
    _playerName = null;
    _hasValidUsername = false;
    _isAnonymous = true;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('player_name');
    await prefs.setBool('is_anonymous', true);
    await prefs.setBool('has_valid_username', false);
  }

  String get playerName => _playerName ?? 'Anonymous';
  bool get hasValidUsername => _hasValidUsername && _playerName != null;
  List<LeaderboardEntry> get cachedLeaderboard => List.unmodifiable(_cachedLeaderboard);
  bool get hasLeaderboardData => _cachedLeaderboard.isNotEmpty;

  Duration? get timeUntilNextSubmission {
    if (_lastScoreSubmission == null) return null;
    
    final nextSubmission = _lastScoreSubmission!.add(_submissionCooldown);
    final now = DateTime.now();
    
    if (now.isAfter(nextSubmission)) return null;
    return nextSubmission.difference(now);
  }

  bool wouldImproveLeaderboard(int score) {
    if (_cachedLeaderboard.isEmpty) return true;
    
    final currentEntry = _cachedLeaderboard.firstWhere(
      (entry) => entry.playerName == _playerName,
      orElse: () => LeaderboardEntry(
        id: '',
        playerName: '',
        score: 0,
        timestamp: DateTime.now(),
        deviceId: '',
        rank: RankSystem.getRankForScore(0),
      ),
    );
    
    // If no current entry, always allow submission
    if (currentEntry.playerName.isEmpty) {
      return true; // CHANGED: Always return true if no entry exists
    }
    
    // If has entry, check if new score is better
    return score > currentEntry.score;
  }

  /// Submit score with rank-up detection
  Future<SubmissionResult> submitScore(int score, {String? customPlayerName}) async {
    try {
      if (!canSubmitScore()) {
        return SubmissionResult(
          success: false,
          message: 'Score submission blocked - cooldown period active',
          needsUsername: false,
          rankUp: null,
        );
      }

      if (score <= 0) {
        return SubmissionResult(
          success: false,
          message: 'Score submission blocked - invalid score',
          needsUsername: false,
          rankUp: null,
        );
      }

      String submissionName;
      String documentId;
      
      if (customPlayerName != null) {
        final cleanName = _cleanUsername(customPlayerName);
        if (cleanName.isEmpty) {
          return SubmissionResult(
            success: false,
            message: 'Invalid username format',
            needsUsername: true,
            rankUp: null,
          );
        }
        submissionName = cleanName;
        documentId = cleanName;
        
        if (customPlayerName != _playerName) {
          final isAvailable = await isUsernameAvailable(submissionName);
          if (!isAvailable) {
            return SubmissionResult(
              success: false,
              message: 'Username is already taken',
              needsUsername: true,
              rankUp: null,
            );
          }
        }
      } else if (_hasValidUsername && _playerName != null) {
        submissionName = _playerName!;
        documentId = _playerName!;
      } else if (_isAnonymous) {
        submissionName = 'Anonymous';
        documentId = 'anon_${_deviceId}';
      } else {
        return SubmissionResult(
          success: false,
          message: 'Username required for submission',
          needsUsername: true,
          rankUp: null,
        );
      }

      // Check for rank up
      final currentEntry = getCurrentPlayerEntry();
      final oldScore = currentEntry?.score ?? 0;
      final rankUp = RankSystem.checkRankUp(oldScore, score);
      
      final entry = LeaderboardEntry(
        id: documentId,
        playerName: submissionName,
        score: score,
        timestamp: DateTime.now(),
        deviceId: _deviceId!,
        rank: RankSystem.getRankForScore(score),
      );

      await _firestore.collection(_collectionName).doc(documentId).set(entry.toMap());
      
      _updateLocalCache(entry);
      await _saveCachedLeaderboard();
      
      // Save new rank
      await _savePreviousRank(entry.rank);
      
      _lastScoreSubmission = DateTime.now();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('leaderboard_last_submission', _lastScoreSubmission!.millisecondsSinceEpoch);
      
      if (kDebugMode) {
        print('Score submitted successfully: $score by $submissionName');
        if (rankUp != null) {
          print('Rank up detected: ${rankUp.title}');
        }
      }
      
      final isFirstSubmission = !(prefs.getBool('has_submitted_before') ?? false);
      if (isFirstSubmission) {
        await prefs.setBool('has_submitted_before', true);
      }

      AchievementsService.instance.onLeaderboardSubmission(
        isFirstTime: isFirstSubmission,
        rank: getPlayerRank(score),
      );
      
      // Trigger rank achievement
      if (rankUp != null) {
        await AchievementsService.instance.onRankAchieved(rankUp.tier);
      }
            
      return SubmissionResult(
        success: true,
        message: 'Score submitted successfully!',
        needsUsername: false,
        rankUp: rankUp,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error submitting score: $e');
      }
      return SubmissionResult(
        success: false,
        message: 'Error submitting score: $e',
        needsUsername: false,
        rankUp: null,
      );
    }
  }

  void _updateLocalCache(LeaderboardEntry newEntry) {
    if (newEntry.playerName != 'Anonymous') {
      _cachedLeaderboard.removeWhere((entry) => entry.playerName == newEntry.playerName);
    } else {
      _cachedLeaderboard.removeWhere((entry) => 
          entry.playerName == 'Anonymous' && entry.deviceId == newEntry.deviceId);
    }
    
    _cachedLeaderboard.add(newEntry);
    _cachedLeaderboard.sort((a, b) => b.score.compareTo(a.score));
  }

  Future<List<LeaderboardEntry>> fetchLeaderboard({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && !_shouldFetchLeaderboard() && _cachedLeaderboard.isNotEmpty) {
        if (kDebugMode) {
          print('Returning cached leaderboard data');
        }
        return _cachedLeaderboard;
      }

      if (_shouldFetchLeaderboard() || _cachedLeaderboard.isEmpty) {
        await _fetchFromFirestore();
      }
      
      return _cachedLeaderboard;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching leaderboard: $e');
      }
      return _cachedLeaderboard;
    }
  }

  Future<void> _fetchFromFirestore() async {
    try {
      if (kDebugMode) {
        print('Fetching fresh leaderboard data from Firestore');
      }
      
      _cachedLeaderboard.clear(); // Clear before fetching
      
      // Fetch _maxEntriesPerRank (250) for EACH rank tier individually
      for (final rankInfo in RankSystem.ranks) {
        try {
          // Fetch all entries, then filter by rank in-memory
          // This is needed because Firestore doesn't support range queries well
          final querySnapshot = await _firestore
              .collection(_collectionName)
              .orderBy('score', descending: true)
              .get(); // Get all entries (or use a large limit)

          // Filter entries that fall within this rank's score range
          final rankEntries = querySnapshot.docs
              .map((doc) => LeaderboardEntry.fromMap(doc.data(), doc.id))
              .where((entry) => 
                entry.score >= rankInfo.minScore && 
                entry.score <= rankInfo.maxScore)
              .take(_maxEntriesPerRank) // Take up to 250 for this rank
              .toList();
          
          _cachedLeaderboard.addAll(rankEntries);
          
          if (kDebugMode) {
            print('Fetched ${rankEntries.length} entries for ${rankInfo.title} rank (${rankInfo.minScore}-${rankInfo.maxScore})');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error fetching ${rankInfo.title} rank: $e');
          }
          // Continue fetching other ranks even if one fails
        }
      }
      
      // Sort all entries by score
      _cachedLeaderboard.sort((a, b) => b.score.compareTo(a.score));
      
      // Save to local storage
      await _saveCachedLeaderboard();
      
      if (kDebugMode) {
        print('Fetched and cached ${_cachedLeaderboard.length} total leaderboard entries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching from Firestore: $e');
      }
      // Don't clear cache on error - keep existing data
    }
  }

  int? getPlayerRank(int score) {
    if (_cachedLeaderboard.isEmpty) return null;
    
    for (int i = 0; i < _cachedLeaderboard.length; i++) {
      if (score >= _cachedLeaderboard[i].score) {
        return i + 1;
      }
    }
    
    return _cachedLeaderboard.length + 1;
  }

  LeaderboardEntry? getCurrentPlayerEntry() {
    if (!_hasValidUsername || _playerName == null) return null;
    
    try {
      return _cachedLeaderboard.firstWhere(
        (entry) => entry.playerName == _playerName,
      );
    } catch (e) {
      return null;
    }
  }

  bool wouldMakeLeaderboard(int score) {
    // REMOVED: This method is no longer used
    // Players can always submit scores
    return true;
  }

  List<LeaderboardEntry> getTopEntries(int count) {
    return _cachedLeaderboard.take(count).toList();
  }

  Future<void> clearLocalCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('leaderboard_last_fetch');
    await prefs.remove('leaderboard_last_submission');
    await prefs.remove('cached_leaderboard');
    
    _lastLeaderboardFetch = null;
    _lastScoreSubmission = null;
    _cachedLeaderboard.clear();
  }

  String? get deviceId => _deviceId;
  bool get hasSubmittedToday => !canSubmitScore();
  bool get isLeaderboardDataFresh => !_shouldFetchLeaderboard();
  DateTime? get lastFetchTime => _lastLeaderboardFetch;
}

/// Result class for submission attempts
class SubmissionResult {
  final bool success;
  final String message;
  final bool needsUsername;
  final RankInfo? rankUp; // Added rank up info

  SubmissionResult({
    required this.success,
    required this.message,
    required this.needsUsername,
    this.rankUp,
  });
}