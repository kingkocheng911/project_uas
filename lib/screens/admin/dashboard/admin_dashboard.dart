import 'package:flutter/material.dart';

import 'dashboard_stats.dart';
import 'dashboard_overview.dart';

import '../orders/order_list_screen.dart';
import '../products/product_list_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "MepuPoin",
              style: TextStyle(
                color: Color(0xffE60012),
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            Text(
              "KDMP Sukamaju",
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none,
              color: Colors.black,
            ),
          ),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,

        selectedItemColor: const Color(0xffE60012),
        unselectedItemColor: Colors.grey,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: "Dashboard",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined),
            label: "Orders",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: "Produk",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: "Customer",
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (currentIndex) {

      case 0:
        return const SingleChildScrollView(
          child: Column(
            children: [
              DashboardStats(),
              SizedBox(height: 12),
              DashboardOverview(),
              SizedBox(height: 20),
            ],
          ),
        );

      case 1:
        return const OrderListScreen();

      case 2:
        return const ProductListScreen();

      case 3:
        return const Center(
          child: Text(
            "Customer Screen",
            style: TextStyle(
              fontSize: 20,
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }
}