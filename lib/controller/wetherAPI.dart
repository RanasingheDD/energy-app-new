import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = 'a2f25c7887c456123593fa0bd7602ec3';

  // Cache
  static Map<String, dynamic>? _cachedWeather;

  Future<Map<String, dynamic>> fetchWeatherByLocation() async {
    if (_cachedWeather != null) return _cachedWeather!;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final double lat = position.latitude;
    final double lon = position.longitude;

    final Uri url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      _cachedWeather = data;
      return data;
    } else {
      throw Exception('Failed to load weather data');
    }
  }

  void clearCache() {
    _cachedWeather = null;
  }
}
