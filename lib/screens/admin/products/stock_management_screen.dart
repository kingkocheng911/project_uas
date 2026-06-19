import 'package:flutter/material.dart';

class StockManagementScreen
    extends StatelessWidget {
  const StockManagementScreen(
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xffF5F7FA),

      appBar: AppBar(
        title:
            const Text("Manajemen Stok"),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            const Color(0xffE60012),

        onPressed: () {},

        label: const Text(
          "Update Stok",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [

            Container(
              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                        20),
              ),

              child: const Column(
                children: [

                  Text(
                    "Stok Saat Ini",
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "25",
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: ListView(
                children: [

                  _historyTile(
                    "+10",
                    "Restok Gudang",
                    Colors.green,
                  ),

                  _historyTile(
                    "-5",
                    "Pesanan Customer",
                    Colors.red,
                  ),

                  _historyTile(
                    "+20",
                    "Barang Masuk",
                    Colors.green,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyTile(
    String qty,
    String title,
    Color color,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              color.withOpacity(.15),
          child: Text(
            qty,
            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),
        title: Text(title),
        subtitle:
            const Text("Hari ini"),
      ),
    );
  }
}