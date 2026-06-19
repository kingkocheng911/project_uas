import 'package:flutter/material.dart';

import '../orders/order_list_screen.dart';

class DashboardOverview extends StatelessWidget {
  const DashboardOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _menu(
                context,
                Icons.inventory_2_outlined,
                "Produk",
                Colors.orange,
                () {
                  // TODO: Product List Screen
                },
              ),

              _menu(
                context,
                Icons.receipt_long,
                "Pesanan",
                Colors.red,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const OrderListScreen(),
                    ),
                  );
                },
              ),

              _menu(
                context,
                Icons.delivery_dining,
                "Kurir",
                Colors.blue,
                () {
                  // TODO: Courier Screen
                },
              ),

              _menu(
                context,
                Icons.campaign,
                "Promo",
                Colors.green,
                () {
                  // TODO: Promotion Screen
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          _inventoryCard(),

          const SizedBox(height: 16),

          _courierCard(),

          const SizedBox(height: 16),

          _recentOrderCard(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x11000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inventoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Inventory Alert",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 10),

          Text("⚠ Beras Premium - 8 tersisa"),
          Text("⚠ Minyak Goreng - 4 tersisa"),
          Text("⚠ Gula Pasir - 2 tersisa"),
        ],
      ),
    );
  }

  Widget _courierCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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

          SizedBox(height: 15),

          ListTile(
            leading: CircleAvatar(
              child: Icon(Icons.person),
            ),
            title: Text("Andi Wijaya"),
            subtitle: Text("Sedang Mengantar"),
            trailing: Text("3 Order"),
          ),

          Divider(),

          ListTile(
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

  Widget _recentOrderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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

          SizedBox(height: 15),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("ORD-240617001"),
            subtitle: Text("Beras Premium x2"),
            trailing: Text(
              "Rp130.000",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Divider(),

          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text("ORD-240617002"),
            subtitle: Text("Minyak Goreng 2L"),
            trailing: Text(
              "Rp32.000",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}