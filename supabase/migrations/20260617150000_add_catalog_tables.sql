create extension if not exists "pgcrypto";

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  label text not null unique,
  icon_name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.products (
  id text primary key,
  name text not null,
  price integer not null,
  original_price integer not null,
  stock integer not null default 0,
  claimed_percent integer not null default 0,
  reward_points integer not null default 0,
  badge text not null default '',
  description text not null,
  icon_name text not null,
  tone_hex text not null,
  image_url text,
  category_labels text[] not null default '{}',
  highlights text[] not null default '{}',
  related_ids text[] not null default '{}',
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

drop trigger if exists set_products_updated_at on public.products;
create trigger set_products_updated_at
before update on public.products
for each row execute procedure public.set_updated_at();

alter table public.categories enable row level security;
alter table public.products enable row level security;

drop policy if exists "anyone can read categories" on public.categories;
create policy "anyone can read categories"
on public.categories
for select
to authenticated, anon
using (true);

drop policy if exists "anyone can read products" on public.products;
create policy "anyone can read products"
on public.products
for select
to authenticated, anon
using (true);

insert into public.categories (label, icon_name, sort_order)
values
  ('Makanan', 'restaurant_outlined', 1),
  ('Minuman', 'local_cafe_outlined', 2),
  ('Sembako', 'shopping_basket_outlined', 3),
  ('Alat-alat', 'handyman_outlined', 4),
  ('Olahraga', 'sports_soccer_outlined', 5),
  ('Elektronik', 'devices_outlined', 6),
  ('Fashion', 'checkroom_outlined', 7)
on conflict (label) do update
set
  icon_name = excluded.icon_name,
  sort_order = excluded.sort_order,
  is_active = true;

insert into public.products (
  id,
  name,
  price,
  original_price,
  stock,
  claimed_percent,
  reward_points,
  badge,
  description,
  icon_name,
  tone_hex,
  image_url,
  category_labels,
  highlights,
  related_ids,
  sort_order
)
values
  (
    'rice',
    'Beras Premium 5kg',
    65000,
    82000,
    24,
    70,
    75,
    'Cooperatively Sourced',
    'Beras pilihan dari mitra koperasi desa dengan bulir utuh, tekstur pulen, dan kualitas yang dikurasi untuk kebutuhan keluarga. Dikemas higienis agar tetap segar sampai ke rumah anggota.',
    'rice_bowl_rounded',
    '#B88A44',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuCYGUUcwqUMgufcQqiugoWXViQWvRED6Ju6tw8B3P6vtnWsHvR0OoH1OzL_lyhRjSmQpf7spTfKDdzYlxy-tdnV25rlnYLJ1y_Na4ZUIs7NeuphU7Y-cvmf7qzMcEfOH1jVS3L7cWYhQ46193Gi6fru9GkiO2F1S4dcBsE-K7kfgnJnvTOAc5fMhtKVPFk92C_GZUsLxn4HI2APT6vghq021oVS03pLwR0rQYmSvtCfZgM0_WTgKCmCLCONxnwzGFOiOCKueChS1Kjx',
    array['Sembako', 'Makanan'],
    array['100% Organic', 'Village Co-op', 'Quality Tested', 'Fast Delivery'],
    array['oil', 'honey'],
    1
  ),
  (
    'oil',
    'Minyak Goreng 2L',
    32000,
    38000,
    36,
    35,
    28,
    'Daily Essential',
    'Minyak goreng jernih untuk kebutuhan dapur harian dengan harga anggota yang stabil. Cocok untuk memasak rumah tangga, usaha kecil, maupun paket sembako bulanan koperasi.',
    'water_drop_outlined',
    '#C89D28',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuDj7aNubhXpJ3yDOVlWGzFwo_1B8ih4-JT0z-3kbKJW2A1-t03GitLX6-4JcPTYZezlXa5QhVzAnHoM8cA5gxKaH7g6h6RJLJWeRslG9rV-O8Zt6jlG7rTuDMlkQw3hXduQYKiBMXFr_pLbw1RLqG5bd93S-dey2tE7UbmP1Yo4j6QWjzHNEQeWETOEeK8bOw6O7giju0IAx4KFh2hRQidG5lJuNnMCr5clrZTkBcSdbNNBjZdGN5F9ZffpJcQ92diS-8JH_yEwIfZc',
    array['Sembako', 'Makanan'],
    array['Trusted Brand', 'Ready Pickup', 'Bulk Order', 'Price Stable'],
    array['rice', 'coffee'],
    2
  ),
  (
    'smartband',
    'MepuPoin Smart Band',
    199000,
    249000,
    12,
    90,
    120,
    'Member Favorite',
    'Smart band modern untuk anggota aktif MepuPoin dengan pemantauan aktivitas, notifikasi transaksi, dan dukungan pembayaran cepat. Ringan dipakai harian dan mudah dipasangkan dengan ponsel.',
    'watch_outlined',
    '#616A72',
    'https://lh3.googleusercontent.com/aida-public/AB6AXuC07iseQS0S0Rfhmc607HIkovcmPRprKhd0hMLfSbq2wCS7ABJQu5EI4bQ2DZo2QsRzo8KscF86Po-DW3lScOwUxep74FuKg_6Bam56l3-m_HbdOYclkx-cD5nuGOJRrZuO637e4KOM-90w3soZ-Qf8Fo4QDSsNj-cpi_EHXUEv2lihUAQ2gkL2eMPQB6T534cuNVR7HAScJgeGE0PzvkDdS-paU2rH_phcFVtcqilA0Eie92a0nVMdGLkGofaev9em_uRIMe9zGMGg',
    array['Elektronik', 'Olahraga', 'Fashion'],
    array['1 Year Warranty', 'Cashless Ready', 'Health Tracking', 'Quick Pairing'],
    array['powerbank', 'coffee'],
    3
  ),
  (
    'honey',
    'Forest Honey 250ml',
    45000,
    52000,
    18,
    48,
    32,
    'Natural Product',
    'Madu hutan dari UMKM anggota koperasi dengan rasa alami dan aroma khas. Diproses secara hati-hati untuk menjaga kualitas, cocok untuk konsumsi keluarga, hampers, atau kebutuhan usaha minuman.',
    'emoji_food_beverage_outlined',
    '#924B2E',
    null,
    array['Makanan', 'Sembako'],
    array['No Preservatives', 'Local UMKM', 'Gift Ready', 'Healthy Choice'],
    array['rice', 'coffee'],
    4
  ),
  (
    'coffee',
    'Arabica Village Blend',
    32000,
    39000,
    28,
    55,
    24,
    'Freshly Roasted',
    'Kopi arabika blend dari petani desa binaan dengan profil rasa seimbang, aroma hangat, dan tingkat sangrai yang nyaman untuk diminum setiap hari. Digiling sesuai kebutuhan agar tetap segar.',
    'coffee_outlined',
    '#5A3727',
    null,
    array['Minuman', 'Makanan'],
    array['Fresh Roast', 'Village Farmers', 'Cafe Quality', 'Ground to Order'],
    array['honey', 'rice'],
    5
  ),
  (
    'powerbank',
    'Power Bank 10.000mAh',
    145000,
    175000,
    10,
    41,
    64,
    'Tech Essentials',
    'Power bank berkapasitas besar untuk mendukung aktivitas lapangan, perjalanan, dan operasional toko digital. Dilengkapi proteksi pengisian agar perangkat tetap aman dan siap digunakan.',
    'battery_charging_full_rounded',
    '#325B83',
    null,
    array['Elektronik', 'Alat-alat', 'Olahraga'],
    array['Fast Charge', 'Safe Battery', 'Portable', 'Business Ready'],
    array['smartband', 'oil'],
    6
  )
on conflict (id) do update
set
  name = excluded.name,
  price = excluded.price,
  original_price = excluded.original_price,
  stock = excluded.stock,
  claimed_percent = excluded.claimed_percent,
  reward_points = excluded.reward_points,
  badge = excluded.badge,
  description = excluded.description,
  icon_name = excluded.icon_name,
  tone_hex = excluded.tone_hex,
  image_url = excluded.image_url,
  category_labels = excluded.category_labels,
  highlights = excluded.highlights,
  related_ids = excluded.related_ids,
  sort_order = excluded.sort_order,
  is_active = true;
