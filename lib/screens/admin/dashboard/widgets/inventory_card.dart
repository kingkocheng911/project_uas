import 'package:flutter/material.dart';

class InventoryCard extends StatelessWidget {
  const InventoryCard({super.key});

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
            "Inventory Alert",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          SizedBox(height: 12),

          Text("⚠ Beras Premium - 8 tersisa"),
          Text("⚠ Minyak Goreng - 4 tersisa"),
          Text("⚠ Gula Pasir - 2 tersisa"),
        ],
      ),
    );
  }
}