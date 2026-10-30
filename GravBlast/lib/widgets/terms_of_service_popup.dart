// terms_of_service_popup.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/audio_service.dart';

class TermsOfServicePopup extends StatelessWidget {
  const TermsOfServicePopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.cyan.withOpacity(0.5),
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.description, color: Colors.cyan, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Terms of Service',
            style: TextStyle(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Last Updated',
                'These Terms of Service were last updated on July 19, 2025. We may update these terms from time to time, and your continued use of Grav Blast constitutes acceptance of any changes.',
              ),
              
              _buildSection(
                'Acceptance of Terms',
                'By downloading, installing, accessing, or using Grav Blast ("the Game"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree with these terms, please do not download, install, or use the Game.\n\nThese Terms constitute a legal agreement between you and Paconot Technologies ("Company," "we," "us," or "our").',
              ),
              
              _buildSection(
                'Eligibility and Age Requirements',
                'You must be at least 13 years old to use Grav Blast. If you are between 13 and 17 years old (or the age of majority in your jurisdiction), you must have permission from a parent or legal guardian to use the Game.\n\nIf you are under 13, you are not permitted to use the Game. Parents or guardians may contact us to report underage use.\n\nBy using the Game, you represent and warrant that you meet these age requirements.',
              ),
              
              _buildSection(
                'License to Use',
                'Subject to these Terms, Paconot Technologies grants you a limited, non-exclusive, non-transferable, revocable license to:\n\n'
                '• Download and install Grav Blast on your personal mobile device\n'
                '• Use the Game for personal, non-commercial entertainment purposes only\n'
                '• Access and use the Game\'s features and content\n\n'
                'This license does not grant you any ownership rights in the Game or its content. All rights not expressly granted are reserved by Paconot Technologies.',
              ),
              
              _buildSection(
                'Game Rules and Acceptable Use',
                'When using Grav Blast, you agree to:\n\n'
                '• Use the Game only for lawful purposes and in accordance with these Terms\n'
                '• Not attempt to hack, modify, reverse engineer, or decompile the Game\n'
                '• Not use cheats, exploits, automation software, bots, hacks, mods, or any unauthorized third-party software\n'
                '• Not create multiple accounts to manipulate leaderboards or gain unfair advantages\n'
                '• Not interfere with or disrupt the Game\'s servers or networks\n'
                '• Not attempt to gain unauthorized access to any part of the Game or related systems\n'
                '• Not remove, alter, or obscure any proprietary notices from the Game',
              ),
              
              _buildSection(
                'Intellectual Property Rights',
                'Grav Blast and all its content, including but not limited to:\n\n'
                '• Game software, code, and mechanics\n'
                '• Graphics, artwork, animations, and visual effects\n'
                '• Audio, music, sound effects, and voice recordings\n'
                '• Game design, characters, and storylines\n'
                '• User interface and game flow\n'
                '• Logos, trademarks, and brand elements\n\n'
                'Are owned by Paconot Technologies and protected by copyright, trademark, and other intellectual property laws. You may not copy, distribute, reproduce, modify, or create derivative works of any Game content without our express written permission.',
              ),
              
              _buildSection(
                'Virtual Items and Game Currency',
                'Grav Blast may include virtual items, currency, or other digital content ("Virtual Items"). You understand and agree that:\n\n'
                '• Virtual Items have no real-world monetary value\n'
                '• You do not own Virtual Items; you only receive a limited license to use them within the Game\n'
                '• Virtual Items cannot be transferred, sold, traded, or exchanged for real currency\n'
                '• We may modify, suspend, or discontinue Virtual Items at any time\n'
                '• Virtual Items are forfeited if your account is terminated or suspended',
              ),
              
              _buildSection(
                'In-App Purchases and Payments',
                'Grav Blast may offer in-app purchases through your device\'s app store (Google Play Store, Apple App Store). You agree that:\n\n'
                '• All purchases are processed by the respective app store, not directly by us\n'
                '• You are responsible for all charges incurred on your account\n'
                '• Prices may change without notice\n'
                '• We are not responsible for any app store billing issues\n'
                '• Contact your app store directly for billing disputes or payment issues',
              ),
              
