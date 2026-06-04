import 'package:flutter/material.dart';

import 'models.dart';

const categories = <CategoryItem>[
  CategoryItem(label: 'Grocery', icon: Icons.local_grocery_store_rounded),
  CategoryItem(label: 'Fresh', icon: Icons.eco_outlined),
  CategoryItem(label: 'Pharmacy', icon: Icons.medical_services_outlined),
  CategoryItem(label: 'Electronics', icon: Icons.devices_outlined),
  CategoryItem(label: 'Services', icon: Icons.support_agent_outlined),
];

const promos = <PromoBanner>[
  PromoBanner(
    title: 'Sembako Murah',
    subtitle: 'Essential goods at village prices.',
    icon: Icons.shopping_basket_rounded,
    colors: [Color(0xFF173C1F), Color(0xFF355B2A)],
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuAEo9wVK97Sm7CFLRk5gmqrR7Rx7OqVnBowIsYCjWr-AvQQJCerc8vhMtWMNCdLiELjh19V7rzxbgE46Ww3AkFW2B3PuMJco0sZAKu049RJ5770udteDtgEa3lNb24-lNAKx1juSxvers0eX5-KgLx6wi8EhjIk1b55rISqeUUM_-fxQd768DUSlqJUVNV72etYavzkansc89552Y5iqGzJEAyC-d46fAvYnMi1ytbWHpbh5hTSHOpLrqGsUDlpFGUHq7XRyFXRS2n0',
  ),
  PromoBanner(
    title: 'Member Discounts',
    subtitle: 'Exclusive deals for KDMP members only.',
    icon: Icons.workspace_premium_rounded,
    colors: [Color(0xFF8E0011), Color(0xFFD9001B)],
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCMQlE4Ymdce44uLRZ58MU8JfcVSyNTENFr4VaBD5CjFE_VRZY2k_2nJ0bg_V5ZS6PZzvR3xzXAXDf-lrHaciepbUeFWImXggMEcAU9qZ_qSOvM0G-wiw4DEXwfyrbOa6iVinYc84vatLeeRcrbPGe3piL6cdGMAtRLtDryP8kEvZ7CZdqR4FRoGYN48pvGAT4qXnYDIZu-HeQhS6G0mFIkmB2P-vt5mMBTkXXEH_9geMZmqYA51FLSgLhNaEOddSD3ZTbM1dlca31X',
  ),
];

const products = <Product>[
  Product(
    id: 'rice',
    name: 'Beras Premium 5kg',
    price: 65000,
    originalPrice: 82000,
    claimedPercent: 70,
    rewardPoints: 75,
    badge: 'Cooperatively Sourced',
    description:
        'Beras premium dari koperasi desa dengan kualitas stabil, aroma wangi, dan cocok untuk kebutuhan keluarga harian.',
    icon: Icons.rice_bowl_rounded,
    tone: Color(0xFFB88A44),
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuCYGUUcwqUMgufcQqiugoWXViQWvRED6Ju6tw8B3P6vtnWsHvR0OoH1OzL_lyhRjSmQpf7spTfKDdzYlxy-tdnV25rlnYLJ1y_Na4ZUIs7NeuphU7Y-cvmf7qzMcEfOH1jVS3L7cWYhQ46193Gi6fru9GkiO2F1S4dcBsE-K7kfgnJnvTOAc5fMhtKVPFk92C_GZUsLxn4HI2APT6vghq021oVS03pLwR0rQYmSvtCfZgM0_WTgKCmCLCONxnwzGFOiOCKueChS1Kjx',
    highlights: [
      '100% Organic',
      'Village Co-op',
      'Quality Tested',
      'Fast Delivery',
    ],
    relatedIds: ['oil', 'honey'],
  ),
  Product(
    id: 'oil',
    name: 'Minyak Goreng 2L',
    price: 32000,
    originalPrice: 38000,
    claimedPercent: 35,
    rewardPoints: 28,
    badge: 'Daily Essential',
    description:
        'Minyak goreng jernih dengan harga ramah anggota, tersedia untuk pembelian reguler maupun program sembako bulanan.',
    icon: Icons.water_drop_outlined,
    tone: Color(0xFFC89D28),
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuDj7aNubhXpJ3yDOVlWGzFwo_1B8ih4-JT0z-3kbKJW2A1-t03GitLX6-4JcPTYZezlXa5QhVzAnHoM8cA5gxKaH7g6h6RJLJWeRslG9rV-O8Zt6jlG7rTuDMlkQw3hXduQYKiBMXFr_pLbw1RLqG5bd93S-dey2tE7UbmP1Yo4j6QWjzHNEQeWETOEeK8bOw6O7giju0IAx4KFh2hRQidG5lJuNnMCr5clrZTkBcSdbNNBjZdGN5F9ZffpJcQ92diS-8JH_yEwIfZc',
    highlights: ['Trusted Brand', 'Ready Pickup', 'Bulk Order', 'Price Stable'],
    relatedIds: ['rice', 'coffee'],
  ),
  Product(
    id: 'smartband',
    name: 'KDMP Smart Band',
    price: 199000,
    originalPrice: 249000,
    claimedPercent: 90,
    rewardPoints: 120,
    badge: 'Member Favorite',
    description:
        'Perangkat wearable untuk anggota aktif dengan pelacakan kesehatan, notifikasi transaksi, dan fitur pembayaran cepat.',
    icon: Icons.watch_outlined,
    tone: Color(0xFF616A72),
    imageUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuC07iseQS0S0Rfhmc607HIkovcmPRprKhd0hMLfSbq2wCS7ABJQu5EI4bQ2DZo2QsRzo8KscF86Po-DW3lScOwUxep74FuKg_6Bam56l3-m_HbdOYclkx-cD5nuGOJRrZuO637e4KOM-90w3soZ-Qf8Fo4QDSsNj-cpi_EHXUEv2lihUAQ2gkL2eMPQB6T534cuNVR7HAScJgeGE0PzvkDdS-paU2rH_phcFVtcqilA0Eie92a0nVMdGLkGofaev9em_uRIMe9zGMGg',
    highlights: [
      '1 Year Warranty',
      'Cashless Ready',
      'Health Tracking',
      'Quick Pairing',
    ],
    relatedIds: ['powerbank', 'coffee'],
  ),
  Product(
    id: 'honey',
    name: 'Forest Honey 250ml',
    price: 45000,
    originalPrice: 52000,
    claimedPercent: 48,
    rewardPoints: 32,
    badge: 'Natural Product',
    description:
        'Madu hutan murni hasil UMKM anggota koperasi, cocok untuk konsumsi keluarga maupun paket hadiah komunitas.',
    icon: Icons.emoji_food_beverage_outlined,
    tone: Color(0xFF924B2E),
    highlights: [
      'No Preservatives',
      'Local UMKM',
      'Gift Ready',
      'Healthy Choice',
    ],
    relatedIds: ['rice', 'coffee'],
  ),
  Product(
    id: 'coffee',
    name: 'Arabica Village Blend',
    price: 32000,
    originalPrice: 39000,
    claimedPercent: 55,
    rewardPoints: 24,
    badge: 'Freshly Roasted',
    description:
        'Kopi arabika blend dari pegunungan desa binaan, diproses oleh koperasi untuk cita rasa seimbang dan segar.',
    icon: Icons.coffee_outlined,
    tone: Color(0xFF5A3727),
    highlights: [
      'Fresh Roast',
      'Village Farmers',
      'Cafe Quality',
      'Ground to Order',
    ],
    relatedIds: ['honey', 'rice'],
  ),
  Product(
    id: 'powerbank',
    name: 'Power Bank 10.000mAh',
    price: 145000,
    originalPrice: 175000,
    claimedPercent: 41,
    rewardPoints: 64,
    badge: 'Tech Essentials',
    description:
        'Power bank untuk operasional lapangan anggota dan perangkat toko digital, lengkap dengan proteksi pengisian aman.',
    icon: Icons.battery_charging_full_rounded,
    tone: Color(0xFF325B83),
    highlights: ['Fast Charge', 'Safe Battery', 'Portable', 'Business Ready'],
    relatedIds: ['smartband', 'oil'],
  ),
];

