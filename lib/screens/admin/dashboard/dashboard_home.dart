import 'package:flutter/material.dart';
import 'dashboard_stats.dart';
import 'dashboard_overview.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          DashboardStats(),
          SizedBox(height: 12),
          DashboardOverview(),
          SizedBox(height: 30),
        ],
      ),
    );
  }
}