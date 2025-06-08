import 'package:flutter/material.dart';
import 'package:myapp/widgets/snackbar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationPage extends StatefulWidget {
  NotificationPage({super.key,  required this.isLoading , required this.hasUpdate, required this.version});

  bool isLoading = true;
  bool hasUpdate = false;
  String version = ""; 

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
  }

Future<void> markUpdateAsAcknowledged() async {
  final latest = await supabase
      .from('updates')
      .select('id')
      .order('created_at', ascending: false)
      .limit(1)
      .maybeSingle();

  if (latest != null) {
    await supabase
        .from('updates')
        .update({'update': true}) 
        .eq('id', latest['id']);
    await supabase
        .from('updates')
        .update({'has_update': false}) 
        .eq('id', latest['id']);        

    showCustomSnackBarDone(context, "Update Triggerd!");

    setState(() {
      widget.hasUpdate = false;
    });
  }
  Navigator.pop(context, true);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 21, 17, 37),
      appBar: AppBar(title: const Text("Notifications"),
      backgroundColor: const Color.fromARGB(255, 21, 17, 37),
      ),
     body: widget.isLoading
    ? const Center(child: CircularProgressIndicator())
    : widget.hasUpdate
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.system_update,
                  size: 80,
                  color: Color.fromARGB(255, 0, 251, 255),
                ),
                const SizedBox(height: 20),
                Text(
                  "New Update Available!",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text("Version: ${widget.version}"),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: markUpdateAsAcknowledged,
                  icon: const Icon(Icons.update),
                  label: const Text("Update Now"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 251, 255).withOpacity(0.5),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        : const Center(child: Text("No new notifications.")),
    );
  }
}