              _buildSection(
                'Refund Policy',
                'All in-app purchases are final and non-refundable, except as required by applicable law or app store policies. For refund requests:\n\n'
                '• Android Users: Contact Google Play Store customer support\n'
                '• iOS Users: Contact Apple App Store customer support\n'
                '• We do not process direct refunds outside of app store policies\n\n'
                'Refund eligibility is determined by the app store\'s terms and policies, not by these Terms. Account suspension or termination for Terms violations does not entitle you to any refunds.',
              ),
              
              _buildSection(
                'Advertising',
                'Grav Blast displays advertisements provided by third-party advertising networks, including Google AdMob. You acknowledge that:\n\n'
                '• Ads are provided by third parties and we do not control their content\n'
                '• We are not responsible for the accuracy or appropriateness of third-party ads\n'
                '• Clicking on ads may redirect you to external websites or apps\n'
                '• You interact with advertisements at your own risk\n'
                '• Ad revenue helps us provide the Game for free',
              ),
              
              _buildSection(
                'Privacy and Data Collection',
                'Your privacy is important to us. Our collection, use, and disclosure of your information is governed by our Privacy Policy, which is incorporated into these Terms by reference. By using the Game, you consent to our Privacy Policy.\n\nKey points:\n\n'
                '• We collect limited data to provide and improve the Game\n'
                '• Third-party services (like AdMob) may collect data for advertising\n'
                '• Your game progress is stored locally on your device\n'
                '• You can control advertising preferences through your device settings',
              ),
              
              _buildSection(
                'Account Termination and Suspension',
                'We reserve the right to suspend or terminate your access to Grav Blast at any time, with or without notice, for:\n\n'
                '• Violation of these Terms\n'
                '• Fraudulent, abusive, or illegal activity\n'
                '• Technical or security reasons\n'
                '• Extended periods of inactivity\n\n'
                'You may stop using the Game at any time by deleting it from your device. Upon termination:\n\n'
                '• Your license to use the Game immediately ends\n'
                '• You lose access to all Virtual Items and game progress\n'
                '• No refunds will be provided for terminated accounts',
              ),
              
              _buildSection(
                'Game Availability and Updates',
                'We strive to keep Grav Blast available and functional, but we cannot guarantee uninterrupted service. We reserve the right to:\n\n'
                '• Modify, update, or discontinue the Game at any time\n'
                '• Perform maintenance that may temporarily interrupt service\n'
                '• Change game features, mechanics, or content\n'
                '• Remove the Game from app stores\n\n'
                'We will provide reasonable notice of significant changes when possible, but are not obligated to do so.',
              ),
              
              _buildSection(
                'Disclaimers and Warranties',
                'Grav Blast is provided "AS IS" and "AS AVAILABLE" without warranties of any kind. To the fullest extent permitted by law, we disclaim all warranties, including:\n\n'
                '• Implied warranties of merchantability and fitness for a particular purpose\n'
                '• Warranties that the Game will be uninterrupted, error-free, or secure\n'
                '• Warranties regarding the accuracy or reliability of any content\n\n'
                'Your use of the Game is at your own risk. We do not warrant that the Game will meet your expectations or requirements.',
              ),
              
              _buildSection(
                'Limitation of Liability',
                'To the maximum extent permitted by applicable law, Paconot Technologies shall not be liable for any:\n\n'
                '• Indirect, incidental, special, or consequential damages\n'
                '• Loss of profits, data, or business opportunities\n'
                '• Damages arising from your use or inability to use the Game\n'
                '• Damages related to third-party content or advertisements\n\n'
                'Our total liability to you for any claims related to the Game shall not exceed the amount you paid for in-app purchases in the 12 months preceding the claim.',
              ),
              
              _buildSection(
                'Indemnification',
                'You agree to defend, indemnify, and hold harmless Paconot Technologies from any claims, damages, or expenses (including reasonable attorneys\' fees) arising from:\n\n'
                '• Your use of the Game\n'
                '• Your violation of these Terms\n'
                '• Your violation of any third-party rights\n'
                '• Any content you submit or transmit through the Game',
              ),
              
