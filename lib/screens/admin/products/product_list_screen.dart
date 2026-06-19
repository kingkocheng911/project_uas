import 'package:flutter/material.dart';

import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'product_detail_screen.dart';
import 'category_screen.dart';
import 'stock_management_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final List<Map<String, dynamic>> products = [
    {
      "name": "Beras Premium 5kg",
      "price": 65000,
      "stock": 25,
      "category": "Sembako",
    },
    {
      "name": "Minyak Goreng 2L",
      "price": 32000,
      "stock": 10,
      "category": "Sembako",
    },
    {
      "name": "Gula Pasir",
      "price": 18000,
      "stock": 5,
      "category": "Sembako",
    },
    {
      "name": "Kopi Bubuk",
      "price": 25000,
      "stock": 15,
      "category": "Minuman",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f7fb),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xffE60012),
        elevation: 8,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddProductScreen(),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 15),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    "Kelola Produk",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 55,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.04),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    hintText: "Cari produk...",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      "Total",
                      "245",
                      Icons.inventory_2_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _summaryCard(
                      "Low Stock",
                      "12",
                      Icons.warning_amber_rounded,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 45,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _filterChip("Semua", true),
                  _filterChip("Aktif", false),
                  _filterChip("Low Stock", false),
                  _filterChip("Promo", false),
                ],
              ),
            ),

            const SizedBox(height: 10),

           Expanded(
  child: GridView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: products.length,
    gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      mainAxisExtent: 330,
    ),
    itemBuilder: (context, index) {
      final product = products[index];

      return InkWell(
        borderRadius: BorderRadius.circular(22),

        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const ProductDetailScreen(),
            ),
          );
        },

        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(.06),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color:
                          Colors.grey.shade100,
                      borderRadius:
                          const BorderRadius
                              .vertical(
                        top:
                            Radius.circular(22),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius:
                            BorderRadius.circular(
                                20),
                      ),
                      child: const Text(
                        "Aktif",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        product['name'],
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(
                          height: 8),

                      Text(
                        "Rp ${product['price']}",
                        style:
                            const TextStyle(
                          color:
                              Color(0xffE60012),
                          fontWeight:
                              FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),

                      const SizedBox(
                          height: 6),

                      Row(
                        children: [
                          Icon(
                            Icons
                                .inventory_2_outlined,
                            size: 15,
                            color: Colors
                                .grey
                                .shade600,
                          ),
                          const SizedBox(
                              width: 4),
                          Text(
                            "Stok ${product['stock']}",
                            style:
                                const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                          height: 8),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: Colors
                              .orange
                              .shade50,
                          borderRadius:
                              BorderRadius
                                  .circular(8),
                        ),
                        child: Text(
                          product['category'],
                          style: TextStyle(
                            color: Colors
                                .orange
                                .shade800,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      const Spacer(),

                      Row(
                        children: [

                          Expanded(
                            child:
                                ElevatedButton
                                    .icon(
                              style:
                                  ElevatedButton
                                      .styleFrom(
                                backgroundColor:
                                    const Color(
                                        0xffE60012),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                          12),
                                ),
                              ),

                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const EditProductScreen(),
                                  ),
                                );
                              },

                              icon: const Icon(
                                Icons.edit,
                                size: 16,
                                color:
                                    Colors.white,
                              ),

                              label:
                                  const Text(
                                "Edit",
                                style:
                                    TextStyle(
                                  color:
                                      Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(
                              width: 8),

                          Container(
                            decoration:
                                BoxDecoration(
                              color: Colors
                                  .grey
                                  .shade100,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                          12),
                            ),
                            child:
                                IconButton(
                              icon: const Icon(
                                Icons.more_vert,
                              ),

                              onPressed:
                                  () {
                                showModalBottomSheet(
                                  context:
                                      context,

                                  shape:
                                      const RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.vertical(
                                      top:
                                          Radius.circular(
                                              20),
                                    ),
                                  ),

                                  builder:
                                      (_) {
                                    return SafeArea(
                                      child:
                                          Column(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [

                                          ListTile(
                                            leading:
                                                const Icon(
                                              Icons.visibility,
                                            ),
                                            title:
                                                const Text(
                                              "Detail Produk",
                                            ),
                                            onTap:
                                                () {
                                              Navigator.pop(
                                                  context);

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const ProductDetailScreen(),
                                                ),
                                              );
                                            },
                                          ),

                                          ListTile(
                                            leading:
                                                const Icon(
                                              Icons.edit,
                                            ),
                                            title:
                                                const Text(
                                              "Edit Produk",
                                            ),
                                            onTap:
                                                () {
                                              Navigator.pop(
                                                  context);

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const EditProductScreen(),
                                                ),
                                              );
                                            },
                                          ),

                                          ListTile(
                                            leading:
                                                const Icon(
                                              Icons.inventory,
                                            ),
                                            title:
                                                const Text(
                                              "Manajemen Stok",
                                            ),
                                            onTap:
                                                () {
                                              Navigator.pop(
                                                  context);

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const StockManagementScreen(),
                                                ),
                                              );
                                            },
                                          ),

                                          ListTile(
                                            leading:
                                                const Icon(
                                              Icons.category,
                                            ),
                                            title:
                                                const Text(
                                              "Kategori",
                                            ),
                                            onTap:
                                                () {
                                              Navigator.pop(
                                                  context);

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      const CategoryScreen(),
                                                ),
                                              );
                                            },
                                          ),

                                          ListTile(
                                            leading:
                                                const Icon(
                                              Icons.delete,
                                              color:
                                                  Colors.red,
                                            ),

                                            title:
                                                const Text(
                                              "Hapus Produk",
                                              style:
                                                  TextStyle(
                                                color:
                                                    Colors.red,
                                              ),
                                            ),

                                            onTap:
                                                () {
                                              setState(
                                                () {
                                                  products.removeAt(
                                                      index);
                                                },
                                              );

                                              Navigator.pop(
                                                  context);

                                              ScaffoldMessenger.of(
                                                      context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content:
                                                      Text(
                                                    "Produk berhasil dihapus",
                                                  ),
                                                ),
                                              );
                                            },
                                          ),

                                          const SizedBox(
                                              height:
                                                  10),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    String text,
    bool selected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        selectedColor: const Color(0xffE60012),
        labelStyle: TextStyle(
          color: selected
              ? Colors.white
              : Colors.black,
        ),
        onSelected: (_) {},
      ),
    );
  }

  Widget _summaryCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor:
                const Color(0xffE60012)
                    .withOpacity(.1),
            child: Icon(
              icon,
              color: const Color(0xffE60012),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}