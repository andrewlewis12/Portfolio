import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/game_service.dart';
import 'game_screen.dart';
import 'menu_screen.dart';

class TrailerGameScreen extends StatefulWidget {
  final String sceneType;
  
  const TrailerGameScreen({
    Key? key,
    required this.sceneType,
  }) : super(key: key);

  @override
  State<TrailerGameScreen> createState() => _TrailerGameScreenState();
}

class _TrailerGameScreenState extends State<TrailerGameScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Game background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    Colors.grey.shade900,
                    Colors.black,
                  ],
                ),
              ),
            ),
            
            // Main game content
            const GravBlastScreen(isTutorialMode: false),
            
          ],
        ),
      ),
    );
  }
  
  String _getSceneDescription(String sceneType) {
    switch (sceneType) {
      case 'piece_placement':
        return 'Showcase strategic piece placement and pattern building';
      case 'line_clear':
        return 'Demonstrate line clearing mechanics and gravity effects';
      case 'combo':
        return 'Show off explosive combo chains and cascading clears';
      case 'full_gameplay':
        return 'Complete gameplay experience with all UI elements';
      default:
        return 'Recording mode active';
    }
  }
}