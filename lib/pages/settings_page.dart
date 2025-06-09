import 'package:flutter/material.dart';
import 'package:myapp/login/signup/register.dart';
import 'package:myapp/provider/ThemeProvider.dart';
import 'package:myapp/widgets/snackbar.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/menu.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isPushNotificationEnabled = true;
  bool isSoundEnabled = true;
  bool isVibrationEnabled = true;
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  void _getAppVersion() async {
    setState(() {
      appVersion = '1.0.0'; // Example version
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode
          ? const Color.fromARGB(255, 21, 17, 37)
          : Colors.white,
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: themeProvider.isDarkMode
            ? const Color.fromARGB(255, 21, 17, 37)
            : Colors.white,
        foregroundColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Drawer(
        child: SideMenuWidget(
          currentIndex: 3,
          onMenuSelect: (index) {
            print('Selected menu index: $index');
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Wifi Configure",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    //fontWeight: FontWeight.bold,
                  ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color:themeProvider.isDarkMode ? Colors.grey : Colors.black.withOpacity(0.2),
                      ),
                      child: IconButton(
                        onPressed: () async {
                          final Uri url = Uri.parse('http://192.168.4.1');
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                        },
                        icon: Icon(
                          Icons.wifi_outlined,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: MediaQuery.sizeOf(
                context
              ).height * 0.03
              )
              ,
              _buildSwitchTile(
                title: themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                value: themeProvider.isDarkMode,
                onChanged: themeProvider.toggleTheme,
              ),
              const SizedBox(height: 20),
              _buildSwitchTile(
                title: 'Push Notifications',
                value: isPushNotificationEnabled,
                onChanged: (value) => setState(() {
                  isPushNotificationEnabled = value;
                }),
              ),
              const SizedBox(height: 20),
              _buildSwitchTile(
                title: 'Notification Sound',
                value: isSoundEnabled,
                onChanged: (value) => setState(() {
                  isSoundEnabled = value;
                }),
              ),
              const SizedBox(height: 20),
              _buildSwitchTile(
                title: 'Notification Vibration',
                value: isVibrationEnabled,
                onChanged: (value) => setState(() {
                  isVibrationEnabled = value;
                }),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Log out",
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    fontSize: 16,
                    //fontWeight: FontWeight.bold,
                  ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color:themeProvider.isDarkMode ? Colors.grey : Colors.black.withOpacity(0.2),
                      ),
                      child: IconButton(
                          onPressed: () async {
                            await Supabase.instance.client.auth.signOut();
                            if (context.mounted) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => const AuthPage()),
                              );
                            }
                          },
                        icon: Icon(
                          Icons.logout_outlined,
                          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                          size: 30,
                        ),
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              _buildAboutSection(themeProvider.isDarkMode),
              const SizedBox(height: 20),
              _buildAppVersion(themeProvider.isDarkMode),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).isDarkMode
                ? Colors.white
                : Colors.black,
            fontSize: 16,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: Colors.grey,
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: const Color.fromRGBO(255, 255, 255, 0.302), thickness: 1),
        Text(
          'About Us',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We are a team passionate about creating amazing apps for our users.\n\nRanasingheDD & Madush123',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildAppVersion(bool isDarkMode) {
    return Row(
      children: [
        Text(
          'App Version: ',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
        Text(
          appVersion.isEmpty ? 'Loading...' : appVersion,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
