// FILE: lib/services/multiplayer_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math';
import '../utils/game_data.dart';

enum GameType {
  classic,
  race,
  teamClassic,
  teamRace,
}

enum GameStatus {
  waiting,
  starting,
  inProgress,
  finished,
}

class MultiplayerGame {
  final String gameId;
  final String hostId;
  final String hostName;
  final GameType gameType;
  final bool isPublic;
  final int maxPlayers;
  final int raceDistance; // For race modes
  final GameStatus status;
  final Map<String, PlayerData> players;
  final Map<String, TeamData>? teams; // For team modes
  final DateTime createdAt;
  final DateTime? startedAt;
  
  MultiplayerGame({
    required this.gameId,
    required this.hostId,
    required this.hostName,
    required this.gameType,
    required this.isPublic,
    required this.maxPlayers,
    this.raceDistance = 10000,
    required this.status,
    required this.players,
    this.teams,
    required this.createdAt,
    this.startedAt,
  });

  factory MultiplayerGame.fromMap(Map<dynamic, dynamic> map, String gameId) {
    final playersMap = map['players'] as Map<dynamic, dynamic>? ?? {};
    final players = <String, PlayerData>{};
    
    playersMap.forEach((key, value) {
      if (value is Map) {
        players[key.toString()] = PlayerData.fromMap(Map<String, dynamic>.from(value));
      }
    });

    Map<String, TeamData>? teams;
    if (map['teams'] != null) {
      final teamsMap = map['teams'] as Map<dynamic, dynamic>;
      teams = {};
      teamsMap.forEach((key, value) {
        if (value is Map) {
          teams![key.toString()] = TeamData.fromMap(Map<String, dynamic>.from(value));
        }
      });
    }

    return MultiplayerGame(
      gameId: gameId,
      hostId: map['hostId'] ?? '',
      hostName: map['hostName'] ?? 'Unknown',
      gameType: GameType.values[map['gameType'] ?? 0],
      isPublic: map['isPublic'] ?? true,
      maxPlayers: map['maxPlayers'] ?? 4,
      raceDistance: map['raceDistance'] ?? 10000,
      status: GameStatus.values[map['status'] ?? 0],
      players: players,
      teams: teams,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      startedAt: map['startedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['startedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostId': hostId,
      'hostName': hostName,
      'gameType': gameType.index,
      'isPublic': isPublic,
      'maxPlayers': maxPlayers,
      'raceDistance': raceDistance,
      'status': status.index,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'startedAt': startedAt?.millisecondsSinceEpoch,
    };
  }

  int get playerCount => players.length;
  bool get isFull => players.length >= maxPlayers;
  bool get isTeamMode => gameType == GameType.teamClassic || gameType == GameType.teamRace;
}

class PlayerData {
  final String playerId;
  final String playerName;
  final int score;
  final double distance;
  final bool isAlive;
  final bool isReady;
  final String? teamId;
  final PlayerShape currentShape;
  final int lane;
  final bool isDashing;
  final DateTime lastUpdate;

  PlayerData({
    required this.playerId,
    required this.playerName,
    this.score = 0,
    this.distance = 0,
    this.isAlive = true,
    this.isReady = false,
    this.teamId,
    this.currentShape = PlayerShape.circle,
    this.lane = 2,
    this.isDashing = false,
    required this.lastUpdate,
  });

