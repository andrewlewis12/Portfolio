import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/audio_service.dart';
import '../utils/game_data.dart';
import '../widgets/shape_widget.dart';

class LegalAcceptanceScreen extends StatefulWidget {
  @override
  _LegalAcceptanceScreenState createState() => _LegalAcceptanceScreenState();
}

class _LegalAcceptanceScreenState extends State<LegalAcceptanceScreen>
    with SingleTickerProviderStateMixin {
  bool termsAccepted = false;
  bool privacyAccepted = false;
  bool canProceed = false;
  
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
  
  void _updateCanProceed() {
    setState(() {
      canProceed = termsAccepted && privacyAccepted;
    });
  }
  
  Future<void> _acceptAndProceed() async {
    if (canProceed) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('legal_accepted', true);
      // CHANGED: Navigate to username setup instead of tutorial
      Navigator.pushReplacementNamed(context, '/username_setup');
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
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: SingleChildScrollView(
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
                          
                          SizedBox(height: 30),
                          
                          // Welcome message
                          Container(
                            padding: EdgeInsets.all(15),
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
                                Text(
                                  'Welcome to Morph Runner!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple.shade800,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Before you start your shape-shifting adventure, please accept our Terms of Service and Privacy Policy.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.3,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 30),
                          
                          // Terms and Privacy checkboxes
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white30),
                            ),
                            child: Column(
                              children: [
                                // Terms checkbox
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: termsAccepted,
                                        onChanged: (bool? value) {
                                          AudioService.instance.playUIClick();
                                          setState(() {
                                            termsAccepted = value ?? false;
                                          });
                                          _updateCanProceed();
                                        },
                                        activeColor: Colors.green,
                                        checkColor: Colors.white,
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => Navigator.pushNamed(context, '/terms'),
                                        child: Text(
                                          'I accept the Terms of Service',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                SizedBox(height: 10),
                                
                                // Privacy checkbox
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: privacyAccepted,
                                        onChanged: (bool? value) {
                                          AudioService.instance.playUIClick();
                                          setState(() {
                                            privacyAccepted = value ?? false;
                                          });
                                          _updateCanProceed();
                                        },
                                        activeColor: Colors.green,
                                        checkColor: Colors.white,
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => Navigator.pushNamed(context, '/privacy'),
                                        child: Text(
                                          'I accept the Privacy Policy',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: 30),
                          
                          // Continue button
                          Container(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: canProceed
                                ? () {
                                    _acceptAndProceed();
                                    AudioService.instance.playUIClick();
                                  }
                                : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canProceed ? Colors.green : Colors.grey.shade600,
                                foregroundColor: Colors.white,
                                elevation: canProceed ? 8 : 0,
                                shadowColor: canProceed ? Colors.green.withOpacity(0.5) : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    canProceed ? Icons.check_circle : Icons.info_outline,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      canProceed ? 'CONTINUE' : 'ACCEPT BOTH TO CONTINUE',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
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
    _animationController.dispose();
    super.dispose();
  }
}