import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/attendance_provider.dart';
import 'providers/holiday_provider.dart';
import 'providers/theme_provider.dart';
import 'services/notification_service.dart';
import 'services/holiday_service.dart';
import 'services/office_service.dart';
import 'services/update_office_location.dart';
import 'services/simple_background_geofence_service.dart';
import 'services/persistent_background_service.dart';
import 'services/settings_persistence_service.dart';
import 'services/admin_service.dart';
import 'themes/app_themes.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/summary_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/profile_confirmation_screen.dart';
import 'screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  try {
    await dotenv.load(fileName: "config.env");
  } catch (e) {
    print('Warning: Could not load config.env file: $e');
  }

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // Initialize settings persistence service first
  await SettingsPersistenceService.initialize();

  // Initialize notification service
  await NotificationService.initialize();

  // Initialize simple background geofence service
  await SimpleBackgroundGeofenceService.initialize();

  // Initialize persistent background service
  await PersistentBackgroundService.initialize();

  // Restart auto check-in service if it was enabled before app restart
  if (await PersistentBackgroundService.isAutoCheckInEnabled()) {
    await PersistentBackgroundService.startAutoCheckIn();
    print('✅ Auto check-in service restarted after app launch');
  }

  // Initialize default data
  await _initializeDefaultData();

  // Initialize admin configuration
  await AdminService.initializeAdminConfig();

  runApp(const AttendanceApp());
}

// Initialize default holidays and offices
Future<void> _initializeDefaultData() async {
  try {
    final holidayService = HolidayService();
    final officeService = OfficeService();

    // Initialize default holidays and offices
    await Future.wait([
      holidayService.initializeDefaultHolidays(),
      officeService.initializeDefaultOffice(),
    ]);

    // Update office location to test coordinates
    await UpdateOfficeLocation.updateToTestLocation();

    // Force update holidays database (uncomment to update holidays)
    // await ForceUpdateHolidays.updateHolidaysDatabase();
  } catch (e) {
    print('Failed to initialize default data: $e');
  }
}

class AttendanceApp extends StatelessWidget {
  const AttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
        ChangeNotifierProvider(create: (_) => HolidayProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'OfficeLog',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: '/',
            routes: {
              '/': (context) => const AuthWrapper(),
              '/login': (context) => const LoginScreen(),
              '/profile-confirmation': (context) =>
                  const ProfileConfirmationScreen(),
              '/profile': (context) => const ProfileScreen(),
              '/home': (context) => const HomeScreen(),
              '/summary': (context) => const SummaryScreen(),
              '/settings': (context) => const SettingsScreen(),
              '/admin': (context) => const AdminScreen(),
              '/feedback': (context) => const FeedbackScreen(),
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  Timer? _resetTimer;
  final bool _isCheckingProfile = false;

  @override
  void initState() {
    super.initState();
    // Only initialize theme provider here, other services will be initialized in HomeScreen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.initializeTheme();

      // Set up callback to reset providers when user changes
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
      final holidayProvider = Provider.of<HolidayProvider>(
        context,
        listen: false,
      );

      authProvider.setUserChangeCallback(() {
        attendanceProvider.resetUserData();
        holidayProvider.resetUserData();
      });
    });
  }

  Future<bool> _needsProfileConfirmation(String userId) async {
    try {
      // Check if onboarding is completed
      final onboardingCompleted =
          await SettingsPersistenceService.isOnboardingCompleted();
      if (!onboardingCompleted) {
        return true;
      }

      // Check if user has an office assigned
      final officeService = OfficeService();
      final userOffice = await officeService.getUserOffice(userId);

      return userOffice == null;
    } catch (e) {
      debugPrint('Error checking profile confirmation: $e');
      return true; // Default to showing confirmation screen if there's an error
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Emergency timeout - if stuck in loading for more than 10 seconds, force reset
        if (authProvider.isLoading || authProvider.isOperating) {
          _resetTimer?.cancel();
          _resetTimer = Timer(const Duration(seconds: 10), () {
            if (mounted) {
              authProvider.forceReset();
            }
          });
        } else {
          _resetTimer?.cancel();
        }

        // Show loading screen while checking auth state
        if (authProvider.isLoading || _isCheckingProfile) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Navigate based on authentication status
        final user = authProvider.user;

        if (authProvider.isAuthenticated && user != null) {
          // Check if user needs profile confirmation
          return FutureBuilder<bool>(
            future: _needsProfileConfirmation(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final needsConfirmation = snapshot.data ?? true;

              if (needsConfirmation) {
                return const ProfileConfirmationScreen(
                  key: ValueKey('profile_confirmation'),
                );
              } else {
                return HomeScreen(key: ValueKey('home_${user.uid}'));
              }
            },
          );
        } else {
          return const LoginScreen(key: ValueKey('login_screen'));
        }
      },
    );
  }
}
