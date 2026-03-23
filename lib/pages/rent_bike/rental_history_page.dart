import 'package:flutter/material.dart';

class RentalHistoryPage extends StatelessWidget {
  const RentalHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rentals = [
      {
        'id': '2022-3988',
        'date': 'June 18, 9:00 AM - On Going',
        'duration': 'Duration: 20 mins',
        'status': 'In Progress',
      },
      {
        'id': '2022-1879',
        'date': 'June 17, 4:30 PM --------',
        'duration': 'Duration: -----',
        'status': 'Cancelled',
      },
      {
        'id': '2022-2344',
        'date': 'June 16, 9:00 AM - June 16, 9:45 AM',
        'duration': 'Duration: 45 mins',
        'status': 'Completed',
      },
      {
        'id': '2022-2348',
        'date': 'June 16, 1:00 PM - June 16, 2:02 PM',
        'duration': 'Duration: 1 hour & 1 mins',
        'status': 'Completed',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _greenHeader(
            context: context,
            title: 'Rental History',
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Rentals: 4',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Average Time: 42 mins',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.filter_alt_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Filter',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'May 2025',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ...rentals.map((rental) => _historyItem(rental)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(Map<String, String> rental) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID: ${rental['id']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  rental['date'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  rental['duration'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            rental['status'] ?? '',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
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