import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/feedback_service.dart';
import '../themes/app_themes.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final FeedbackService _feedbackService = FeedbackService();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _populateUserDetails();
  }

  void _populateUserDetails() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Autopopulate name and email from Firebase Auth
      if (user.displayName != null && user.displayName!.isNotEmpty) {
        _nameController.text = user.displayName!;
      }
      if (user.email != null && user.email!.isNotEmpty) {
        _emailController.text = user.email!;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _feedbackService.submitFeedback(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        message: _messageController.text.trim(),
      );

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Thank you for your feedback!'),
              ],
            ),
            backgroundColor: AppThemes.getSuccessColor(context),
            duration: const Duration(seconds: 3),
          ),
        );

        // Clear form
        _nameController.clear();
        _emailController.clear();
        _messageController.clear();

        // Navigate back after a short delay
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to submit feedback. Please try again.'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppThemes.getErrorColor(context),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback'), elevation: 0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.feedback,
                          size: 48,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.blue.shade300
                              : Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'We\'d love your feedback!',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help us improve OfficeLog by sharing your thoughts, suggestions, or reporting issues.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade300
                                : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Form Fields
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name field (optional)
                        Row(
                          children: [
                            Text(
                              'Name (optional)',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (_nameController.text.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppThemes.getSuccessColor(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Auto-filled',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppThemes.getSuccessColor(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Your name',
                            prefixIcon: const Icon(Icons.person_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                          textInputAction: TextInputAction.next,
                        ),

                        const SizedBox(height: 20),

                        // Email field (optional)
                        Row(
                          children: [
                            Text(
                              'Email (optional)',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (_emailController.text.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.check_circle,
                                size: 16,
                                color: AppThemes.getSuccessColor(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Auto-filled',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppThemes.getSuccessColor(context),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'your.email@example.com',
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (value) {
                            if (value != null && value.trim().isNotEmpty) {
                              if (!FeedbackService.isValidEmail(value)) {
                                return 'Please enter a valid email address';
                              }
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),

                        // Message field (required)
                        Text(
                          'Feedback Message *',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 6,
                          decoration: InputDecoration(
                            hintText:
                                'Share your thoughts, suggestions, or report issues...',
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(bottom: 100),
                              child: Icon(Icons.message_outlined),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
                            alignLabelWithHint: true,
                          ),
                          textInputAction: TextInputAction.newline,
                          validator: (value) {
                            if (!FeedbackService.isValidMessage(value ?? '')) {
                              return 'Please enter your feedback message';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 8),
                        Text(
                          '* Required field',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade400
                                : Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade600
                          : Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Submitting...'),
                            ],
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send),
                              SizedBox(width: 8),
                              Text(
                                'Submit Feedback',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // Privacy note
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.blue.shade900.withValues(alpha: 0.3)
                        : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.blue.shade600
                          : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.privacy_tip_outlined,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.blue.shade300
                            : Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Your feedback helps us improve OfficeLog. We respect your privacy and will only use this information to enhance the app.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.blue.shade100
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Extra bottom padding to ensure content is not cut off
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}