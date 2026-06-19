import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() =>
      _AddProductScreenState();
}

class _AddProductScreenState
    extends State<AddProductScreen> {

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Produk"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: ListView(
          children: [

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Nama Produk",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: "Harga",
              ),
            ),

            const SizedBox(height: 16),

            TextField(
              controller: stockController,
              decoration: const InputDecoration(
                labelText: "Stok",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {},
              child: const Text(
                "Simpan Produk",
              ),
            ),
          ],
        ),
      ),
    );
  }
}