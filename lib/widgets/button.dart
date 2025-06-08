import 'package:flutter/material.dart';

// ignore: must_be_immutable
class BUTTONWIDGET extends StatelessWidget {
  BUTTONWIDGET({
    super.key,
    required this.name,
    required this.color,
    required this.additem,
  });

  final String name;
  final Color color;
  Function() additem;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        additem();
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color, // Text color
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(name),
    );
  }
}
