import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../themes/app_themes.dart';

class OfficeLogLogo extends StatelessWidget {
  final double height;
  final bool showTagline;
  final double taglineFontSize;
  final bool isAnimated;
  final bool maintainAspectRatio;

  const OfficeLogLogo({
    super.key,
    this.height = 80.0,
    this.showTagline = false,
    this.taglineFontSize = 16.0,
    this.isAnimated = false,
    this.maintainAspectRatio = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final mutedColor = AppThemes.getMutedColor(context);

    // Choose logo based on theme
    final logoAsset = isDarkMode
        ? 'assets/images/Full Logo-02.png'
        : 'assets/images/Full Logo-01.png';

    Widget logoWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main Logo Image
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              logoAsset,
              height: height,
              fit: maintainAspectRatio ? BoxFit.contain : BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to text logo if image fails to load
                return _buildFallbackLogo(context);
              },
            ),
          ),
        ),

        // Tagline
        if (showTagline) ...[
          const SizedBox(height: 16),
          Text(
            'Your workdays, beautifully logged.',
            style: GoogleFonts.poppins(
              fontSize: taglineFontSize,
              fontWeight: FontWeight.w400,
              color: mutedColor,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    // Add animation if requested
    if (isAnimated) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.scale(
              scale: 0.8 + (0.2 * value),
              child: logoWidget,
            ),
          );
        },
      );
    }

    return logoWidget;
  }

  // Fallback text logo in case image fails to load
  Widget _buildFallbackLogo(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;
    final accentColor = AppThemes.getAccentColor(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circular "O" with accent background
        Container(
          width: height * 0.6,
          height: height * 0.6,
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'O',
              style: GoogleFonts.poppins(
                fontSize: height * 0.3,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Rest of the text with gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [primaryColor, secondaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            'fficeLog',
            style: GoogleFonts.poppins(
              fontSize: height * 0.6,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Colors.white, // This will be masked by the gradient
            ),
          ),
        ),
      ],
    );
  }
}

// Smaller version for app bars
class OfficeLogAppBarTitle extends StatelessWidget {
  const OfficeLogAppBarTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return const OfficeLogLogo(
      height: 32.0,
      showTagline: false,
      maintainAspectRatio: true,
    );
  }
}

// Favicon-sized version
class OfficeLogFavicon extends StatelessWidget {
  final double size;

  const OfficeLogFavicon({super.key, this.size = 32.0});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(
          'assets/images/Logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to circular "O" if image fails
            final accentColor = AppThemes.getAccentColor(context);
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  'O',
                  style: GoogleFonts.poppins(
                    fontSize: size * 0.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
