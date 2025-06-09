import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceCard extends StatefulWidget {
  final Map<String, dynamic> device;
  final int index;
  final Function(int) onToggle;
  final Function(int) onEdit;
  final Function(int) onDelete;

  const DeviceCard({
    super.key,
    required this.device,
    required this.index,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool isOn = false;
  bool isLoading = true;
  int count = 0; // Initialize count to 0
  final SupabaseClient supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchDeviceStatus();
    _deviceCount();
  }

  Future<void> _fetchDeviceStatus() async {
    try {
      final response =
          await supabase
              .from('devices') // Replace with your table name
              .select('is_on') // Match device ID
              .single(); // Get single record
      setState(() {
        isOn = response['status'] ?? false;
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deviceCount() async {
    try {
      final response = await supabase
          .from('devices')
          .select('*')
          .count(CountOption.exact);
      final int count0 = response.count;
      setState(() {
        count = count0; // Update count with setState to trigger UI rebuild
      });
      print('Device count: $count0');
    } catch (error) {
      print('Error fetching device count: $error');
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final device = widget.device;
    final index = widget.index;

    return Container(
      width: screenSize.width * 0.95,
      height: screenSize.height * 0.15,
      padding: const EdgeInsets.only(top: 18, bottom: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF182C36),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(255, 35, 46, 104),
            const Color.fromARGB(255, 4, 48, 124),
            const Color.fromARGB(255, 12, 6, 70),
          ],
        ),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: more_vert on left, toggle on right
          Center(
            child: Row(
              children: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: const Color(0xFF204952).withOpacity(1),
                  onSelected: (value) {
                    if (value == 'edit') {
                      widget.onEdit(index);
                    } else if (value == 'delete') {
                      widget.onDelete(index);
                    }
                  },
                  itemBuilder:
                      (context) => const [
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(
                            'Edit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Delete',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 4, 66),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(Icons.light,
                  size: 40,
                  ),
                ),
                Column(
                  children: [
                    Text(
                      device['name'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: screenSize.width * 0.36),
                    Text(
                      device['is_on'] ? 'Connected' : 'Waiting',
                      style: TextStyle(
                        color:
                            device['is_on']
                                ? const Color.fromARGB(255, 0, 251, 255)
                                : Colors.white38,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: screenSize.width * 0.1),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: device['is_on']
                        ? [
                            BoxShadow(
                              color: const Color.fromARGB(255, 0, 251, 255).withOpacity(0.6),
                              blurRadius: 50,
                              spreadRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : [],
                  ),
                  child: Switch(
                    value: device['is_on'],
                    onChanged: (_) => widget.onToggle(index),
                    activeColor: const Color.fromARGB(255, 0, 251, 255),
                    inactiveTrackColor: Colors.white24,
                  ),
                )

              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
