// FILE: lib/screens/username_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';
import '../services/leaderboard_service.dart';
import '../widgets/shape_widget.dart';
import '../utils/game_data.dart';

class UsernameSetupScreen extends StatefulWidget {
  @override
  _UsernameSetupScreenState createState() => _UsernameSetupScreenState();
}

class _UsernameSetupScreenState extends State<UsernameSetupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  bool _isChecking = false;
  bool _isAvailable = false;
  String? _availabilityMessage;
  bool _canProceed = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
  }

  void _checkUsername(String value) async {
    if (value.trim().length >= 3) {
      setState(() {
        _isChecking = true;
        _availabilityMessage = 'Checking availability...';
        _canProceed = false;
      });
      
      final available = await LeaderboardService.instance.isUsernameAvailable(value.trim());
      
      setState(() {
        _isChecking = false;
        _isAvailable = available;
        if (available) {
          _availabilityMessage = '✓ Username available';
          _canProceed = true;
        } else {
          _availabilityMessage = '✗ Username taken';
          _canProceed = false;
        }
      });
    } else {
      setState(() {
        _isChecking = false;
        _isAvailable = false;
        _canProceed = false;
        _availabilityMessage = value.trim().isEmpty 
            ? null 
            : 'Minimum 3 characters';
      });
    }
  }

  Future<void> _saveUsername() async {
    if (!_canProceed) return;
    
    final username = _usernameController.text.trim();
    final success = await LeaderboardService.instance.setPlayerName(username);
    
    if (success) {
      await _completeSetup();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to set username. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _chooseAnonymous() async {
    await LeaderboardService.instance.setAnonymousMode();
    await _completeSetup();
  }

  Future<void> _completeSetup() async {
    // Mark username setup as completed
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('username_setup_completed', true);
    
    // Navigate to home
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade600,
              Colors.purple.shade400,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        
                        // App Logo
                        Column(
                          children: [
                            Container(
                              height: 50,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: PlayerShape.values.take(4).map((shape) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 3),
                                    child: ShapeWidget(
                                      shape: shape,
                                      size: 25,
                                      animate: true,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'MORPH',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 4,
                                shadows: [
                                  Shadow(
                                    blurRadius: 15.0,
                                    color: Colors.purple.shade300,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'RUNNER',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w300,
                                color: Colors.white,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10.0,
                                    color: Colors.purple.shade300,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              height: 50,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: PlayerShape.values.skip(4).map((shape) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 3),
                                    child: ShapeWidget(
                                      shape: shape,
                                      size: 25,
                                      animate: true,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 40),
                        
                        // Title
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 10,
                                offset: Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.leaderboard,
                                size: 48,
                                color: Colors.deepPurple.shade700,
                              ),
                              SizedBox(height: 15),
                              Text(
                                'Choose Your Display Name',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'This name will appear on the leaderboard when you submit scores. You can play anonymously or create a unique username.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 30),
                        
                        // Username input section
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Username',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 15),
                              
                              TextField(
                                controller: _usernameController,
                                style: TextStyle(color: Colors.white),
                                maxLength: 20,
                                onChanged: _checkUsername,
                                decoration: InputDecoration(
                                  hintText: 'Your username',
                                  hintStyle: TextStyle(color: Colors.white60),
                                  filled: true,
                                  fillColor: Colors.white.withOpacity(0.1),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white60),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.cyan, width: 2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  counterStyle: TextStyle(color: Colors.white60),
                                  suffixIcon: _isChecking 
                                      ? Padding(
                                          padding: EdgeInsets.all(12),
                                          child: SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              
                              if (_availabilityMessage != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Text(
                                    _availabilityMessage!,
                                    style: TextStyle(
                                      color: _isAvailable ? Colors.green : Colors.red,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              
                              SizedBox(height: 15),
                              
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Username Requirements:',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      '• 3-20 characters\n• Letters, numbers, hyphens (-) and underscores (_) only\n• Must be unique',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 25),
                        
                        // Save username button
                        Container(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _canProceed
                                ? () {
                                    AudioService.instance.playUIClick();
                                    _saveUsername();
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canProceed ? Colors.green : Colors.grey.shade600,
                              foregroundColor: Colors.white,
                              elevation: _canProceed ? 8 : 0,
                              shadowColor: _canProceed ? Colors.green.withOpacity(0.5) : Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _canProceed ? Icons.check_circle : Icons.info_outline,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _canProceed ? 'SAVE USERNAME' : 'ENTER VALID USERNAME',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // OR divider
                        Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white30, thickness: 1)),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10),
                              child: Text(
                                'OR',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Expanded(child: Divider(color: Colors.white30, thickness: 1)),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Play anonymously button
                        Container(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              AudioService.instance.playUIClick();
                              _chooseAnonymous();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white70, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.person_off, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'PLAY ANONYMOUSLY',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Info box
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.orange.shade300, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'You can change this later in the Settings menu',
                                  style: TextStyle(
                                    color: Colors.orange.shade200,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 15),
                        
                        // Company info
                        Text(
                          'By ${GameData.companyName}',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                          ),
                        ),
                        
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}