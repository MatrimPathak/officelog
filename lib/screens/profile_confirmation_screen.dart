import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/office_service.dart';
import '../services/settings_persistence_service.dart';
import '../models/office_model.dart';
import '../themes/app_themes.dart';

class ProfileConfirmationScreen extends StatefulWidget {
  const ProfileConfirmationScreen({super.key});

  @override
  State<ProfileConfirmationScreen> createState() =>
      _ProfileConfirmationScreenState();
}

class _ProfileConfirmationScreenState extends State<ProfileConfirmationScreen> {
  final OfficeService _officeService = OfficeService();
  final Completer<void> _disposedCompleter = Completer<void>();

  List<OfficeModel> _offices = [];
  OfficeModel? _selectedOffice;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOffices();
  }

  @override
  void dispose() {
    // Mark widget as disposed to cancel ongoing operations
    if (!_disposedCompleter.isCompleted) {
      _disposedCompleter.complete();
    }
    super.dispose();
  }

  Future<void> _loadOffices() async {
    try {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Use Future.any to make the operation cancellable
      final result = await Future.any([
        _officeService.getAllOffices(),
        _disposedCompleter.future.then(
          (_) => throw Exception('Widget disposed'),
        ),
      ]);

      if (!mounted) return;

      setState(() {
        _offices = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      // Don't show error if widget was disposed
      if (e.toString().contains('Widget disposed')) return;

      setState(() {
        _errorMessage = 'Failed to load offices: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmAndContinue() async {
    if (_selectedOffice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select your office location'),
          backgroundColor: AppThemes.getErrorColor(context),
        ),
      );
      return;
    }

    try {
      if (!mounted) return;

      setState(() {
        _isSaving = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Use Future.any to make the operation cancellable
      await Future.any([
        Future.wait([
          _officeService.assignUserToOffice(user.uid, _selectedOffice!.id),
          SettingsPersistenceService.setOnboardingCompleted(true),
        ]),
        _disposedCompleter.future.then(
          (_) => throw Exception('Widget disposed'),
        ),
      ]);

      // Navigate to homepage
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;

      // Don't show error if widget was disposed
      if (e.toString().contains('Widget disposed')) return;

      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save office selection: ${e.toString()}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save office selection: $e'),
          backgroundColor: AppThemes.getErrorColor(context),
        ),
      );
    }
  }

  Widget _buildProfileCard() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 35,
              backgroundImage: user.photoURL != null
                  ? NetworkImage(user.photoURL!)
                  : null,
              backgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.1),
              child: user.photoURL == null
                  ? Icon(
                      Icons.person,
                      size: 35,
                      color: Theme.of(context).primaryColor,
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              user.displayName ?? 'User',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 8),

            // Email
            Text(
              user.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOfficeSelectionCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Office Location',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Office Dropdown
            DropdownButtonFormField<OfficeModel>(
              initialValue: _selectedOffice,
              decoration: InputDecoration(
                labelText: 'Select Office Location',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.location_on),
                errorText: _selectedOffice == null
                    ? 'Auto Check-In requires selecting your office'
                    : null,
              ),
              items: _offices.map((office) {
                return DropdownMenuItem<OfficeModel>(
                  value: office,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Text(
                      office.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (OfficeModel? office) {
                if (mounted) {
                  setState(() {
                    _selectedOffice = office;
                    _errorMessage = null;
                  });
                }
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select your office location';
                }
                return null;
              },
            ),

            if (_selectedOffice != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Selected: ${_selectedOffice!.name}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 1,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Select your office location to enable Auto Check-In. '
                'This allows automatic attendance logging when you arrive at work.',
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 13,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48, maxHeight: 56),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_selectedOffice != null && !_isSaving)
              ? _confirmAndContinue
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(
              0xFF1565C0,
            ), // Blue color that stands out
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
            elevation: 2,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          child: _isSaving
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text('Saving...', overflow: TextOverflow.ellipsis),
                    ),
                  ],
                )
              : const Text(
                  'Continue to OfficeLog',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Profile'),
        centerTitle: true,
        automaticallyImplyLeading: false, // Prevent back navigation
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading offices...'),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadOffices,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Profile Card
                            _buildProfileCard(),

                            const SizedBox(height: 12),

                            // Office Selection Card
                            _buildOfficeSelectionCard(),

                            const SizedBox(height: 8),

                            // Info Card
                            _buildInfoCard(),

                            const Spacer(),

                            // Continue Button
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: _buildContinueButton(),
                            ),

                            const SizedBox(height: 16),
                          ],
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
