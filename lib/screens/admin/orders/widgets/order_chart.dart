import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class OrderChart extends StatelessWidget {
  const OrderChart({super.key});

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 220,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: LineChart(
        LineChartData(
          gridData: const FlGridData(
            show: false,
          ),

          titlesData: const FlTitlesData(
            show: false,
          ),

          borderData: FlBorderData(
            show: false,
          ),

          lineBarsData: [
            LineChartBarData(
              isCurved: true,

              spots: const [
                FlSpot(0, 10),
                FlSpot(1, 20),
                FlSpot(2, 15),
                FlSpot(3, 35),
                FlSpot(4, 25),
                FlSpot(5, 50),
              ],
            )
          ],
        ),
      ),
    );
  }
}