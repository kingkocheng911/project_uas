import 'package:flutter/material.dart';

class CourierCard extends StatelessWidget {
  const CourierCard({super.key});

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
            "Kurir Aktif",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 12),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text("Andi Wijaya"),
            subtitle: Text("Sedang Mengantar"),
            trailing: Text("3 Order"),
          ),

          Divider(),

          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text("Budi Santoso"),
            subtitle: Text("Online"),
            trailing: Text("1 Order"),
          ),
        ],
      ),
    );
  }
}