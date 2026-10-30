import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/audio_service.dart';
import 'terms_of_service_popup.dart';

class SettingsPopup extends StatefulWidget {
  const SettingsPopup({Key? key}) : super(key: key);

  @override
  State<SettingsPopup> createState() => _SettingsPopupState();
}

class _SettingsPopupState extends State<SettingsPopup> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
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
              Icon(Icons.settings, color: Colors.cyan, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Settings',
                style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audio Settings Section
                _buildSectionHeader('Audio Settings', Icons.volume_up),
                const SizedBox(height: 12),
                
                // Sound Effects Toggle
                Container(
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
                      Icon(
                        audioService.soundEnabled ? Icons.volume_up : Icons.volume_off,
                        color: audioService.soundEnabled ? Colors.cyan : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sound Effects',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'Enable game sound effects',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: audioService.soundEnabled,
                        onChanged: (value) {
                          audioService.setSoundEnabled(value);
                          if (value) {
                            // Play test sound when enabling
                            audioService.playUIClick();
                          }
                        },
                        activeColor: Colors.cyan,
                        activeTrackColor: Colors.cyan.withOpacity(0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Background Music Toggle
                Container(
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
                      Icon(
                        audioService.musicEnabled ? Icons.music_note : Icons.music_off,
                        color: audioService.musicEnabled ? Colors.purple : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Background Music',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              audioService.isMusicPlaying ? 'Playing' : 'Stopped',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: audioService.musicEnabled,
                        onChanged: (value) {
                          audioService.setMusicEnabled(value);
                        },
                        activeColor: Colors.purple,
                        activeTrackColor: Colors.purple.withOpacity(0.3),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey.withOpacity(0.3),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Sound Effects Volume Control
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.cyan.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.volume_down, color: Colors.cyan, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Effects Volume',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(audioService.volume * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.cyan,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.cyan,
                          inactiveTrackColor: Colors.cyan.withOpacity(0.3),
                          thumbColor: Colors.cyan,
                          overlayColor: Colors.cyan.withOpacity(0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: audioService.volume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: audioService.soundEnabled ? (value) {
                            audioService.setVolume(value);
                          } : null,
                          onChangeEnd: (value) {
                            if (audioService.soundEnabled && value > 0) {
                              // Play test sound at new volume
                              audioService.playUIClick();
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Music Volume Control
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.purple.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.music_note, color: Colors.purple, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Music Volume',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${(audioService.musicVolume * 100).round()}%',
                            style: const TextStyle(
                              color: Colors.purple,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.purple,
                          inactiveTrackColor: Colors.purple.withOpacity(0.3),
                          thumbColor: Colors.purple,
                          overlayColor: Colors.purple.withOpacity(0.2),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: audioService.musicVolume,
                          min: 0.0,
                          max: 1.0,
                          divisions: 10,
                          onChanged: audioService.musicEnabled ? (value) {
                            audioService.setMusicVolume(value);
                          } : null,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Links Section
                _buildSectionHeader('Links & Info', Icons.link),
                const SizedBox(height: 12),
                
                // Website
                _buildLinkItem(
                  'Official Website',
                  'paconotenterprises.com',
                  Icons.language,
                  () => _launchURL('https://paconotenterprises.com'),
                ),
                
                // Contact
                _buildLinkItem(
                  'Contact Us',
                  'Get support or send feedback',
                  Icons.contact_support,
                  () => _launchURL('https://paconotenterprises.com/contact'),
                ),
                
                // Privacy Policy
                _buildLinkItem(
                  'Privacy Policy',
                  'How we handle your data',
                  Icons.privacy_tip,
                  () => _showPrivacyPolicy(),
                ),
                
                // Terms of Service
                _buildLinkItem(
                  'Terms of Service',
                  'Terms and conditions',
                  Icons.description,
                  () => _showTermsOfService(),
                ),
                
                const SizedBox(height: 12),
                
                // Social Media Section
                _buildSectionHeader('Follow Us', Icons.share),
                const SizedBox(height: 12),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Instagram
                    _buildSocialButton(
                      'Instagram',
                      Icons.camera_alt,
                      Colors.purple,
                      () => _launchURL('https://instagram.com/paconotenterprises'),
                    ),
                    
                    // Tiktok
                    _buildSocialButton(
                      'TikTok',
                      Icons.music_note,
                      Colors.cyanAccent,
                      () => _launchURL('https://www.tiktok.com/@lil_paconot'),
                    ),
                    
                    // Youtube
                    _buildSocialButton(
                      'YouTube',
                      Icons.play_arrow,
                      Colors.red,
                      () => _launchURL('https://www.youtube.com/@LilPaconot'),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // App Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.cyan.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.cyan, size: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Grav Blast',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'v1.1.2', // GAME_VERSION
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '© 2025 Paconot Technologies',
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
          actions: [
            TextButton(
              onPressed: () {
                audioService.playUIClick();
                Navigator.of(context).pop();
              },
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.cyan, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyan, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Expanded(
          child: Divider(
            color: Colors.cyan,
            thickness: 1,
            indent: 12,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLinkItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          context.read<AudioService>().playUIClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.cyan.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.cyan, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                color: Colors.cyan.withOpacity(0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildSocialButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        context.read<AudioService>().playUIClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar('Could not open $url');
      }
    } catch (e) {
      _showErrorSnackBar('Error opening link: $e');
    }
  }
  
  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => const TermsOfServicePopup(),
    );
  }
  
  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => const PrivacyPolicyPopup(),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.withOpacity(0.8),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}