import 'package:flutter/material.dart';

class TopProductCard extends StatelessWidget {
  const TopProductCard({super.key});

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
            "Produk Terlaris",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 12),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Beras Premium"),
            trailing: Text("245 Terjual"),
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Minyak Goreng"),
            trailing: Text("180 Terjual"),
          ),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("Gula Pasir"),
            trailing: Text("143 Terjual"),
          ),
        ],
      ),
    );
  }
}