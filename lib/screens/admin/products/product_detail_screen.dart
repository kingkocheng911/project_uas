import 'package:flutter/material.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      body: CustomScrollView(
        slivers: [

          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,

            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(
                    Icons.image,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(
                    "Beras Premium 5kg",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Rp 65.000",
                    style: TextStyle(
                      color: Color(0xffE60012),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    children: [

                      _infoChip(
                        "Sembako",
                        Icons.category,
                      ),

                      const SizedBox(width: 10),

                      _infoChip(
                        "25 Stok",
                        Icons.inventory,
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  _statCard(),

                  const SizedBox(height: 25),

                  const Text(
                    "Deskripsi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Beras premium kualitas terbaik untuk kebutuhan rumah tangga dan usaha.",
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    children: [

                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit),
                          label:
                              const Text("Edit Produk"),

                          style:
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(
                                    0xffE60012),
                          ),

                          onPressed: () {},
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: OutlinedButton.icon(
                          icon:
                              const Icon(Icons.inventory),
                          label:
                              const Text("Kelola Stok"),
                          onPressed: () {},
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
    );
  }

  Widget _infoChip(
    String text,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 8,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.05),
            blurRadius: 8,
          )
        ],
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 5),
          Text(text),
        ],
      ),
    );
  }

  Widget _statCard() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: const Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [

          Column(
            children: [
              Text(
                "150",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Terjual"),
            ],
          ),

          Column(
            children: [
              Text(
                "4.9",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Rating"),
            ],
          ),

          Column(
            children: [
              Text(
                "25",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Stok"),
            ],
          ),
        ],
      ),
    );
  }
}