const orders = <OrderItem>[
  OrderItem(
    id: 'ORD-240526-01',
    title: 'Beras Premium 5kg x 2',
    status: 'On Delivery',
    createdAt: '26 May 2026, 09:15',
    total: 130000,
    progressLabel: 'Kurir menuju lokasi pengantaran',
    address: 'Jl. Merdeka No. 42, Sukamaju Village',
    items: ['Beras Premium 5kg', 'Voucher Ongkir Anggota'],
  ),
  OrderItem(
    id: 'ORD-240525-02',
    title: 'Minyak Goreng 2L',
    status: 'Ready for Pickup',
    createdAt: '25 May 2026, 15:40',
    total: 32000,
    progressLabel: 'Pesanan siap diambil di koperasi',
    address: 'KDMP Sukamaju - Pickup Counter',
    items: ['Minyak Goreng 2L'],
  ),
  OrderItem(
    id: 'ORD-240523-03',
    title: 'KDMP Smart Band',
    status: 'Completed',
    createdAt: '23 May 2026, 13:10',
    total: 199000,
    progressLabel: 'Pesanan selesai dan poin masuk',
    address: 'Jl. Merdeka No. 42, Sukamaju Village',
    items: ['KDMP Smart Band', 'Garansi 1 Tahun'],
  ),
];

const activities = <ActivityEntry>[
  ActivityEntry(
    title: 'Pembayaran berhasil',
    subtitle: 'Top up saldo KDMP sebesar Rp 250.000 berhasil diproses.',
    icon: Icons.account_balance_wallet_outlined,
    color: Color(0xFF1A936F),
    time: '10 menit lalu',
  ),
  ActivityEntry(
    title: 'Promo baru tersedia',
    subtitle: 'Flash sale kebutuhan dapur dibuka untuk anggota area Sukamaju.',
    icon: Icons.local_offer_outlined,
    color: Color(0xFFD9001B),
    time: '1 jam lalu',
  ),
  ActivityEntry(
    title: 'Alamat diperbarui',
    subtitle: 'Alamat pengiriman utama berhasil diubah melalui profil.',
    icon: Icons.location_on_outlined,
    color: Color(0xFF5A6C7D),
    time: 'Kemarin',
  ),
];

const profileSettings = <SettingShortcut>[
  SettingShortcut(
    title: 'Personal Info',
    subtitle: 'Kelola nama, nomor telepon, dan email.',
    icon: Icons.person_outline_rounded,
  ),
  SettingShortcut(
    title: 'Saved Addresses',
    subtitle: 'Simpan alamat rumah, toko, dan pickup point.',
    icon: Icons.location_on_outlined,
  ),
  SettingShortcut(
    title: 'Payment Methods',
    subtitle: 'Atur rekening, e-wallet, dan saldo koperasi.',
    icon: Icons.credit_card_outlined,
  ),
  SettingShortcut(
    title: 'Notifications',
    subtitle: 'Kontrol promo, pesanan, dan pengingat pembayaran.',
    icon: Icons.notifications_none_rounded,
  ),
  SettingShortcut(
    title: 'Security',
    subtitle: 'PIN, verifikasi login, dan perlindungan akun.',
    icon: Icons.shield_outlined,
  ),
];
