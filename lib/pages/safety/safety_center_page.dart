import 'package:flutter/material.dart';

class SafetyCenterPage extends StatelessWidget {
  const SafetyCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Center'),
      ),
      body: const Center(
        child: Text(
          'Safety Center page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}