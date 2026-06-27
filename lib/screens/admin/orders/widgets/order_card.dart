import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final String customerName;
  final String invoice;
  final String status;
  final String totalPrice;
  final String itemCount;

  const OrderCard({
    super.key,
    required this.customerName,
    required this.invoice,
    required this.status,
    required this.totalPrice,
    required this.itemCount,
  });

  Color getStatusColor() {
    switch (status.toLowerCase()) {
      case "pending":
        return Colors.orange;
      case "diproses":
        return Colors.blue;
      case "dikirim":
        return Colors.green;
      case "selesai":
        return Colors.teal;
      case "dibatalkan":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData getStatusIcon() {
    switch (status.toLowerCase()) {
      case "pending":
        return Icons.schedule;
      case "diproses":
        return Icons.inventory_2;
      case "dikirim":
        return Icons.local_shipping;
      case "selesai":
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
<<<<<<< HEAD
            color: Colors.black.withValues(alpha: .06),
=======
            color: Colors.black.withValues(alpha: 0.06),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          children: [
            /// HEADER
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(
                    0xffE60012,
<<<<<<< HEAD
                  ).withValues(alpha: .1),
=======
                  ).withValues(alpha: 0.1),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)

                  child: const Icon(Icons.person, color: Color(0xffE60012)),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        invoice,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),

                  decoration: BoxDecoration(
<<<<<<< HEAD
                    color: getStatusColor().withValues(alpha: .12),
=======
                    color: getStatusColor().withValues(alpha: 0.12),
>>>>>>> 8a05f08 (feat: finalize mepupoin backend sync and release prep)
                    borderRadius: BorderRadius.circular(30),
                  ),

                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(getStatusIcon(), size: 14, color: getStatusColor()),

                      const SizedBox(width: 5),

                      Text(
                        status,
                        style: TextStyle(
                          color: getStatusColor(),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Divider(color: Colors.grey.shade200),

            const SizedBox(height: 12),

            /// INFO ORDER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Jumlah Item",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      itemCount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Total Belanja",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      totalPrice,
                      style: const TextStyle(
                        color: Color(0xffE60012),
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 18),

            /// ACTION BUTTON
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onPressed: () {},

                    icon: const Icon(Icons.visibility),

                    label: const Text("Detail"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(45),

                      backgroundColor: const Color(0xffE60012),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),

                    onPressed: () {},

                    icon: const Icon(Icons.local_shipping, color: Colors.white),

                    label: const Text(
                      "Assign",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
