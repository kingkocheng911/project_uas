import 'package:flutter/material.dart';

class CategoryItem {
  const CategoryItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class ActiveProfile {
  final String name;
  final String phone;
  final String email;
  final String avatarUrl;
  final String role; // <-- Pastikan ada baris ini

  const ActiveProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.avatarUrl,
    this.role = 'user', // Default 'user'
  });
}

class PromoBanner {
  const PromoBanner({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    this.imageUrl,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final String? imageUrl;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.originalPrice,
    required this.stock,
    required this.claimedPercent,
    required this.rewardPoints,
    required this.badge,
    required this.description,
    required this.icon,
    required this.tone,
    required this.categories,
    this.imageUrl,
    required this.highlights,
    required this.relatedIds,
  });

  final String id;
  final String name;
  final int price;
  final int originalPrice;
  final int stock;
  final int claimedPercent;
  final int rewardPoints;
  final String badge;
  final String description;
  final IconData icon;
  final Color tone;
  final List<String> categories;
  final String? imageUrl;
  final List<String> highlights;
  final List<String> relatedIds;
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.total,
    required this.progressLabel,
    required this.address,
    required this.items,
  });

  final String id;
  final String title;
  final String status;
  final String createdAt;
  final int total;
  final String progressLabel;
  final String address;
  final List<String> items;
}

class ActivityEntry {
  const ActivityEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.time,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String time;
}

class SettingShortcut {
  const SettingShortcut({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
