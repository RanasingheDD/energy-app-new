import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final Function(int index, String startTime, String endTime) onScheduleChange;

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
    required this.onScheduleChange,
  });

  @override
  State<DeviceCard> createState() => _DeviceCardState();
}

class _DeviceCardState extends State<DeviceCard> {
  bool isOn = false;
  bool isLoading = true;
  int count = 0;
  bool showTiming = false;
  String? startTime;
  String? endTime;
  final SupabaseClient supabase = Supabase.instance.client;
  Timer? _timeChecker;

  // Threshold values (can be made configurable)
  static const double powerThresholdHigh = 3000.0; // 3kW
  static const double powerThresholdMedium = 2500.0; // 2.5kW
  static const double powerThresholdLow = 2000.0; // 2kW

  @override
  void initState() {
    super.initState();
    _fetchDeviceStatus();
    _deviceCount();
    startTime = widget.device['start_time'];
    endTime = widget.device['end_time'];

    _startTimingScheduler();
  }

  @override
  void dispose() {
    _timeChecker?.cancel();
    super.dispose();
  }

  int ico(Map<String, dynamic> device) {
    return int.parse(device['icon_code']); // parse decimal string to int
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

  void _startTimingScheduler() {
    _timeChecker = Timer.periodic(const Duration(minutes: 1), (_) {
      final now = TimeOfDay.now().format(context);

      if (!widget.device['auto_mode']) {
        if (startTime != null && now == startTime && !widget.device['is_on']) {
          widget.onToggle(widget.index); // Turn ON
        } else if (endTime != null &&
            now == endTime &&
            widget.device['is_on']) {
          widget.onToggle(widget.index); // Turn OFF
        }
      }
    });
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
      height: screenSize.height * 0.39, // Increased height for new controls
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
                child: Icon(
                  IconData(
                    device['icon_code'], // Decimal value of the icon code (e.g., 0xE037)
                    fontFamily:
                        'FontAwesomeSolid', // Make sure this matches the actual font family used
                  ),
                  size: 30,
                  color: Colors.white,
                ),
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
                    value:
                        ['high', 'medium', 'low'].contains(device['priority'])
                            ? device['priority']
                            : 'medium', // avoid invalid values
                    dropdownColor: const Color(0xFF204952),
                    style: const TextStyle(color: Colors.white),
                    items:
                        ['high', 'medium', 'low'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value[0].toUpperCase() +
                                  value.substring(1), // High, Medium, Low
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
                  const SizedBox(width: 64),
                ],
              ),
            ),
          if (!device['auto_mode']) // Show only in manual mode
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.schedule),
                    label: const Text(
                      'Timing Schedule',
                      style: TextStyle(fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF139790),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        showTiming = !showTiming;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  if (showTiming)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              startTime != null ? startTime! : 'Start Time',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF139790),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  startTime = picked.format(context);
                                });
                                widget.onScheduleChange(
                                  index,
                                  startTime!,
                                  endTime ??
                                      '', // Use a separate handler if needed
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              endTime != null ? endTime! : 'End Time',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF139790),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: TimeOfDay.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  endTime = picked.format(context);
                                });
                                widget.onScheduleChange(
                                  widget.index,
                                  startTime ?? '',
                                  endTime!,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
