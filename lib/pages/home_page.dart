import 'package:flutter/material.dart';
import 'package:myapp/controller/wetherAPI.dart';
import 'package:myapp/pages/notification.dart';
import 'package:myapp/widgets/device_card.dart';
import 'package:myapp/widgets/menu.dart';
import 'package:myapp/widgets/wether.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required String title});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> devices = [];
  final String title = "Light";
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final WeatherService weatherService = WeatherService();
  bool showInputFields = false;
  bool isLoading = true;
  bool hasUpdate = false;
  String version = "";

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    fetchUpdateStatus();
  }

  Future<void> _showEditDialog(int index) async {
    final TextEditingController editController = TextEditingController(
      text: devices[index]['name'],
    );

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
                  style: TextStyle(color: Colors.green),
                ),
                onPressed: () async {
                  final newName = editController.text.trim();
                  if (newName.isNotEmpty) {
                    await supabase
                        .from('devices')
                        .update({'name': newName})
                        .eq('device_id', devices[index]['device_id']);
                    setState(() {
                      devices[index]['name'] = newName;
                    });
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _fetchDevices() async {
    final response = await supabase.from('devices').select();

    setState(() {
      devices = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> _addDevice() async {
    final name = nameController.text.trim();
    final id = idController.text.trim();

    if (name.isNotEmpty && id.isNotEmpty) {
      print("ok");
      final newDevice = {'name': name, 'is_on': false, 'mac': id};

      final insertedDevice =
          await supabase.from('devices').insert(newDevice).select().single();

      setState(() {
        devices.add(insertedDevice);
        showInputFields = false;
        nameController.clear();
        idController.clear();
      });
    }
  }

  Future<void> _removeDevice(int index) async {
    final device = devices[index];
    await supabase.from('devices').delete().eq('name', device['name']);
    setState(() {
      devices.removeAt(index);
    });
  }

  Future<void> _togglePower(int index) async {
    final device = devices[index];
    final newState = !device['is_on'];

    await supabase
        .from('devices')
        .update({'is_on': newState})
        .eq('device_id', device['device_id']);

    setState(() {
      devices[index]['is_on'] = newState;
    });
  }

  Future<void> fetchUpdateStatus() async {
    final response =
        await supabase
            .from('updates')
            .select('has_update, version')
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
    if (response != null && response['has_update'] == true) {
      setState(() {
        hasUpdate = true;
        version = response['version'] ?? '';
        isLoading = false;
      });
    } else {
      setState(() {
        hasUpdate = false;
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _fetchDevices(),
      fetchUpdateStatus(),
      weatherService.fetchWeatherByLocation(),
    ]);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 17, 37),
      key: _scaffoldKey,
      /*appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color:const Color.fromARGB(255, 21, 17, 37),
            ),
            child: IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu, color: Colors.white),
              splashRadius: 20,
            ),
          ),
        ),
        title: Text(
          'Devices',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor:const Color.fromARGB(255, 21, 17, 37),
        actions: [
          IconButton(
            icon: Icon(
              showInputFields ? Icons.close : Icons.add,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                showInputFields = !showInputFields;
              });
            },
          ),
        ],
      ),*/
      drawer: Drawer(
        child: SideMenuWidget(
          currentIndex: 0,
          onMenuSelect: (index) {
            print('Selected menu index: $index');
          },
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showInputFields)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Device Name',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: idController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Device ID',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _addDevice,
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    Climate(weatherService: weatherService),
                    Positioned(
                      top: screenSize.height * 0.01,
                      left: screenSize.width * 0.01,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Color.fromARGB(255, 21, 17, 37),
                        ),
                        child: IconButton(
                          onPressed:
                              () => _scaffoldKey.currentState?.openDrawer(),
                          icon: const Icon(Icons.menu, color: Colors.white),
                          splashRadius: 20,
                        ),
                      ),
                    ),
                    Positioned(
                      top: screenSize.height * 0.01,
                      left: screenSize.width * 0.88,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Color.fromARGB(255, 21, 17, 37),
                        ),
                        child: IconButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => NotificationPage(
                                        version: version,
                                        hasUpdate: hasUpdate,
                                        isLoading: isLoading,
                                      ),
                                ),
                              ),
                          icon: const Icon(
                            Icons.notification_add_outlined,
                            color: Colors.white,
                          ),
                          splashRadius: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),
                Center(
                  child: Container(
                    width: screenSize.width * 0.9,
                    height: 67,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0C2B), // dark blue background
                      borderRadius: BorderRadius.circular(35),
                      border: Border.all(
                        color: Colors.white.withOpacity(
                          0.2,
                        ), // 👈 border color here
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            // Glowing Icon Background
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
                                    color: Colors.redAccent.withOpacity(
                                      0.6,
                                    ), // shadow color
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 4), // x, y offset
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.bolt,
                                color: Colors.white,
                                size: 35,
                              ),
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
                          children: const [
                            Text(
                              '10KWh',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'Per Day',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                hasUpdate == true
                    ? Column(
                      children: [
                        SizedBox(height: 10),
                        Center(
                          child: SizedBox(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                width: screenSize.width,
                                height: 80,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(
                                    255,
                                    241,
                                    245,
                                    16,
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(),
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color.fromARGB(
                                        255,
                                        30,
                                        255,
                                        0,
                                      ).withOpacity(0.6),
                                      const Color.fromARGB(
                                        255,
                                        255,
                                        251,
                                        0,
                                      ).withOpacity(0.7),
                                    ],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Icon(Icons.info, size: 25),
                                    Text(
                                      "Firmware Update \n Available",
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
                                                  version: version,
                                                  hasUpdate: hasUpdate,
                                                  isLoading: isLoading,
                                                ),
                                          ),
                                        );
                                        if (result == true) {
                                          await _refreshData();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: Colors.black,
                                      ),
                                      child: Text("View"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    )
                    : SizedBox.shrink(),

                // Convert ListView.builder to Column
                ...devices.asMap().entries.map((entry) {
                  int index = entry.key;
                  var device = entry.value;
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DeviceCard(
                      device: device,
                      index: index,
                      onToggle: _togglePower,
                      onEdit: _showEditDialog,
                      onDelete: _removeDevice,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
