import 'package:flutter/material.dart';

class UserNavigationPage extends StatefulWidget {
  final String bikeId;

  const UserNavigationPage({
    super.key,
    required this.bikeId,
  });

  @override
  State<UserNavigationPage> createState() => _UserNavigationPageState();
}

class _UserNavigationPageState extends State<UserNavigationPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F4F7),
      appBar: AppBar(
        title: const Text('Navigation'),
        backgroundColor: const Color(0xFF8BE08E),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Text(
          '🚲 Riding ${widget.bikeId}',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}