              _buildSection(
                'Governing Law and Disputes',
                'These Terms are governed by the laws of the state of Texas, without regard to conflict of law principles. Any disputes arising from these Terms or your use of the Game shall be resolved through:\n\n'
                '• Good faith negotiations first\n'
                '• Binding arbitration if negotiations fail (where permitted by law)\n'
                '• Courts of competent jurisdiction in the state of Texas if arbitration is not available\n\n'
                'You waive any right to participate in class action lawsuits or class-wide arbitration.',
              ),
              
              _buildSection(
                'Severability and Entire Agreement',
                'If any provision of these Terms is found to be unenforceable, the remaining provisions will remain in full force and effect. These Terms, together with our Privacy Policy, constitute the entire agreement between you and Paconot Technologies regarding Grav Blast.\n\nNo waiver of any term shall be deemed a further or continuing waiver of such term or any other term.',
              ),
              
              _buildSection(
                'Changes to Terms',
                'We may modify these Terms at any time by posting the revised terms within the Game or on our website. Material changes will be effective 30 days after posting. Your continued use of the Game after changes become effective constitutes acceptance of the new Terms.\n\nIf you do not agree to modified Terms, you must stop using the Game.',
              ),
              
              _buildSection(
                'Contact Information',
                'For questions, concerns, or notices regarding these Terms of Service, please contact us:\n\n'
                'Paconot Technologies\n'
                'Website: paconotenterprises.com/contact\n'
                'Email: paconot@paconotenterprises.com\n\n'
                'We will respond to legitimate inquiries within a reasonable time frame.',
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: const Text(
                  'Last Updated: July 19, 2025\n© 2025 Paconot Technologies. All rights reserved.\n\nBy using Grav Blast, you acknowledge that you have read, understood, and agree to be bound by these Terms of Service.',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<AudioService>().playUIClick();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.cyan, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class PrivacyPolicyPopup extends StatelessWidget {
  const PrivacyPolicyPopup({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.black.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Colors.cyan.withOpacity(0.5),
          width: 2,
        ),
      ),
      title: Row(
        children: [
          Icon(Icons.privacy_tip, color: Colors.cyan, size: 24),
          const SizedBox(width: 8),
          const Text(
            'Privacy Policy',
            style: TextStyle(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.6,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                'Last Updated',
                'This Privacy Policy was last updated on July 19, 2025. We may update this policy from time to time to reflect changes in our practices or legal requirements.',
              ),
              
              _buildSection(
                'Who We Are',
                'Grav Blast is developed and operated by Paconot Technologies ("we," "us," or "our"). We are committed to protecting your privacy and being transparent about how we collect, use, and protect your information.',
              ),
              
              _buildSection(
                'Information We Collect',
                'When you play Grav Blast, we may collect the following information:\n\n'
                '• Game Data: Your game progress, high scores, level achievements, and gameplay statistics (stored locally on your device)\n'
                '• Device Information: Device type, operating system version, device model, and unique device identifiers (AAID on Android, IDFA on iOS)\n'
                '• Usage Data: How you interact with the game, time spent playing, features used, and app performance data\n'
                '• Technical Data: IP address, app version, crash reports, error logs, and diagnostic information\n'
                '• Audio Settings: Your sound and volume preferences (stored locally)\n'
                '• Advertising Data: Ad views, clicks, and interaction data for personalized advertising',
              ),
              
              _buildSection(
                'How We Collect Information',
                'We collect information in the following ways:\n\n'
                '• Directly from You: When you adjust game settings, accept our terms, or interact with game features\n'
                '• Automatically: Through your gameplay and device interactions with our app\n'
                '• From Third Parties: Through advertising networks and analytics services\n'
                '• Device Storage: Using local storage to save your preferences and game progress',
              ),
              
              _buildSection(
                'Third-Party Services and Data Sharing',
                'Grav Blast integrates with the following third-party services that may collect your data:\n\n'
                '• Google AdMob: Provides advertising services and collects device identifiers, IP address, ad interaction data, and usage patterns for targeted advertising\n'
                '• Google Mobile Ads SDK: Enables ad serving and collects similar data to AdMob for ad optimization\n'
                '• Flutter SoLoud: Audio engine for game sounds (does not collect personal data)\n'
                '• Device Operating System: For local data storage and crash reporting\n\n'
                'We do not sell your personal information to third parties. However, ad networks may share data with their partners for advertising purposes under their own privacy policies.',
              ),
              
              _buildSection(
                'How We Use Your Information',
                'We use your information for the following purposes:\n\n'
                '• Game Functionality: To provide core game features, save your progress, and maintain your preferences\n'
                '• Performance Improvement: To fix bugs, improve game performance, and enhance user experience\n'
                '• Advertising: To display relevant ads and measure ad effectiveness\n'
                '• Analytics: To understand how players use our game and improve gameplay\n'
                '• Legal Compliance: To comply with applicable laws and respond to legal requests\n'
                '• Communication: To respond to your inquiries and provide customer support',
              ),
              
              _buildSection(
                'Legal Basis for Processing (GDPR)',
                'If you are in the European Union, we process your personal data based on:\n\n'
                '• Legitimate Interest: For game analytics, performance monitoring, and advertising\n'
                '• Consent: For personalized advertising and non-essential data collection (you can withdraw consent anytime)\n'
                '• Contract Performance: To provide the game services you requested\n'
                '• Legal Obligation: To comply with applicable laws and regulations',
              ),
              
              _buildSection(
                'Data Storage and Security',
                'Your game data is primarily stored locally on your device using secure storage mechanisms. We implement appropriate technical and organizational measures to protect your information:\n\n'
                '• Encryption: Data transmitted to third parties is encrypted\n'
                '• Access Controls: Limited access to personal data by authorized personnel only\n'
                '• Regular Updates: We regularly update our security measures\n'
                '• Third-Party Security: We work only with reputable third-party services that maintain appropriate security standards',
              ),
              
              _buildSection(
                'Data Retention',
                'We retain your information for the following periods:\n\n'
                '• Game Progress: Until you delete the app from your device\n'
                '• Audio Settings: Until you delete the app or reset settings\n'
                '• Advertising Data: Maximum 90 days as per AdMob policies\n'
                '• Crash Reports: Maximum 90 days for debugging purposes\n'
                '• Analytics Data: Aggregated and anonymized data may be retained longer for business insights',
              ),
              
              _buildSection(
                'Your Privacy Rights',
                'Depending on your location, you may have the following rights:\n\n'
                '• Access: Request information about what personal data we have about you\n'
                '• Correction: Request correction of inaccurate personal data\n'
                '• Deletion: Request deletion of your personal data\n'
                '• Portability: Request a copy of your data in a machine-readable format\n'
                '• Objection: Object to processing of your personal data\n'
                '• Restriction: Request restriction of processing in certain circumstances\n'
                '• Withdraw Consent: Withdraw consent for data processing (where applicable)',
              ),
              
              _buildSection(
                'California Privacy Rights (CCPA/CPRA)',
                'If you are a California resident, you have additional rights:\n\n'
                '• Right to Know: What personal information we collect, use, disclose, and sell\n'
                '• Right to Delete: Request deletion of your personal information\n'
                '• Right to Opt-Out: Opt-out of the sale or sharing of personal information\n'
                '• Right to Non-Discrimination: We will not discriminate against you for exercising your rights\n'
                '• Right to Correct: Request correction of inaccurate personal information\n\n'
                'We do not sell personal information in the traditional sense, but advertising networks may consider data sharing as a "sale" under CCPA. You can opt-out through your device\'s advertising settings.',
              ),
              
              _buildSection(
                'Children\'s Privacy (COPPA Compliance)',
                'Grav Blast is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided personal information to us, please contact us immediately, and we will delete such information.',
              ),
              
              _buildSection(
                'International Data Transfers',
                'Your information may be transferred to and processed in countries other than your own, including the United States where our servers and third-party services are located. We ensure appropriate safeguards are in place for such transfers in compliance with applicable laws.',
              ),
              
              _buildSection(
                'Advertising and Tracking',
                'Grav Blast displays advertisements provided by Google AdMob. These ads may be personalized based on your interests and usage patterns. You can control personalized advertising through:\n\n'
                '• Android: Settings > Google > Ads > Opt out of Ads Personalization\n'
                '• iOS: Settings > Privacy & Security > Apple Advertising > Personalized Ads (turn off)\n\n'
                'We use device identifiers for analytics and advertising purposes. You can reset these identifiers in your device settings.',
              ),
              
              _buildSection(
                'Do Not Track and Global Privacy Control',
                'We respond to Global Privacy Control (GPC) signals and similar privacy preference signals. When we detect such signals from your browser or device, we will honor your opt-out preferences for data sharing and personalized advertising.',
              ),
              
              _buildSection(
                'Changes to This Privacy Policy',
                'We may update this Privacy Policy periodically to reflect changes in our practices, technology, or legal requirements. We will notify you of significant changes by:\n\n'
                '• Posting the updated policy in the app\n'
                '• Updating the "Last Updated" date\n'
                '• Providing in-app notifications for material changes\n\n'
                'Your continued use of Grav Blast after such changes constitutes acceptance of the updated policy.',
              ),
              
              _buildSection(
                'How to Exercise Your Rights',
                'To exercise your privacy rights or for privacy-related inquiries, please contact us at:\n\n'
                '• Website: paconotenterprises.com/contact\n'
                '• Email: paconot@paconotenterprises.com\n\n'
                'We will respond to your request within 30 days (or as required by applicable law). We may need to verify your identity before processing certain requests.',
              ),
              
              _buildSection(
                'Contact Information',
                'For questions, concerns, or requests regarding this Privacy Policy or our privacy practices, please contact us:\n\n'
                'Paconot Technologies\n'
                'Website: paconotenterprises.com/contact\n'
                'Email: paconot@paconotenterprises.com\n'
                'Privacy Officer: Available upon request\n\n'
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.cyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                ),
                child: const Text(
                  'Last Updated: July 19, 2025\n© 2025 Paconot Technologies. All rights reserved.\n\nThis Privacy Policy complies with GDPR, CCPA/CPRA, COPPA, and other applicable privacy laws.',
                  style: TextStyle(
                    color: Colors.cyan,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<AudioService>().playUIClick();
            Navigator.of(context).pop();
          },
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.cyan, fontSize: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class FirstTimeAgreementPopup extends StatefulWidget {
  final VoidCallback onAccepted;
  
  const FirstTimeAgreementPopup({
    Key? key,
    required this.onAccepted,
  }) : super(key: key);

  @override
  State<FirstTimeAgreementPopup> createState() => _FirstTimeAgreementPopupState();
}

class _FirstTimeAgreementPopupState extends State<FirstTimeAgreementPopup> {
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissing without accepting
      child: AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.cyan.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.handshake, color: Colors.cyan, size: 24),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Welcome to Grav Blast!',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Before you start playing, please review and accept our Terms of Service and Privacy Policy.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            
            // Terms of Service checkbox
            InkWell(
              onTap: () {
                context.read<AudioService>().playUIClick();
                showDialog(
                  context: context,
                  builder: (context) => const TermsOfServicePopup(),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.cyan.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                        context.read<AudioService>().playUIClick();
                      },
                      activeColor: Colors.cyan,
                      checkColor: Colors.black,
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I agree to the Terms of Service',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Tap to read the full Terms of Service',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      color: Colors.cyan,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Privacy Policy checkbox
            InkWell(
              onTap: () {
                context.read<AudioService>().playUIClick();
                showDialog(
                  context: context,
                  builder: (context) => const PrivacyPolicyPopup(),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.cyan.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _agreedToPrivacy,
                      onChanged: (value) {
                        setState(() {
                          _agreedToPrivacy = value ?? false;
                        });
                        context.read<AudioService>().playUIClick();
                      },
                      activeColor: Colors.cyan,
                      checkColor: Colors.black,
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'I agree to the Privacy Policy',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Tap to read the full Privacy Policy',
                            style: TextStyle(
                              color: Colors.cyan,
                              fontSize: 12,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.open_in_new,
                      color: Colors.cyan,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'You must accept both agreements to continue playing.',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: (_agreedToTerms && _agreedToPrivacy) ? () {
              context.read<AudioService>().playUIClick();
              Navigator.of(context).pop();
              widget.onAccepted();
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (_agreedToTerms && _agreedToPrivacy) 
                  ? Colors.cyan 
                  : Colors.grey,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Accept & Continue',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}