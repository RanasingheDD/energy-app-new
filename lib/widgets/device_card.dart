import 'package:flutter/material.dart';
import 'package:myapp/provider/power_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeviceCard extends StatefulWidget {
  final Map<String, dynamic> device;
  final int index;
  final Function(int) onToggle;
  final Function(int) onEdit;
  final Function(int) onDelete;
  final Function(int, String) onPriorityChange;
  final Function(int, bool) onModeChange;
  final double currentHomePower; // Current total home power consumption

  const DeviceCard({
    super.key,
    required this.device,
    required this.index,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onPriorityChange,
    required this.onModeChange,
    required this.currentHomePower,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool isOn = false;
  bool isLoading = true;
  int count = 0;
  final SupabaseClient supabase = Supabase.instance.client;

  // Threshold values (can be made configurable)
  static const double powerThresholdHigh = 3000.0; // 3kW
  static const double powerThresholdMedium = 2500.0; // 2.5kW
  static const double powerThresholdLow = 2000.0; // 2kW

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
              .from('devices')
              .select('is_on')
              .eq('id', widget.device['id'])
              .single();
      setState(() {
        isOn = response['is_on'] ?? false;
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
      setState(() {
        count = response.count;
      });
    } catch (error) {
      print('Error fetching device count: $error');
    }
  }

  void _handleAutoModePowerManagement(double power) {
    if (!widget.device['auto_mode']) return;

    final priority = widget.device['priority'] ?? 'medium';
    final isCurrentlyOn = widget.device['is_on'];

    // Check if we need to turn off based on priority and thresholds
    if (isCurrentlyOn && _shouldTurnOffBasedOnPriority(priority, power)) {
      widget.onToggle(widget.index);
    }
    // Check if we can turn back on when power decreases
    else if (!isCurrentlyOn && _shouldTurnOnBasedOnPriority(priority, power)) {
      widget.onToggle(widget.index);
    }
  }

  bool _shouldTurnOffBasedOnPriority(String priority, double power) {
    switch (priority) {
      case 'low':
        return power > powerThresholdLow;
      case 'medium':
        return power > powerThresholdMedium;
      case 'high':
        return power > powerThresholdHigh;
      default:
        return false;
    }
  }

  bool _shouldTurnOnBasedOnPriority(String priority, double power) {
    // Add some hysteresis to prevent rapid toggling
    const double hysteresis = 200.0; // 200W buffer

    switch (priority) {
      case 'low':
        return power < (powerThresholdLow - hysteresis);
      case 'medium':
        return power < (powerThresholdMedium - hysteresis);
      case 'high':
        return power < (powerThresholdHigh - hysteresis);
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final device = widget.device;
    final index = widget.index;
    final power = context.watch<PowerProvider>().currentHomePower;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleAutoModePowerManagement((power ?? 0).toDouble());
    });

    return Container(
      width: screenSize.width * 0.95,
      height: screenSize.height * 0.34, // Increased height for new controls
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                child: Icon(Icons.light, size: 40),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device['name'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow:
                      device['is_on']
                          ? [
                            BoxShadow(
                              color: const Color.fromARGB(
                                255,
                                0,
                                251,
                                255,
                              ).withOpacity(0.6),
                              blurRadius: 50,
                              spreadRadius: 1,
                              offset: const Offset(0, 1),
                            ),
                          ]
                          : [],
                ),
                child: Switch(
                  value: device['is_on'],
                  onChanged: (value) {
                    if (!device['auto_mode']) {
                      widget.onToggle(index);
                    }
                  },
                  activeColor: const Color.fromARGB(255, 0, 251, 255),
                  inactiveTrackColor: Colors.white24,
                ),
              ),
            ],
          ),

          // Auto/Manual mode toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  'Mode:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    'Manual',
                    style: TextStyle(
                      color: !device['auto_mode'] ? Colors.black : Colors.white,
                    ),
                  ),
                  selected: !device['auto_mode'],
                  selectedColor: Colors.blueAccent,
                  onSelected: (selected) {
                    widget.onModeChange(index, !selected);
                  },
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(
                    'Auto',
                    style: TextStyle(
                      color: device['auto_mode'] ? Colors.black : Colors.white,
                    ),
                  ),
                  selected: device['auto_mode'],
                  selectedColor: Colors.greenAccent,
                  onSelected: (selected) {
                    widget.onModeChange(index, selected);
                  },
                ),
              ],
            ),
          ),

          // Priority selector (only visible in auto mode)
          if (device['auto_mode'])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Text(
                    'Priority:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: device['priority'] ?? 'medium',
                    dropdownColor: const Color(0xFF204952),
                    style: const TextStyle(color: Colors.white),
                    items:
                        ['high', 'medium', 'low'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value[0].toUpperCase() + value.substring(1),
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        widget.onPriorityChange(index, newValue);
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
