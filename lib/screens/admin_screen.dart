import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/holiday_provider.dart';
import '../models/holiday_model.dart';
import '../models/office_model.dart';
import '../services/office_service.dart';
import '../themes/app_themes.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final OfficeService _officeService = OfficeService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Check if current user is admin
  bool _isAdmin() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && user.email == 'matrimpathak1999@gmail.com';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin()) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Admin access required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Only administrators can access this page'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.event), text: 'Holidays'),
            Tab(icon: Icon(Icons.location_on), text: 'Offices'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildHolidaysTab(), _buildOfficesTab()],
      ),
    );
  }

  Widget _buildHolidaysTab() {
    return Consumer<HolidayProvider>(
      builder: (context, holidayProvider, child) {
        return Column(
          children: [
            // Add Holiday Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddHolidayDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Holiday'),
              ),
            ),

            // Holidays List
            Expanded(
              child: holidayProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: holidayProvider.holidays.length,
                      itemBuilder: (context, index) {
                        final holiday = holidayProvider.holidays[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.event_note,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(holiday.name),
                            subtitle: Text(holiday.date),
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Edit'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _showEditHolidayDialog(holiday);
                                } else if (value == 'delete') {
                                  _deleteHoliday(holiday);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOfficesTab() {
    return FutureBuilder<List<OfficeModel>>(
      future: _officeService.getAllOffices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final offices = snapshot.data ?? [];

        return Column(
          children: [
            // Add Office Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () => _showAddOfficeDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Add Office'),
              ),
            ),

            // Offices List
            Expanded(
              child: ListView.builder(
                itemCount: offices.length,
                itemBuilder: (context, index) {
                  final office = offices[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.business, color: Colors.white),
                      ),
                      title: Text(office.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${office.latitude}, ${office.longitude}'),
                          Text(
                            'Radius: ${office.radius}m • ${office.timezone}',
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            _showEditOfficeDialog(office);
                          } else if (value == 'delete') {
                            _deleteOffice(office);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // Holiday Management Methods
  void _showAddHolidayDialog() {
    _showHolidayDialog();
  }

  void _showEditHolidayDialog(HolidayModel holiday) {
    _showHolidayDialog(holiday: holiday);
  }

  void _showHolidayDialog({HolidayModel? holiday}) {
    final isEditing = holiday != null;
    final nameController = TextEditingController(text: holiday?.name ?? '');
    DateTime selectedDate = holiday?.toDateTime() ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Edit Holiday' : 'Add Holiday'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Holiday Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date'),
                  subtitle: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;

                // Cache context references BEFORE any async operations
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                final successColor = AppThemes.getSuccessColor(context);
                final holidayProvider = Provider.of<HolidayProvider>(
                  context,
                  listen: false,
                );

                final newHoliday = HolidayModel.fromDateTime(
                  selectedDate,
                  nameController.text.trim(),
                );

                Navigator.of(context).pop();

                final success = isEditing
                    ? await holidayProvider.updateHoliday(
                        newHoliday.copyWith(id: holiday.id),
                      )
                    : await holidayProvider.addHoliday(newHoliday);

                if (success && mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing ? 'Holiday updated!' : 'Holiday added!',
                      ),
                      backgroundColor: successColor,
                    ),
                  );
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteHoliday(HolidayModel holiday) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text('Are you sure you want to delete "${holiday.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Cache context references before async operation
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final successColor = AppThemes.getSuccessColor(context);
              final holidayProvider = Provider.of<HolidayProvider>(
                context,
                listen: false,
              );

              final success = await holidayProvider.deleteHoliday(holiday.id);

              if (success && mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: const Text('Holiday deleted!'),
                    backgroundColor: successColor,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Office Management Methods
  void _showAddOfficeDialog() {
    _showOfficeDialog();
  }

  void _showEditOfficeDialog(OfficeModel office) {
    _showOfficeDialog(office: office);
  }

  void _showOfficeDialog({OfficeModel? office}) {
    final isEditing = office != null;
    final nameController = TextEditingController(text: office?.name ?? '');
    final latController = TextEditingController(
      text: office?.latitude.toString() ?? '',
    );
    final lngController = TextEditingController(
      text: office?.longitude.toString() ?? '',
    );
    final radiusController = TextEditingController(
      text: office?.radius.toString() ?? '200',
    );
    final timezoneController = TextEditingController(
      text: office?.timezone ?? 'Asia/Kolkata',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Office' : 'Add Office'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Office Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: radiusController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Radius (meters)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: timezoneController,
                      decoration: const InputDecoration(
                        labelText: 'Timezone',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty ||
                  latController.text.trim().isEmpty ||
                  lngController.text.trim().isEmpty) {
                return;
              }

              final newOffice = OfficeModel(
                id:
                    office?.id ??
                    'office_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text.trim(),
                latitude: double.parse(latController.text.trim()),
                longitude: double.parse(lngController.text.trim()),
                radius: double.parse(radiusController.text.trim()),
                timezone: timezoneController.text.trim(),
                createdAt: DateTime.now(),
              );

              // Cache context references BEFORE async operations
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final successColor = AppThemes.getSuccessColor(context);
              final errorColor = AppThemes.getErrorColor(context);

              Navigator.of(context).pop();

              try {
                if (isEditing) {
                  await _officeService.updateOffice(newOffice);
                } else {
                  await _officeService.addOffice(newOffice);
                }

                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        isEditing ? 'Office updated!' : 'Office added!',
                      ),
                      backgroundColor: successColor,
                    ),
                  );
                  setState(() {}); // Refresh the list
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed: $e'),
                      backgroundColor: errorColor,
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }

  void _deleteOffice(OfficeModel office) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Office'),
        content: Text('Are you sure you want to delete "${office.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Cache context references before async operation
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final successColor = AppThemes.getSuccessColor(context);
              final errorColor = AppThemes.getErrorColor(context);

              try {
                await _officeService.deleteOffice(office.id);
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: const Text('Office deleted!'),
                      backgroundColor: successColor,
                    ),
                  );
                  setState(() {}); // Refresh the list
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: errorColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
