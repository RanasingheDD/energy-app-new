import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:myapp/controller/wetherAPI.dart';
import 'package:myapp/pages/notification.dart';
import 'package:myapp/provider/power_provider.dart';
import 'package:myapp/widgets/device_card.dart';
import 'package:myapp/widgets/menu.dart';
import 'package:myapp/widgets/wether.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myapp/widgets/snackbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required String title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Constants
  static const _backgroundColor = Color.fromARGB(255, 21, 17, 37);
  static const _energyCardColor = Color(0xFF0D0C2B);
  static const _updateCardGradient = [
    Color.fromARGB(255, 30, 255, 0),
    Color.fromARGB(255, 255, 251, 0),
  ];

  // State variables
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final SupabaseClient _supabase = Supabase.instance.client;
  final WeatherService _weatherService = WeatherService();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  List<Map<String, dynamic>> _devices = [];
  bool _isLoading = true;
  bool _hasUpdate = false;
  String _version = "";
  double _currentHomePower = 0.0;
  bool showInputFields = false;
  double _currentHomeBill = 0.0;

  @override
  void initState() {
    super.initState();
    _startAutoToggleTimer();
    _supabase.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedIn)
        await FirebaseMessaging.instance.requestPermission();
      await FirebaseMessaging.instance.getAPNSToken();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _setFcmToken(token);
      }
    });
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      await _setFcmToken(token);
    });

    FirebaseMessaging.onMessage.listen((payload) {
      final notification = payload.notification;
      if (notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${notification.title} ${notification.body}')),
        );
      }
    });
    _initializeData();
  }

  void _startAutoToggleTimer() {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkAndUpdateDeviceStates();
    });
  }

  Future<void> _checkAndUpdateDeviceStates() async {
    final now = TimeOfDay.now();

    for (int i = 0; i < _devices.length; i++) {
      final device = _devices[i];
      // Allow both manual and auto modes to use scheduling
      final isAutoMode = device['auto_mode'] ?? false;
      final startStr = device['start_time'];
      final endStr = device['end_time'];
      if (startStr == null || endStr == null) continue;

      final start = _parseTimeOfDay(startStr);
      final end = _parseTimeOfDay(endStr);
      final now = TimeOfDay.now();
      final isOn = device['is_on'];

      final shouldBeOn = _isWithinTimeRange(now, start, end);
      if (shouldBeOn != isOn) {
        // Only auto-toggle if manual mode AND scheduling is defined
        if (!isAutoMode) {
          await _togglePower(i);
        }
      }
    }
  }

  TimeOfDay _parseTimeOfDay(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isWithinTimeRange(TimeOfDay now, TimeOfDay start, TimeOfDay end) {
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    } else {
      // Handles overnight schedules like 23:00–05:00
      return nowMinutes >= startMinutes || nowMinutes < endMinutes;
    }
  }

  Future<void> _setFcmToken(String fcmToken) async {
    final userId = await _supabase.auth.currentUser!.id;
    await _supabase.from('profiles').upsert({
      'profile_id': userId,
      'fcm_token': fcmToken,
    });
  }

  void _showDialog(String? title, String? body) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title ?? 'Notification'),
            content: Text(body ?? 'No message body'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _fetchDevices(),
      _fetchUpdateStatus(),
      _weatherService.fetchWeatherByLocation(),
    ]);
    _listenToDeviceChanges();
    _getElectricityBill();
  }

  void _listenToDeviceChanges() {
    _supabase
        .channel('public:SensorData')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'SensorData',
          callback: (payload) {
            final newRecord = payload.newRecord;
            _currentHomePower = newRecord['power'];
            context.read<PowerProvider>().setPower(_currentHomePower);
          },
        )
        .subscribe();
  }
  void _listenToDeviceChanges(String userId) {
      _supabase
          .channel('public:SensorData')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'SensorData',
            callback: (payload) {
              final newRecord = payload.newRecord;
  
              if (newRecord != null && newRecord['user_id'] == userId) {
                final currentPower = newRecord['power'];
                print('Power1: $currentPower');
                context.read<PowerProvider>().setPower(currentPower);
              }
            },
          )
          .subscribe();
    }

  Future<void> _addDevice(IconData? icon) async {
    final name = nameController.text.trim();
    final id = idController.text.trim().toUpperCase();
    final iconCode = icon?.codePoint ?? FontAwesomeIcons.lightbulb.codePoint;
    print(iconCode);

    final macRegex = RegExp(r'^([0-9A-F]{2}:){5}[0-9A-F]{2}$');

    if (name.isEmpty || id.isEmpty) {
      showCustomSnackBarError(context, "Please fill all fields.");
      return;
    }

    if (!macRegex.hasMatch(id)) {
      showCustomSnackBarError(context, "Invalid format. Use XX:XX:XX:XX:XX:XX");
      return;
    }

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        showCustomSnackBarError(context, "User not logged in.");
        return;
      }

      final newDevice = {
        'name': name,
        'mac': id,
        'is_on': false,
        'user_id': userId,
        'icon_code': iconCode, // Store the icon code point
        'start_time': startTime?.format(context),
        'end_time': endTime?.format(context),
        'auto_mode': true,
      };

      final insertedDevice =
          await _supabase.from('devices').insert(newDevice).select().single();

      setState(() {
        _devices.add(insertedDevice);
        showInputFields = false;
        nameController.clear();
        idController.clear();
      });

      showCustomSnackBarDone(context, "New Device Added Successfully!");
    } catch (e) {
      showCustomSnackBarError(context, "Error adding device: $e");
    }
  }

  // Data Fetching Methods
  Future<void> _fetchDevices() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final response = await _supabase
          .from('devices')
          .select()
          .eq('user_id', userId);

      setState(() => _devices = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      _showErrorSnackbar('Error fetching devices: $e');
    }
  }

  Future<void> _fetchUpdateStatus() async {
    try {
      final response =
          await _supabase
              .from('updates')
              .select('has_update, version')
              .order('created_at', ascending: false)
              .limit(1)
              .maybeSingle();

      setState(() {
        _hasUpdate = response?['has_update'] == true;
        _version = response?['version'] ?? '';
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar('Error fetching updates: $e');
      setState(() => _isLoading = false);
    }
  }

  // Device Management Methods
  Future<void> _togglePower(int index) async {
    final device = _devices[index];
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || device['id'] == null) return;

    final newState = !(device['is_on'] ?? false);

    try {
      await _supabase
          .from('devices')
          .update({'is_on': newState})
          .eq('id', device['id'])
          .eq('user_id', userId);

      setState(() => _devices[index]['is_on'] = newState);
    } catch (e) {
      _showErrorSnackbar('Failed to toggle device: $e');
    }
  }

  Future<void> _updateDevicePriority(int index, String newPriority) async {
    try {
      await _supabase
          .from('devices')
          .update({'priority': newPriority})
          .eq('id', _devices[index]['id']);

      setState(() => _devices[index]['priority'] = newPriority);
    } catch (e) {
      _showErrorSnackbar('Failed to update priority: $e');
    }
  }

  Future<void> _getElectricityBill() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('Bill')
          .select('price')
          .eq('user_id', userId);

      print(response);

      if (response.isNotEmpty && response[0]['price'] != null) {
        setState(() => _currentHomeBill = response[0]['price'].toDouble());
      } else {
        setState(() => _currentHomeBill = 0.0);
      }
    } catch (e) {
      _showErrorSnackbar('Failed to fetch electricity bill: $e');
    }
  }

  Future<void> _updateDeviceMode(int index, bool isAutoMode) async {
    try {
      await _supabase
          .from('devices')
          .update({'auto_mode': isAutoMode})
          .eq('id', _devices[index]['id']);

      setState(() => _devices[index]['auto_mode'] = isAutoMode);
    } catch (e) {
      _showErrorSnackbar('Failed to change mode: $e');
    }
  }

  Future<void> _removeDevice(int index) async {
    final deviceId = _devices[index]['id'];
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase
          .from('devices')
          .delete()
          .eq('id', deviceId)
          .eq('user_id', userId);

      setState(() => _devices.removeAt(index));
    } catch (e) {
      _showErrorSnackbar('Failed to remove device: $e');
    }
  }

  // UI Helper Methods
  Future<void> _showEditDialog(int index) async {
    final editController = TextEditingController(text: _devices[index]['name']);

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: const Color(0xFF182C36),
            title: const Text(
              'Edit Device Name',
              style: TextStyle(color: Colors.white),
            ),
            content: TextField(
              controller: editController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Enter new name',
                hintStyle: TextStyle(color: Colors.white54),
              ),
            ),

            actions: [
              TextButton(
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              TextButton(
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.deepPurpleAccent),
                ),
                onPressed: () async {
                  final newName = editController.text.trim();
                  if (newName.isNotEmpty) {
                    Navigator.pop(context); // Close the dialog immediately
                    try {
                      await _saveDeviceName(index, newName);
                    } catch (e) {
                      print(e);
                    } finally {
                      editController.dispose();
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _saveDeviceName(int index, String newName) async {
    try {
      await _supabase
          .from('devices')
          .update({'name': newName})
          .eq('id', _devices[index]['id']);

      if (!mounted) return; // ✅ Prevent calling setState if widget is gone

      setState(() => _devices[index]['name'] = newName);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar('Failed to update device name: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchDevices(),
      _fetchUpdateStatus(),
      _weatherService.fetchWeatherByLocation(),
    ]);
    setState(() {});
  }

  // Widget Build Methods
  Widget _buildAppBar(BuildContext context, Size screenSize) {
    return Stack(
      children: [
        Climate(weatherService: _weatherService),
        Positioned(
          top: screenSize.height * 0.01,
          left: screenSize.width * 0.01,
          child: IconButton(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(FontAwesomeIcons.list, color: Colors.white),
            splashRadius: 20,
          ),
        ),
        Positioned(
          top: screenSize.height * 0.01,
          right: screenSize.width * 0.01,
          child: IconButton(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => NotificationPage(
                          version: _version,
                          hasUpdate: _hasUpdate,
                          isLoading: _isLoading,
                        ),
                  ),
                ),
            icon: const Icon(FontAwesomeIcons.solidBell, color: Colors.white),
            splashRadius: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildEnergyUsageCard(Size screenSize, double power) {
    return Container(
      width: screenSize.width * 0.95,
      height: 67,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: _energyCardColor,
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color.fromARGB(255, 255, 0, 0),
                      Color.fromARGB(255, 255, 230, 0),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withOpacity(0.6),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 35),
              ),
              const SizedBox(width: 10),
              const Text(
                'Energy Usage',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${(power / 60000).toString()} Kwh",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                'Rs. ${_currentHomeBill.toStringAsFixed(2)}',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUpdateCard(Size screenSize) {
    return Container(
      width: screenSize.width,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(),
        gradient: LinearGradient(
          colors: _updateCardGradient.map((c) => c.withOpacity(0.7)).toList(),
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.info, size: 25),
          const Text(
            "Firmware Update\nAvailable",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => NotificationPage(
                        version: _version,
                        hasUpdate: _hasUpdate,
                        isLoading: _isLoading,
                      ),
                ),
              );
              if (result == true) await _refreshData();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            child: const Text("View"),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
    return Column(
      children:
          _devices.asMap().entries.map((entry) {
            final index = entry.key;
            final device = entry.value;
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: DeviceCard(
                device: device,
                index: index,
                onToggle: _togglePower,
                onEdit: _showEditDialog,
                onDelete: _removeDevice,
                currentHomePower: _currentHomePower,
                onModeChange: _updateDeviceMode,
                onPriorityChange: _updateDevicePriority,
                onScheduleChange: (index, start, end) async {
                  final deviceId = _devices[index]['id'];
                  await Supabase.instance.client
                      .from('devices')
                      .update({'start_time': start, 'end_time': end})
                      .eq('id', deviceId);
                  // Optional: Refresh UI or re-fetch data if needed
                },
              ),
            );
          }).toList(),
    );
  }

  Widget _buildAddButton({required VoidCallback onCancel}) {
    // List of available device icons
    final List<IconData> deviceIcons = [
      FontAwesomeIcons.lightbulb, // Light
      FontAwesomeIcons.snowflake, // AC
      FontAwesomeIcons.tv, // TV
      FontAwesomeIcons.fan, // fan
      FontAwesomeIcons.wifi, // Router
      FontAwesomeIcons.camera, // Camera
      FontAwesomeIcons.kitchenSet, // Kitchen appliance
    ];

    IconData? selectedIcon = FontAwesomeIcons.lightbulb; // Default icon

    return Column(
      children: [
        if (showInputFields)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.blueGrey[800],
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon Selection Grid
                      const Text(
                        'Select Device Icon',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 150,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 5,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                              ),
                          itemCount: deviceIcons.length,
                          itemBuilder: (context, index) {
                            final icon = deviceIcons[index];
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedIcon = icon;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      selectedIcon == icon
                                          ? Colors.deepPurpleAccent.withOpacity(
                                            0.5,
                                          )
                                          : Colors.blueGrey[700],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  icon,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Device Name Field
                      TextField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Device Name',
                          labelStyle: const TextStyle(color: Colors.white70),
                          prefixIcon: Icon(selectedIcon, color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blueGrey[600]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Device ID Field
                      TextField(
                        controller: idController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Device ID (XX:XX:XX:XX:XX:XX)',
                          labelStyle: const TextStyle(color: Colors.white70),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.blueGrey[600]!,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.info, size: 20),
                            color: Colors.blueGrey[300],
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: const Text('Device ID Format'),
                                      content: const Text(
                                        'Please enter the device ID in correct format:\n\nXX:XX:XX:XX:XX:XX\n\nExample: 1A:2B:3C:4D:5E:6F',
                                      ),
                                      actions: [
                                        TextButton(
                                          child: const Text('OK'),
                                          onPressed:
                                              () => Navigator.pop(context),
                                        ),
                                      ],
                                    ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: onCancel,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _addDevice(selectedIcon),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurpleAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Add Device'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _saveStartTime(int index, String time) async {
    final device = _devices[index];
    await _supabase
        .from('devices')
        .update({'start_time': time})
        .eq('id', device['id']);
    setState(() {
      _devices[index]['start_time'] = time;
    });
  }

  Future<void> _saveEndTime(int index, String time) async {
    final device = _devices[index];
    await _supabase
        .from('devices')
        .update({'end_time': time})
        .eq('id', device['id']);
    setState(() {
      _devices[index]['end_time'] = time;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final power = context.watch<PowerProvider>().currentHomePower;
    ScrollController _scrollController = ScrollController();

    return Scaffold(
      backgroundColor: _backgroundColor,
      key: _scaffoldKey,
      drawer: Drawer(
        child: SideMenuWidget(
          currentIndex: 0,
          onMenuSelect: (index) => print('Selected menu index: $index'),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(context, screenSize),
                const SizedBox(height: 20),
                Center(child: _buildEnergyUsageCard(screenSize, power ?? 0)),
                if (_hasUpdate) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: _buildUpdateCard(screenSize),
                  ),
                  const SizedBox(height: 10),
                ],
                if (showInputFields)
                  _buildAddButton(
                    onCancel: () {
                      setState(() {
                        showInputFields = false;
                        nameController.clear();
                        idController.clear();
                        startTime = null;
                        endTime = null;
                      });
                    },
                  ),
                const SizedBox(height: 10),
                _buildDeviceList(),
                //_buildAddButton(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton:
          showInputFields
              ? null
              : FloatingActionButton(
                child: Icon(Icons.add),
                backgroundColor: Colors.deepPurpleAccent,
                foregroundColor: Colors.white,
                onPressed: () {
                  setState(() {
                    showInputFields = true;
                    print(showInputFields);
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      if (_scrollController.hasClients) {
                        _scrollController.animateTo(
                          _scrollController.position.maxScrollExtent,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOut,
                        );
                      }
                    });
                  });
                },
              ),
    );
  }
}
