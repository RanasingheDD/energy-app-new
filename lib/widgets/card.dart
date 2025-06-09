import 'package:flutter/material.dart';
import 'package:myapp/models/card_model.dart';

class CardPage extends StatelessWidget {
  final CardData card;
  const CardPage({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(255, 12, 78, 192).withOpacity(0.4
        ),
          boxShadow: const [
            BoxShadow(
              color:Color.fromARGB(255, 92, 5, 143),
              blurRadius: 5,
              spreadRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                card.image_url,
                width: 15, // Smaller image size
                height: 15,
              ),
              const SizedBox(height: 8),
              Text(
                card.title,
                style: const TextStyle(
                  fontSize: 14, // Reduced text size
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    card.value,
                    style: const TextStyle(
                      fontSize: 18, // Adjusted font size
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    card.symbol,
                    style: const TextStyle(
                      fontSize: 18, // Adjusted font size
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
