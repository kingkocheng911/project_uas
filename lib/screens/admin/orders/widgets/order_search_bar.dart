import 'package:flutter/material.dart';

class OrderSearchBar extends StatelessWidget {
  const OrderSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      hintText: "Cari Order...",
      leading: const Icon(Icons.search),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStateProperty.all(
        Colors.white,
      ),
    );
  }
}