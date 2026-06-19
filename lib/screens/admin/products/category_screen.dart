import 'package:flutter/material.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      "Sembako",
      "Minuman",
      "Makanan",
      "Peralatan"
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF5F7FA),

      appBar: AppBar(
        title: const Text("Kategori Produk"),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            const Color(0xffE60012),

        onPressed: () {},

        label: const Text(
          "Tambah",
          style: TextStyle(
            color: Colors.white,
          ),
        ),

        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: categories.length,

        itemBuilder: (context, index) {
          return Card(
            elevation: 3,

            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(18),
            ),

            child: ListTile(
              leading:
                  const Icon(Icons.category),

              title:
                  Text(categories[index]),

              trailing: Row(
                mainAxisSize:
                    MainAxisSize.min,

                children: [

                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      color: Colors.blue,
                    ),
                    onPressed: () {},
                  ),

                  IconButton(
                    icon: const Icon(
                      Icons.delete,
                      color: Colors.red,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}