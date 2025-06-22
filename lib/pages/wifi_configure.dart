import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class WifiConfigure extends StatefulWidget {
  const WifiConfigure({super.key});

  @override
  State<WifiConfigure> createState() => _WifiConfigureState();
}

class _WifiConfigureState extends State<WifiConfigure> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool _showPassword = false;
  bool _connectionSuccess = false;
  String _message = '';
  Color _messageColor = Colors.black;

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendWifiCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _message = '';
      _connectionSuccess = false;
    });

    try {
      final response = await http
          .post(
            Uri.parse('http://192.168.4.1/wifisave'),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              's': _ssidController.text.trim(),
              'p': _passwordController.text.trim(),
              'id1': _supabase.auth.currentUser?.id,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _message = 'WiFi credentials sent successfully!';
          _messageColor = Colors.green;
          _connectionSuccess = true;
        });
        _passwordController.clear();
      } else {
        setState(() {
          _message =
              'Failed to configure device (Error ${response.statusCode})';
          _messageColor = Colors.orange;
        });
      }
    } on http.ClientException catch (e) {
      if (!mounted) return;
      setState(() {
        _message = 'Network error: ${e.message}';
        _messageColor = Colors.red;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _message = 'Connection timeout — device not responding';
        _messageColor = Colors.red;
      });
    } catch (e, stack) {
      debugPrint('Unexpected error: $e\n$stack');
      if (!mounted) return;
      setState(() {
        _message = 'An unexpected error occurred';
        _messageColor = Colors.red;
      });
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configure Device WiFi"),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Image.asset(
                  'assets/wifi_setup.png', // Add this asset to your project
                  height: 150,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Enter your WiFi credentials to connect your device',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _ssidController,
                decoration: const InputDecoration(
                  labelText: 'WiFi Network Name (SSID)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.wifi),
                  filled: true,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your WiFi name';
                  }
                  if (value.length > 32) {
                    return 'SSID too long (max 32 characters)';
                  }
                  return null;
                },
                inputFormatters: [LengthLimitingTextInputFormatter(32)],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: !_showPassword,
                decoration: InputDecoration(
                  labelText: 'WiFi Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your WiFi password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              const Text(
                'Make sure your device is in configuration mode',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon:
                    _isLoading
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Icon(Icons.send),
                label: Text(_isLoading ? 'Configuring...' : 'Configure Device'),
                onPressed: _isLoading ? null : _sendWifiCredentials,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_message.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _messageColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _messageColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _connectionSuccess ? Icons.check_circle : Icons.info,
                        color: _messageColor,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _message,
                          style: TextStyle(color: _messageColor),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              if (_connectionSuccess)
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Done'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Device Configuration Help'),
            content: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1. Put your device in configuration mode'),
                SizedBox(height: 8),
                Text('2. Connect your phone to the device hotspot'),
                SizedBox(height: 8),
                Text('3. Enter your home WiFi credentials'),
                SizedBox(height: 8),
                Text('4. The device will attempt to connect'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
