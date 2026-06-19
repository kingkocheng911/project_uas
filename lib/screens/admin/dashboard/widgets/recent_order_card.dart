import 'package:flutter/material.dart';

class RecentOrderCard extends StatelessWidget {
  const RecentOrderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Pesanan Terbaru",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 12),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("#ORD-240526-01"),
            subtitle: Text("Beras Premium 5kg"),
            trailing: Text("Rp130.000"),
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("#ORD-240526-02"),
            subtitle: Text("Minyak Goreng 2L"),
            trailing: Text("Rp32.000"),
          ),
        ],
      ),
    );
  }
}