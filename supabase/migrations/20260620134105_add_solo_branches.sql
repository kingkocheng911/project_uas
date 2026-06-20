insert into public.branches (
  code,
  name,
  phone,
  email,
  address,
  province,
  city,
  district,
  postal_code,
  latitude,
  longitude,
  is_active,
  opened_at
)
values
  (
    'KDMP-SLO-01',
    'KDMP Solo Banjarsari',
    '+62 271 555 0101',
    'banjarsari@kdmp.co.id',
    'Jl. Ahmad Yani No. 178, Manahan, Banjarsari, Surakarta',
    'Jawa Tengah',
    'Surakarta',
    'Banjarsari',
    '57139',
    -7.5561000,
    110.8065000,
    true,
    date '2026-06-20'
  ),
  (
    'KDMP-SLO-02',
    'KDMP Solo Jebres',
    '+62 271 555 0102',
    'jebres@kdmp.co.id',
    'Jl. Ir. Sutami No. 36, Jebres, Surakarta',
    'Jawa Tengah',
    'Surakarta',
    'Jebres',
    '57126',
    -7.5609000,
    110.8342000,
    true,
    date '2026-06-20'
  )
on conflict (code) do update
set
  name = excluded.name,
  phone = excluded.phone,
  email = excluded.email,
  address = excluded.address,
  province = excluded.province,
  city = excluded.city,
  district = excluded.district,
  postal_code = excluded.postal_code,
  latitude = excluded.latitude,
  longitude = excluded.longitude,
  is_active = excluded.is_active,
  opened_at = excluded.opened_at,
  updated_at = now();
