import 'package:flutter/material.dart';

class ToggleProvider extends ChangeNotifier {
  bool _isToggled = false;

  bool get isToggled => _isToggled;

  void toggle() {
    _isToggled = !_isToggled;
    notifyListeners();
  }

  void setToggle(bool value) {
    _isToggled = value;
    notifyListeners();
  }
}
