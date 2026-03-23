import 'package:flutter/material.dart';

class ManageBikePage extends StatefulWidget {
  const ManageBikePage({super.key});

  @override
  State<ManageBikePage> createState() => _ManageBikePageState();
}

class _ManageBikePageState extends State<ManageBikePage> {
  final List<Map<String, dynamic>> _bikes = [
    {
      'bikeName': "Aiyeen's Bike",
      'deviceCode': 'TDK-44572',
      'status': 'Available for Rent',
      'maintenance': 'No',
      'available': true,
    },
    {
      'bikeName': "Aiyeen's Bike",
      'deviceCode': 'TDK-44573',
      'status': 'Available for Rent',
      'maintenance': 'No',
      'available': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _greenHeader(
            context: context,
            title: 'Manage Bike',
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              transform: Matrix4.translationValues(0, -24, 0),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F5F8),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: [
                  const Text(
                    'Registered Bike',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(
                    _bikes.length,
                        (index) => _bikeCard(
                      bikeName: _bikes[index]['bikeName'],
                      deviceCode: _bikes[index]['deviceCode'],
                      status: _bikes[index]['status'],
                      maintenance: _bikes[index]['maintenance'],
                      available: _bikes[index]['available'],
                      onToggle: (value) {
                        setState(() {
                          _bikes[index]['available'] = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bikeCard({
    required String bikeName,
    required String deviceCode,
    required String status,
    required String maintenance,
    required bool available,
    required ValueChanged<bool> onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bike name: $bikeName',
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ),
              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade600),
            ],
          ),
          const SizedBox(height: 6),
          Text('Device Code: $deviceCode'),
          const SizedBox(height: 4),
          Text('Status: $status'),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text('Maintenance Needed: $maintenance')),
              const Text(
                'Availability',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Switch(
                value: available,
                onChanged: onToggle,
                activeColor: const Color(0xFF66D16A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _greenHeader({
    required BuildContext context,
    required String title,
  }) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF39D34A),
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 42),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          ),
          Expanded(
            child: Center(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 26),
        ],
      ),
    );
  }
}