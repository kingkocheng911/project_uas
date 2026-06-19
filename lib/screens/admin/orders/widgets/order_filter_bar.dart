import 'package:flutter/material.dart';

class OrderFilterBar extends StatelessWidget {
  const OrderFilterBar({super.key});

  @override
  Widget build(BuildContext context) {

    final filters = [
      "Semua",
      "Pending",
      "Diproses",
      "Dikirim",
      "Selesai"
    ];

    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        itemBuilder: (context,index){

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Chip(
              label: Text(filters[index]),
            ),
          );
        },
      ),
    );
  }
}