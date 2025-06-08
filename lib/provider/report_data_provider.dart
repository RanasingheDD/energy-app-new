import 'package:flutter/material.dart';
import 'package:myapp/models/card_model.dart';
import 'package:myapp/models/report_card_model.dart';

class ReportDataProvider extends ChangeNotifier {

  final Map<String, ReportData> _reportData = {};

  Map<String, ReportData> get reportData {
    return {..._reportData};
  }

  // Add homepage data to report page
  void addData(String room, List<CardData> cardData) {
    // Extract values from the cardData list
    final String voltage = cardData.firstWhere(
      (card) => card.title == "Voltage",
      orElse: () => CardData(title: "Voltage", value: "0", symbol: "V", image_url: 'asseets/voltage.png'),
    ).value;

    final String current = cardData.firstWhere(
      (card) => card.title == "Current",
      orElse: () => CardData(title: "Current", value: "0", symbol: "A", image_url: 'asseets/voltage.png'),
    ).value;

    final String power = cardData.firstWhere(
      (card) => card.title == "Power",
      orElse: () => CardData(title: "Power", value: "0", symbol: "", image_url: 'asseets/voltage.png'),
    ).value;

    final String humidity = cardData.firstWhere(
      (card) => card.title == "Humidity",
      orElse: () => CardData(title: "Humidity", value: "0", symbol: "%", image_url: 'asseets/voltage.png'),
    ).value;

    final String brightness = cardData.firstWhere(
      (card) => card.title == "Light",
      orElse: () => CardData(title: "Light", value: "0", symbol: "lux", image_url: 'asseets/voltage.png'),
    ).value;

    final String temperature = cardData.firstWhere(
      (card) => card.title == "Temperature",
      orElse: () => CardData(title: "Temperature", value: "0", symbol: "°C", image_url: 'asseets/voltage.png'),
    ).value;

    // Add the extracted values to the _reportData map
    _reportData.putIfAbsent(
      room,
      () => ReportData(
        volt: voltage,
        current: current,
        power: power,
        hum: humidity,
        light: brightness,
        room: room,
        tempure: temperature,
      ),
    );

    // Notify listeners about the change
    notifyListeners();
  }
}
