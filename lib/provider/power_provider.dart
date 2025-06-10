// power_provider.dart
import 'package:flutter/material.dart';

class PowerProvider with ChangeNotifier {
  double? _power;

  double? get currentHomePower => _power;

  void setPower(double newPower) {
    if (_power != newPower) {
      _power = newPower;
      notifyListeners(); // notify consumers
    }
  }
}
