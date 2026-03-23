import 'package:flutter/material.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = [
      {
        'id': '2022-3988',
        'date': 'June 18, 2025',
        'duration': 'Duration: 45 mins',
        'amount': '₱75.00',
      },
      {
        'id': '2022-1879',
        'date': 'June 17, 2025',
        'duration': 'Duration: 40 mins',
        'amount': '₱65.00',
      },
      {
        'id': '2022-2343',
        'date': 'June 16, 2025',
        'duration': 'Duration: 60 mins',
        'amount': '₱95.00',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          _greenHeader(
            context: context,
            title: 'Earnings',
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
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F1F4),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 150,
                          height: 110,
                          decoration: const BoxDecoration(
                            color: Color(0xFFDFF4D8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.pedal_bike,
                            size: 72,
                            color: Color(0xFF62C95A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Earnings Summary',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _summaryRow(Icons.pedal_bike_outlined, 'Total Earnings:', '₱2,130.00'),
                        const SizedBox(height: 12),
                        _summaryRow(Icons.calendar_month_outlined, 'This month:', '₱780.00'),
                        const SizedBox(height: 12),
                        _summaryRow(Icons.calendar_today_outlined, 'This week:', '₱250.00'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Row(
                    children: [
                      const Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.filter_alt_outlined, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Filter',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...transactions.map((tx) => _transactionItem(tx)).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade700),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _transactionItem(Map<String, String> tx) {
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
                  'ID: ${tx['id']}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  tx['date'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  tx['duration'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            tx['amount'] ?? '',
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