import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/audio_service.dart';
import '../utils/game_data.dart';

class PrivacyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade900,
              Colors.deepPurple.shade700,
              Colors.purple.shade500,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () { 
                        AudioService.instance.playUIClick();
                        Navigator.of(context).pop();
                      },
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 20),
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy Policy for Morph Runner',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple.shade800,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Effective Date: July 25, 2025\nLast Updated: July 25, 2025',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        SizedBox(height: 20),
                        
                        _buildSection(
                          '1. INTRODUCTION',
                          'This Privacy Policy describes how Paconot Technologies ("we," "us," "our," or "Company") collects, uses, stores, shares, and protects information when you use our mobile application "Morph Runner." This Policy complies with applicable privacy laws including GDPR, CCPA/CPRA, and other regulations.\n\nBy downloading, installing, or using our App, you agree to the collection and use of information in accordance with this Policy.'
                        ),
                        
                        _buildSection(
                          '2. INFORMATION WE COLLECT',
                          'Account Information: If you create an account, we may collect your username, email address, and password.\n\nGame Data: High scores, game statistics, gameplay preferences, and progress data stored locally on your device.\n\nLeaderboard Data: Username (optional), scores, submission timestamps, and device identifiers for competitive features.\n\nDevice Information: Device type, operating system version, unique device identifiers for technical purposes.\n\nUsage Analytics: App usage patterns, feature usage, session duration, and crash reports.\n\nWe Do NOT Collect: Location data, camera/microphone access, contacts, personal files, or biometric data.'
                        ),
                        
                        _buildSection(
                          '3. HOW WE USE YOUR INFORMATION',
                          'Core App Functionality: Providing gaming features, saving progress, personalizing experience.\n\nLeaderboard Services: Displaying global rankings, preventing duplicate submissions, maintaining fair competition.\n\nApp Improvement: Analyzing usage patterns, fixing bugs, developing new features, optimizing performance.\n\nCommunications: Responding to support requests and providing customer service.\n\nLegal Compliance: Complying with applicable laws and protecting our rights.'
                        ),
                        
                        _buildSection(
                          '4. LEADERBOARD AND COMPETITIVE FEATURES',
                          'Public Information: Leaderboard entries (usernames and scores) are publicly visible to all users.\n\nUsername Requirements: 3-20 characters, letters/numbers/hyphens/underscores only, must be unique.\n\nOptional Participation: Leaderboard submission is entirely optional. You can play without participating.\n\nAnonymous Option: You may submit scores anonymously or create a username.\n\nSubmission Limits: One submission per 24-hour period to ensure fair competition.\n\nData Storage: Leaderboard data is stored in Google Firebase/Firestore cloud services.\n\nDevice Tracking: We use device identifiers to prevent spam and ensure submission limits.'
                        ),
                        
                        _buildSection(
                          '5. DATA SHARING AND DISCLOSURE',
                          'We Do NOT Sell Personal Information to third parties.\n\nPublic Leaderboards: Usernames and scores are displayed publicly within the app.\n\nLimited Sharing: We may share information only with trusted service providers (Google Firebase/Firestore, analytics services, customer support), when required by law, in business transfers (with notification), or to protect safety and security.\n\nThird-Party Services: Firebase/Firestore (Google), app stores, analytics services, and advertising networks (with consent where required).'
                        ),
                        
                        _buildSection(
                          '6. THIRD-PARTY SERVICES',
                          'Google Firebase/Firestore: Used for leaderboard data storage and real-time synchronization. Subject to Google\'s Privacy Policy.\n\nGoogle Mobile Ads: Used for advertising services. Subject to Google\'s Advertising Privacy Policy.\n\nApp Store Services: Apple App Store and Google Play Store for app distribution.\n\nAnalytics Services: For app performance monitoring and improvement.'
                        ),
                        
                        _buildSection(
                          '7. YOUR PRIVACY RIGHTS',
                          'All Users: Access, correction, deletion, data portability, and opt-out rights.\n\nLeaderboard Rights: Request removal of your leaderboard entries, change username (subject to availability), or delete all competitive data.\n\nCalifornia Residents (CCPA/CPRA): Right to know, delete, opt-out, correct, limit use of sensitive information, and non-discrimination.\n\nEuropean Users (GDPR): Rectification, erasure ("right to be forgotten"), restriction, objection, data portability, and withdrawal of consent.\n\nTo exercise rights, contact: paconot@paconotenterprises.com'
                        ),
                        
                        _buildSection(
                          '8. CHILDREN\'S PRIVACY',
                          'Our App is suitable for users of all ages. However:\n\n• We do not knowingly collect personal information from children under 13\n• For users aged 13-17, parental consent may be required\n• We comply with COPPA (US) and GDPR (EU) requirements for children\n• Parents can review and request deletion of their child\'s information\n• Leaderboard participation requires username creation, which we recommend parents supervise for minors'
                        ),
                        
                        _buildSection(
                          '9. DATA SECURITY',
                          'We implement industry-standard security measures including:\n\n• Encryption of data in transit and at rest\n• Secure cloud storage with Google Firebase/Firestore\n• Regular security audits and assessments\n• Access controls and authentication protocols\n• Secure coding practices\n• Rate limiting to prevent abuse\n\nData Retention: Game data retained while you use the App, leaderboard data for competitive integrity, analytics data for 2 years maximum, account data deleted within 30 days of account deletion.'
                        ),
                        
                        _buildSection(
                          '10. INTERNATIONAL DATA TRANSFERS',
                          'For users outside the United States:\n\n• Data may be transferred to and processed in the United States and Google\'s global infrastructure\n• We use appropriate safeguards including Standard Contractual Clauses\n• Google Firebase/Firestore complies with international data protection requirements\n• Transfers comply with applicable data protection laws'
                        ),
                        
                        _buildSection(
                          '11. COOKIES AND TRACKING',
                          'We use local storage for game data, analytics SDKs for performance monitoring, Firebase for leaderboard synchronization, and advertising IDs for personalized ads (with consent).\n\nYour Choices: Control tracking through app settings, device settings (limit ad tracking), and in-app preferences. You can disable leaderboard features entirely in settings.'
                        ),
                        
                        _buildSection(
                          '12. DATA BREACH NOTIFICATION',
                          'In the event of a data breach affecting personal information:\n\n• We will notify affected users within 72 hours when feasible\n• Notification will include nature of breach, data involved, and steps being taken\n• We will cooperate with relevant authorities as required by law\n• Leaderboard data breaches will be communicated through in-app notifications'
                        ),
                        
                        _buildSection(
                          '13. POLICY UPDATES',
                          'We may update this Policy periodically. Material changes will be notified through the App or email. Continued use constitutes acceptance of changes.\n\nFor significant changes affecting leaderboard features, we will provide prominent notice and may require re-acceptance.'
                        ),
                        
                        _buildSection(
                          '14. CONTACT INFORMATION',
                          'Paconot Technologies\n\nGeneral Contact: paconot@paconotenterprises.com\nPrivacy Officer: paconot@paconotenterprises.com\nData Protection Officer: paconot@paconotenterprises.com\nCalifornia Privacy Rights: paconot@paconotenterprises.com\nLeaderboard Issues: paconot@paconotenterprises.com\nWebsite: ${GameData.companyWebsite}'
                        ),
                        
                        SizedBox(height: 30),
                        
                        // Contact buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildContactButton(
                              'Email Us',
                              Icons.email,
                              () => _launchEmail(),
                            ),
                            _buildContactButton(
                              'Exercise Rights',
                              Icons.security,
                              () => _launchRightsEmail(),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.deepPurple.shade200),
                          ),
                          child: Text(
                            'Summary: Morph Runner respects your privacy. We collect minimal data for game functionality and optional leaderboards, don\'t sell personal information, and provide full control over your data. Leaderboard participation is optional and usernames/scores are publicly displayed. All data processing complies with GDPR, CCPA, and other privacy laws.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.deepPurple.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Leaderboard specific notice
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.leaderboard, color: Colors.blue.shade700, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Leaderboard Privacy Notice',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Leaderboard participation is optional. If you choose to participate, your username and scores will be publicly visible to other players. You can submit anonymously or create a unique username. Submission is limited to once per day for fair competition.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        Text(
                          'Last Review Date: January 1, 2025\nNext Scheduled Review: January 1, 2026\nVersion: 2.0 (Updated for Leaderboard Features)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple.shade700,
          ),
        ),
        SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade800,
            height: 1.5,
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildContactButton(String text, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'paconot@paconotenterprises.com',
      query: 'subject=Morph Runner - Privacy Inquiry',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchRightsEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'paconot@paconotenterprises.com',
      query: 'subject=Morph Runner - Privacy Rights Request&body=Please specify your request: Access, Correction, Deletion, Opt-out, Leaderboard Data Removal, or other privacy rights.',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}