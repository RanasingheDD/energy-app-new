import 'package:supabase_flutter/supabase_flutter.dart';

class SensorDataService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, double>>> fetchSensorData() async {
    try {
      // Fetch data from the 'SensorData' table and select multiple columns
      final response = await supabase
          .from('SensorData') // Table name
          .select(
            'power, voltage, current, temperature, humidity, light',
          ) // Selecting multiple columns
          .limit(100) // Optional: limit the number of records if needed
          .order(
            'created_at',
            ascending: false,
          ); // Optional: order by creation date if applicable
      final List<Map<String, dynamic>> sensorData =
          response.map((data) {
            return {
              'power': data['power'] ?? 0.0,
              'voltage': data['voltage'] ?? 0.0,
              'current': data['current'] ?? 0.0,
              'temperature': data['temperature'] ?? 0.0,
              'humidity': data['humidity'] ?? 0.0,
              'light': data['light'] ?? 0.0,
            };
          }).toList();

      // Initialize sums
      double totalPower = 0;
      double totalVoltage = 0;
      double totalCurrent = 0;
      double totalTemperature = 0;
      double totalHumidity = 0;
      double totalLight = 0;

      // Sum up values
      for (var data in sensorData) {
        totalPower += (data['power'] as num).toDouble();
        totalVoltage += (data['voltage'] as num).toDouble();
        totalCurrent += (data['current'] as num).toDouble();
        totalTemperature += (data['temperature'] as num).toDouble();
        totalHumidity += (data['humidity'] as num).toDouble();
        totalLight += (data['light'] as num).toDouble();
      }

      // Calculate averages
      int count = sensorData.length - 1;
      if (count == 0) throw Exception('No data available.');

      // Calculate the averages and return them with 2 decimal points
      final Map<String, double> avgSensorData = {
        'power': double.parse((totalPower / count).toStringAsFixed(2)),
        'voltage': double.parse((totalVoltage / count).toStringAsFixed(2)),
        'current': double.parse((totalCurrent / count).toStringAsFixed(2)),
        'temperature': double.parse(
          (totalTemperature / count).toStringAsFixed(2),
        ),
        'humidity': double.parse((totalHumidity / count).toStringAsFixed(2)),
        'light': double.parse((totalLight / count).toStringAsFixed(2)),
      };

      // Return the average data
      return [avgSensorData];
    } catch (e) {
      // Improved error handling
      print('Error fetching sensor data: $e');
      throw Exception("Failed to fetch sensor data: $e");
    }
  }
}
