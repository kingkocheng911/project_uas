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

## Workflow Supabase CLI

Project ini sekarang sudah disiapkan untuk workflow Supabase CLI:

1. Inisialisasi lokal sudah ada di `supabase/config.toml`
2. Migration utama ada di:
   - `supabase/migrations/20260611130722_initial_app_database.sql`
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
