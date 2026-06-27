# Supabase Setup

Project ini sudah disiapkan untuk workflow Supabase CLI.

## Hubungkan ke project remote

1. Login ke Supabase:

```bash
supabase login
```

2. Link repo ini ke project remote:

```bash
supabase link --project-ref edvkcuflsyccujwmglwp
```

3. Push migration ke database remote:

```bash
supabase db push
```

4. Cek status migration:

```bash
supabase migration list
```

Jika `supabase link` meminta database password, masukkan password database dari
project Supabase Anda.

## Jalankan stack lokal

Butuh Docker Desktop aktif.

```bash
supabase start
supabase db reset
```

## Hubungkan Flutter ke Supabase

Kredensial Flutter dikirim lewat `dart-define`, bukan hardcoded di source code.

1. Salin `dart_defines.example.json` menjadi `dart_defines.json`
2. Isi:
   - `SUPABASE_URL`
   - `SUPABASE_PUBLISHABLE_KEY`
3. Jalankan:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Alternatif:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

Jika credential belum diisi, aplikasi tetap bisa berjalan dalam mode demo lokal.

## File SQL yang tersedia

- `schema.sql`
  Dipakai untuk setup schema inti aplikasi:
  - `profiles`
  - `addresses`
  - `user_settings`
  - `categories`
  - `products`

- `account_schema.sql`
  Dipakai jika Anda ingin fokus setup database akun saja terlebih dahulu:
  - `profiles`
  - `addresses`
  - `user_settings`

Catatan penting:

- Kedua file di atas bukan lagi representasi penuh schema aktif aplikasi retail KDMP.
- Untuk database yang benar-benar dipakai Flutter saat ini, gunakan migration di folder `supabase/migrations/` sebagai source of truth.

## Migration KDMP Retail

Backend retail multi-cabang KDMP sudah mulai dipisahkan melalui migration:

- `supabase/migrations/20260619210602_add_kdmp_retail_backend.sql`
- `supabase/migrations/20260626101500_add_secure_order_transaction_functions.sql`

Migration ini menambahkan atau memperluas:

- `branches`
- `branch_admins`
- `branch_products`
- `promotions`
- `notifications`
- `notification_settings`
- `payment_methods`
- `orders`
- `order_items`
- `stock_movements`
- `branch_performance`

Selain tabel inti, migration tersebut juga menyiapkan:

- helper function RLS untuk `superadmin` dan `branch_admin`
- policy akses data per role
- RPC transaksi order customer dan admin cabang
- bucket storage:
  - `avatars`
  - `product-images`
  - `branch-assets`
  - `promotion-banners`

Catatan:

- Migration ini dibuat additive agar auth, profile, dan address yang sudah ada tetap bisa dipertahankan.
- `products` saat ini tetap dipakai sebagai master produk, sedangkan harga dan stok operasional dipindahkan ke `branch_products`.
- `user_settings` belum dihapus, tetapi preferensi notifikasi mulai diarahkan ke `notification_settings`.

## Workflow Supabase CLI

Project ini sekarang sudah disiapkan untuk workflow Supabase CLI:

1. Inisialisasi lokal sudah ada di `supabase/config.toml`
2. Schema aktif ada di:
   - `supabase/migrations/`
3. Seed data awal ada di:
   - `supabase/seed.sql`

### Perintah yang dipakai

Jalankan stack lokal:

```bash
supabase start
```

Reset database lokal dan apply migration + seed:

```bash
supabase db reset
```

Buat migration baru:

```bash
supabase migration new nama_perubahan
```

Push migration ke project Supabase yang sudah di-link:

```bash
supabase db push
```

## Catatan penting

- Setelah memakai workflow migration, hindari mengubah schema langsung dari SQL Editor remote untuk perubahan permanen.
- Gunakan migration file agar schema tetap sinkron dengan Git.

## Integrasi Sandbox Pembayaran

Project ini menyiapkan alur top up saldo dan checkout `Transfer Bank` atau `QRIS`
melalui sandbox pembayaran internal berbasis Supabase Edge Functions.

### 1. Deploy Edge Functions

Jalankan:

```bash
supabase functions deploy sandbox-start-topup
supabase functions deploy sandbox-sync-topup
supabase functions deploy sandbox-start-order-payment
supabase functions deploy sandbox-sync-order-payment
```

### 2. Push migration terbaru

Jalankan:

```bash
supabase db push
```

Migration yang perlu ikut ter-push:

- `20260624090000_add_sandbox_provider_fields_to_wallet_topups.sql`
- `20260624101500_add_sandbox_provider_fields_to_orders.sql`

Keduanya menambah kolom metadata provider sandbox dan function SQL idempoten
untuk update status top up maupun order.

### 3. Jalankan Flutter

Tidak ada credential provider pembayaran yang perlu ditaruh di aplikasi Flutter
karena seluruh simulasi dijalankan oleh backend Supabase Function.

Tetap jalankan app seperti biasa:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

### 4. Simulasi pembayaran Sandbox

- Pilih `Virtual Account` atau `QRIS` saat top up.
- Untuk checkout, pilih `Transfer Bank` atau `QRIS`.
- Setelah transaksi dibuat, tunggu beberapa detik lalu tekan tombol `Cek Status`.
- Status sandbox akan berubah otomatis menjadi berhasil selama transaksi belum kedaluwarsa.
