import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class WifiConfigure extends StatefulWidget {
  const WifiConfigure({super.key});

  @override
  State<WifiConfigure> createState() => _WifiConfigureState();
}

class _WifiConfigureState extends State<WifiConfigure> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final user = Supabase.instance.client.auth.currentUser;
  bool isLoading = false;
  String message = '';

  Future<void> sendWifiCredentials(BuildContext context, String ssid, String password) async {
    setState(() {
      isLoading = true;
      message = '';
    });

    try {
      final url = Uri.parse('http://192.168.4.1/wifisave');
      print(user?.id);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          's': ssid, 
          'p': password,
          'id1': user?.id,
          },
      ).timeout(Duration(seconds: 8));
      if (response.statusCode == 200) {
        setState(() {
          message = '✅ Credentials sent successfully';
          //Navigator.pop(context, true);
        });
      } else {
        setState(() {
          message = '⚠️ Failed to send';
          //Navigator.pop(context, false);
        });
      }
    } catch (e) {
      setState(() {
        message = 'Error: Failed to send';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure Your Device with Wifi"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.wifi, size: 100, color: Color.fromARGB(255, 0, 202, 182)),
              const SizedBox(height: 20),
              TextFormField(
                controller: ssidController,
                decoration: const InputDecoration(
                  labelText: 'Your WiFi SSID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wifi),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter SSID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Your WiFi Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text("Submit"),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          sendWifiCredentials(context,
                            ssidController.text,
                            passwordController.text,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
              const SizedBox(height: 20),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
