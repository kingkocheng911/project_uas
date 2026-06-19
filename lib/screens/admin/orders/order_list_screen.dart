import 'package:flutter/material.dart';

import 'order_detail_screen.dart';
import 'widgets/order_card.dart';
import 'widgets/order_chart.dart';
import 'widgets/order_filter_bar.dart';
import 'widgets/order_search_bar.dart';
import 'widgets/order_status_card.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final List<Map<String, dynamic>> orders = [
    {
      "customer": "Ahmad Fauzi",
      "invoice": "INV-2026001",
      "status": "Pending",
      "total": "Rp 250.000",
      "items": "4 Produk",
    },
    {
      "customer": "Budi Santoso",
      "invoice": "INV-2026002",
      "status": "Diproses",
      "total": "Rp 180.000",
      "items": "3 Produk",
    },
    {
      "customer": "Siti Nurhaliza",
      "invoice": "INV-2026003",
      "status": "Dikirim",
      "total": "Rp 420.000",
      "items": "7 Produk",
    },
  ];

  Future<void> _refreshOrders() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xffE60012),
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Fitur laporan segera tersedia"),
            ),
          );
        },
        icon: const Icon(Icons.print,color: Colors.white),
        label: const Text(
          "Laporan",
          style: TextStyle(color: Colors.white),
        ),
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshOrders,

          child: ListView(
            padding: const EdgeInsets.all(16),

            children: [

              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Orders",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 4),

                      Text(
                        "Kelola seluruh pesanan",
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const OrderSearchBar(),

              const SizedBox(height: 20),

              SizedBox(
                height: 170,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [

                    OrderStatusCard(
                      title: "Pending",
                      value: "12",
                      icon: Icons.pending_actions,
                      colors: [
                        Color(0xffFF9800),
                        Color(0xffFFB74D),
                      ],
                    ),

                    SizedBox(width: 12),

                    OrderStatusCard(
                      title: "Diproses",
                      value: "8",
                      icon: Icons.inventory_2,
                      colors: [
                        Color(0xff1E88E5),
                        Color(0xff42A5F5),
                      ],
                    ),

                    SizedBox(width: 12),

                    OrderStatusCard(
                      title: "Dikirim",
                      value: "15",
                      icon: Icons.local_shipping,
                      colors: [
                        Color(0xff43A047),
                        Color(0xff66BB6A),
                      ],
                    ),

                    SizedBox(width: 12),

                    OrderStatusCard(
                      title: "Batal",
                      value: "3",
                      icon: Icons.cancel,
                      colors: [
                        Color(0xffE53935),
                        Color(0xffEF5350),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Colors.black.withOpacity(.04),
                      blurRadius: 12,
                    ),
                  ],
                ),

                child: const Row(
                  children: [

                    CircleAvatar(
                      radius: 28,
                      backgroundColor:
                          Color(0xffE8F5E9),
                      child: Icon(
                        Icons.payments,
                        color: Colors.green,
                      ),
                    ),

                    SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [

                          Text(
                            "Omzet Hari Ini",
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),

                          SizedBox(height: 4),

                          Text(
                            "Rp 4.850.000",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const OrderChart(),

              const SizedBox(height: 20),

              const OrderFilterBar(),

              const SizedBox(height: 20),

              const Text(
                "Daftar Pesanan",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...orders.map(
                (order) => Padding(
                  padding:
                      const EdgeInsets.only(bottom: 12),

                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(20),

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const OrderDetailScreen(),
                        ),
                      );
                    },

                    child: Stack(
                      children: [

                        OrderCard(
                          customerName:
                              order["customer"],
                          invoice:
                              order["invoice"],
                          status:
                              order["status"],
                          totalPrice:
                              order["total"],
                          itemCount:
                              order["items"],
                        ),

                        Positioned(
                          top: 10,
                          right: 10,
                          child: PopupMenuButton(
                            itemBuilder: (context) => [

                              const PopupMenuItem(
                                value: 'detail',
                                child: Text(
                                    'Detail Order'),
                              ),

                              const PopupMenuItem(
                                value: 'invoice',
                                child:
                                    Text('Cetak Invoice'),
                              ),

                              const PopupMenuItem(
                                value: 'status',
                                child:
                                    Text('Ubah Status'),
                              ),

                              const PopupMenuItem(
                                value: 'delete',
                                child:
                                    Text('Hapus'),
                              ),
                            ],

                            onSelected: (value) {

                              if (value ==
                                  'detail') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const OrderDetailScreen(),
                                  ),
                                );
                              }

                              if (value ==
                                  'delete') {
                                ScaffoldMessenger.of(
                                        context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Order berhasil dihapus",
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}