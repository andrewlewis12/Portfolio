import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/audio_service.dart';
import '../utils/game_data.dart';

class TermsScreen extends StatelessWidget {
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
                        'Terms of Service',
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
                          'Terms of Service for Morph Runner',
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
                          '1. AGREEMENT TO TERMS',
                          'These Terms of Service constitute a legally binding agreement between you and Paconot Technologies regarding your use of the Morph Runner mobile application.\n\nBY DOWNLOADING, INSTALLING, ACCESSING, OR USING THE APP, YOU AGREE TO BE BOUND BY THESE TERMS. IF YOU DO NOT AGREE, DO NOT USE THE APP.'
                        ),
                        
                        _buildSection(
                          '2. DESCRIPTION OF SERVICE',
                          'Morph Runner is a mobile gaming application that provides an endless runner experience with shape-shifting mechanics. The App includes:\n\n• Single-player gameplay\n• Score tracking and statistics\n• Global leaderboards and competitive features\n• Game settings and preferences\n• Optional social features\n\nAvailable on Apple App Store and Google Play Store.'
                        ),
                        
                        _buildSection(
                          '3. USER ACCOUNTS AND REGISTRATION',
                          'Account creation is optional for basic gameplay. If you create an account or participate in leaderboards:\n\n• You must provide accurate and complete information\n• You are responsible for maintaining account security\n• Choose strong passwords and notify us of unauthorized access\n• Usernames must comply with our community guidelines\n• We may suspend or terminate accounts for Terms violations\n• You may participate anonymously in leaderboards'
                        ),
                        
                        _buildSection(
                          '4. LEADERBOARD AND COMPETITIVE FEATURES',
                          'Participation Rules:\n• Leaderboard participation is entirely optional\n• One score submission per 24-hour period\n• Scores must be achieved through legitimate gameplay\n• Usernames must be appropriate and comply with guidelines\n\nUsername Requirements:\n• 3-20 characters in length\n• Letters, numbers, hyphens, and underscores only\n• Must be unique across the platform\n• Cannot contain offensive or inappropriate content\n\nProhibited Leaderboard Activities:\n• Using automated tools or bots\n• Score manipulation or cheating\n• Creating multiple accounts for submission\n• Submitting inappropriate usernames\n• Circumventing rate limits'
                        ),
                        
                        _buildSection(
                          '5. LICENSE TO USE',
                          'We grant you a limited, non-exclusive, non-transferable, revocable license to:\n\n• Download and install the App on compatible devices\n• Use the App for personal, non-commercial purposes\n• Access and use the App\'s features and content\n• Participate in leaderboards and competitive features\n\nYou may NOT modify, reverse engineer, distribute, or use the App for commercial purposes without permission.'
                        ),
                        
                        _buildSection(
                          '6. ACCEPTABLE USE POLICY',
                          'Permitted Uses: Play the game, track statistics, customize settings, participate in leaderboards, contact support.\n\nProhibited Activities:\n• Violating laws or third-party rights\n• Hacking or compromising security\n• Using automated tools for unfair advantages\n• Cheating or exploiting game mechanics\n• Interfering with other users or leaderboards\n• Distributing malicious code\n• Creating inappropriate usernames\n• Harassing or impersonating other users\n• Submitting false or misleading scores'
                        ),
                        
                        _buildSection(
                          '7. COMMUNITY GUIDELINES',
                          'Username and Interaction Standards:\n• Keep usernames family-friendly and appropriate\n• No hate speech, discrimination, or offensive content\n• No impersonation of other users or public figures\n• No spam or promotional content\n• No sharing of personal information\n• Respect other players and maintain good sportsmanship\n\nWe reserve the right to remove inappropriate usernames and ban users who violate these guidelines.'
                        ),
                        
                        _buildSection(
                          '8. INTELLECTUAL PROPERTY RIGHTS',
                          'The App and all content are owned by Paconot Technologies and protected by copyright, trademark, and other intellectual property laws. This includes:\n\n• Software code and architecture\n• Game design and mechanics\n• Graphics, images, and visual elements\n• Audio, music, and sound effects\n• User interface design\n• Leaderboard system and algorithms\n• Trademarks and logos\n\nUser-Generated Content: By choosing a username, you grant us a license to display it publicly in leaderboards.'
                        ),
                        
                        _buildSection(
                          '9. PRIVACY AND DATA PROTECTION',
                          'Your privacy is important to us. Our collection, use, and protection of your information is governed by our Privacy Policy, which is incorporated into these Terms.\n\nLeaderboard Data: By participating in leaderboards, you understand that your username and scores will be publicly visible. You may submit anonymously if preferred.\n\nBy using the App, you consent to data processing as described in our Privacy Policy.'
                        ),
                        
                        _buildSection(
                          '10. THIRD-PARTY SERVICES',
                          'The App integrates with third-party services:\n\n• Google Firebase/Firestore for leaderboard data\n• Google Mobile Ads for advertising\n• App store services for distribution\n• Analytics services for performance monitoring\n\nThese services have their own terms and privacy policies that apply to your use.'
                        ),
                        
                        _buildSection(
                          '11. DISCLAIMERS AND WARRANTIES',
                          'THE APP IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND.\n\nWe do not warrant that:\n• The App will be uninterrupted or error-free\n• Leaderboards will be available 24/7\n• Defects will be corrected promptly\n• The App will meet your specific requirements\n• Data transmission will be secure\n• Leaderboard data will be permanently preserved'
                        ),
                        
                        _buildSection(
                          '12. LIMITATION OF LIABILITY',
                          'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR:\n\n• Indirect, incidental, or consequential damages\n• Loss of profits, data, or goodwill\n• Damages from unauthorized access to your data\n• Third-party conduct or content\n• Leaderboard data loss or corruption\n• Disputes between users\n\nOur total liability shall not exceed \$100 or the amount you paid us in the preceding 12 months.'
                        ),
                        
                        _buildSection(
                          '13. CONTENT MODERATION',
                          'We reserve the right to:\n\n• Monitor leaderboard content and usernames\n• Remove inappropriate or offensive usernames\n• Suspend or ban users who violate guidelines\n• Reset or adjust scores that appear to be manipulated\n• Take action against cheating or exploitation\n\nModeration decisions are at our sole discretion. Repeat violations may result in permanent bans.'
                        ),
                        
                        _buildSection(
                          '14. TERMINATION',
                          'You may stop using the App at any time. We may suspend or terminate access for:\n\n• Violation of these Terms\n• Violation of applicable laws\n• Suspected fraudulent activity\n• Cheating or exploitation\n• Inappropriate leaderboard conduct\n• Extended periods of inactivity\n\nUpon termination, your right to use the App ends immediately. Leaderboard entries may be removed at our discretion.'
                        ),
                        
                        _buildSection(
                          '15. DISPUTE RESOLUTION',
                          'Before filing legal action, contact us at paconot@paconotenterprises.com to resolve disputes informally.\n\nFor leaderboard disputes, provide specific details about usernames, scores, and submission times.\n\nAny unresolved disputes shall be resolved through binding arbitration. YOU WAIVE ANY RIGHT TO PARTICIPATE IN CLASS ACTION LAWSUITS.'
                        ),
                        
                        _buildSection(
                          '16. AGE REQUIREMENTS',
                          'Users must be at least 13 years old. Users under 18 must have parental consent. For users under 18:\n\n• Parents/guardians are responsible for monitoring usage\n• Parents may request account deletion at any time\n• We recommend parental supervision for leaderboard participation\n• We comply with children\'s privacy laws (COPPA, GDPR)'
                        ),
                        
                        _buildSection(
                          '17. CHANGES TO TERMS',
                          'We may update these Terms periodically. Material changes will be notified through the App or email. Continued use constitutes acceptance of changes.\n\nFor changes affecting leaderboard features, we will provide prominent notice and may require re-acceptance.'
                        ),
                        
                        _buildSection(
                          '18. CONTACT INFORMATION',
                          'For questions about these Terms:\n\nPaconot Technologies\nLegal Department: paconot@paconotenterprises.com\nSupport: paconot@paconotenterprises.com\nLeaderboard Issues: paconot@paconotenterprises.com\nWebsite: ${GameData.companyWebsite}'
                        ),
                        
                        SizedBox(height: 30),
                        
                        // Contact buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildContactButton(
                              'Legal Questions',
                              Icons.gavel,
                              () => _launchLegalEmail(),
                            ),
                            _buildContactButton(
                              'Support',
                              Icons.support_agent,
                              () => _launchSupportEmail(),
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
                            'Summary: These terms protect both you and us while you enjoy Morph Runner. Play responsibly, respect intellectual property, follow leaderboard guidelines, and contact us with any questions. Terms comply with app store requirements and applicable laws.',
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
                                    'Leaderboard Terms Notice',
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
                                'Leaderboard participation is optional and subject to fair play rules. Cheating, automation, or inappropriate usernames will result in removal and potential account suspension. Submit scores legitimately and maintain good sportsmanship.',
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
                        
                        // Platform disclaimers
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Platform Disclaimers',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Apple App Store: Apple is not responsible for the App or claims relating to it.\n\nGoogle Play Store: Google is not responsible for the App or claims relating to it.\n\nGoogle Firebase/Firestore: Used for leaderboard services, subject to Google\'s terms.\n\nAll claims should be directed to Paconot Technologies.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 20),
                        
                        Text(
                          'Current Version: 2.1 (Updated for Leaderboard Features)\nEffective Date: January 1, 2025\nPrevious Version: 2.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: 20),
                        
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Text(
                            'ACKNOWLEDGMENT\n\nBY USING THE APP, INCLUDING LEADERBOARD FEATURES, YOU ACKNOWLEDGE THAT YOU HAVE READ THESE TERMS, UNDERSTAND THEM, AND AGREE TO BE BOUND BY THEIR CONDITIONS.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
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

  void _launchLegalEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'paconot@paconotenterprises.com',
      query: 'subject=Morph Runner - Legal Question',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'paconot@paconotenterprises.com',
      query: 'subject=Morph Runner - Support Request',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }
}