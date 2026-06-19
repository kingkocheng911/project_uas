import 'package:flutter/material.dart';

import 'order_invoice_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),

      appBar: AppBar(
        title: const Text("Detail Pesanan"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [

                      const Text(
                        "ORD-2026001",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Pending",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Informasi Customer",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                    ),
                    title: Text("Budi Santoso"),
                    subtitle: Text(
                      "+62 8123456789",
                    ),
                  ),

                  const Divider(),

                  const Text(
                    "Alamat Pengiriman",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    "Jl. Sukamaju No. 12, Kecamatan Sukamaju",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  const Text(
                    "Produk Pesanan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _productItem(
                    "Beras Premium",
                    "2",
                    "Rp130.000",
                  ),

                  _productItem(
                    "Gula Pasir",
                    "1",
                    "Rp18.000",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(20),
              ),

              child: Column(
                children: [

                  _priceRow(
                    "Subtotal",
                    "Rp148.000",
                  ),

                  const SizedBox(height: 10),

                  _priceRow(
                    "Ongkir",
                    "Rp10.000",
                  ),

                  const Divider(),

                  _priceRow(
                    "Total",
                    "Rp158.000",
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xffE60012),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),

                icon: const Icon(
                  Icons.print,
                  color: Colors.white,
                ),

                label: const Text(
                  "Cetak Invoice",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),

                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const OrderInvoiceScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                icon: const Icon(Icons.edit),

                label: const Text(
                  "Ubah Status",
                ),

                onPressed: () {
                  showModalBottomSheet(
                    context: context,

                    builder: (_) {
                      return Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [

                          ListTile(
                            title:
                                const Text("Pending"),
                            onTap: () {},
                          ),

                          ListTile(
                            title: const Text(
                              "Diproses",
                            ),
                            onTap: () {},
                          ),

                          ListTile(
                            title: const Text(
                              "Dikirim",
                            ),
                            onTap: () {},
                          ),

                          ListTile(
                            title: const Text(
                              "Selesai",
                            ),
                            onTap: () {},
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productItem(
    String name,
    String qty,
    String price,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text("Qty $qty"),
      trailing: Text(price),
    );
  }

  Widget _priceRow(
    String title,
    String value, {
    bool bold = false,
  }) {
    return Row(
      mainAxisAlignment:
          MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}