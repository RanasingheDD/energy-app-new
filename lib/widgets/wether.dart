import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/controller/wetherAPI.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Climate extends StatefulWidget {
  const Climate({super.key, required this.weatherService});

  final WeatherService weatherService;

  @override
  State<Climate> createState() => _ClimateState();
}

class _ClimateState extends State<Climate> {
  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String _errorMessage = '';
  bool _hasFetchedOnce = false;
  String name = "";

  @override
  void initState() {
    super.initState();
    _initializeWeather();
    _getUserName();
  }

  void _initializeWeather() {
    if (!_hasFetchedOnce) {
      _fetchWeather();
      _hasFetchedOnce = true;
    }
  }

  Future<void> _getUserName() async {
    try {
      final user = await Supabase.instance.client.auth.currentUser;
      final displayName = user?.userMetadata?['full_name'] ?? 'No name set';
      setState(() {
        this.name = displayName;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '⚠️ Unable to load username.';
      });
    }
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final data = await widget.weatherService.fetchWeatherByLocation();
      setState(() {
        _weatherData = data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '⚠️ Unable to load weather data.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final double padding = screenSize.width * 0.04;
    final double imageWidth = screenSize.width * 0.4;
    final double iconSize = screenSize.width * 0.22;
    final double titleFontSize = screenSize.width * 0.05;
    final double tempFontSize = screenSize.width * 0.14;
    final double descFontSize = screenSize.width * 0.04;

    return Container(
      width: double.infinity,
      height: screenSize.height * 0.5,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(4, 6),
          ),
        ],
      ),
      child:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : _weatherData != null
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 15),
                  Padding(
                    padding: EdgeInsets.only(
                      top: 15,
                      left: 50,
                      right: 20,
                      bottom: 15,
                    ),
                    child: Text(
                      'Hi ${name}',
                      style: GoogleFonts.alef(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.asset(
                              "assets/cloud.png",
                              width: imageWidth - 20,
                              height: imageWidth - 20,
                            ),
                            Positioned(
                              top: 10,
                              child: Image.asset(
                                "assets/moon.png",
                                width: iconSize,
                                height: iconSize,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${_weatherData!['name']}, ${_weatherData!['sys']['country']}',
                                    style: TextStyle(
                                      fontSize: titleFontSize,
                                      color: Colors.white70,
                                      //fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${_weatherData!['main']['temp'].toStringAsFixed(1)}°C',
                                    style: GoogleFonts.antonio(
                                      fontSize: tempFontSize,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _weatherData!['weather'][0]['description']
                                      .toString()
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: descFontSize,
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    color: const Color.fromRGBO(255, 255, 255, 0.302),
                    thickness: 1,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomIconText(
                        icon: Icons.air,
                        value: '${_weatherData!['wind']['speed']} km/h',
                        label: 'Wind',
                      ),
                      _buildBottomIconText(
                        icon: Icons.water_drop,
                        value: '${_weatherData!['main']['humidity']}%',
                        label: 'Humidity',
                      ),
                      _buildBottomIconText(
                        icon: Icons.thermostat,
                        value:
                            '${_weatherData!['main']['feels_like'].toStringAsFixed(1)}°C',
                        label: 'Feels Like',
                      ),
                    ],
                  ),
                ],
              )
              : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _fetchWeather,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Retry"),
                  ),
                ],
              ),
    );
  }

  Widget _buildBottomIconText({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
