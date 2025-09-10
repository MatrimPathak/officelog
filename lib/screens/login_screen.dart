import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/office_log_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Spacer to push content up
                const Spacer(flex: 2),

                // App Logo with tagline
                const OfficeLogLogo(
                  height: 100.0,
                  showTagline: true,
                  taglineFontSize: 16.0,
                ),

                const Spacer(flex: 3),

                // Welcome message
                Text(
                  'Welcome to OfficeLog',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Sign in with your Google account to continue',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 48),

                // Google Sign In Button
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    return Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: ElevatedButton.icon(
                        onPressed:
                            (authProvider.isOperating || authProvider.isLoading)
                            ? null
                            : () async {
                                final success = await authProvider
                                    .signInWithGoogle();
                                if (!success &&
                                    context.mounted &&
                                    authProvider.errorMessage != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(authProvider.errorMessage!),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                        icon:
                            (authProvider.isOperating || authProvider.isLoading)
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                Icons.login,
                                color: theme.colorScheme.onPrimary,
                              ),
                        label: Text(
                          (authProvider.isOperating || authProvider.isLoading)
                              ? 'Signing in...'
                              : 'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          padding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 2),

                // Footer text
                Text(
                  'By signing in, you agree to our Terms of Service',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
