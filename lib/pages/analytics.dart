import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:myapp/models/card_model.dart';
import 'package:myapp/provider/report_data_provider.dart';
import 'package:myapp/supabase/supabase_data.dart';
import 'package:myapp/widgets/button.dart';
import 'package:myapp/widgets/card.dart';
import 'package:myapp/widgets/menu.dart';
import 'package:myapp/widgets/snackbar.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

//Initial cards data
List<CardData> cards = [
  CardData(
    title: "Voltage",
    image_url: "assets/voltage.png",
    value: "0",
    symbol: "V",
  ),
  CardData(
    title: "Current",
    image_url: "assets/voltage.png",
    value: "0",
    symbol: "A",
  ),
  CardData(title: "Power", image_url: "assets/pf.png", value: "0", symbol: ""),
  CardData(
    title: "Temperature",
    image_url: "assets/hum.png",
    value: "0",
    symbol: "C",
  ),
  CardData(
    title: "Humidity",
    image_url: "assets/hum.png",
    value: "0",
    symbol: "%",
  ),
  CardData(
    title: "Light",
    image_url: "assets/bright.png",
    value: "0",
    symbol: "lux",
  ),
];

class Devices extends StatefulWidget {
  const Devices({super.key});

  @override
  _DevicesState createState() => _DevicesState();
}

class _DevicesState extends State<Devices> {
  final SensorDataService _sensorDataService = SensorDataService();
  final supabase = Supabase.instance.client;
 
  double averagePower = 0.0;

  bool showInputFields = false;
  final TextEditingController _roomNameController = TextEditingController();
  final user = Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadSensorData();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _showTitle = true;
      });
    });
  }

  Future<void> _loadSensorData() async {
    try {
      //final response = await supabase.from('devices').select();
      final data = await _sensorDataService.fetchSensorData();
      print(data);
      setState(() {
        //averagePower = _calculateAveragePower(data);
        //devices = List<Map<String, dynamic>>.from(response);
        //print(devices.length);
        cards[0].value = data.isNotEmpty ? data[0]['voltage'].toString() : "0";
        cards[1].value = data.isNotEmpty ? data[0]['current'].toString() : "0";
        cards[2].value = data.isNotEmpty ? data[0]['power'].toString() : "0";
        cards[3].value = data.isNotEmpty ? data[0]['temperature'].toString() : "0";
        cards[4].value = data.isNotEmpty ? data[0]['humidity'].toString() : "0";
        cards[5].value = data.isNotEmpty ? data[0]['light'].toString() : "0";
      });
    } catch (e) {
      print('Error loading sensor data: $e');
    }
  }

  void _showRoomNameDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Room Name'),
          content: TextField(
            controller: _roomNameController,
            decoration: const InputDecoration(hintText: 'Room Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
  onPressed: () async {
    String roomName = _roomNameController.text.isNotEmpty
        ? _roomNameController.text
        : 'Room 01'; // Default name

    try {
      final reportProvider = Provider.of<ReportDataProvider>(context, listen: false);
      final reportData = reportProvider.reportData.values;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      const apiUrl = 'http://104.154.38.183:5000/generate-pdf';

      final details = reportData.map((data) {
        return {
          "room": data.room.isNotEmpty ? data.room : roomName,
          "voltage": data.volt,
          "current": data.current,
          "power": data.power,
          "humidity": double.tryParse(data.hum.toString()) ?? 0.0,
          "light_intensity": double.tryParse(data.light.toString()) ?? 0.0,
          "temperature": double.tryParse(data.tempure.toString()) ?? 0.0,
        };
      }).toList();

      final payload = {
        "room_number": "010", // or set to roomName if needed
        "date": DateTime.now().toIso8601String().split('T')[0],
        "time": TimeOfDay.now().format(context),
        "details": details,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        showCustomSnackBarDone(context, "Report Sent Succesfully!");
        print("Response: ${response.body}");
      } else {
        throw Exception("Failed to send report. Status code: ${response.statusCode}");
      }
    } catch (e) {
      showCustomSnackBarError(context, "Faild to send Report!");
    } finally {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(); // Dismiss loading dialog
      }
    }

    Navigator.of(context).pop(); // Close the add room dialog
  },
  child: const Text('Add'),
)

          ],
        );
      },
    );
  }


  void _confirmAndDeleteDatabase(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Database Data"),
          content: const Text(
            "Are you sure you want to delete all data from the database? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteSupabaseData(context);
                Navigator.of(context).pop(); // Close the dialog after deleting
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

Future<void> _deleteSupabaseData(BuildContext context) async {
  try {
    print("Fetching all data to delete except the first row...");
    // Now delete those rows
    final deleteResponse = await supabase
        .from('SensorData')
        .delete()
        .eq('user_id', user!.id).order('created_at', ascending: true).range(1, 100);

    print("Deleted rows: $deleteResponse");

    if (deleteResponse == null) {
          snackbarDone();
    }
  } catch (e) {
    print("Error deleting data: $e");
    if (context.mounted) {
      snackbarError();
    }
  }
}

void snackbarDone(){
  showCustomSnackBarDone(context, "All data deleted successfully!");
}

void snackbarError(){
  showCustomSnackBarError(context, "Something went wrong!");
}

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showTitle = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Assign the GlobalKey
      backgroundColor: const Color.fromARGB(255, 21, 17, 37),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 21, 17, 37),
        leading: IconButton(
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          icon: const Icon(Icons.menu, color: Colors.white),
        ),
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          transitionBuilder:
              (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
          child:
              _showTitle
                  ? const Text(
                    'Analytics',
                    key: ValueKey("title"),
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  )
                  : const SizedBox(height: 20),
        ),
        centerTitle: true,
        actions: [

        ],
      ),
      drawer: Drawer(
        child: SideMenuWidget(
          currentIndex: 1,
          onMenuSelect: (index) {
            print('Selected menu index: $index');
          },
        ),
      ),
      body: Consumer<ReportDataProvider>(
        builder: (context, reportData, child) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showInputFields)


                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Number of columns
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio:
                              1.5, // Adjust this for card height/width ratio
                        ),
                    // physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final CardData card = cards[index];
                      return CardPage(card: card);
                    },
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    BUTTONWIDGET(
                      name: "Make Report ",
                      color: Colors.green,
                      additem: _showRoomNameDialog,
                    ),
                    BUTTONWIDGET(
                      name: "Delete Data",
                      color: Colors.red,
                      additem: () => _confirmAndDeleteDatabase(context),
                    ),
                  ],
                ),
               
              ],
            ),
          );
        },
      ),
    );
  }
}