  factory PlayerData.fromMap(Map<String, dynamic> map) {
    return PlayerData(
      playerId: map['playerId'] ?? '',
      playerName: map['playerName'] ?? 'Unknown',
      score: map['score'] ?? 0,
      distance: (map['distance'] ?? 0).toDouble(),
      isAlive: map['isAlive'] ?? true,
      isReady: map['isReady'] ?? false,
      teamId: map['teamId'],
      currentShape: PlayerShape.values[map['currentShape'] ?? 0],
      lane: map['lane'] ?? 2,
      isDashing: map['isDashing'] ?? false,
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(map['lastUpdate'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'score': score,
      'distance': distance,
      'isAlive': isAlive,
      'isReady': isReady,
      'teamId': teamId,
      'currentShape': currentShape.index,
      'lane': lane,
      'isDashing': isDashing,
      'lastUpdate': lastUpdate.millisecondsSinceEpoch,
    };
  }

  PlayerData copyWith({
    int? score,
    double? distance,
    bool? isAlive,
    bool? isReady,
    String? teamId,
    PlayerShape? currentShape,
    int? lane,
    bool? isDashing,
  }) {
    return PlayerData(
      playerId: playerId,
      playerName: playerName,
      score: score ?? this.score,
      distance: distance ?? this.distance,
      isAlive: isAlive ?? this.isAlive,
      isReady: isReady ?? this.isReady,
      teamId: teamId ?? this.teamId,
      currentShape: currentShape ?? this.currentShape,
      lane: lane ?? this.lane,
      isDashing: isDashing ?? this.isDashing,
      lastUpdate: DateTime.now(),
    );
  }
}

class TeamData {
  final String teamId;
  final String teamName;
  final int teamColor; // Color value
  final int totalScore;
  final List<String> playerIds;

  TeamData({
    required this.teamId,
    required this.teamName,
    required this.teamColor,
    this.totalScore = 0,
    required this.playerIds,
  });

  factory TeamData.fromMap(Map<String, dynamic> map) {
    return TeamData(
      teamId: map['teamId'] ?? '',
      teamName: map['teamName'] ?? '',
      teamColor: map['teamColor'] ?? 0,
      totalScore: map['totalScore'] ?? 0,
      playerIds: List<String>.from(map['playerIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teamId': teamId,
      'teamName': teamName,
      'teamColor': teamColor,
      'totalScore': totalScore,
      'playerIds': playerIds,
    };
  }
}

class MultiplayerService extends ChangeNotifier {
  static MultiplayerService? _instance;
  static MultiplayerService get instance => _instance ??= MultiplayerService._();
  MultiplayerService._();

  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
  String? _currentPlayerId;
  String? _currentPlayerName;
  String? _currentGameId;
  MultiplayerGame? _currentGame;
  
  StreamSubscription<DatabaseEvent>? _gameSubscription;
  StreamSubscription<DatabaseEvent>? _publicGamesSubscription;
  
  List<MultiplayerGame> _publicGames = [];
  
  // Getters
  String? get currentPlayerId => _currentPlayerId;
  String? get currentPlayerName => _currentPlayerName;
  String? get currentGameId => _currentGameId;
  MultiplayerGame? get currentGame => _currentGame;
  List<MultiplayerGame> get publicGames => List.unmodifiable(_publicGames);
  bool get isInGame => _currentGameId != null;

  /// Initialize multiplayer service
  Future<void> initialize(String playerName) async {
    _currentPlayerId = _generatePlayerId();
    _currentPlayerName = playerName;
    
    // Start listening to public games
    _listenToPublicGames();
    
    if (kDebugMode) {
      print('MultiplayerService initialized for player: $_currentPlayerName');
    }
  }

  /// Generate unique player ID
  String _generatePlayerId() {
    return 'player_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}';
  }

  /// Generate unique game ID
  String _generateGameId() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  /// Create a new game
  Future<String?> createGame({
    required GameType gameType,
    required bool isPublic,
    required int maxPlayers,
    int raceDistance = 10000,
  }) async {
    if (_currentPlayerId == null || _currentPlayerName == null) {
      return null;
    }

    try {
      final gameId = _generateGameId();
      
      final playerData = PlayerData(
        playerId: _currentPlayerId!,
        playerName: _currentPlayerName!,
        isReady: true, // Host is always ready
        lastUpdate: DateTime.now(),
      );

      final game = MultiplayerGame(
        gameId: gameId,
        hostId: _currentPlayerId!,
        hostName: _currentPlayerName!,
        gameType: gameType,
        isPublic: isPublic,
        maxPlayers: maxPlayers,
        raceDistance: raceDistance,
        status: GameStatus.waiting,
        players: {_currentPlayerId!: playerData},
        teams: _createInitialTeams(gameType),
        createdAt: DateTime.now(),
      );

      await _database.ref('games/$gameId').set(game.toMap());
      await _database.ref('games/$gameId/players/${_currentPlayerId}').set(playerData.toMap());
      
      if (game.teams != null) {
        for (final team in game.teams!.values) {
          await _database.ref('games/$gameId/teams/${team.teamId}').set(team.toMap());
        }
      }

      _currentGameId = gameId;
      _listenToGame(gameId);

      if (kDebugMode) {
        print('Game created: $gameId');
      }

      return gameId;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating game: $e');
      }
      return null;
    }
  }

  /// Create initial teams for team modes
  Map<String, TeamData>? _createInitialTeams(GameType gameType) {
    if (gameType != GameType.teamClassic && gameType != GameType.teamRace) {
      return null;
    }

    return {
      'team_red': TeamData(
        teamId: 'team_red',
        teamName: 'Red Team',
        teamColor: 0xFFFF0000,
        playerIds: [],
      ),
      'team_blue': TeamData(
        teamId: 'team_blue',
        teamName: 'Blue Team',
        teamColor: 0xFF0000FF,
        playerIds: [],
      ),
    };
  }

  /// Join a game by code
  Future<bool> joinGame(String gameId) async {
    if (_currentPlayerId == null || _currentPlayerName == null) {
      return false;
    }

    try {
      final gameRef = _database.ref('games/$gameId');
      final snapshot = await gameRef.get();

      if (!snapshot.exists) {
        if (kDebugMode) {
          print('Game not found: $gameId');
        }
        return false;
      }

      final gameData = Map<String, dynamic>.from(snapshot.value as Map);
      final game = MultiplayerGame.fromMap(gameData, gameId);

      if (game.isFull) {
        if (kDebugMode) {
          print('Game is full');
        }
        return false;
      }

      if (game.status != GameStatus.waiting) {
        if (kDebugMode) {
          print('Game already started');
        }
        return false;
      }

      final playerData = PlayerData(
        playerId: _currentPlayerId!,
        playerName: _currentPlayerName!,
        lastUpdate: DateTime.now(),
      );

      await gameRef.child('players/${_currentPlayerId}').set(playerData.toMap());

      _currentGameId = gameId;
      _listenToGame(gameId);

      if (kDebugMode) {
        print('Joined game: $gameId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error joining game: $e');
      }
      return false;
    }
  }

  /// Leave current game
  Future<void> leaveGame() async {
    if (_currentGameId == null || _currentPlayerId == null) {
      return;
    }

    try {
      final gameRef = _database.ref('games/$_currentGameId');
      
      // Remove player from game
      await gameRef.child('players/$_currentPlayerId').remove();
      
      // If player was in a team, remove from team
      if (_currentGame?.isTeamMode == true) {
        final playerData = _currentGame?.players[_currentPlayerId!];
        if (playerData?.teamId != null) {
          await gameRef.child('teams/${playerData!.teamId}/playerIds').get().then((snapshot) {
            if (snapshot.exists) {
              final playerIds = List<String>.from(snapshot.value as List);
              playerIds.remove(_currentPlayerId);
              gameRef.child('teams/${playerData.teamId}/playerIds').set(playerIds);
            }
          });
        }
      }

      // Check if this was the host - if so, delete the game or transfer host
      if (_currentGame?.hostId == _currentPlayerId) {
        final remainingPlayers = _currentGame?.players.values
            .where((p) => p.playerId != _currentPlayerId)
            .toList();
        
        if (remainingPlayers == null || remainingPlayers.isEmpty) {
          // Delete game if no players left
          await gameRef.remove();
        } else {
          // Transfer host to next player
          final newHost = remainingPlayers.first;
          await gameRef.update({
            'hostId': newHost.playerId,
            'hostName': newHost.playerName,
          });
        }
      }

      _gameSubscription?.cancel();
      _currentGameId = null;
      _currentGame = null;
      
      notifyListeners();

      if (kDebugMode) {
        print('Left game');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error leaving game: $e');
      }
    }
  }

  /// Update player ready status
  Future<void> setReady(bool ready) async {
    if (_currentGameId == null || _currentPlayerId == null) {
      return;
    }

    try {
      await _database.ref('games/$_currentGameId/players/$_currentPlayerId/isReady').set(ready);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting ready: $e');
      }
    }
  }

  /// Join a team
  Future<void> joinTeam(String teamId) async {
    if (_currentGameId == null || _currentPlayerId == null) {
      return;
    }

    try {
      final gameRef = _database.ref('games/$_currentGameId');
      
      // Remove from old team if in one
      final currentTeamId = _currentGame?.players[_currentPlayerId!]?.teamId;
      if (currentTeamId != null) {
        final oldTeamPlayersRef = gameRef.child('teams/$currentTeamId/playerIds');
        final snapshot = await oldTeamPlayersRef.get();
        if (snapshot.exists) {
          final playerIds = List<String>.from(snapshot.value as List);
          playerIds.remove(_currentPlayerId);
          await oldTeamPlayersRef.set(playerIds);
        }
      }

      // Add to new team
      await gameRef.child('players/$_currentPlayerId/teamId').set(teamId);
      
      final newTeamPlayersRef = gameRef.child('teams/$teamId/playerIds');
      final snapshot = await newTeamPlayersRef.get();
      final playerIds = snapshot.exists ? List<String>.from(snapshot.value as List) : <String>[];
      if (!playerIds.contains(_currentPlayerId)) {
        playerIds.add(_currentPlayerId!);
        await newTeamPlayersRef.set(playerIds);
      }

      if (kDebugMode) {
        print('Joined team: $teamId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error joining team: $e');
      }
    }
  }

  /// Start the game (host only)
  Future<bool> startGame() async {
    if (_currentGameId == null || _currentGame == null) {
      return false;
    }

    if (_currentGame!.hostId != _currentPlayerId) {
      if (kDebugMode) {
        print('Only host can start game');
      }
      return false;
    }

    // Check if all players are ready
    final allReady = _currentGame!.players.values.every((p) => p.isReady);
    if (!allReady) {
      if (kDebugMode) {
        print('Not all players are ready');
      }
      return false;
    }

    // For team modes, check teams are balanced
    if (_currentGame!.isTeamMode) {
      final teams = _currentGame!.teams!;
      final teamSizes = teams.values.map((t) => t.playerIds.length).toList();
      if (teamSizes.any((size) => size == 0)) {
        if (kDebugMode) {
          print('All teams must have at least one player');
        }
        return false;
      }
    }

    try {
      await _database.ref('games/$_currentGameId').update({
        'status': GameStatus.inProgress.index,
        'startedAt': DateTime.now().millisecondsSinceEpoch,
      });

      if (kDebugMode) {
        print('Game started');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting game: $e');
      }
      return false;
    }
  }

  /// Update player game state
  Future<void> updatePlayerState({
    int? score,
    double? distance,
    bool? isAlive,
    PlayerShape? currentShape,
    int? lane,
    bool? isDashing,
  }) async {
    if (_currentGameId == null || _currentPlayerId == null) {
      return;
    }

    try {
      final updates = <String, dynamic>{
        'lastUpdate': DateTime.now().millisecondsSinceEpoch,
      };

      if (score != null) updates['score'] = score;
      if (distance != null) updates['distance'] = distance;
      if (isAlive != null) updates['isAlive'] = isAlive;
      if (currentShape != null) updates['currentShape'] = currentShape.index;
      if (lane != null) updates['lane'] = lane;
      if (isDashing != null) updates['isDashing'] = isDashing;

      await _database.ref('games/$_currentGameId/players/$_currentPlayerId').update(updates);
    } catch (e) {
      if (kDebugMode) {
        print('Error updating player state: $e');
      }
    }
  }

  /// End the game
  Future<void> endGame() async {
    if (_currentGameId == null) {
      return;
    }

    try {
      await _database.ref('games/$_currentGameId/status').set(GameStatus.finished.index);
      
      // Calculate team scores for team modes
      if (_currentGame?.isTeamMode == true) {
        for (final team in _currentGame!.teams!.values) {
          int totalScore = 0;
          for (final playerId in team.playerIds) {
            final player = _currentGame!.players[playerId];
            if (player != null) {
              totalScore += player.score;
            }
          }
          await _database.ref('games/$_currentGameId/teams/${team.teamId}/totalScore').set(totalScore);
        }
      }

      if (kDebugMode) {
        print('Game ended');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error ending game: $e');
      }
    }
  }

  /// Listen to game updates
  void _listenToGame(String gameId) {
    _gameSubscription?.cancel();

    _gameSubscription = _database.ref('games/$gameId').onValue.listen((event) {
      if (!event.snapshot.exists) {
        // Game was deleted
        _currentGameId = null;
        _currentGame = null;
        notifyListeners();
        return;
      }

      final gameData = Map<String, dynamic>.from(event.snapshot.value as Map);
      _currentGame = MultiplayerGame.fromMap(gameData, gameId);
      notifyListeners();

      if (kDebugMode) {
        print('Game updated: ${_currentGame!.playerCount} players');
      }
    });
  }

  /// Listen to public games
  void _listenToPublicGames() {
    _publicGamesSubscription?.cancel();

    _publicGamesSubscription = _database.ref('games')
        .orderByChild('isPublic')
        .equalTo(true)
        .onValue.listen((event) {
      if (!event.snapshot.exists) {
        _publicGames = [];
        notifyListeners();
        return;
      }

      final gamesData = Map<String, dynamic>.from(event.snapshot.value as Map);
      _publicGames = gamesData.entries
          .map((entry) => MultiplayerGame.fromMap(
                Map<String, dynamic>.from(entry.value),
                entry.key,
              ))
          .where((game) => 
              game.status == GameStatus.waiting && 
              !game.isFull)
          .toList();

      // Sort by player count (descending)
      _publicGames.sort((a, b) => b.playerCount.compareTo(a.playerCount));

      notifyListeners();

      if (kDebugMode) {
        print('Public games updated: ${_publicGames.length} games');
      }
    });
  }

  /// Update game settings (host only)
  Future<bool> updateGameSettings({
    GameType? gameType,
    bool? isPublic,
    int? maxPlayers,
    int? raceDistance,
  }) async {
    if (_currentGameId == null || _currentGame == null) {
      return false;
    }

    if (_currentGame!.hostId != _currentPlayerId) {
      return false;
    }

    if (_currentGame!.status != GameStatus.waiting) {
      return false;
    }

    try {
      final updates = <String, dynamic>{};
      
      if (gameType != null) updates['gameType'] = gameType.index;
      if (isPublic != null) updates['isPublic'] = isPublic;
      if (maxPlayers != null) updates['maxPlayers'] = maxPlayers;
      if (raceDistance != null) updates['raceDistance'] = raceDistance;

      await _database.ref('games/$_currentGameId').update(updates);

      // If changing to team mode, create teams
      if (gameType != null && (gameType == GameType.teamClassic || gameType == GameType.teamRace)) {
        if (_currentGame!.teams == null) {
          final teams = _createInitialTeams(gameType)!;
          for (final team in teams.values) {
            await _database.ref('games/$_currentGameId/teams/${team.teamId}').set(team.toMap());
          }
        }
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating settings: $e');
      }
      return false;
    }
  }

  /// Clean up old games (run periodically)
  Future<void> cleanupOldGames() async {
    try {
      final snapshot = await _database.ref('games').get();
      if (!snapshot.exists) return;

      final gamesData = Map<String, dynamic>.from(snapshot.value as Map);
      final now = DateTime.now();
      
      for (final entry in gamesData.entries) {
        final gameData = Map<String, dynamic>.from(entry.value);
        final createdAt = DateTime.fromMillisecondsSinceEpoch(gameData['createdAt'] ?? 0);
        
        // Delete games older than 1 hour
        if (now.difference(createdAt).inHours > 1) {
          await _database.ref('games/${entry.key}').remove();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cleaning up games: $e');
      }
    }
  }

  /// Dispose
  void dispose() {
    _gameSubscription?.cancel();
    _publicGamesSubscription?.cancel();
    super.dispose();
  }
}