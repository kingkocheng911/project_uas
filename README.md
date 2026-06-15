# project_uas

Flutter app dengan backend Supabase.

## Flutter app

Project ini memakai `supabase_flutter` untuk autentikasi dan sinkronisasi data.
Kredensial Supabase tidak lagi disimpan hardcoded di source code, tetapi dikirim
lewat `dart-define`.

1. Salin `dart_defines.example.json` menjadi `dart_defines.json`
2. Isi nilai Supabase Anda
3. Jalankan aplikasi:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Alternatif tanpa file:

```bash
flutter run --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_SUPABASE_PUBLISHABLE_KEY
```

Jika credential belum diisi, aplikasi tetap berjalan dalam mode demo lokal.

## Supabase CLI workflow

Konfigurasi CLI ada di folder `supabase/`.

1. Login ke Supabase CLI:

```bash
supabase login
```

2. Link repo ini ke project Supabase remote:

```bash
supabase link --project-ref edvkcuflsyccujwmglwp
```

3. Push migration ke database remote:

```bash
supabase db push
```

4. Cek daftar migration:

```bash
supabase migration list
```

## Local development dengan Supabase CLI

Butuh Docker Desktop aktif.

```bash
supabase start
supabase db reset
```

File penting:

- `supabase/migrations/20260611130722_initial_app_database.sql`
- `supabase/seed.sql`
- `supabase/schema.sql`
- `supabase/account_schema.sql`

## Catatan

- Gunakan migration file untuk perubahan schema permanen.
- Hindari mengubah schema remote langsung dari SQL Editor jika perubahan itu
  perlu tersimpan di Git.
