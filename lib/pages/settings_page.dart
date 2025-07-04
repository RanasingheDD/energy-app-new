import 'package:flutter/material.dart';
import 'package:myapp/login/signup/register.dart';
import 'package:myapp/pages/wifi_configure.dart';
import 'package:myapp/provider/ThemeProvider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
  bool wifiConnected = false;

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }

  void _getAppVersion() async {
    setState(() {
      appVersion = '2.0.0';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor:
          themeProvider.isDarkMode
              ? const Color.fromARGB(255, 21, 17, 37)
              : Colors.white,
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor:
            themeProvider.isDarkMode
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
                  Text(
                    "Wifi Configure",
                    style: TextStyle(
                      color:
                          themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                      fontSize: 16,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color:
                            wifiConnected ? Colors.green.shade200 : Colors.grey,
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const WifiConfigure(),
                            ),
                          ).then((result) {
                            if (result == true) {
                              setState(() {
                                wifiConnected = true;
                              });
                            }
                          });
                        },
                        icon: Icon(
                          Icons.wifi_outlined,
                          //color: wifiConnected ? Colors.green : Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Log out",
                    style: TextStyle(
                      color:
                          themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black,
                      fontSize: 16,
                      //fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color:
                            themeProvider.isDarkMode
                                ? Colors.grey
                                : Colors.black.withOpacity(0.2),
                      ),
                      child: IconButton(
                          onPressed: () async {
                            final shouldLogout = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Confirm Logout'),
                                content: const Text('Are you sure you want to logout?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );

                            if (shouldLogout == true) {
                              await Supabase.instance.client.auth.signOut();
                              if (context.mounted) {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AuthPage(),
                                  ),
                                  (route) => false,
                                );
                              }
                            }
                          },
                          icon: Icon(
                            Icons.logout_outlined,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                            size: 30,
                          ),
                        )

                    ),
                  ),
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

  Widget _buildAboutSection(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          color: const Color.fromRGBO(255, 255, 255, 0.302),
          thickness: 1,
        ),
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
