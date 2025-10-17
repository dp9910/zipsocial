import 'package:flutter/material.dart';
import 'profile_setup_screen.dart';

class NewUserTermsScreen extends StatefulWidget {
  const NewUserTermsScreen({super.key});

  @override
  State<NewUserTermsScreen> createState() => _NewUserTermsScreenState();
}

class _NewUserTermsScreenState extends State<NewUserTermsScreen> {
  bool _hasAgreed = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF4ECDC4),
                            const Color(0xFF4ECDC4).withOpacity(0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4ECDC4).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.gavel,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Welcome to ZipSocial!',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please read our community guidelines before continuing',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Terms Content
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection(
                          'Age Requirement',
                          'You must be 18 years or older to use ZipSocial. By using this app, you confirm that you are at least 18 years of age.',
                          Icons.badge,
                          Colors.red,
                        ),
                        
                        _buildSection(
                          'Zero Tolerance Policy',
                          'ZipSocial has ZERO TOLERANCE for objectionable content including but not limited to: hate speech, harassment, threats, explicit content, spam, or any form of abuse. Violations will result in immediate account suspension.',
                          Icons.block,
                          Colors.orange,
                        ),
                        
                        _buildSection(
                          'Content Moderation',
                          'All content is subject to automated and manual moderation. We reserve the right to remove any content and suspend users who violate our community standards without prior notice.',
                          Icons.security,
                          Colors.blue,
                        ),
                        
                        _buildSection(
                          'Reporting System',
                          'Users must report inappropriate content immediately. We respond to all reports within 24 hours and take swift action against violating accounts.',
                          Icons.report,
                          Colors.green,
                        ),
                        
                        _buildSection(
                          'User Responsibilities',
                          'You are responsible for all content you post and interactions you have. Respect other users and follow community guidelines at all times.',
                          Icons.person_outline,
                          Colors.purple,
                        ),
                        
                        _buildSection(
                          'Enforcement',
                          'Violations may result in content removal, account suspension, or permanent ban. Appeals can be submitted to hellozipsocial@gmail.com.',
                          Icons.gavel,
                          Colors.red.shade800,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning, color: Colors.red.shade600, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Important Notice',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'By continuing, you acknowledge that you understand and agree to our zero tolerance policy for objectionable content and abusive behavior. This is a community-focused platform that prioritizes user safety and respectful communication.',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Agreement Checkbox
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _hasAgreed 
                      ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasAgreed 
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _hasAgreed,
                      onChanged: (value) {
                        setState(() {
                          _hasAgreed = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF4ECDC4),
                    ),
                    Expanded(
                      child: Text(
                        'I am 18+ years old and agree to the Terms of Service and zero tolerance policy for objectionable content',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: _hasAgreed 
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _hasAgreed && !_isLoading ? _acceptTermsAndContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: _hasAgreed ? 8 : 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Accept & Continue to Profile Setup',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _hasAgreed 
                                ? Colors.white 
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptTermsAndContinue() async {
    setState(() => _isLoading = true);
    
    try {
      // Just navigate to profile setup - no need to save acceptance
      // since this is only for new users and they'll complete profile setup
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const ProfileSetupScreen(),
          ),
        );
      }
    } catch (e) {
      print('Error navigating to profile setup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }
}