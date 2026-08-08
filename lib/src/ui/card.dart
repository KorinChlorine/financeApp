// src/components/card1.dart
import 'package:flutter/material.dart';

class Card1 extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const Card1({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.color = Colors.blue, // default color
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Tapped on $title")),
          );
        },
      ),
    );
  }
}
